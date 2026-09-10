import SwiftUI
import Testing

@testable import PadelDesign

/// The ramp is a mapping, and a mapping is worth testing for the two ways it
/// goes wrong: two entries landing on the same font, so a screen names a role
/// and gets somebody else's, and an entry losing its `relativeTo:`, so Dynamic
/// Type quietly stops working on it.
///
/// The sizes themselves are not asserted. They are a design decision and will
/// move; a test that froze them would have to be edited by whoever moves them,
/// which is a test that only ever says "yes, you changed what you changed".
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

    /// `ScoreView` sets the games digit on the score's baseline, and the
    /// ticket says the two "have to move together when type scales".
    ///
    /// They only do that if they scale by the *same factor*, and the factor
    /// comes from the anchor: `.largeTitle` and `.title2` do not grow alike,
    /// so anchoring the pair apart would let the digit drift off the baseline
    /// at the far end of the range. Sharing the anchor is the whole mechanism,
    /// which is why it is asserted rather than left to the doc comment.
    ///
    /// This replaces an earlier check that every entry "carries a
    /// `relativeTo`". That one could not fail — `relativeTo` is a
    /// non-optional `Font.TextStyle`, so `allCases.contains` is true for
    /// every possible value — and it was cited twice as evidence the ramp was
    /// anchored. It verified nothing.
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
