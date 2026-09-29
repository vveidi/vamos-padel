import Foundation
import PadelScoring

public struct SavedMatch: Equatable, Sendable, Identifiable {
    public let id: UUID

    /// Every change to the journal moves the two moments below with it, which
    /// is what ``record(rallyWonBy:at:)`` and ``undo(at:)`` are for.
    public private(set) var match: Match

    /// The moment of the first rally, not of the app opening.
    public var startedAt: Date

    /// The moment the match was last played to: the last rally, or the undo
    /// that took one back.
    public var lastRallyAt: Date

    public var duration: TimeInterval { lastRallyAt.timeIntervalSince(startedAt) }

    public init(
        id: UUID = UUID(), match: Match, startedAt: Date, lastRallyAt: Date? = nil
    ) {
        self.id = id
        self.match = match
        self.startedAt = startedAt
        self.lastRallyAt = lastRallyAt ?? startedAt
    }
}

extension SavedMatch {
    public mutating func record(rallyWonBy side: Side, at moment: Date) {
        let wasFirstRally = match.journal.isEmpty

        guard match.record(rallyWonBy: side) else { return }

        if wasFirstRally { startedAt = moment }
        lastRallyAt = moment
    }

    /// Ends the match at the undo, and not at the rally now last: rallies carry
    /// no time (ADR-0001), so that moment is written down nowhere.
    public mutating func undo(at moment: Date) {
        guard match.undo() else { return }

        lastRallyAt = match.journal.isEmpty ? startedAt : moment
    }

    public mutating func abandon() {
        match.abandon()
    }
}
