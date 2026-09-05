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

    /// The language and region the row is being read in — the day and the
    /// duration are formatted with it, so that they speak the same language as
    /// the ruleset written above them.
    @Environment(\.locale) private var locale

    var body: some View {
        let state = match.match.state
        let score = state.finalScore
        let isAbandoned = state.outcome == .abandoned

        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(score.written)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isAbandoned ? .secondary : .primary)
                    .accessibilityLabel(Text(score.spoken))

                Spacer(minLength: 8)

                if isAbandoned { abandoned }
            }

            Text(match.match.ruleset.name)
                .font(.subheadline)

            // Two whole things and a separator: neither of them is a word
            // handed to the other to build a sentence out of.
            Text(verbatim: "\(match.whenPlayed(in: locale)) · \(match.lasted(in: locale))")
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
    /// labeled at once. Gray rather than red: the same color the watch marks
    /// it with on the outcome screen, and being stopped early is not an error
    /// to warn about.
    ///
    /// The match card says the same thing in a whole sentence instead: there
    /// is one match on it and room to announce the outcome where a win would
    /// have been announced.
    private var abandoned: some View {
        Text("unfinished")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.fill.tertiary, in: Capsule())
    }
}

#if DEBUG

#Preview("The rows") {
    List { everyRow }
}

/// The same rows in the other language — the one a phone set to neither of
/// ours does not get. Where English wraps, Russian is the longer of the two.
#Preview("In Russian") {
    List { everyRow }
        .environment(\.locale, Locale(identifier: "ru"))
}

/// One of every row there is: a win, a defeat, two sets, a match to N points,
/// and the two ways a match is left unfinished.
@ViewBuilder private var everyRow: some View {
    MatchRow(match: .preview(classicWonBy: .us))
    MatchRow(match: .preview(classicWonBy: .them))
    MatchRow(match: .preview(twoSetsWonBy: .us))
    MatchRow(match: .preview(pointsTo: 16))
    MatchRow(match: .preview(pointsTo: 21, abandonedAfter: 9))
    MatchRow(match: .previewClassicAbandoned)
}

#endif
