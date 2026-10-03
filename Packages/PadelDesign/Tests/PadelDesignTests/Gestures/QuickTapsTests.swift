import Testing

@testable import PadelDesign

@Suite("Quick taps")
struct QuickTapsTests {
    static let start = ContinuousClock.now

    static func taps(_ offsets: [Duration]) -> [Bool] {
        var taps = QuickTaps(count: 10, gap: .milliseconds(500))
        return offsets.map { taps.tap(at: start + $0) }
    }

    static func evenly(_ count: Int, every gap: Duration, from first: Duration = .zero) -> [Duration] {
        (0..<count).map { first + gap * $0 }
    }

    @Test("Ten quick taps complete the run on the tenth")
    func tenQuickTaps() {
        let results = Self.taps(Self.evenly(10, every: .milliseconds(300)))

        #expect(results == Array(repeating: false, count: 9) + [true])
    }

    @Test("Nine quick taps do not")
    func nineQuickTaps() {
        #expect(!Self.taps(Self.evenly(9, every: .milliseconds(300))).contains(true))
    }

    @Test("Ten slow taps do not")
    func tenSlowTaps() {
        #expect(!Self.taps(Self.evenly(10, every: .milliseconds(600))).contains(true))
    }

    @Test("A long pause starts the count over")
    func aPauseStartsOver() {
        let before = Self.evenly(5, every: .milliseconds(300))
        let after = Self.evenly(10, every: .milliseconds(300), from: .seconds(3))

        let results = Self.taps(before + after)

        #expect(results.firstIndex(of: true) == before.count + 9)
    }

    @Test("A gap of exactly the limit still counts")
    func theLimitCounts() {
        #expect(Self.taps(Self.evenly(10, every: .milliseconds(500))).last == true)
    }

    @Test("A completed run starts over: twenty quick taps complete it twice")
    func twentyQuickTaps() {
        let results = Self.taps(Self.evenly(20, every: .milliseconds(300)))

        #expect(results.indices.filter { results[$0] } == [9, 19])
    }
}
