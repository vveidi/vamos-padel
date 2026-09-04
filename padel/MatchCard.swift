import PadelScoring
import PadelStorage
import SwiftUI

/// The match card: how the score came about, and not only how it ended.
///
/// Nothing here is read out of the store beyond the ruleset and the rally
/// journal. The course of the score is rebuilt from them by the same engine
/// that counted the match on the watch — that is what the journal is stored
/// for instead of the final score (ADR-0001), and what the engine lives in a
/// shared package for.
struct MatchCard: View {
    let match: SavedMatch

    var body: some View {
        List {
            Section { summary }

            course
        }
        .navigationTitle(match.day)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The score and the outcome are asked of the engine every time rather
    /// than kept in a `@State`: recomputing them costs a walk over a journal
    /// of a few hundred rallies, and a copy would be one more thing that can
    /// disagree with the journal.
    private var state: MatchState { match.match.state }

    // MARK: How it ended

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(state.outcome.winner == .us ? ourSideColor : Color.secondary)

            // Our side first, the same as in the history's row: the card is
            // opened from that row, and a score that swapped sides on the way
            // in would have to be read twice.
            Text("\(state.finalScore[.us]) : \(state.finalScore[.them])")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel(
                    "У нас \(state.finalScore[.us]), у соперников \(state.finalScore[.them])")

            Text(match.match.ruleset.name)
                .font(.subheadline)

            Text("\(match.match.ruleset.manner) · \(match.timeOfDay) · \(match.lasted)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    /// An abandoned match is said to be one in as many words, and not by the
    /// absence of a winner: "counts as neither a win nor a loss" is a result
    /// of its own, and a card that simply stayed silent about the outcome
    /// would read as a card that lost it.
    ///
    /// The mark the history's row carries has no place next to this line — it
    /// would be the same sentence twice. The row needs it because a score in a
    /// column of results must not pass for a win at a glance; here the outcome
    /// is already spelled out where a win would have been announced.
    private var headline: String {
        switch state.outcome {
        case .finished(let winner): winner == .us ? "Мы выиграли" : "Выиграли соперники"
        case .abandoned: "Матч не доигран"
        case .inProgress: "Матч идёт"
        }
    }

    // MARK: How it came about

    @ViewBuilder private var course: some View {
        switch match.match.course {
        case .points(let steps) where steps.isEmpty:
            Section("Ход матча") { nothingPlayed }

        case .points(let steps):
            Section("Ход матча") { ScoreStrip(steps: steps, step: "Розыгрыш") }

        // A classic match stopped before its first game was played out. There
        // are no games to draw, and the points of the game it was left in are
        // the only thing that happened in it.
        case .sets(let sets) where sets.isEmpty:
            Section("Ход матча") {
                if wasStoppedMidGame { unfinishedGame } else { nothingPlayed }
            }

        case .sets(let sets):
            ForEach(Array(sets.enumerated()), id: \.offset) { number, set in
                Section {
                    ScoreStrip(steps: set.games, step: "Гейм")

                    if let tieBreak = set.tieBreak { self.tieBreak(tieBreak) }

                    // The game the match was stopped in belongs to the set it
                    // was stopped in, and that is always the last one.
                    if number == sets.count - 1, wasStoppedMidGame { unfinishedGame }
                } header: {
                    header(of: set, number: number + 1, alone: sets.count == 1)
                }
            }
        }
    }

    /// A set's line above its games: which set it is and how it ended.
    ///
    /// In a match of one set the number is not worth saying — there is nothing
    /// to tell it apart from — and neither is the score, which is the match's
    /// own and already stands in large type above.
    private func header(of set: SetCourse, number: Int, alone: Bool) -> some View {
        HStack {
            Text(alone ? "Ход матча" : "Сет \(number)")

            if !alone {
                Spacer()

                Text("\(set.score[.us]) : \(set.score[.them])")
                    .monospacedDigit()
                    .accessibilityLabel(
                        "у нас \(set.score[.us]), у соперников \(set.score[.them])")
            }
        }
    }

    /// The tiebreak's points, which the set's own score hides: "7 : 6" says
    /// that a tiebreak happened and nothing at all about how it went.
    private func tieBreak(_ points: SideCounts) -> some View {
        LabeledContent("Тай-брейк", value: "\(points[.us]) : \(points[.them])")
            .font(.subheadline)
            .monospacedDigit()
            .accessibilityLabel(
                "Тай-брейк: у нас \(points[.us]), у соперников \(points[.them])")
    }

    /// Where inside a game the match was stopped.
    ///
    /// A game carried no further than 40:30 wins nobody anything and is
    /// therefore no step of the course — but it is exactly where an abandoned
    /// match was left standing, and the card would otherwise end on the last
    /// game that did finish, as if play had stopped on a clean boundary.
    ///
    /// Nothing to say in a match played out to the end: its last rally closes
    /// a game, so no points are left over.
    private var wasStoppedMidGame: Bool { !state.points.isEmpty }

    private var unfinishedGame: some View {
        LabeledContent(
            "Гейм не доигран",
            value: "\(state.points.label(for: .us)) : \(state.points.label(for: .them))"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityLabel(
            """
            Гейм не доигран: у нас \(state.points.label(for: .us)), \
            у соперников \(state.points.label(for: .them))
            """)
    }

    /// A match with an empty journal. It has no business on the phone — the
    /// watch does not send one (ticket 10) — but a card that drew a blank
    /// section instead of saying so would hide the arrival of one.
    private var nothingPlayed: some View {
        Text("Ни одного розыгрыша")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

}

/// Our side's colour — the one the watch marks our half of the score screen
/// with. The score screen owns that decision on the watch and this file owns it
/// here: two targets with no shared home for a colour, and the same meaning on
/// both.
private let ourSideColor = Color(red: 0.188, green: 0.820, blue: 0.345)

/// The fills of a step that was won. Our side is named by the colour it is
/// named by everywhere else; the opponents get no colour of their own — being
/// filled at all is what says they took the step.
private let ourSideFill = ourSideColor.opacity(0.3)

private let theirSideFill = Color.secondary.opacity(0.18)

/// The course of the score as a scoreboard: a column per step, our row above
/// the opponents'.
///
/// The score after every step and not the winner of it, because the question
/// the card is opened with is "was it close" — and a row of names of winners
/// answers it only by being counted up in the reader's head. The step just
/// taken is the one filled in, so the alternation can be read off without
/// reading a single number.
private struct ScoreStrip: View {
    let steps: [ScoreStep]

    /// What one step is called here — a game or a rally. Only VoiceOver ever
    /// hears it: on screen the columns are told apart by the set they stand
    /// under.
    let step: String

    /// The cells grow with the reader's type size instead of clipping the
    /// digits inside them. A set then stops fitting the width at some point
    /// and starts scrolling, which is the same thing a long match does anyway.
    @ScaledMetric(relativeTo: .caption) private var height: CGFloat = 22

    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 18

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: Self.spacing) {
                side("Мы")
                side("Соперники")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

            // The columns are sized so that the longest set there is — six
            // games each and a tiebreak, thirteen columns — fits the width
            // without scrolling. A match to twenty-one points does not fit and
            // scrolls, and cutting it short instead would lose exactly the end
            // everyone reads first.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.spacing) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { number, step in
                        column(step, number: number + 1)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .padding(.vertical, 2)
    }

    private func side(_ name: String) -> some View {
        Text(name)
            .frame(height: height, alignment: .leading)
    }

    private func column(_ step: ScoreStep, number: Int) -> some View {
        VStack(spacing: Self.spacing) {
            cell(step.score[.us], won: step.winner == .us, isOurs: true)
            cell(step.score[.them], won: step.winner == .them, isOurs: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(self.step) \(number)")
        .accessibilityValue(
            """
            у нас \(step.score[.us]), у соперников \(step.score[.them]), \
            выиграли \(step.winner == .us ? "мы" : "соперники")
            """)
    }

    private func cell(_ score: Int, won: Bool, isOurs: Bool) -> some View {
        Text("\(score)")
            .font(.caption.weight(won ? .semibold : .regular))
            .monospacedDigit()
            .foregroundStyle(won ? .primary : .secondary)
            .frame(minWidth: width, minHeight: height)
            .background(
                won ? (isOurs ? ourSideFill : theirSideFill) : .clear,
                in: RoundedRectangle(cornerRadius: 5))
    }

    private static let spacing: CGFloat = 2
}

#if DEBUG

#Preview("A win") {
    NavigationStack { MatchCard(match: .preview(classicWonBy: .us)) }
}

#Preview("Two sets and a tiebreak") {
    NavigationStack { MatchCard(match: .preview(twoSetsWonBy: .us)) }
}

#Preview("The match to N points") {
    NavigationStack { MatchCard(match: .preview(pointsTo: 16)) }
}

#Preview("Stopped early") {
    NavigationStack { MatchCard(match: .previewClassicAbandoned) }
}

#Preview("Stopped early, to N points") {
    NavigationStack { MatchCard(match: .preview(pointsTo: 21, abandonedAfter: 9)) }
}

#endif
