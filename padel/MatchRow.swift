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
struct MatchRow: View {
    let match: SavedMatch

    var body: some View {
        let state = match.match.state
        let score = state.finalScore
        let isAbandoned = state.outcome == .abandoned

        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                // Our side first, always — including in a match we lost. The
                // history is read as a column rather than row by row, and a
                // score whose sides swap places by the outcome cannot be
                // scanned down. Which side is which is then said by the order
                // alone: "4 : 6" is a defeat.
                Text("\(score[.us]) : \(score[.them])")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isAbandoned ? .secondary : .primary)
                    .accessibilityLabel(
                        "У нас \(score[.us]), у соперников \(score[.them])")

                Spacer(minLength: 8)

                if isAbandoned { abandoned }
            }

            Text(match.match.ruleset.name)
                .font(.subheadline)

            Text("\(match.whenPlayed) · \(match.lasted)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        // The row is one thing to read out, not four: VoiceOver walking
        // separately over a score, a ruleset and a date is a way of hearing
        // everything about a match and learning nothing.
        .accessibilityElement(children: .combine)
    }

    /// The mark that has to be caught by the eye without reading the row.
    ///
    /// An abandoned match counts as neither a win nor a loss, and in a column
    /// of results its score must not pass for one — so it is dimmed and
    /// labelled at once. Grey rather than red: the same colour the watch marks
    /// it with on the outcome screen, and being stopped early is not an error
    /// to warn about.
    ///
    /// The match card says the same thing in a whole sentence instead: there
    /// is one match on it and room to announce the outcome where a win would
    /// have been announced.
    private var abandoned: some View {
        Text("не доигран")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.fill.tertiary, in: Capsule())
    }
}

#if DEBUG

#Preview {
    List {
        MatchRow(match: .preview(classicWonBy: .us))
        MatchRow(match: .preview(classicWonBy: .them))
        MatchRow(match: .preview(twoSetsWonBy: .us))
        MatchRow(match: .preview(pointsTo: 16))
        MatchRow(match: .preview(pointsTo: 21, abandonedAfter: 9))
        MatchRow(match: .previewClassicAbandoned)
    }
}

#endif
