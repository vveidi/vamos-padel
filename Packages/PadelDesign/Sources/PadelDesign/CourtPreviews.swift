import PadelScoring
import SwiftUI

// The court, the net, the ball and the light, drawn.
//
// Five boards. Everything here is geometry, and geometry is the part of a
// design that cannot be read off source: a service line at 30% of the wrong
// edge, a post at one end of the net, a weave that has become stripes and a
// floodlight that has become a colour all compile.
//
// Both platforms come from the same five. The thicknesses and the radii
// resolve per platform, so these are the watch's when the canvas is running
// the watch scheme and the phone's when it is running `padel` — which is what
// makes running them twice worth the trouble.

// MARK: - The court

/// The whole thing, as four of the six boards draw it: full bleed to every
/// edge, lit from a corner.
private struct CourtBoard: View {
    var body: some View {
        Court()
            .overlay { Floodlight(corner: .topLeading, strength: 0.17) }
            .ignoresSafeArea()
    }
}

#Preview("The court") { CourtBoard() }

// MARK: - The halves

/// The two halves apart, on `night`, so that the mirror and the missing fourth
/// edge are both visible.
///
/// Their service line is 30% down from the top and ours is 30% up from the
/// bottom; their centre line runs from the service line to the net and ours
/// from the net to the service line; and neither outline has an edge along the
/// net. Put the two back together and it is one court.
private struct HalvesBoard: View {
    var body: some View {
        VStack(spacing: 22) {
            ForEach(Side.allCases, id: \.self) { side in
                CourtHalf(side: side)
                    .overlay(alignment: .topLeading) {
                        Text(verbatim: side == .them ? "them · the net is below" : "us · the net is above")
                            .textStyle(.caption)
                            .foregroundStyle(Color.courtInk(side).weight(.secondary))
                            .padding(10)
                    }
            }
        }
        .padding(.vertical, 22)
        .background(Color.night)
    }
}

#Preview("The halves") { HalvesBoard() }

// MARK: - The net

/// The net at both screens' widths, over a court and over `night`.
///
/// Over the court because the shadow is what lifts it off the turf and there
/// is nothing to lift it off otherwise; over `night` because that is where the
/// posts are easiest to count, and there are two of them.
private struct NetBoard: View {
    private let widths: [CGFloat] = [198, 393]

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 26) {
                ForEach(widths, id: \.self) { width in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "\(Int(width))pt")
                            .textStyle(.caption)
                            .foregroundStyle(.ink.weight(.tertiary))

                        NetLine().frame(width: width)

                        VStack(spacing: 0) {
                            CourtHalf(side: .them).frame(height: 40)
                            NetLine().zIndex(1)
                            CourtHalf(side: .us).frame(height: 40)
                        }
                        .frame(width: width)
                    }
                }
            }
            .padding(22)
        }
        .background(Color.night)
    }
}

#Preview("The net") { NetBoard() }

// MARK: - The ball

/// Every size the ball is drawn at, and both ways round.
///
/// 10pt is the score screen's corner — the size the dot has today — 20pt is
/// the one waiting on the net before a match, and 21 to 34 are the phone's
/// tiles and buttons. It has to be the same object at both ends of that.
private struct BallBoard: View {
    private let sizes: [CGFloat] = [10, 15, 20, 21, 24, 30, 34]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                row("on the court", finish: .onCourt)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.ourHalf)

                row("cut out of a button", finish: .cutOut)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.ball)
            }
            .padding(.vertical, 20)
        }
        .background(Color.night)
    }

    private func row(_ name: String, finish: Ball.Finish) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(sizes, id: \.self) { size in
                    Ball(size: size, finish: finish)
                }
            }

            Text(verbatim: name)
                .textStyle(.caption)
                .foregroundStyle(finish == .onCourt ? Color.inkOurHalf : .onBall)
        }
    }
}

#Preview("The ball") { BallBoard() }

// MARK: - The light

/// The floodlight from each corner, and the scrim at each edge.
///
/// What to look for: the floodlight reading as light rather than as a second
/// colour, and the scrim reaching `night` at its edge without a visible band
/// where it starts.
private struct LightBoard: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Floodlight.Corner.allCases, id: \.self) { corner in
                    Court()
                        .overlay { Floodlight(corner: corner) }
                        .frame(height: 120)
                        .overlay(alignment: .bottom) {
                            Text(verbatim: ".\(corner)")
                                .textStyle(.caption)
                                .foregroundStyle(.ink.weight(.secondary))
                                .padding(6)
                        }
                }

                Court()
                    .overlay { NightScrim(edge: .top, depth: 60) }
                    .overlay { NightScrim(edge: .bottom, depth: 60) }
                    .frame(height: 200)
                    .overlay(alignment: .top) { label("the scrim, both edges") }
            }
            .padding(14)
        }
        .background(Color.night)
    }

    private func label(_ text: String) -> some View {
        Text(verbatim: text)
            .textStyle(.caption)
            .foregroundStyle(.ink.weight(.secondary))
            .padding(6)
    }
}

#Preview("The light") { LightBoard() }
