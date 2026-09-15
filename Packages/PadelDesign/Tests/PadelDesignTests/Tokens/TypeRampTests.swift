import SwiftUI
import Testing

@testable import PadelDesign

/// The sizes themselves are deliberately not asserted. They are a design
/// decision and will move, and a test that froze them would only ever say
/// "yes, you changed what you changed".
@Suite("The type ramp")
struct TypeRampTests {
    @Test("Seven entries, and seven is the budget")
    func theRampHasSevenEntries() {
        #expect(TypeRamp.allCases.count == 7)
    }

    @Test("No two entries resolve to the same font")
    func entriesAreDistinct() {
        let fonts = Set(TypeRamp.allCases.map(\.font))

        #expect(fonts.count == TypeRamp.allCases.count)
    }

    @Test("Every entry has a size worth setting type at", arguments: TypeRamp.allCases)
    func everySizeIsPlausible(entry: TypeRamp) {
        #expect(entry.size >= 13)
    }

    @Test("The score is the largest thing on the screen")
    func theScoreLeadsTheRamp() {
        for entry in TypeRamp.allCases where entry != .score {
            #expect(TypeRamp.score.size > entry.size)
        }
    }

    /// The shared anchor is the whole mechanism: two text styles do not grow
    /// alike, so anchoring the pair apart would let the games digit drift off
    /// the score's baseline at the far end of the range.
    @Test("The score and the digit beside it scale by one factor")
    func theScoreAndItsAsideStayAPair() {
        #expect(TypeRamp.score.relativeTo == TypeRamp.scoreAside.relativeTo)
        #expect(TypeRamp.score.size > TypeRamp.scoreAside.size)
        #expect(TypeRamp.score.design == TypeRamp.scoreAside.design)
    }

    @Test("The numbers and the titles are rounded, the words are not")
    func theRampSplitsRoundedFromDefault() {
        let rounded: Set<TypeRamp> = [.score, .scoreAside, .display, .tileScore]

        for entry in TypeRamp.allCases {
            #expect(
                entry.design == (rounded.contains(entry) ? .rounded : .default),
                "\(entry) is set in the wrong face")
        }
    }
}
