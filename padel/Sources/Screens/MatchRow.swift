import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

/// One match in the history: the score it ended on, the rules it was played
/// by, the day it was played and how long it lasted.
///
/// The rules are on the row and not only inside the match card, because
/// without them the score cannot be read: "16 : 14" is a strange tennis result
/// and an ordinary match to 16 points, and only the line beneath says which of
/// the two it is.
///
/// What the row is drawn *on* is not here. It is the content of a
/// ``PadelDesign/CourtTile``, and the tile's tint is what says how the match
/// ended — so this file never asks who won in order to pick a background, only
/// in order to pick the ink that background needs.
struct MatchRow: View {
    let match: SavedMatch

    /// The language and region the row is being read in — the day and the
    /// duration are formatted with it, so that they speak the same language as
    /// the ruleset written above them.
    @Environment(\.locale) private var locale

    var body: some View {
        // Walked once. The score and the outcome both come out of a walk over
        // the journal (ADR-0001), and this row is drawn a few hundred times
        // down a scrolling column.
        let state = match.match.state

        // Side by side while the two columns fit, stacked when they stop
        // fitting — which on a phone is a question about the type size, and at
        // the accessibility settings the answer is no. Measured rather than
        // asked of the environment: what decides is whether a date and a
        // ruleset fit on one line, and the same setting gives a different
        // answer in the two languages.
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
        // The row is one thing to read out, not four: VoiceOver walking
        // separately over a score, a ruleset and a date is a way of hearing
        // everything about a match and learning nothing.
        .accessibilityElement(children: .combine)
    }

    // MARK: How it ended

    /// The score, the mark an unfinished match carries, and the rules the
    /// score has to be read by.
    private func result(_ state: MatchState) -> some View {
        VStack(alignment: .leading, spacing: Board.lineGap) {
            outcome(state)

            Text(match.match.ruleset.name)
                .textStyle(.caption)
                .foregroundStyle(.ink.weight(.secondary))
        }
    }

    /// The score, with the mark beside it while the two fit and under it when
    /// they stop.
    ///
    /// A played-out match is the score alone, so it needs neither the
    /// arrangement nor the measuring: what is being fitted here is a word that
    /// only an abandoned match carries.
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
            .foregroundStyle(Self.ink(state.outcome))
            .accessibilityLabel(Text(state.finalScore.spoken))
    }

    /// The ink the score is set in: the court's own, on a tile that is a half
    /// of it.
    ///
    /// A won tile is turf and a lost one is glass, and text inside a half is
    /// what ``PadelDesign/SwiftUI/Color/courtInk(_:)`` exists for. A match with
    /// no winner is on `night` instead, where the ink is the weight this app
    /// sets a title in — the same three-way answer the watch's outcome screen
    /// gives.
    private static func ink(_ outcome: MatchOutcome) -> Color {
        guard let winner = outcome.winner else { return .ink.weight(.control) }

        return .courtInk(winner)
    }

    /// The mark that has to be caught by the eye without reading the row.
    ///
    /// An abandoned match counts as neither a win nor a loss, and in a column
    /// of results its score must not pass for one. The tile's tint says so as
    /// well now — it is the one tile cut from neither half — but a tint is a
    /// thing you have to have learned, and the word is not.
    ///
    /// The match card says the same thing in a whole sentence instead: there
    /// is one match on it and room to announce the outcome where a win would
    /// have been announced.
    /// It keeps its own line whatever the type size: a word wrapped inside a
    /// capsule is a lozenge, not a mark.
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

    /// The day and how long the match lasted.
    ///
    /// The hour it started at is on the match card and not here: two matches
    /// on one evening are told apart by their scores, and the column is
    /// scanned by day.
    ///
    /// - Parameter alignment: Which edge the two lines are set against —
    ///   trailing when they stand beside the score, leading when they have
    ///   dropped underneath it.
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

/// What `PhoneHistory.dc.html` draws inside a tile. The phone boards are 1x, so
/// these are the board's pixels (the spec's "Reading the boards").
///
/// The tile's own padding, its radius and its tints come out of `PadelDesign`.
/// What is left is the spacing between the things the row carries.
private enum Board {
    /// Between the score and the day beside it — the board's 14px gap between
    /// the two columns, and the gap they keep when they stack.
    static let columnGap: CGFloat = 14

    /// Between the score and the rules under it.
    static let lineGap: CGFloat = 5

    /// Between the day and the duration under it.
    static let stampGap: CGFloat = 4

    /// Between the score and the mark an unfinished match carries.
    static let markGap: CGFloat = 8

    /// Left and right of that mark's word, inside its capsule.
    static let markPadding: CGFloat = 8

    /// Above and below it.
    static let markPaddingVertical: CGFloat = 3
}

#if DEBUG

#Preview("The tiles") { tiles }

/// The same tiles in the other language — the one a phone set to neither of
/// ours does not get. Where English wraps, Russian is the longer of the two,
/// and the day at the trailing edge is longer again.
#Preview("In Russian") { inRussian(tiles) }

/// The setting at which the two columns stop fitting side by side and the day
/// drops under the score.
#Preview("At the largest type") { atLargestType(tiles) }

#Preview("In Russian, at the largest type") { atLargestType(inRussian(tiles)) }

/// One of every tile there is: a win, a defeat, two sets, a match to N points,
/// and the two ways a match is left unfinished — on the ground they are cut
/// from, because a tile's tint is half of what it says.
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
