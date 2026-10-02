import Foundation
import PadelScoring
import PadelStorage
import Synchronization

/// The phone's end of the live link, holding the match it scores, paired or
/// alone. Every change is written to the store and goes out to the remote and
/// to ``updates()``. ``MatchRemote`` is the watch's end.
public final class MatchScorer: Sendable {
    private let store: any MatchStore
    private let link: any ScorerLink

    /// Held across the write and both sends, so two changes never go out in
    /// the opposite order to the one they were made in. The link is sent to
    /// under it and must not call back before returning.
    private let held = Mutex<Held?>(nil)

    private let broadcast = Broadcast<MatchUpdate>(.noMatch(echo: nil))

    public init(store: any MatchStore, link: any ScorerLink) {
        self.store = store
        self.link = link

        link.onIntent { [weak self] intent in self?.apply(intent) }

        // The remote keeps nothing, so a link that comes back is answered with
        // the match as it stands.
        link.onReachabilityChange { [weak self] isReachable in
            if isReachable { self?.republish() }
        }
    }

    /// The first value is the update as it stands.
    public func updates() -> AsyncStream<MatchUpdate> {
        broadcast.stream()
    }

    /// - Returns: `nil` when refused, because a match is already running.
    @discardableResult
    public func start(ruleset: Ruleset, firstServer: Side, isPaired: Bool) -> SavedMatch? {
        held.withLock { held in
            guard start(&held, ruleset: ruleset, firstServer: firstServer, isPaired: isPaired) else {
                return nil
            }

            publish(held, echo: nil)

            return held?.saved
        }
    }

    public func record(rallyWonBy side: Side) {
        change(.rally(side))
    }

    public func undo() {
        change(.undo)
    }

    /// Does nothing to a match already over.
    public func end() {
        change(.end)
    }

    /// The match stays in the store as it is, and the scorer holds nothing.
    public func release() {
        held.withLock { held in
            held = nil

            publish(held, echo: nil)
        }
    }

    /// Refused, with nothing changed, when there is no paired match running or
    /// `base` is not its number of rallies; a `start` is refused while any
    /// match runs, and what it starts is paired.
    public func apply(_ intent: MatchIntent) {
        held.withLock { held in
            let accepted =
                switch intent {
                case .rally(let side, let base) where held.answers(on: base): change(&held, .rally(side))
                case .undo(let base) where held.answers(on: base): change(&held, .undo)
                case .end(let base) where held.answers(on: base): change(&held, .end)
                case .start(let ruleset, let firstServer):
                    start(&held, ruleset: ruleset, firstServer: firstServer, isPaired: true)
                default: false
                }

            publish(held, echo: Echo(intent: intent, accepted: accepted))
        }
    }

    fileprivate struct Held {
        var saved: SavedMatch
        let isPaired: Bool
    }

    private enum Change {
        case rally(Side)
        case undo
        case end
    }

    private func change(_ change: Change) {
        held.withLock { held in
            guard self.change(&held, change) else { return }

            publish(held, echo: nil)
        }
    }

    private func republish() {
        held.withLock { held in publish(held, echo: nil) }
    }

    // MARK: Under the lock

    private func start(_ held: inout Held?, ruleset: Ruleset, firstServer: Side, isPaired: Bool) -> Bool {
        guard !held.isRunning else { return false }

        let started = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: .now)

        held = Held(saved: started, isPaired: isPaired)
        persist(started)

        return true
    }

    /// - Returns: `false` when the match was left as it was.
    private func change(_ held: inout Held?, _ change: Change) -> Bool {
        guard let before = held?.saved else { return false }

        var match = before
        switch change {
        case .rally(let side): match.record(rallyWonBy: side, at: .now)
        case .undo: match.undo(at: .now)
        case .end: match.abandon()
        }

        guard match != before else { return false }

        held?.saved = match
        persist(match)

        return true
    }

    private func publish(_ held: Held?, echo: Echo?) {
        let update: MatchUpdate =
            held.map { .match($0.saved, isPaired: $0.isPaired, echo: echo) } ?? .noMatch(echo: echo)

        broadcast.send(update)

        // Unreachable is the usual case for a match scored alone, and a remote
        // that missed an update is answered with the truth on its next intent.
        try? link.send(update)
    }

    /// A write that fails is logged and the match goes on: on court the score
    /// matters more than the record of it.
    private func persist(_ match: SavedMatch) {
        do {
            try store.save(match)
        } catch {
            logger.error("the match was not saved: \(error.localizedDescription)")
        }
    }
}

extension Optional where Wrapped == MatchScorer.Held {
    fileprivate var isRunning: Bool {
        map { !$0.saved.match.state.outcome.isOver } ?? false
    }

    fileprivate func answers(on base: Int) -> Bool {
        isRunning && self?.isPaired == true && self?.saved.match.journal.count == base
    }
}
