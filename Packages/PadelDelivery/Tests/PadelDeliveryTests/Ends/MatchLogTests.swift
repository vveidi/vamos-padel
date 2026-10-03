import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("The match's lines in the console")
struct MatchLogTests {
    @Test("A start names the ruleset, how the match is scored and who serves")
    func startNamesItsSetUp() {
        let saved = SavedMatch.played(
            [], ruleset: .classic(setsToWin: 2, goldenPoint: false), firstServer: .them, scoring: .paired)

        #expect(MatchLog.setUp(of: saved) == "classic, 2 sets to win, advantage, paired, them to serve")
    }

    @Test("A match to N points is scored in points alone")
    func pointsToScoresPointsAlone() {
        let saved = SavedMatch.played([.us, .us, .them])

        #expect(MatchLog.score(of: saved.match) == "2–1")
    }

    @Test("A single set shows no sets, a longer match does")
    func setsOnlyWhenThereAreSeveral() {
        let rallies: [Side] = [.us, .them, .us]

        #expect(
            MatchLog.score(of: SavedMatch.played(rallies, ruleset: .defaultClassic).match)
                == "games 0–0, points 30–15")
        #expect(
            MatchLog.score(of: SavedMatch.played(rallies, ruleset: .classic(setsToWin: 2, goldenPoint: true)).match)
                == "sets 0–0, games 0–0, points 30–15")
    }

    @Test("A finished match ends on its final score and how long it lasted")
    func finishedEndsOnItsScore() {
        let saved = SavedMatch.played([.us, .them, .us], ruleset: toTwo)

        #expect(MatchLog.ending(of: saved) == "the match is over: won by us, 2–1, after 0:00:02; \(saved.id)")
    }

    @Test("An abandoned match ends on the score it was left at")
    func abandonedEndsWhereItWasLeft() {
        var saved = SavedMatch.played([.us])
        saved.abandon()

        #expect(MatchLog.ending(of: saved) == "the match was abandoned at 1–0 after 0:00:00; \(saved.id)")
    }
}
