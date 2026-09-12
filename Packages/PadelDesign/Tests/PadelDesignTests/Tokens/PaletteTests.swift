import PadelScoring
import SwiftUI
import Testing

@testable import PadelDesign

/// A color is a color, and there is not much here to assert. What there is:
/// that the hex the boards are written in survives the trip into `Color`, and
/// that the tokens which are meant to differ actually do — a weight that
/// collapses onto the one above it is a design bug that reads as a rendering
/// one.
@Suite("The palette")
struct PaletteTests {
    /// Resolving in a default environment is enough: there is one appearance
    /// and no dynamic colors in this palette (ADR-0006), so nothing here
    /// depends on what the environment says.
    static func resolved(_ color: Color) -> Color.Resolved {
        color.resolve(in: EnvironmentValues())
    }

    @Test("Hex arrives as the sRGB the board wrote")
    func hexConvertsToSRGB() {
        let resolved = Self.resolved(Color(hex: 0x04_18_1F))

        #expect(abs(resolved.red - 4 / 255) < 0.001)
        #expect(abs(resolved.green - 24 / 255) < 0.001)
        #expect(abs(resolved.blue - 31 / 255) < 0.001)
        #expect(abs(resolved.opacity - 1) < 0.001)
    }

    @Test(
        "Every token is the color the board gives",
        arguments: [
            (Color.night, UInt32(0x04_18_1F)),
            (.theirHalf, 0x0E_3D_4C),
            (.ourHalf, 0x12_56_4F),
            (.ball, 0xDD_F3_5C),
            (.onBall, 0x16_26_0A),
            (.knob, 0x0B_2B_26),
            (.ink, 0xEE_F7_F5),
            (.inkTheirHalf, 0xDC_EF_E9),
            (.inkOurHalf, 0xF4_FF_FB),
            (.lineTheirHalf, 0xB4_EB_DE),
            (.lineOurHalf, 0xBE_F5_E4),
            (.floodlight, 0xFF_F8_D6),
        ])
    func tokensMatchTheBoards(token: Color, hex: UInt32) {
        #expect(Self.resolved(token) == Self.resolved(Color(hex: hex)))
    }

    @Test("The ink's weights descend in one order")
    func inkWeightsAreOrdered() {
        // Two pairs are the same number on purpose — `hairline` and `surface`
        // land on 0.12, `tape` and `control` on 0.82, and neither pair has a
        // reason to move together — so the descent is checked with both pairs
        // collapsed.
        let descending: [InkWeight] = [
            .primary, .post, .tape, .strong, .secondary, .tertiary, .surface, .surfaceQuiet,
        ]

        #expect(
            descending.count == InkWeight.allCases.count - 2,
            "a weight was added and left out of the descent")

        for (heavier, lighter) in zip(descending, descending.dropFirst()) {
            #expect(
                heavier.opacity > lighter.opacity,
                "\(heavier) should sit above \(lighter)")
        }

        #expect(InkWeight.hairline.opacity == InkWeight.surface.opacity)
        #expect(InkWeight.tape.opacity == InkWeight.control.opacity)
    }

    /// Ticket 02 draws the net out of these and ticket 03 the controls, and
    /// the point of naming them here is that neither writes a hex of its own.
    @Test("The net, the seam and the shadow are the boards' values")
    func thePrimitivesTokensMatchTheBoards() {
        #expect(abs(Self.resolved(.netTape).opacity - 0.82) < 0.001)
        #expect(abs(Self.resolved(.netPost).opacity - 0.9) < 0.001)
        #expect(abs(Self.resolved(.shadow).opacity - 0.5) < 0.001)

        // rgba(20, 40, 18, 0.4) — dark green, and emphatically not `onBall`.
        let seam = Self.resolved(.ballSeam)

        #expect(abs(seam.red - 20 / 255) < 0.001)
        #expect(abs(seam.green - 40 / 255) < 0.001)
        #expect(abs(seam.blue - 18 / 255) < 0.001)
        #expect(abs(seam.opacity - 0.4) < 0.001)
        #expect(Self.resolved(.onBall) != Self.resolved(Color(hex: 0x14_28_12)))
    }

    @Test("A weight is the color at that opacity and nothing else")
    func weightOnlyChangesOpacity() {
        let full = Self.resolved(.ink)
        let secondary = Self.resolved(.ink.weight(.secondary))

        #expect(secondary.red == full.red)
        #expect(secondary.green == full.green)
        #expect(secondary.blue == full.blue)
        #expect(abs(secondary.opacity - 0.55) < 0.001)
    }

    @Test("The two halves are two surfaces, two inks and two sets of lines")
    func theHalvesDiffer() {
        #expect(Self.resolved(.courtSurface(.us)) != Self.resolved(.courtSurface(.them)))
        #expect(Self.resolved(.courtInk(.us)) != Self.resolved(.courtInk(.them)))

        for line in CourtLine.allCases {
            #expect(
                Self.resolved(.courtLine(line, on: .us))
                    != Self.resolved(.courtLine(line, on: .them)),
                "the \(line) line is the same on both halves")
        }

        #expect(Self.resolved(.courtWeave(on: .us)) != Self.resolved(.courtWeave(on: .them)))
    }

    /// The ink that goes with a ``CourtTile``'s tint. The tile draws a won
    /// match on turf and a lost one on glass, so the ink has to be that half's
    /// and not one answer for both; a match that finished on neither half is
    /// on `night`, and takes the ink the app sets a title in.
    @Test("A tile's ink follows the half its tint came from")
    func theOutcomesInkFollowsTheTint() {
        #expect(Self.resolved(.courtInk(.finished(winner: .us))) == Self.resolved(.courtInk(.us)))
        #expect(
            Self.resolved(.courtInk(.finished(winner: .them))) == Self.resolved(.courtInk(.them)))

        for outcome in [MatchOutcome.abandoned, .inProgress] {
            #expect(
                Self.resolved(.courtInk(outcome)) == Self.resolved(.ink.weight(.control)),
                "\(outcome) stands on night and does not take a half's ink")
        }
    }

    @Test(
        "The service line is read first and the outline last",
        arguments: Side.allCases)
    func linesDescendFromServiceToOutline(side: Side) {
        let service = Self.resolved(.courtLine(.service, on: side)).opacity
        let center = Self.resolved(.courtLine(.center, on: side)).opacity
        let outline = Self.resolved(.courtLine(.outline, on: side)).opacity

        #expect(service > center)
        #expect(center > outline)
    }

    @Test("Our half is the lit one", arguments: CourtLine.allCases)
    func ourLinesAreBrighterThanTheirs(line: CourtLine) {
        #expect(
            Self.resolved(.courtLine(line, on: .us)).opacity
                > Self.resolved(.courtLine(line, on: .them)).opacity)
    }

    @Test("The light never arrives at full strength")
    func gradientsStartBelowOpaque() {
        for stop in Gradient.floodlight().stops + Gradient.ballGlow.stops {
            #expect(Self.resolved(stop.color).opacity < 0.2)
        }

        // The scrim is the exception: it exists to hide the court, and its far
        // end is nearly `night` itself.
        #expect(Self.resolved(Gradient.nightScrim.stops.first!.color).opacity == 0)
        #expect(Self.resolved(Gradient.nightScrim.stops.last!.color).opacity > 0.9)
    }
}
