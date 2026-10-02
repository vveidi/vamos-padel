import Foundation
import PadelScoring
import PadelStorage
import PadelStorageDatabase
import Testing

@testable import PadelDelivery

@Suite("The phone holding the match")
struct MatchScorerTests {
    private let store: DatabaseMatchStore
    private let link = FakeScorerLink()
    private let scorer: MatchScorer

    init() throws {
        store = try DatabaseMatchStore.inMemory()
        scorer = MatchScorer(store: store, link: link)
    }

    // MARK: One door

    @Test("A rally through an intent and through the scorer's own method reach the same journal")
    func intentsAndOwnMethodsAgree() throws {
        let byHandLink = FakeScorerLink()
        let byHand = try MatchScorer(store: DatabaseMatchStore.inMemory(), link: byHandLink)
        byHand.start(ruleset: toTwo, firstServer: .us, isPaired: true)
        byHand.record(rallyWonBy: .us)
        byHand.record(rallyWonBy: .them)

        scorer.apply(.start(ruleset: toTwo, firstServer: .us))
        scorer.apply(.rally(wonBy: .us, base: 0))
        scorer.apply(.rally(wonBy: .them, base: 1))

        #expect(heldMatch(of: link)?.match.journal == RallyJournal([Rally(wonBy: .us), Rally(wonBy: .them)]))
        #expect(heldMatch(of: link)?.match.journal == heldMatch(of: byHandLink)?.match.journal)
    }

    @Test("Every change is written to the store")
    func everyChangeIsWritten() throws {
        let started = try #require(scorer.start(ruleset: toTwo, firstServer: .them, isPaired: true))
        #expect(try store.match(id: started.id)?.match == started.match)

        scorer.record(rallyWonBy: .us)
        #expect(try store.match(id: started.id)?.match.journal.count == 1)

        scorer.apply(.rally(wonBy: .them, base: 1))
        #expect(try store.match(id: started.id)?.match.journal.count == 2)

        scorer.undo()
        #expect(try store.match(id: started.id)?.match.journal.count == 1)

        scorer.end()
        #expect(try store.match(id: started.id)?.match.isAbandoned == true)
    }

    @Test("Every change is broadcast, with no echo when the phone made it")
    func everyChangeIsBroadcast() throws {
        let started = try #require(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true))
        scorer.record(rallyWonBy: .them)

        var expected = started
        expected.record(rallyWonBy: .them, at: .now)

        #expect(link.sent.count == 2)
        #expect(heldMatch(of: link)?.match == expected.match)
        #expect(echo(of: link.lastSent) == nil)
    }

    @Test("A store that will not write does not stop the match")
    func aFailedWriteIsNotAFailedRally() throws {
        let link = FakeScorerLink()
        let scorer = MatchScorer(store: FailingMatchStore(), link: link)

        scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true)
        scorer.apply(.rally(wonBy: .us, base: 0))

        #expect(echo(of: link.lastSent)?.accepted == true)
        #expect(heldMatch(of: link)?.match.journal.count == 1)
    }

    // MARK: The judgment

    @Test("An intent delivered twice records once")
    func aDuplicateIntentRecordsOnce() {
        scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true)

        scorer.apply(.rally(wonBy: .us, base: 0))
        scorer.apply(.rally(wonBy: .us, base: 0))

        #expect(heldMatch(of: link)?.match.journal.count == 1)
        #expect(echo(of: link.lastSent) == Echo(intent: .rally(wonBy: .us, base: 0), accepted: false))
    }

    @Test("A stale intent is refused and answered with the match as it stands")
    func aStaleIntentIsAnsweredWithTheTruth() throws {
        scorer.start(ruleset: .defaultClassic, firstServer: .us, isPaired: true)
        scorer.record(rallyWonBy: .them)
        scorer.record(rallyWonBy: .them)
        let truth = try #require(heldMatch(of: link))

        scorer.apply(.undo(base: 1))

        #expect(link.lastSent == .match(truth, isPaired: true, echo: Echo(intent: .undo(base: 1), accepted: false)))
        #expect(try store.match(id: truth.id)?.match == truth.match)
    }

    @Test("An intent into a finished match is refused")
    func anIntentIntoAFinishedMatchIsRefused() {
        scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true)
        scorer.record(rallyWonBy: .us)
        scorer.record(rallyWonBy: .us)

        for intent in [MatchIntent.rally(wonBy: .them, base: 2), .undo(base: 2), .end(base: 2)] {
            scorer.apply(intent)

            #expect(echo(of: link.lastSent) == Echo(intent: intent, accepted: false))
        }

        #expect(heldMatch(of: link)?.match.journal.count == 2)
        #expect(heldMatch(of: link)?.match.isAbandoned == false)
    }

    @Test("An intent with no match to stand on is refused with no match")
    func anIntentWithNoMatchIsRefused() {
        scorer.apply(.rally(wonBy: .us, base: 0))

        #expect(link.lastSent == .noMatch(echo: Echo(intent: .rally(wonBy: .us, base: 0), accepted: false)))
    }

    @Test("A match scored alone goes out as such, and is not the remote's to change")
    func aMatchScoredAloneRefusesTheRemote() throws {
        let alone = try #require(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: false))

        for intent in [MatchIntent.rally(wonBy: .them, base: 0), .undo(base: 0), .end(base: 0)] {
            scorer.apply(intent)

            #expect(link.lastSent == .match(alone, isPaired: false, echo: Echo(intent: intent, accepted: false)))
        }

        scorer.record(rallyWonBy: .us)
        #expect(heldMatch(of: link)?.match.journal.count == 1)
    }

    @Test("A match the remote starts is paired")
    func aStartFromTheRemoteIsPaired() {
        scorer.apply(.start(ruleset: toTwo, firstServer: .them))

        guard case .match(_, let isPaired, _) = link.lastSent else { Issue.record("no match held"); return }
        #expect(isPaired)
    }

    @Test("The echo names the intent it answers")
    func theEchoNamesItsIntent() {
        let intents: [MatchIntent] = [
            .start(ruleset: toTwo, firstServer: .them),
            .rally(wonBy: .them, base: 0),
            .undo(base: 1),
            .end(base: 0),
        ]

        for intent in intents {
            scorer.apply(intent)

            #expect(echo(of: link.lastSent) == Echo(intent: intent, accepted: true))
        }
    }

    @Test("A start is refused while a match runs, whoever asks")
    func oneMatchAtATime() throws {
        let running = try #require(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true))

        #expect(scorer.start(ruleset: .defaultClassic, firstServer: .them, isPaired: true) == nil)

        scorer.apply(.start(ruleset: .defaultClassic, firstServer: .them))

        #expect(link.lastSent == .match(running, isPaired: true, echo: Echo(intent: .start(ruleset: .defaultClassic, firstServer: .them), accepted: false)))
    }

    @Test("A match over, or let go, makes room for the next")
    func aStartFollowsTheEndOrTheRelease() throws {
        scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true)
        scorer.end()
        #expect(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true) != nil)

        scorer.release()
        #expect(link.lastSent == .noMatch(echo: nil))

        scorer.apply(.start(ruleset: toTwo, firstServer: .them))
        #expect(echo(of: link.lastSent)?.accepted == true)
    }

    @Test("A link that comes back is sent the match as it stands, with no echo")
    func aLinkThatComesBackIsAnswered() throws {
        link.becomeReachable(false)
        let started = try #require(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true))
        #expect(link.sent.isEmpty)

        link.becomeReachable(true)
        #expect(link.sent == [.match(started, isPaired: true, echo: nil)])
    }

    @Test("A link that cannot be reached does not stop the match")
    func anUnreachableLinkIsNotAFailedRally() async throws {
        link.becomeReachable(false)
        let started = try #require(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true))
        let updates = scorer.updates()

        scorer.record(rallyWonBy: .us)

        let held = await updates.first(2).last
        #expect(try store.match(id: started.id)?.match.journal.count == 1)
        guard case .match(let saved, _, _) = held else { Issue.record("no match held"); return }
        #expect(saved.match.journal.count == 1)
    }

    @Test("Whether the remote is reachable starts at now and follows every change")
    func theRemoteIsFollowed() async throws {
        let link = FakeScorerLink(reachable: false)
        let reachable = try MatchScorer(store: DatabaseMatchStore.inMemory(), link: link).reachabilityChanges()

        link.becomeReachable(true)
        link.becomeReachable(false)

        #expect(await reachable.first(3) == [false, true, false])
    }

    @Test("An intent arriving over the link is judged")
    func anIntentOverTheLinkIsApplied() {
        link.deliver(.start(ruleset: toTwo, firstServer: .us))
        link.deliver(.rally(wonBy: .them, base: 0))

        #expect(heldMatch(of: link)?.match.journal == RallyJournal([Rally(wonBy: .them)]))
    }

    // MARK: The remote declining

    @Test("A remote scoring alone is heard, and its answer changes nothing and is not echoed")
    func aDeclineIsHeardAndNotEchoed() async throws {
        let started = try #require(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true))
        let sentBefore = link.sent
        let declines = scorer.remoteDeclines()

        link.deliver(.scoringAlone)

        #expect(await declines.first(1).count == 1)
        #expect(link.sent == sentBefore)
        #expect(try store.match(id: started.id)?.match == started.match)
    }

    @Test("A broadcast that keeps nothing replays nothing to a listener that arrives late")
    func aBroadcastThatKeepsNothingReplaysNothing() async {
        let broadcast = Broadcast<Int>(keepsLatest: false)
        broadcast.send(1)

        let late = broadcast.stream()
        broadcast.send(2)

        #expect(await late.first(1) == [2])
    }

    // MARK: The stream

    @Test("The stream starts at the update as it stands and follows every change")
    func theStreamFollowsTheMatch() async throws {
        let started = try #require(scorer.start(ruleset: toTwo, firstServer: .us, isPaired: true))
        let updates = scorer.updates()

        scorer.apply(.rally(wonBy: .us, base: 0))

        let values = await updates.first(2)
        #expect(values.first == .match(started, isPaired: true, echo: nil))
        #expect(values.last == link.lastSent)
    }

    // MARK: Reading what went out

    private func heldMatch(of link: FakeScorerLink) -> SavedMatch? {
        guard case .match(let saved, _, _) = link.lastSent else { return nil }

        return saved
    }

    private func echo(of update: MatchUpdate?) -> Echo? {
        switch update {
        case .match(_, _, let echo), .noMatch(let echo): echo
        case nil: nil
        }
    }
}
