import Foundation
import PadelScoring

/// The match as the store remembers it: the match itself plus when it was
/// played.
///
/// A match in the engine is a ruleset and a rally journal, nothing more
/// (ADR-0001). There is no time in it and there must not be: the score does
/// not depend on it, while the history on the phone (tickets 11, 12) has
/// nothing to show without it. So time lives here, outside the engine, and the
/// match stays what it was.
public struct SavedMatch: Equatable, Sendable, Identifiable {
    /// Which match this is. Created once on the first rally and never changed:
    /// by it the store recognizes that this is the same match and not a new
    /// one — and by it the phone tells apart a match delivered twice
    /// (ticket 10).
    public let id: UUID

    /// The match itself.
    ///
    /// Mutated only through this type, so that every change to the journal
    /// keeps the two moments below true.
    public private(set) var match: Match

    /// The moment of the first rally.
    public var startedAt: Date

    /// The moment the match was last played to: the last rally, or the undo
    /// that took one back.
    public var lastRallyAt: Date

    /// How long the match lasted.
    ///
    /// Computed from the two moments rather than stored as a third number, for
    /// the same reason the score is not stored (ADR-0001): a value somebody has
    /// to keep up to date will one day be forgotten. The end of the match here
    /// is its last play, not "now": a match cut short by a dead battery lasted
    /// until its last point, not until the moment it was opened again.
    public var duration: TimeInterval { lastRallyAt.timeIntervalSince(startedAt) }

    /// `lastRallyAt` defaults to the start: a match in which not a single
    /// rally has been played has zero duration.
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
    /// Records a rally and remembers when it happened.
    ///
    /// A match begins with its first rally — that is how the glossary defines
    /// it — and not with the app launching: between "opened the app on court"
    /// and "served" there is a warm-up, and that is not part of the match's
    /// duration.
    ///
    /// A rally the engine did not accept (the match is already over) does not
    /// move the time either: otherwise a tap out of habit would lengthen a
    /// finished match.
    public mutating func record(rallyWonBy side: Side, at moment: Date) {
        let wasFirstRally = match.journal.isEmpty

        guard match.record(rallyWonBy: side) else { return }

        if wasFirstRally { startedAt = moment }
        lastRallyAt = moment
    }

    /// Takes the last rally back and ends the match at the undo.
    ///
    /// At the undo, and not at the rally now last: rallies carry no time
    /// (ADR-0001), so that moment is written down nowhere. An undo the engine
    /// refuses — an abandoned match, an empty journal — moves neither moment,
    /// and emptying the journal returns the match to zero duration.
    public mutating func undo(at moment: Date) {
        guard match.undo() else { return }

        lastRallyAt = match.journal.isEmpty ? startedAt : moment
    }

    /// Stops the match early, leaving both moments where they are.
    ///
    /// Stopping appends no rally: the match lasted until its last point, not
    /// until the moment it was stopped.
    public mutating func abandon() {
        match.abandon()
    }
}
