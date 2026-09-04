import Testing

@testable import PadelScoring

@Suite("The course of the score")
struct MatchCourseTests {
    // MARK: The match to N points

    @Test("Every rally is a step, and the step carries the score after it")
    func everyRallyIsAStep() {
        let course = pointsToCourse([.us, .them, .us], target: 16)

        #expect(
            course == [
                ScoreStep(winner: .us, score: SideCounts(us: 1, them: 0)),
                ScoreStep(winner: .them, score: SideCounts(us: 1, them: 1)),
                ScoreStep(winner: .us, score: SideCounts(us: 2, them: 1)),
            ])
    }

    @Test("The course ends with the rally that won the match")
    func theCourseEndsWithTheWinningRally() {
        let course = pointsToCourse([.us, .them, .us, .us, .them, .them], target: 3)

        #expect(course.count == 4)
        #expect(course.last == ScoreStep(winner: .us, score: SideCounts(us: 3, them: 1)))
    }

    @Test("A journal without rallies has no course")
    func anEmptyJournalHasNoCourse() {
        #expect(MatchCourse(ruleset: .defaultPointsTo, journal: RallyJournal()).isEmpty)
        #expect(MatchCourse(ruleset: .defaultClassic, journal: RallyJournal()).isEmpty)
    }

    // MARK: Classic scoring

    @Test("A game won is a step, and the step carries the games after it")
    func everyGameIsAStep() {
        let course = classicCourse(gamesWonBy([.us, .them, .us]))

        #expect(course.count == 1)
        #expect(
            course.first?.games == [
                ScoreStep(winner: .us, score: SideCounts(us: 1, them: 0)),
                ScoreStep(winner: .them, score: SideCounts(us: 1, them: 1)),
                ScoreStep(winner: .us, score: SideCounts(us: 2, them: 1)),
            ])
    }

    /// The course is made of what was played out. A game abandoned at 40:30 is
    /// not a step of it — the card says as much from the state's points, and
    /// inventing a step for it would put a game into the course that nobody
    /// won.
    @Test("Rallies of a game not carried to its end are no step")
    func anUnfinishedGameIsNoStep() {
        let course = classicCourse(gamesWonBy([.us]) + rallies(.them, 3))

        #expect(course.first?.games.count == 1)
        #expect(course.first?.score == SideCounts(us: 1, them: 0))
    }

    @Test("A set records the side that took it")
    func aSetRecordsItsWinner() {
        let course = classicCourse(gamesWonBy([.us, .us, .us, .us, .us, .us]))

        #expect(course.count == 1)
        #expect(course.first?.winner == .us)
        #expect(course.first?.score == SideCounts(us: 6, them: 0))
    }

    @Test("The set the match stands in has no winner yet")
    func anUnfinishedSetHasNoWinner() {
        let course = classicCourse(gamesWonBy([.us, .them, .us]))

        #expect(course.first?.winner == nil)
    }

    @Test("A match longer than one set keeps the sets apart, in order")
    func aLongMatchKeepsItsSetsApart() {
        let course = classicCourse(
            gamesWonBy([.us, .us, .us, .us, .us, .us])
                + gamesWonBy([.them, .them, .them, .them, .them, .them])
                + gamesWonBy([.us, .them]),
            setsToWin: 3)

        #expect(course.count == 3)
        #expect(course.map(\.winner) == [.us, .them, nil])
        #expect(course.map(\.score) == [
            SideCounts(us: 6, them: 0), SideCounts(us: 0, them: 6), SideCounts(us: 1, them: 1),
        ])
    }

    /// Between the set that was taken and the first game of the next one the
    /// match stands in a set nothing has happened in. It is not a set that was
    /// played, and the card must not draw an empty one.
    @Test("A set nothing has been played in yet is not part of the course")
    func anEmptySetIsNotPartOfTheCourse() {
        let firstSet = gamesWonBy([.us, .us, .us, .us, .us, .us])

        #expect(classicCourse(firstSet, setsToWin: 2).count == 1)
        #expect(classicCourse(firstSet + rallies(.them, 2), setsToWin: 2).count == 1)
        #expect(classicCourse(firstSet + gamesWonBy([.them]), setsToWin: 2).count == 2)
    }

    @Test("A set decided by a tiebreak carries the tiebreak's points")
    func aTieBreakSetCarriesItsPoints() {
        let course = classicCourse(toSixAll + [.us, .us, .them, .us, .them, .us, .them, .us, .us, .us])

        #expect(course.first?.score == SideCounts(us: 7, them: 6))
        #expect(course.first?.tieBreak == SideCounts(us: 7, them: 3))
    }

    @Test("A set played out without a tiebreak carries none")
    func aSetWithoutATieBreakCarriesNoPoints() {
        let course = classicCourse(gamesWonBy([.us, .us, .us, .us, .us, .us]))

        #expect(course.first?.tieBreak == nil)
    }

    // MARK: Shared with the engine

    /// The point of the whole thing: the card rebuilds the score from the
    /// journal instead of being told it, so the two have to arrive at the same
    /// number — on the phone as on the watch.
    @Test(
        "The course ends on the score the match is remembered by",
        arguments: [
            Ruleset.defaultPointsTo,
            .pointsTo(target: 5, serveChangesEvery: 2),
            .defaultClassic,
            .classic(setsToWin: 1, goldenPoint: false),
            .classic(setsToWin: 2, goldenPoint: true),
        ])
    func theCourseEndsOnTheFinalScore(ruleset: Ruleset) {
        for winners in [longMatch, Array(longMatch.prefix(37)), gamesWonBy([.us]), []] {
            let journal = journal(winners)

            #expect(
                MatchCourse(ruleset: ruleset, journal: journal).finalScore(of: ruleset)
                    == MatchState(ruleset: ruleset, journal: journal).finalScore,
                "\(ruleset), \(winners.count) rallies")
        }
    }

    /// What "a match restored on the phone shows the same score as it had on
    /// the watch" comes down to: the course depends on nothing but the ruleset
    /// and the journal, so what travels is enough to rebuild it.
    @Test("The same journal always yields the same course")
    func theSameJournalAlwaysYieldsTheSameCourse() {
        var replayed = RallyJournal()
        for side in longMatch { replayed.append(wonBy: side) }

        #expect(
            MatchCourse(ruleset: .defaultClassic, journal: journal(longMatch))
                == MatchCourse(ruleset: .defaultClassic, journal: replayed))
    }

    @Test("A match stopped early keeps the course it was stopped at")
    func abandoningLeavesTheCourseAlone() {
        var match = Match(ruleset: .defaultClassic, journal: journal(gamesWonBy([.us, .them])))
        let before = match.course

        match.abandon()

        #expect(match.course == before)
        #expect(match.state.outcome == .abandoned)
    }
}

// MARK: - Reading a course

extension MatchCourse {
    /// The score the match is remembered by, read off the course.
    ///
    /// Lives in the test and not in the engine on purpose: a test that asked
    /// the engine for the answer it is checking would be checking nothing.
    fileprivate func finalScore(of ruleset: Ruleset) -> SideCounts {
        switch self {
        case .points(let steps):
            steps.last?.score ?? SideCounts()
        case .sets(let sets) where ruleset.isMultiSet:
            sets.reduce(into: SideCounts()) { counts, set in
                guard let winner = set.winner else { return }

                counts = counts.incrementing(winner)
            }
        case .sets(let sets):
            sets.last?.score ?? SideCounts()
        }
    }
}

// MARK: - Building journals

private func pointsToCourse(_ winners: [Side], target: Int) -> [ScoreStep] {
    let course = MatchCourse(
        ruleset: .pointsTo(target: target, serveChangesEvery: 4), journal: journal(winners))

    guard case .points(let steps) = course else {
        Issue.record("a match to N points was not scored as a run of rallies")

        return []
    }

    return steps
}

private func classicCourse(
    _ winners: [Side], goldenPoint: Bool = true, setsToWin: Int = 1
) -> [SetCourse] {
    let course = MatchCourse(
        ruleset: .classic(setsToWin: setsToWin, goldenPoint: goldenPoint),
        journal: journal(winners))

    guard case .sets(let sets) = course else {
        Issue.record("a classic match was not scored as sets")

        return []
    }

    return sets
}

/// The rallies that bring the games to 6:6.
private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

/// A journal long enough to reach into every corner of both rulesets: past a
/// tiebreak, past the end of a set, and past the end of a short match.
private let longMatch = toSixAll + rallies(.us, 7) + gamesWonBy([.them, .them, .us])

private func journal(_ winners: [Side]) -> RallyJournal {
    RallyJournal(winners.map(Rally.init(wonBy:)))
}

private func rallies(_ side: Side, _ count: Int) -> [Side] {
    Array(repeating: side, count: count)
}

/// The rallies by which the listed sides each win a game to love.
private func gamesWonBy(_ winners: [Side]) -> [Side] {
    winners.flatMap { rallies($0, 4) }
}
