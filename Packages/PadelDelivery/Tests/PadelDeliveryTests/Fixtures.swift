import Foundation
import PadelScoring
import PadelStorage
import Synchronization

@testable import PadelDelivery

/// A round second on purpose: the store keeps time to milliseconds, and the
/// round trip through the database and the parcel has to return it unchanged.
let aMoment = Date(timeIntervalSince1970: 1_800_000_000)

let toTwo = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)

extension SavedMatch {
    /// A match in which the listed rallies were played, one per second.
    static func played(
        _ winners: [Side],
        ruleset: Ruleset = .defaultPointsTo,
        firstServer: Side = .us,
        scoring: MatchScoring = .aloneOnWatch,
        from start: Date = aMoment
    ) -> SavedMatch {
        var saved = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), scoring: scoring,
            startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played)))
        }

        return saved
    }
}

final class FakeTransport: MatchSender, MatchReceiver, Sendable {
    private struct Queue {
        var queued: [SavedMatch] = []
        var written: [SavedMatch] = []
        var transportReady: (@Sendable () -> Void)?
        var confirmDelivery: (@Sendable (SavedMatch) -> Void)?
        var receiveMatch: (@Sendable (SavedMatch) -> Void)?
    }

    private let queue = Mutex(Queue())

    /// What the watch handed over since the last ``forget()``.
    var sent: [SavedMatch] { queue.withLock { $0.queued } }

    /// What the phone signed for since the last ``forget()``.
    var receipts: [SavedMatch] { queue.withLock { $0.written } }

    func send(_ match: SavedMatch) {
        queue.withLock { $0.queued.append(match) }
    }

    func confirmArrival(of match: SavedMatch) {
        queue.withLock { $0.written.append(match) }
    }

    func onReady(_ ready: @escaping @Sendable () -> Void) {
        queue.withLock { $0.transportReady = ready }
    }

    func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {
        queue.withLock { $0.confirmDelivery = confirm }
    }

    func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
        queue.withLock { $0.receiveMatch = receive }
    }

    /// The session came up.
    func becomeReady() {
        queue.withLock { $0.transportReady }?()
    }

    func confirmDelivered() {
        deliverReceipts(for: sent)
    }

    /// Receipts get through for exactly the listed versions of the matches.
    func deliverReceipts(for matches: [SavedMatch]) {
        let confirm = queue.withLock { $0.confirmDelivery }

        for match in matches { confirm?(match) }
    }

    /// A match arrived on the phone.
    func deliver(_ match: SavedMatch) {
        queue.withLock { $0.receiveMatch }?(match)
    }

    func forget() {
        queue.withLock { queue in
            queue.queued = []
            queue.written = []
        }
    }
}

/// One end of the live link, with the other end played by the test. A send
/// while unreachable throws and is not kept, as the real one's is.
final class FakeLiveLink<Outgoing: Sendable, Incoming: Sendable>: Sendable {
    private struct Wire {
        var outgoing: [Outgoing] = []
        var reachable: Bool
        var receive: (@Sendable (Incoming) -> Void)?
        var reachabilityChange: (@Sendable (Bool) -> Void)?
    }

    private let wire: Mutex<Wire>

    init(reachable: Bool = true) {
        wire = Mutex(Wire(reachable: reachable))
    }

    var sent: [Outgoing] { wire.withLock { $0.outgoing } }

    var lastSent: Outgoing? { sent.last }

    var isReachable: Bool { wire.withLock { $0.reachable } }

    func onReachabilityChange(_ change: @escaping @Sendable (Bool) -> Void) {
        wire.withLock { $0.reachabilityChange = change }
    }

    fileprivate func keep(_ value: Outgoing) throws {
        try wire.withLock { wire in
            guard wire.reachable else { throw LiveLinkError.unreachable }

            wire.outgoing.append(value)
        }
    }

    fileprivate func setReceiver(_ handle: @escaping @Sendable (Incoming) -> Void) {
        wire.withLock { $0.receive = handle }
    }

    func deliver(_ value: Incoming) {
        wire.withLock { $0.receive }?(value)
    }

    func becomeReachable(_ isReachable: Bool) {
        let change = wire.withLock { wire in
            wire.reachable = isReachable
            return wire.reachabilityChange
        }

        change?(isReachable)
    }
}

typealias FakeScorerLink = FakeLiveLink<MatchUpdate, MatchIntent>

typealias FakeRemoteLink = FakeLiveLink<MatchIntent, MatchUpdate>

extension FakeLiveLink: LiveLink {}

extension FakeLiveLink: ScorerLink where Outgoing == MatchUpdate, Incoming == MatchIntent {
    func send(_ update: MatchUpdate) throws { try keep(update) }

    func onIntent(_ receive: @escaping @Sendable (MatchIntent) -> Void) { setReceiver(receive) }
}

extension FakeLiveLink: RemoteLink where Outgoing == MatchIntent, Incoming == MatchUpdate {
    func send(_ intent: MatchIntent) throws { try keep(intent) }

    func onUpdate(_ receive: @escaping @Sendable (MatchUpdate) -> Void) { setReceiver(receive) }
}

extension AsyncStream {
    func first(_ count: Int) async -> [Element] {
        var values: [Element] = []

        for await value in self {
            values.append(value)
            if values.count == count { break }
        }

        return values
    }
}

struct FailingMatchStore: MatchStore {
    struct Failure: Error {}

    func save(_ match: SavedMatch) throws { throw Failure() }

    func matchInProgress(scored ways: Set<MatchScoring>) throws -> SavedMatch? { nil }

    func match(id: UUID) throws -> SavedMatch? { nil }

    func lastRuleset() throws -> Ruleset? { nil }

    func matches() throws -> [SavedMatch] { [] }

    /// Yields an empty history before finishing: the protocol promises a first
    /// value, and a double that skips it leaves its reader waiting forever.
    func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }
}
