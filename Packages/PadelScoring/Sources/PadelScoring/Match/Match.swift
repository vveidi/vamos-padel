public struct Match: Equatable, Sendable {
    public let ruleset: Ruleset

    public let firstServer: Side

    public private(set) var journal: RallyJournal

    public private(set) var isAbandoned: Bool

    public init(
        ruleset: Ruleset,
        firstServer: Side = .us,
        journal: RallyJournal = RallyJournal(),
        isAbandoned: Bool = false
    ) {
        self.ruleset = ruleset
        self.firstServer = firstServer
        self.journal = journal
        self.isAbandoned = isAbandoned
    }

    public var state: MatchState {
        let state = MatchState(ruleset: ruleset, journal: journal, firstServer: firstServer)

        return isAbandoned ? state.abandoned : state
    }

    public var course: MatchCourse {
        MatchCourse(ruleset: ruleset, journal: journal)
    }

    /// - Returns: `true` if the rally went into the journal, `false` if play
    ///   had already ended and nothing changed.
    @discardableResult
    public mutating func record(rallyWonBy side: Side) -> Bool {
        guard !state.outcome.isOver else { return false }

        journal.append(wonBy: side)

        return true
    }

    /// - Returns: `true` if a rally came off the journal, `false` if the match
    ///   was abandoned or had no rallies to take back.
    @discardableResult
    public mutating func undo() -> Bool {
        guard !isAbandoned else { return false }

        return journal.removeLast() != nil
    }

    /// Does nothing in a finished match: it already has a winner, and
    /// declaring it abandoned would mean canceling its outcome.
    public mutating func abandon() {
        guard !state.outcome.isOver else { return }

        isAbandoned = true
    }
}
