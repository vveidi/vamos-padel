import Foundation
import PadelScoring
import PadelStorage

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
        from start: Date = aMoment
    ) -> SavedMatch {
        var saved = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played)))
        }

        return saved
    }
}

final class FakeTransport: MatchSender, MatchReceiver, @unchecked Sendable {
    private let lock = NSLock()
    private var queued: [SavedMatch] = []
    private var written: [SavedMatch] = []
    private var transportReady: (@Sendable () -> Void)?
    private var confirmDelivery: (@Sendable (SavedMatch) -> Void)?
    private var receiveMatch: (@Sendable (SavedMatch) -> Void)?

    /// What the watch handed over since the last ``forget()``.
    var sent: [SavedMatch] { lock.withLock { queued } }

    /// What the phone signed for since the last ``forget()``.
    var receipts: [SavedMatch] { lock.withLock { written } }

    func send(_ match: SavedMatch) {
        lock.withLock { queued.append(match) }
    }

    func confirmArrival(of match: SavedMatch) {
        lock.withLock { written.append(match) }
    }

    func onReady(_ ready: @escaping @Sendable () -> Void) {
        lock.withLock { transportReady = ready }
    }

    func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {
        lock.withLock { confirmDelivery = confirm }
    }

    func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
        lock.withLock { receiveMatch = receive }
    }

    /// The session came up.
    func becomeReady() {
        lock.withLock { transportReady }?()
    }

    func confirmDelivered() {
        deliverReceipts(for: sent)
    }

    /// Receipts get through for exactly the listed versions of the matches.
    func deliverReceipts(for matches: [SavedMatch]) {
        let confirm = lock.withLock { confirmDelivery }

        for match in matches { confirm?(match) }
    }

    /// A match arrived on the phone.
    func deliver(_ match: SavedMatch) {
        lock.withLock { receiveMatch }?(match)
    }

    func forget() {
        lock.withLock {
            queued = []
            written = []
        }
    }
}

struct FailingMatchStore: MatchStore {
    struct Failure: Error {}

    func save(_ match: SavedMatch) throws { throw Failure() }

    func matchInProgress() throws -> SavedMatch? { nil }

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
