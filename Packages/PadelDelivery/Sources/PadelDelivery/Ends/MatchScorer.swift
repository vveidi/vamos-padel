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
    private let held: Mutex<SavedMatch?>

    private let broadcast: Broadcast<MatchUpdate>
    private let reachability = Broadcast<Bool>()
    private let declines = Broadcast<Void>(keepsLatest: false)

    private let matchLog = MatchLog(subsystem: "com.vveidi.padel")

    /// Takes the phone's own unfinished match back from the store.
    /// - Important: Build it before the link comes up, or the remote hears
    ///   that there is no match and closes the one it was showing.
    public init(store: any MatchStore, link: any ScorerLink) {
        self.store = store
        self.link = link

        let restored = Self.restore(from: store)
        held = Mutex(restored)
        broadcast = Broadcast(Self.update(restored, echo: nil))

        if let restored { matchLog.restored(restored) }

        link.onIntent { [weak self] intent in self?.apply(intent) }

        // The remote keeps nothing, so a link that comes back is answered with
        // the match as it stands.
        link.onReachabilityChange { [weak self, reachability] isReachable in
            reachability.send(isReachable)

            if isReachable { self?.republish() }
        }

        // Read after subscribing, so a change made in between is not lost.
        reachability.send(link.isReachable)
    }

    /// The first value is the update as it stands.
    public func updates() -> AsyncStream<MatchUpdate> {
        broadcast.stream()
    }

    /// The first value is whether the remote is reachable now.
    public func reachabilityChanges() -> AsyncStream<Bool> {
        reachability.stream()
    }

    /// A value each time the remote answers ``MatchIntent/scoringAlone``, heard
    /// only by a listener subscribed before it arrived.
    public func remoteDeclines() -> AsyncStream<Void> {
        declines.stream()
    }

    /// - Precondition: `scoring` is not ``MatchScoring/aloneOnWatch``.
    /// - Returns: `nil` when refused, because a match is already running.
    @discardableResult
    public func start(ruleset: Ruleset, firstServer: Side, scoring: MatchScoring) -> SavedMatch? {
        precondition(scoring != .aloneOnWatch, "the phone does not score the watch's match")

        return held.withLock { held in
            guard start(&held, ruleset: ruleset, firstServer: firstServer, scoring: scoring) else {
                return nil
            }

            publish(held, echo: nil)

            return held
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
    /// Does nothing once the scorer holds another match: one the remote
    /// started after `matchID` was read.
    public func release(_ matchID: UUID) {
        held.withLock { held in
            guard held?.id == matchID else { return }

            held = nil

            publish(held, echo: nil)
        }
    }

    /// Refused, with nothing changed, when there is no paired match running or
    /// `base` is not its number of rallies; a `start` is refused while any
    /// match runs, and what it starts is paired.
    public func apply(_ intent: MatchIntent) {
        guard intent != .scoringAlone else { return declines.send(()) }

        held.withLock { held in
            let accepted =
                switch intent {
                case .rally(let side, let base) where held.answers(on: base): change(&held, .rally(side))
                case .undo(let base) where held.answers(on: base): change(&held, .undo)
                case .end(let base) where held.answers(on: base): change(&held, .end)
                case .start(let ruleset, let firstServer):
                    start(&held, ruleset: ruleset, firstServer: firstServer, scoring: .paired)
                case .rally, .undo, .end, .scoringAlone: false
                }

            publish(held, echo: Echo(intent: intent, accepted: accepted))
        }
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

    /// A read that fails is logged and the scorer starts empty, as on a fresh
    /// install.
    private static func restore(from store: any MatchStore) -> SavedMatch? {
        do {
            return try store.matchInProgress(scored: [.aloneOnPhone, .paired])
        } catch {
            logger.error("the match in progress was not read: \(error.localizedDescription)")

            return nil
        }
    }

    private static func update(_ held: SavedMatch?, echo: Echo?) -> MatchUpdate {
        held.map { .match($0, echo: echo) } ?? .noMatch(echo: echo)
    }

    // MARK: Under the lock

    private func start(
        _ held: inout SavedMatch?, ruleset: Ruleset, firstServer: Side, scoring: MatchScoring
    ) -> Bool {
        guard !held.isRunning else { return false }

        let started = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), scoring: scoring,
            startedAt: .now)

        held = started
        matchLog.started(started)
        persist(started)

        return true
    }

    /// - Returns: `false` when the match was left as it was.
    private func change(_ held: inout SavedMatch?, _ change: Change) -> Bool {
        guard let before = held else { return false }

        var match = before
        switch change {
        case .rally(let side): match.record(rallyWonBy: side, at: .now)
        case .undo: match.undo(at: .now)
        case .end: match.abandon()
        }

        guard match != before else { return false }

        held = match
        matchLog.changed(from: before, to: match)
        persist(match)

        return true
    }

    private func publish(_ held: SavedMatch?, echo: Echo?) {
        let update = Self.update(held, echo: echo)

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

extension Optional where Wrapped == SavedMatch {
    fileprivate var isRunning: Bool {
        map { !$0.match.state.outcome.isOver } ?? false
    }

    fileprivate func answers(on base: Int) -> Bool {
        isRunning && self?.isPaired == true && self?.match.journal.count == base
    }
}
