import SwiftUI
import Testing

@testable import PadelDesign

@Suite("The ball switch")
@MainActor
struct BallSwitchTests {
    static let width: CGFloat = 320

    static func toggle(isOn: Bool) throws -> Raster {
        var held = isOn

        let binding = Binding(get: { held }, set: { held = $0 })

        return try #require(
            Raster(
                Toggle(isOn: binding) { Text(verbatim: "Golden point").textStyle(.body) }
                    .toggleStyle(.ball)
                    .frame(width: width)
                    .background(Color.night)))
    }

    /// The knob's middle: a knob's half-width in from the trailing edge of the
    /// track, once the track's own inset is taken off.
    static func knob(_ raster: Raster) -> (column: Int, row: Int) {
        let knobWidth = ControlMetrics.switchTrack.height - 2 * ControlMetrics.switchKnobInset

        return (
            raster.width - Int(ControlMetrics.switchKnobInset + knobWidth / 2),
            raster.height / 2
        )
    }

    @Test("Turned on, the track is ball and the knob is the deep teal")
    func theKnobIsNotAHoleInTheTrack() throws {
        let raster = try Self.toggle(isOn: true)
        let knob = Self.knob(raster)

        // The track showing past the knob at the other end of its travel.
        let track = (
            column: raster.width - Int(ControlMetrics.switchTrack.width) + 3, row: knob.row
        )

        #expect(
            raster.pixel(track.column, track.row, isCloseTo: .ball),
            "the track is not drawn in the ball's yellow")
        #expect(
            raster.pixel(knob.column, knob.row, isCloseTo: .knob),
            "the knob is not the boards' deep teal")
    }

    @Test("Turned off, the knob crosses and nothing is lit")
    func theKnobCrossesAndTheLightGoesOut() throws {
        let raster = try Self.toggle(isOn: false)
        let knob = Self.knob(raster)

        let atTheOtherEnd = raster.width - Int(ControlMetrics.switchTrack.width) + 6

        #expect(
            raster.luminance(atTheOtherEnd, knob.row) > 2 * raster.luminance(knob.column, knob.row),
            "the knob did not cross to the leading end of the track")

        let lit = (0..<raster.width).contains { column in
            (0..<raster.height).contains { row in
                raster.pixel(column, row, isCloseTo: .ball, tolerance: 0.1)
            }
        }

        #expect(!lit, "the accent is drawn on a switch that is off")
    }
}
