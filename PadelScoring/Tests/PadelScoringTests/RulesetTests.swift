import Testing

@testable import PadelScoring

@Suite("Набор правил")
struct RulesetTests {
    @Test("Счёт до N очков по умолчанию идёт до 16 со сменой подачи каждые 4 розыгрыша")
    func pointsToDefaults() {
        #expect(Ruleset.defaultPointsTo == .pointsTo(target: 16, serveChangesEvery: 4))
    }

    @Test("Классический счёт по умолчанию — один сет с золотым очком")
    func classicDefaults() {
        #expect(Ruleset.defaultClassic == .classic(setsToWin: 1, goldenPoint: true))
    }

    @Test("Наборы правил с разными параметрами различаются")
    func rulesetsWithDifferentParametersDiffer() {
        #expect(Ruleset.pointsTo(target: 16, serveChangesEvery: 4) != .pointsTo(target: 21, serveChangesEvery: 4))
        #expect(Ruleset.classic(setsToWin: 1, goldenPoint: true) != .classic(setsToWin: 1, goldenPoint: false))
    }
}
