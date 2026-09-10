import SwiftUI
import Testing

@testable import PadelDesign

/// `.textStyle(_:)` is the only thing in this package that is machinery rather
/// than a value — a `ViewModifier` carrying a `DynamicProperty` — and it is
/// what every screen in tickets 04–09 will call. Everything else here can be
/// read off; this has to be drawn to be believed.
///
/// The assertion is that the entry reaches the glyphs: taller entries render
/// taller text. A modifier that silently applied nothing would leave all seven
/// the same height, which is exactly the failure that compiles.
///
/// Rendering happens on the Mac, which is why the package carries `.macOS` —
/// the same reason the neighboring three do.
///
/// **What is deliberately not tested here: that the ramp scales with Dynamic
/// Type.** The obvious test renders an entry at `.xSmall` and again at
/// `.accessibility5` and watches it grow. It cannot live here, because macOS
/// has no Dynamic Type at all — measured, and not assumed: on the Mac,
/// SwiftUI's own `.font(.body)` renders to the same height at both settings,
/// and so does a bare `@ScaledMetric` in a plain `View`. A test written
/// against that would be asserting the Mac's behavior and calling it the
/// ramp's.
///
/// So say it plainly: **nothing here proves the ramp answers Dynamic Type.**
/// That an entry carries an anchor is a type-level guarantee rather than a
/// tested one — `relativeTo` is a non-optional `Font.TextStyle` — and a test
/// asserting it would be a test that cannot fail. What is checked instead is
/// the one consequence that *is* checkable: `.score` and `.scoreAside` share
/// an anchor, so the pair scales by one factor (`TypeRampTests`). Beyond that
/// it is the eye — `Previews.swift` renders the ramp twice, once at the
/// default setting and once at `.accessibility5`, and on a watch or phone
/// canvas the difference between those two previews is the whole of the
/// evidence.
@Suite("Rendering")
@MainActor
struct RenderingTests {
    /// The rendered height of the sample text in pixels, or zero if nothing
    /// was drawn.
    ///
    /// `cgImage` rather than the platform's own image type: it is the one
    /// `ImageRenderer` offers everywhere, and this suite has no business
    /// caring which platform it woke up on.
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
        // the same line height on the phone, and two entries a point apart
        // have no business being told apart by a bitmap.
        for (smaller, larger) in zip(heights, heights.dropFirst()) {
            #expect(smaller <= larger, "the ramp does not reach the text: \(heights)")
        }

        #expect(
            Self.renderedHeight(.score) > Self.renderedHeight(.caption),
            ".textStyle applied nothing — every entry drew the same size")
    }
}
