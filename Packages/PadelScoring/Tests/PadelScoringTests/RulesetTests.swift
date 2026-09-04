import Testing

@testable import PadelScoring

@Suite("Ruleset")
struct RulesetTests {
    @Test("A match to N points defaults to 16, with the serve changing every 4 rallies")
    func pointsToDefaults() {
        #expect(Ruleset.defaultPointsTo == .pointsTo(target: 16, serveChangesEvery: 4))
    }

    @Test("Classic scoring defaults to one set with the golden point")
    func classicDefaults() {
        #expect(Ruleset.defaultClassic == .classic(setsToWin: 1, goldenPoint: true))
    }

    /// This answer decides both which score the match is remembered by and
    /// whether the screen shows a set score: in a match to one set there is
    /// nothing to show, and in a match to two, games without sets do not say
    /// who is ahead.
    @Test("A match longer than one set is told apart from a short one")
    func onlyAMatchLongerThanOneSetHasSetsWorthShowing() {
        #expect(Ruleset.classic(setsToWin: 2, goldenPoint: true).isMultiSet)
        #expect(Ruleset.classic(setsToWin: 3, goldenPoint: false).isMultiSet)
        #expect(!Ruleset.classic(setsToWin: 1, goldenPoint: true).isMultiSet)
        #expect(!Ruleset.defaultPointsTo.isMultiSet)
    }

    @Test("Rulesets with different parameters differ")
    func rulesetsWithDifferentParametersDiffer() {
        #expect(Ruleset.pointsTo(target: 16, serveChangesEvery: 4) != .pointsTo(target: 21, serveChangesEvery: 4))
        #expect(Ruleset.classic(setsToWin: 1, goldenPoint: true) != .classic(setsToWin: 1, goldenPoint: false))
    }
}
