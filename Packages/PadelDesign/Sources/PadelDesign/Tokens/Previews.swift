import SwiftUI

// The palette, the ramp and the radii, drawn.
//
// A token is a number until it is next to the other numbers, and the two
// mistakes this package can make — a weight that does not separate from the
// one above it, a ramp entry that lands on top of the one below — are both
// invisible in source and obvious here.
//
// Three boards and four previews; the ramp gets two, because a ramp is only
// doing its job if it moves. Both platforms come from the same four: the sizes
// and the radii resolve per platform, so these are the watch's when the canvas
// is running the watch scheme and the phone's when it is running `padel`.
// There is nothing to preview for a light appearance, because there is no
// light appearance (ADR-0006).

// MARK: - The palette

private struct PaletteBoard: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                group("Ground and court") {
                    row("night", .night)
                    row("court", .court)
                    row("courtLit", .courtLit)
                }

                group("The accent") {
                    row("ball", .ball)
                    row("onBall", .onBall)
                    row("ballWash", .ballWash)
                    row("knob", .knob)
                    row("ballSeam", Color.ballSeam)
                }

                group("The ink, weighted") {
                    ForEach(InkWeight.allCases, id: \.self) { weight in
                        row(".\(weight)", .ink.weight(weight))
                    }
                }

                group("The net") {
                    row("netTape", Color.netTape, over: .court)
                    row("netPost", Color.netPost, over: .court)
                    row("shadow", Color.shadow, over: .court)
                }

                group("On the court") {
                    row("courtInk", .courtInk, over: .court)
                    row("courtWeave", Color.courtWeave(), over: .court)
                    row("courtSurface(dimmed:)", .courtSurface(dimmed: true), over: .night)
                }

                group("The light") {
                    row("floodlight", downward(.floodlight()), over: .court)
                    row("nightScrim", downward(.nightScrim), over: .court)
                    row("ballGlow", downward(.ballGlow), over: .night)
                }
            }
            .padding()
        }
        .background(Color.night)
    }

    private func group(
        _ title: String, @ViewBuilder rows: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .textStyle(.caption)
                .foregroundStyle(.ink.weight(.tertiary))

            rows()
        }
    }

    /// One swatch and its name.
    ///
    /// `some ShapeStyle` rather than `Color`, so a gradient and a flat color
    /// go through the same row: they are the same chip over the same ground
    /// with the same label, and drawing them twice is how two rows that ought
    /// to match drift apart.
    private func row(
        _ name: String, _ fill: some ShapeStyle, over ground: Color = .night
    ) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: .segment)
                .fill(ground)
                .overlay(RoundedRectangle(cornerRadius: .segment).fill(fill))
                .overlay(
                    RoundedRectangle(cornerRadius: .segment)
                        .strokeBorder(.ink.weight(.hairline)))
                .frame(width: 46, height: 26)

            Text(name)
                .textStyle(.body)
                .foregroundStyle(.ink.weight(.secondary))
        }
    }

    /// A gradient token laid out top to bottom, which is the only direction a
    /// 46×26 chip has room to show one in.
    private func downward(_ gradient: Gradient) -> LinearGradient {
        LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
    }
}

#Preview("The palette") { PaletteBoard() }

// MARK: - The ramp

private struct RampBoard: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(TypeRamp.allCases, id: \.self) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: "40")
                            .textStyle(entry)
                            .foregroundStyle(.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)

                        Text(verbatim: ".\(entry) · \(Int(entry.size))pt · \(entry.relativeTo)")
                            .textStyle(.caption)
                            .foregroundStyle(.ink.weight(.tertiary))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color.night)
    }
}

#Preview("The ramp") { RampBoard() }

/// The ramp is only doing its job if it moves, and macOS cannot show that —
/// see `RenderingTests`. On a watch or phone canvas, this preview beside the
/// one above it is the whole of the evidence that the anchors are live.
#Preview("The ramp, largest type") {
    RampBoard().environment(\.dynamicTypeSize, .accessibility5)
}

// MARK: - The radii

private struct RadiiBoard: View {
    private let radii: [(String, CGFloat)] = [
        ("card", .card),
        ("tile", .tile),
        ("button", .button),
        ("segment", .segment),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(radii, id: \.0) { name, radius in
                    RoundedRectangle(cornerRadius: radius)
                        .fill(.ink.weight(.surface))
                        .overlay(
                            RoundedRectangle(cornerRadius: radius)
                                .strokeBorder(.ink.weight(.hairline)))
                        .frame(height: 54)
                        .overlay(
                            Text(verbatim: ".\(name) · \(Int(radius))")
                                .textStyle(.control)
                                .foregroundStyle(.ink.weight(.secondary)))
                }
            }
            .padding()
        }
        .background(Color.night)
    }
}

#Preview("The radii") { RadiiBoard() }
