import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("Посылка с матчем")
struct MatchPayloadTests {
    /// Круговой рейс через то единственное, что умеет переносить транспорт, —
    /// словарь. Матч обязан вернуться тем же: идентификатор, набор правил,
    /// первая подача, журнал розыгрышей, времена и пометка недоигранности.
    @Test(
        "Матч разбирается обратно тем же",
        arguments: [
            SavedMatch.played([.us, .them, .us], ruleset: .classic(setsToWin: 2, goldenPoint: false)),
            SavedMatch.played([.them, .them], ruleset: .pointsTo(target: 21, serveChangesEvery: 2)),
            SavedMatch.played([], ruleset: .defaultClassic, firstServer: .them),
        ])
    func aMatchSurvivesTheRoundTrip(saved: SavedMatch) throws {
        #expect(try MatchPayload.decode(MatchPayload.encode(saved)) == saved)
    }

    @Test("Недоигранный матч приезжает недоигранным")
    func anAbandonedMatchArrivesAbandoned() throws {
        var saved = SavedMatch.played([.us, .them])
        saved.match.abandon()

        let arrived = try MatchPayload.decode(MatchPayload.encode(saved))

        #expect(arrived == saved)
        #expect(arrived.match.isAbandoned)
    }

    /// Подтверждение доставки приходит вместе с посылкой, и разбирать её ради
    /// одного идентификатора незачем.
    @Test("Идентификатор матча читается из посылки отдельно")
    func theMatchIdIsReadableOnItsOwn() {
        let saved = SavedMatch.played([.us, .us])

        #expect(MatchPayload.matchId(in: MatchPayload.encode(saved)) == saved.id)
    }

    /// Приложения на часах и на телефоне обновляются порознь, поэтому старое
    /// однажды получит посылку, которой не понимает. Потерять матч с записью в
    /// логе лучше, чем показать в истории счёт, собранный из умолчаний.
    ///
    /// Случаи перечислены внутри теста, а не аргументами: словарь с `Any`
    /// нельзя передать между потоками, а параметры теста этого требуют.
    @Test("Непонятная посылка не превращается в матч")
    func anUnreadablePayloadIsRefused() {
        let id = UUID().uuidString
        let times: [String: Any] = ["startedAt": aMoment, "lastRallyAt": aMoment]

        let payloads: [(what: String, payload: [String: Any])] = [
            ("пустая посылка", [:]),
            ("идентификатор не UUID", ["id": "не UUID"]),
            ("матч без времени", ["id": id]),
            ("матч без набора правил", ["id": id].merging(times) { a, _ in a }),
            (
                "неизвестный набор правил",
                ["id": id, "ruleset": "americano", "firstServer": "us"]
                    .merging(times) { a, _ in a }
            ),
            (
                "классический счёт без правил",
                ["id": id, "ruleset": "classic", "firstServer": "us"]
                    .merging(times) { a, _ in a }
            ),
            (
                "неизвестная первая подача",
                [
                    "id": id, "ruleset": "classic", "setsToWin": 1, "goldenPoint": true,
                    "firstServer": "судья",
                ].merging(times) { a, _ in a }
            ),
            (
                "неизвестная сторона в журнале",
                [
                    "id": id, "ruleset": "pointsTo", "target": 16, "serveChangesEvery": 4,
                    "firstServer": "us", "rallies": ["us", "никто"],
                ].merging(times) { a, _ in a }
            ),
        ]

        for (what, payload) in payloads {
            #expect(throws: MatchPayloadError.self, "\(what)") {
                try MatchPayload.decode(payload)
            }
        }
    }
}
