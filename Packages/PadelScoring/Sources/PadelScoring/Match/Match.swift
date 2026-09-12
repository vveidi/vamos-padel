/// A single game from the first rally to the moment the ruleset declares it
/// over.
///
/// A match is a ruleset, a rally journal and an abandoned mark, and nothing
/// else: the score and the outcome are computed from them afresh every time
/// (ADR-0001).
public struct Match: Equatable, Sendable {
    public let ruleset: Ruleset

    /// The side that served the first rally. A property of the match, not of
    /// the ruleset: the rules are remembered until the next match, while who
    /// serves first is decided anew every time. The start screen asks for it,
    /// and starts the match with the same tap.
    public let firstServer: Side

    public private(set) var journal: RallyJournal

    /// Whether the match was stopped early.
    ///
    /// The only thing about a match that has to be stored besides the journal,
    /// and therefore not a violation of ADR-0001 but its boundary: the score
    /// can be computed from the journal, the decision to walk off the court
    /// cannot. The journal of a match stopped at 5:2 and of a match about to
    /// resume is the same.
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

    /// The match's score, serve and outcome as of the current journal.
    ///
    /// The mark is laid over what was computed rather than mixed into the
    /// score: the engine stays a pure function of the ruleset and the journal,
    /// and an abandoned match keeps the score it was stopped at.
    public var state: MatchState {
        let state = MatchState(ruleset: ruleset, journal: journal, firstServer: firstServer)

        return isAbandoned ? state.abandoned : state
    }

    /// The course of the score — how the match came about, and not only how
    /// it ended.
    ///
    /// Computed from the ruleset and the journal by the same walk the state is
    /// read off, and stored nowhere (ADR-0001). The abandoned mark does not
    /// enter into it: being stopped early is a fact about the outcome, and
    /// what was played was played.
    public var course: MatchCourse {
        MatchCourse(ruleset: ruleset, journal: journal)
    }

    /// Records a rally won by the given side.
    ///
    /// Does nothing in a finished match: a tap on the screen after the last
    /// rally must neither change the score nor push undo (ticket 05) further
    /// away by extra presses. A match stopped early is the same case: play in
    /// it has ended, even though there is no winner.
    ///
    /// - Returns: `true` if the rally went into the journal, `false` if play
    ///   had already ended and nothing changed.
    @discardableResult
    public mutating func record(rallyWonBy side: Side) -> Bool {
        guard !state.outcome.isOver else { return false }

        journal.append(wonBy: side)

        return true
    }

    /// Undoes the last rally.
    ///
    /// There is no arithmetic run backwards here, and there cannot be: the
    /// journal gets shorter, and the points, games, sets and serving side are
    /// recomputed from what is left (ADR-0001). That is why undo crosses the
    /// boundary of a game, a set and a tiebreak alike — the boundaries exist
    /// only inside the fold.
    ///
    /// A finished match is no exception: undo exists precisely to bring back
    /// into play a match finished by mistake. A match stopped early is the
    /// exception, and the only one: stopping is not a rally, undoing a point
    /// does not lift it, and shortening the journal of a match already marked
    /// abandoned would change its score while bringing nothing back into play.
    /// Stopping is guarded against a stray tap by a confirmation, not by undo.
    ///
    /// Does nothing on an empty journal.
    ///
    /// - Returns: `true` if a rally came off the journal, `false` if the match
    ///   was abandoned or had no rallies to take back.
    @discardableResult
    public mutating func undo() -> Bool {
        guard !isAbandoned else { return false }

        return journal.removeLast() != nil
    }

    /// Stops the match early: the court time ran out, it started raining,
    /// somebody pulled their back.
    ///
    /// The hour of play is not lost by it — the match stays exactly what it
    /// was and is saved alongside the rest, only marked. Does nothing in a
    /// finished match: it already has a winner, and declaring it abandoned
    /// would mean canceling its outcome.
    public mutating func abandon() {
        guard !state.outcome.isOver else { return }

        isAbandoned = true
    }
}
