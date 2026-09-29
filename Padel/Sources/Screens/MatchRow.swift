import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

struct MatchRow: View {
    let match: SavedMatch

    @Environment(\.locale) private var locale

    var body: some View {
        // Walked once. The score and the outcome both come out of a walk over
        // the journal (ADR-0001), and this row is drawn a few hundred times
        // down a scrolling column.
        let state = match.match.state

        // Measured rather than asked of the type size: what decides is whether
        // a date and a ruleset fit one line, which differs by language.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                result(state)

                Spacer(minLength: Board.columnGap)

                stamp(alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: Board.columnGap) {
                result(state)

                stamp(alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: How it ended

    private func result(_ state: MatchState) -> some View {
        VStack(alignment: .leading, spacing: Board.lineGap) {
            outcome(state)

            Text(match.match.ruleset.name)
                .textStyle(.caption)
                .foregroundStyle(.ink.weight(.secondary))
        }
    }

    @ViewBuilder private func outcome(_ state: MatchState) -> some View {
        if state.outcome == .abandoned {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Board.markGap) {
                    score(state)

                    abandoned
                }

                VStack(alignment: .leading, spacing: Board.lineGap) {
                    score(state)

                    abandoned
                }
            }
        } else {
            score(state)
        }
    }

    private func score(_ state: MatchState) -> some View {
        Text(state.finalScore.written)
            .textStyle(.tileScore)
            .monospacedDigit()
            .foregroundStyle(Color.courtInk(state.outcome))
            .accessibilityLabel(Text(state.finalScore.spoken))
    }

    /// The word keeps its own line whatever the type size: wrapped inside a
    /// capsule it is a lozenge, not a mark.
    private var abandoned: some View {
        Text("unfinished")
            .textStyle(.caption)
            .foregroundStyle(.ink.weight(.secondary))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, Board.markPadding)
            .padding(.vertical, Board.markPaddingVertical)
            .background(.ink.weight(.surface), in: Capsule())
    }

    // MARK: When it was played

    private func stamp(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: Board.stampGap) {
            Text(match.day(in: locale))
                .foregroundStyle(.ink.weight(.strong))

            Text(match.lasted(in: locale))
                .foregroundStyle(.ink.weight(.tertiary))
        }
        .textStyle(.caption)
        .lineLimit(1)
    }
}

/// What the history board drew inside a tile, in its pixels — the phone boards
/// are 1x (`docs/design/README.md`, "Reading the boards").
private enum Board {
    static let columnGap: CGFloat = 14

    static let lineGap: CGFloat = 5

    static let stampGap: CGFloat = 4

    static let markGap: CGFloat = 8

    static let markPadding: CGFloat = 8

    static let markPaddingVertical: CGFloat = 3
}

#if DEBUG

#Preview("The tiles") { tiles }

#Preview("In Russian") { inRussian(tiles) }

#Preview("At the largest type") { atLargestType(tiles) }

#Preview("In Russian, at the largest type") { atLargestType(inRussian(tiles)) }

private var tiles: some View {
    ScrollView {
        LazyVStack(spacing: 10) {
            tile(.preview(classicWonBy: .us))
            tile(.preview(classicWonBy: .them))
            tile(.preview(twoSetsWonBy: .us))
            tile(.preview(pointsTo: 16))
            tile(.preview(pointsTo: 21, abandonedAfter: 9))
            tile(.previewClassicAbandoned)
        }
        .padding(20)
    }
    .background {
        Color.night
            .overlay { Floodlight(corner: .topTrailing) }
            .ignoresSafeArea()
    }
}

private func tile(_ match: SavedMatch) -> some View {
    CourtTile(outcome: match.match.state.outcome) { MatchRow(match: match) }
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

#endif
