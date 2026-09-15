import PadelScoring
import SwiftUI
import Testing

@testable import PadelDesign

@Suite("The palette")
struct PaletteTests {
    /// A default environment is enough: there is one appearance and no dynamic
    /// colors in this palette (ADR-0006).
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
            (.court, 0x17_40_6F),
            (.courtLit, 0x2C_70_AE),
            (.ball, 0xDD_F3_5C),
            (.onBall, 0x16_26_0A),
            (.knob, 0x0B_2B_26),
            (.ink, 0xEE_F7_F5),
            (.courtInk, 0xE6_EE_F8),
            (.floodlight, 0xFF_F8_D6),
        ])
    func tokensMatchTheBoards(token: Color, hex: UInt32) {
        #expect(Self.resolved(token) == Self.resolved(Color(hex: hex)))
    }

    @Test("The ink's weights descend in one order")
    func inkWeightsAreOrdered() {
        // Two pairs share a number on purpose — `hairline` with `surface`,
        // `tape` with `control` — so the descent is checked with both pairs
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

    @Test("The surface, the ink and the weave are each one value")
    func theCourtAnswersOnce() {
        #expect(Self.resolved(.courtSurface()) == Self.resolved(.court))

        for onTheCourt in [MatchOutcome.finished(winner: .us), .inProgress] {
            #expect(Self.resolved(.courtInk(onTheCourt)) == Self.resolved(.courtInk))
        }

        let weave = Self.resolved(.courtWeave())

        #expect(weave.opacity > 0 && weave.opacity < 0.05)
        #expect(Self.resolved(.courtWeave(dimmed: true)).opacity == 0)
    }

    /// Brightness alone is also satisfied by white, by the floodlight and by
    /// the ball, which ADR-0011 rejected as marks — so the claim is checked as
    /// channel ratios rather than as luminance, and the three rejects are run
    /// through the same check to show that it separates them.
    @Test("The lit court is the court, brighter")
    func theLitCourtKeepsTheCourtsHue() {
        let court = Self.resolved(.court)
        let lit = Self.resolved(.courtLit)

        #expect(lit.red > court.red)
        #expect(lit.green > court.green)
        #expect(lit.blue > court.blue)

        // The tolerance sits just above `courtLit`'s own drift of 0.07 and an
        // order of magnitude below the nearest reject's 0.58.
        #expect(Self.hueDrift(from: .court, to: .courtLit) < 0.08)

        for brighter in [Color.white, .floodlight, .ball] {
            #expect(
                Self.hueDrift(from: .court, to: brighter) > 0.08,
                "a brightness-only check would have let this through")
        }
    }

    /// How far one color's channel balance sits from another's: each channel
    /// over the blue, so a color that is the court scaled up comes out at zero
    /// however far it was scaled, and one that brightened by turning white
    /// does not.
    static func hueDrift(from base: Color, to other: Color) -> Double {
        let ratios = { (color: Color) -> (red: Double, green: Double) in
            let resolved = Self.resolved(color)

            return (
                red: Double(resolved.red / resolved.blue),
                green: Double(resolved.green / resolved.blue)
            )
        }

        let one = ratios(base)
        let two = ratios(other)

        return max(abs(one.red - two.red), abs(one.green - two.green))
    }

    @Test("A tile's ink follows the ground its tile is drawn on")
    func theOutcomesInkFollowsTheGround() {
        for outcome in [MatchOutcome.finished(winner: .us), .inProgress] {
            #expect(
                Self.resolved(.courtInk(outcome)) == Self.resolved(.courtInk),
                "\(outcome) stands on the court and takes the court's ink")
        }

        for outcome in [MatchOutcome.finished(winner: .them), .abandoned] {
            #expect(
                Self.resolved(.courtInk(outcome)) == Self.resolved(.ink.weight(.control)),
                "\(outcome) stands on night and does not take the court's ink")
        }
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
