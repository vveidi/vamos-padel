import Foundation
import PadelScoring
import PadelStorage

/// The phone's end of the live link, holding the match it scores, paired or
/// alone. Every change is written to the store and goes out to the remote and
/// to ``updates()``. ``MatchRemote`` is the watch's end.
public final class MatchScorer: @unchecked Sendable {
    private let store: any MatchStore
    private let link: any ScorerLink

    /// Guards `held`, and is held across the write and both sends, so two
    /// changes never go out in the opposite order to the one they were made in.
    /// The link is sent to under it and must not call back before returning.
    private let lock = NSLock()
    private var held: SavedMatch?

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
    public func start(ruleset: Ruleset, firstServer: Side) -> SavedMatch? {
        lock.withLock {
            guard startLocked(ruleset: ruleset, firstServer: firstServer) else { return nil }

            publish(echo: nil)

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
    public func release() {
        lock.withLock {
            held = nil

            publish(echo: nil)
        }
    }

    /// Refused, with nothing changed, when there is no match running or `base`
    /// is not its number of rallies; a `start` is refused while one runs.
    public func apply(_ intent: MatchIntent) {
        lock.withLock {
            let accepted =
                switch intent {
                case .rally(let side, let base) where stands(on: base): changeLocked(.rally(side))
                case .undo(let base) where stands(on: base): changeLocked(.undo)
                case .end(let base) where stands(on: base): changeLocked(.end)
                case .start(let ruleset, let firstServer):
                    startLocked(ruleset: ruleset, firstServer: firstServer)
                default: false
                }

            publish(echo: Echo(intent: intent, accepted: accepted))
        }
    }

    private enum Change {
        case rally(Side)
        case undo
        case end
    }

    private func change(_ change: Change) {
        lock.withLock {
            guard changeLocked(change) else { return }

            publish(echo: nil)
        }
    }

    private func republish() {
        lock.withLock { publish(echo: nil) }
    }

    // MARK: Under the lock

    private var isRunning: Bool {
        held.map { !$0.match.state.outcome.isOver } ?? false
    }

    private func stands(on base: Int) -> Bool {
        isRunning && held?.match.journal.count == base
    }

    private func startLocked(ruleset: Ruleset, firstServer: Side) -> Bool {
        guard !isRunning else { return false }

        let started = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: .now)

        held = started
        persist(started)

        return true
    }

    /// - Returns: `false` when the match was left as it was.
    private func changeLocked(_ change: Change) -> Bool {
        guard let before = held else { return false }

        var match = before
        switch change {
        case .rally(let side): match.record(rallyWonBy: side, at: .now)
        case .undo: match.undo(at: .now)
        case .end: match.abandon()
        }

        guard match != before else { return false }

        held = match
        persist(match)

        return true
    }

    private func publish(echo: Echo?) {
        let update: MatchUpdate = held.map { .match($0, echo: echo) } ?? .noMatch(echo: echo)

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
