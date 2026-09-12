import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("The match parcel")
struct MatchPayloadTests {
    /// The round trip through the one thing the transport can carry — a
    /// dictionary. The match has to come back the same: identifier, ruleset,
    /// first server, rally journal, times and abandoned mark.
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

    /// The receipt travels over the same channel and in the same format as the
    /// match, so telling them apart is the parcel's own job: the receiving side
    /// only knows that it was handed a dictionary.
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

    /// The apps on the watch and on the phone are updated separately, so one
    /// day the older one will receive a parcel it does not understand. Losing a
    /// match with a line in the log is better than showing a score assembled
    /// out of defaults in the history.
    ///
    /// The cases are listed inside the test rather than as arguments: a
    /// dictionary of `Any` cannot be passed between threads, and test
    /// parameters require exactly that.
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
