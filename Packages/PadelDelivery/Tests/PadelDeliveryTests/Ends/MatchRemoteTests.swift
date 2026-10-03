import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("The watch as the phone's remote")
struct MatchRemoteTests {
    private let link = FakeRemoteLink()
    private let remote: MatchRemote

    init() {
        remote = MatchRemote(link: link)
    }

    @Test("The stream yields exactly what arrived, and nothing of its own")
    func theStreamIsWhatArrived() async throws {
        let first = MatchUpdate.match(.played([.us]), echo: nil)
        let rally = MatchIntent.rally(wonBy: .them, base: 1)
        let second = MatchUpdate.match(.played([.us, .them]), echo: Echo(intent: rally, accepted: true))
        let updates = remote.updates()

        link.deliver(first)
        try remote.send(rally)
        try remote.send(.undo(base: 1))
        link.deliver(second)

        #expect(await updates.first(2) == [first, second])
        #expect(link.sent == [rally, .undo(base: 1)])
    }

    @Test("A late listener starts at the last update that arrived")
    func aLateListenerStartsAtTheLastUpdate() async {
        let last = MatchUpdate.noMatch(echo: nil)

        link.deliver(.match(.played([.us]), echo: nil))
        link.deliver(last)

        #expect(await remote.updates().first(1) == [last])
    }

    @Test("Whether the link is alive starts at now and follows every change")
    func theLinkIsFollowed() async {
        let link = FakeRemoteLink(reachable: false)
        let alive = MatchRemote(link: link).reachabilityChanges()

        link.becomeReachable(true)
        link.becomeReachable(false)

        #expect(await alive.first(3) == [false, true, false])
    }

    @Test("A paired match ended is passed on, then answered, on every arrival")
    func anEndIsAnsweredEachTime() async {
        var ended = SavedMatch.played([.us], scoring: .paired)
        ended.abandon()
        let updates = remote.updates()

        link.deliver(.match(ended, echo: nil))
        link.deliver(.match(ended, echo: nil))

        #expect(await updates.first(2) == [.match(ended, echo: nil), .match(ended, echo: nil)])
        #expect(link.sent == [.heardEnd(of: ended.id), .heardEnd(of: ended.id)])
    }

    @Test("A match running, won, or not paired is not answered")
    func onlyAPairedEndIsAnswered() {
        var alone = SavedMatch.played([.us], scoring: .aloneOnPhone)
        alone.abandon()

        link.deliver(.match(.played([.us], scoring: .paired), echo: nil))
        link.deliver(.match(.played([.us, .us], ruleset: toTwo, scoring: .paired), echo: nil))
        link.deliver(.match(alone, echo: nil))
        link.deliver(.noMatch(echo: nil))

        #expect(link.sent.isEmpty)
    }

    @Test("An end that arrives as the phone goes out of reach is still passed on")
    func anUnanswerableEndIsStillPassedOn() async {
        var ended = SavedMatch.played([.us], scoring: .paired)
        ended.abandon()
        link.becomeReachable(false)

        link.deliver(.match(ended, echo: nil))

        #expect(await remote.updates().first(1) == [.match(ended, echo: nil)])
        #expect(link.sent.isEmpty)
    }

    @Test("An intent sent while the phone is unreachable fails at once and is kept nowhere")
    func anUnreachableSendFails() async {
        let updates = remote.updates()
        link.becomeReachable(false)

        #expect(throws: LiveLinkError.unreachable) { try remote.send(.undo(base: 0)) }

        link.deliver(.noMatch(echo: nil))
        #expect(await updates.first(1) == [.noMatch(echo: nil)])
        #expect(link.sent.isEmpty)
    }
}
