import SwiftUI

// MARK: - The court

private struct CourtBoard: View {
    var body: some View {
        Court()
            .overlay { Floodlight(corner: .topLeading, strength: 0.17) }
            .ignoresSafeArea()
    }
}

#Preview("The court") { CourtBoard() }

// MARK: - The halves

private struct HalvesBoard: View {
    private let labels = ["the net is below", "the net is above"]

    var body: some View {
        VStack(spacing: 22) {
            ForEach(labels, id: \.self) { label in
                CourtHalf()
                    .overlay(alignment: .topLeading) {
                        Text(verbatim: label)
                            .textStyle(.caption)
                            .foregroundStyle(Color.courtInk.weight(.secondary))
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
                            CourtHalf().frame(height: 40)
                            NetLine().zIndex(1)
                            CourtHalf().frame(height: 40)
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

private struct BallBoard: View {
    private let sizes: [CGFloat] = [10, 15, 20, 21, 24, 30, 34]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                row("on the court", finish: .onCourt)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.court)

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
                .foregroundStyle(finish == .onCourt ? Color.courtInk : .onBall)
        }
    }
}

#Preview("The ball") { BallBoard() }

// MARK: - The light

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
