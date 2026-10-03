import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("The match parcel")
struct MatchPayloadTests {
    @Test(
        "A match decodes back unchanged",
        arguments: [
            SavedMatch.played([.us, .them, .us], ruleset: .classic(setsToWin: 2, goldenPoint: false)),
            SavedMatch.played([.them, .them], ruleset: .pointsTo(target: 21, serveChangesEvery: 2)),
            SavedMatch.played([], ruleset: .defaultClassic, firstServer: .them),
        ])
    func aMatchSurvivesTheRoundTrip(saved: SavedMatch) throws {
        #expect(try MatchPayload.decode(MatchPayload.encode(.match(saved))) == .match(saved))
    }

    @Test("A receipt is not mistaken for a match")
    func aReceiptIsNotMistakenForAMatch() throws {
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        #expect(try MatchPayload.decode(MatchPayload.encode(.receipt(saved))) == .receipt(saved))
        #expect(
            try MatchPayload.decode(MatchPayload.encode(.match(saved)))
                != .receipt(saved))
    }

    @Test("An abandoned match arrives abandoned")
    func anAbandonedMatchArrivesAbandoned() throws {
        var saved = SavedMatch.played([.us, .them])
        saved.abandon()

        guard case .match(let arrived) = try MatchPayload.decode(MatchPayload.encode(.match(saved)))
        else {
            Issue.record("the match arrived as something other than a match")
            return
        }

        #expect(arrived == saved)
        #expect(arrived.match.isAbandoned)
    }

    @Test("How a match was scored travels with it", arguments: MatchScoring.allCases)
    func theScoringTravels(scoring: MatchScoring) throws {
        let saved = SavedMatch.played([.us, .them], scoring: scoring)
        let update = MatchUpdate.match(saved, echo: nil)

        #expect(try MatchPayload.decode(MatchPayload.encode(.match(saved))) == .match(saved))
        #expect(try MatchPayload.decode(MatchPayload.encode(.update(update))) == .update(update))
    }

    @Test("A match parcel written before the live link still decodes, under the same keys")
    func aMatchParcelKeepsItsKeys() throws {
        let saved = SavedMatch.played([.us, .them], ruleset: .classic(setsToWin: 2, goldenPoint: true))
        let written: [String: Any] = [
            "kind": "match", "id": saved.id.uuidString, "firstServer": "us",
            "startedAt": aMoment, "lastRallyAt": aMoment.addingTimeInterval(1),
            "abandoned": false, "rallies": ["us", "them"], "scoring": "aloneOnWatch",
            "ruleset": "classic", "setsToWin": 2, "goldenPoint": true,
        ]

        #expect(try MatchPayload.decode(written) == .match(saved))
        #expect(Set(MatchPayload.encode(.match(saved)).keys) == Set(written.keys))
        #expect(Set(MatchPayload.encode(.receipt(saved)).keys) == Set(written.keys))
    }

    @Test(
        "An intent decodes back unchanged",
        arguments: [
            MatchIntent.start(ruleset: .classic(setsToWin: 3, goldenPoint: false), firstServer: .them),
            .start(ruleset: .pointsTo(target: 16, serveChangesEvery: 4), firstServer: .us),
            .rally(wonBy: .us, base: 0),
            .rally(wonBy: .them, base: 27),
            .undo(base: 5),
            .end(base: 12),
            .scoringAlone,
        ])
    func anIntentSurvivesTheRoundTrip(intent: MatchIntent) throws {
        #expect(try MatchPayload.decode(MatchPayload.encode(.intent(intent))) == .intent(intent))
    }

    @Test(
        "An update decodes back unchanged, with its echo or without one",
        arguments: [
            MatchUpdate.match(SavedMatch.played([.us], ruleset: .defaultClassic), echo: nil),
            .match(
                SavedMatch.played([.us, .them], ruleset: .classic(setsToWin: 1, goldenPoint: true)),
                echo: Echo(intent: .rally(wonBy: .them, base: 1), accepted: true)),
            .match(
                SavedMatch.played([.them], ruleset: .pointsTo(target: 21, serveChangesEvery: 2)),
                echo: Echo(intent: .undo(base: 2), accepted: false)),
            .match(
                SavedMatch.played([], ruleset: .defaultPointsTo, firstServer: .them),
                echo: Echo(
                    intent: .start(ruleset: .defaultPointsTo, firstServer: .them), accepted: true)),
            .noMatch(echo: nil),
            .noMatch(echo: Echo(intent: .end(base: 9), accepted: false)),
        ])
    func anUpdateSurvivesTheRoundTrip(update: MatchUpdate) throws {
        #expect(try MatchPayload.decode(MatchPayload.encode(.update(update))) == .update(update))
    }

    @Test("An update is not mistaken for a delivered match")
    func anUpdateIsNotMistakenForADeliveredMatch() throws {
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        #expect(
            try MatchPayload.decode(MatchPayload.encode(.update(.match(saved, echo: nil))))
                != .match(saved))
    }

    /// The cases are listed in the body rather than as arguments: a
    /// `[String: Any]` is not `Sendable`, and test parameters must be.
    @Test("An unreadable live link parcel is refused rather than defaulted")
    func anUnreadableLiveLinkParcelIsRefused() {
        let saved = SavedMatch.played([.us], ruleset: toTwo)
        let update = MatchPayload.encode(.update(.match(saved, echo: nil)))
        let rally = MatchPayload.encode(.intent(.rally(wonBy: .us, base: 1)))

        func without(_ key: String, in payload: [String: Any]) -> [String: Any] {
            payload.filter { $0.key != key }
        }

        func with(_ key: String, _ value: Any, in payload: [String: Any]) -> [String: Any] {
            payload.merging([key: value]) { _, new in new }
        }

        let payloads: [(what: String, payload: [String: Any])] = [
            ("an update without its kind", without("kind", in: update)),
            ("an update without its journal", without("rallies", in: update)),
            ("an update that does not say how the match is scored", without("scoring", in: update)),
            ("an intent without its kind", without("kind", in: rally)),
            ("an intent of no known kind", with("intent", "serve", in: rally)),
            ("an intent that names none", without("intent", in: rally)),
            ("a rally without its base", without("base", in: rally)),
            ("a rally with a negative base", with("base", -1, in: rally)),
            ("a rally without its winner", without("winner", in: rally)),
            ("an undo without its base", ["kind": "intent", "intent": "undo"]),
            ("an end without its base", ["kind": "intent", "intent": "end"]),
            (
                "a start without its first server",
                ["kind": "intent", "intent": "start", "ruleset": "pointsTo", "target": 16,
                    "serveChangesEvery": 4]
            ),
            (
                "an echo without its verdict",
                with("echo", without("kind", in: rally), in: update)
            ),
            (
                "an echo whose intent has no base",
                with("echo", without("base", in: rally).merging(["accepted": true]) { a, _ in a },
                    in: update)
            ),
            ("an echo that is not a parcel", with("echo", "rally", in: update)),
            (
                "no match whose echo has no verdict",
                ["kind": "noMatch", "echo": ["intent": "end", "base": 3]]
            ),
        ]

        for (what, payload) in payloads {
            #expect(throws: MatchPayloadError.self, "\(what)") {
                try MatchPayload.decode(payload)
            }
        }
    }

    /// The cases are listed in the body rather than as arguments: a
    /// `[String: Any]` is not `Sendable`, and test parameters must be.
    @Test("An unreadable parcel does not turn into a match")
    func anUnreadablePayloadIsRefused() {
        let id = UUID().uuidString
        let times: [String: Any] = [
            "kind": "match", "startedAt": aMoment, "lastRallyAt": aMoment,
        ]
        let journal: [String: Any] = ["rallies": ["us"], "abandoned": false]

        let payloads: [(what: String, payload: [String: Any])] = [
            ("an empty parcel", [:]),
            ("an identifier that is not a UUID", ["id": "not a UUID"]),
            ("a match without times", ["id": id]),
            ("a match without a ruleset", ["id": id].merging(times) { a, _ in a }),
            (
                "an unknown ruleset",
                ["id": id, "ruleset": "americano", "firstServer": "us"]
                    .merging(times) { a, _ in a }
            ),
            (
                "classic scoring without its rules",
                ["id": id, "ruleset": "classic", "firstServer": "us"]
                    .merging(times) { a, _ in a }
            ),
            (
                "an unknown first server",
                [
                    "id": id, "ruleset": "classic", "setsToWin": 1, "goldenPoint": true,
                    "firstServer": "referee",
                ].merging(times) { a, _ in a }.merging(journal) { a, _ in a }
            ),
            (
                "an unknown side in the journal",
                [
                    "id": id, "ruleset": "pointsTo", "target": 16, "serveChangesEvery": 4,
                    "firstServer": "us", "rallies": ["us", "nobody"], "abandoned": false,
                ].merging(times) { a, _ in a }
            ),
            (
                "a match without a rally journal",
                [
                    "id": id, "ruleset": "pointsTo", "target": 16, "serveChangesEvery": 4,
                    "firstServer": "us",
                ].merging(times) { a, _ in a }
            ),
            (
                "a match that does not say how it was scored",
                [
                    "id": id, "ruleset": "pointsTo", "target": 16, "serveChangesEvery": 4,
                    "firstServer": "us",
                ].merging(times) { a, _ in a }.merging(journal) { a, _ in a }
            ),
            (
                "an unknown way of scoring",
                [
                    "id": id, "ruleset": "pointsTo", "target": 16, "serveChangesEvery": 4,
                    "firstServer": "us", "scoring": "byTheReferee",
                ].merging(times) { a, _ in a }.merging(journal) { a, _ in a }
            ),
            (
                "a parcel of an unknown kind",
                [
                    "id": id, "kind": "letter", "ruleset": "pointsTo", "target": 16,
                    "serveChangesEvery": 4, "firstServer": "us", "startedAt": aMoment,
                    "lastRallyAt": aMoment,
                ].merging(journal) { a, _ in a }
            ),
        ]

        for (what, payload) in payloads {
            #expect(throws: MatchPayloadError.self, "\(what)") {
                try MatchPayload.decode(payload)
            }
        }
    }
}
