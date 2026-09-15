import SwiftUI
import Testing

@testable import PadelDesign

/// - Important: Nothing here proves the ramp answers Dynamic Type. Measured:
///   on the Mac, SwiftUI's own `.font(.body)` renders to the same height at
///   `.xSmall` and at `.accessibility5`, so such a test would be asserting the
///   Mac's behavior and calling it the ramp's.
@Suite("Rendering")
@MainActor
struct RenderingTests {
    /// The rendered height of the sample text in pixels, or zero if nothing
    /// was drawn.
    static func renderedHeight(_ entry: TypeRamp) -> Int {
        ImageRenderer(content: Text(verbatim: "40").textStyle(entry).fixedSize())
            .cgImage?.height ?? 0
    }

    @Test("The entry reaches the glyphs")
    func theRampIsActuallyApplied() {
        let bySize = TypeRamp.allCases.sorted { $0.size < $1.size }
        let heights = bySize.map(Self.renderedHeight)

        #expect(heights.allSatisfy { $0 > 0 }, "an entry rendered nothing at all")

        // Not strictly increasing: `.body` at 15 and `.control` at 16 round to
        // the same line height on the phone.
        for (smaller, larger) in zip(heights, heights.dropFirst()) {
            #expect(smaller <= larger, "the ramp does not reach the text: \(heights)")
        }

        #expect(
            Self.renderedHeight(.score) > Self.renderedHeight(.caption),
            ".textStyle applied nothing — every entry drew the same size")
    }
}
