import Foundation
import PadelScoring

@testable import PadelStorage

/// Момент, с которого начинаются матчи в тестах.
///
/// Круглая секунда намеренно: GRDB хранит время с точностью до миллисекунды, и
/// `Date()` с его долями микросекунды не вернулся бы из базы тем же значением.
/// Матчу этой точности хватает с запасом, а тесту круговой рейс важнее.
let aMoment = Date(timeIntervalSince1970: 1_800_000_000)

/// Матч кончается на втором очке: тестам, которым важно, что матч кончился, а
/// не каким счётом, двух розыгрышей довольно.
let toTwo = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)

extension SavedMatch {
    /// Матч, в котором сыграны перечисленные розыгрыши, по одному в секунду.
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
