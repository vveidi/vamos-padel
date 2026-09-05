import PadelScoring
import SwiftUI

/// The match's outcome — what is seen right after the last rally, or after the
/// match was stopped early.
struct OutcomeView: View {
    /// The side that won the match, or `nil` if the match was left abandoned.
    ///
    /// `nil` precisely, and not "the opponents won": an abandoned match counts
    /// as neither a win nor a loss, and the screen is the last place where that
    /// difference could be lost.
    let winner: Side?

    /// The score the match will be remembered by: games in classic scoring,
    /// points in the match to N points. The ruleset chooses it, not this
    /// screen.
    let score: SideCounts

    let onUndo: () -> Void

    /// Leads to the start screen for the next match. With the same tap the
    /// player picks the first server — on court it is being decided anew right
    /// then.
    let onFinish: () -> Void

    var body: some View {
        Group {
            if let winner { finished(winner) } else { unfinished }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }

    private func finished(_ winner: Side) -> some View {
        outcome(headline: Self.headline(winner), isOurs: winner == .us) {
            // The winner's score comes first — the side the line above named.
            // Otherwise the outcome reads backwards: on the score screen the
            // opponents are on top, while here they would come second.
            Text(verbatim: "\(score[winner]) : \(score[winner.opposite])")
        }
        // The same gesture as on the score screen. Without it there is nothing
        // to undo a match finished by a mistaken tap with: this screen takes
        // the place of the one the gesture lives on.
        //
        // An abandoned match has no gesture: stopping is not a rally, undoing
        // a point does not lift it, and a gesture that looks like it works
        // while in fact only changing the score of an already stopped match is
        // worse than none. An accidental stop is guarded against by the
        // confirmation.
        .onLongPressGesture(minimumDuration: 0.5) { onUndo() }
        .accessibilityAction(named: "Undo the last rally", onUndo)
    }

    /// Who won, as a whole sentence and not as the name of a side handed to a
    /// frame: English puts the side before the verb and Russian after it, so
    /// there is no frame left for a name to be dropped into.
    ///
    /// The phone's card says this about a match already in the history, and it
    /// is the same sentence rather than a copy of one — a win is a win on
    /// either screen.
    private static func headline(_ winner: Side) -> LocalizedStringKey {
        winner == .us ? "We won" : "Opponents won"
    }

    private var unfinished: some View {
        outcome(headline: "Match unfinished", isOurs: false) {
            // Who is who is said by the color — the same one that marks our
            // half of the score screen. There is no winner here to set the
            // order, and a "us" label would take room away from the score.
            (Text(verbatim: "\(score[.us])").foregroundStyle(ScoreView.ourColor)
                + Text(verbatim: " : \(score[.them])"))
                .accessibilityLabel(Text("us \(score[.us]), opponents \(score[.them])"))
        }
    }

    private func outcome(
        headline: LocalizedStringKey, isOurs: Bool, @ViewBuilder score: () -> some View
    ) -> some View {
        VStack(spacing: 8) {
            // This is the sentence the screen exists to say, and it has to
            // reach its end: "Opponents…" is not an outcome. The screen does
            // not scroll, so at the largest type the line has to give way
            // instead — a second line first, and shrinking after that. The
            // floor is half, which at the largest type is still around the
            // size this line has at the ordinary one; on the smallest watch
            // "Выиграли соперники" is the one outcome that needs both.
            Text(headline)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .foregroundStyle(isOurs ? ScoreView.ourColor : .secondary)

            score()
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            // A button, not a gesture: on this screen the player is no longer
            // on serve and is in no hurry, and mis-tapping into a new match in
            // the middle of dissecting the last rally is not something anybody
            // wants. By this point the match is written down in full, so
            // leaving here risks nothing.
            Button("New match", action: onFinish)
                .buttonStyle(.bordered)
                .font(.footnote)
                .padding(.top, 4)
        }
    }
}

#if DEBUG

/// Every outcome in both languages. The headline is where this screen is
/// widest, and the longest of the three is the one Russian and English disagree
/// about the order of: "Opponents won" against "Выиграли соперники".
private func outcome(winner: Side?, score: SideCounts) -> some View {
    OutcomeView(winner: winner, score: score, onUndo: {}, onFinish: {})
}

private func outcomeInRussian(winner: Side?, score: SideCounts) -> some View {
    outcome(winner: winner, score: score).environment(\.locale, Locale(identifier: "ru"))
}

#Preview("A win") { outcome(winner: .us, score: SideCounts(us: 6, them: 4)) }

#Preview("In Russian: a win") { outcomeInRussian(winner: .us, score: SideCounts(us: 6, them: 4)) }

#Preview("A defeat") { outcome(winner: .them, score: SideCounts(us: 4, them: 6)) }

#Preview("In Russian: a defeat") {
    outcomeInRussian(winner: .them, score: SideCounts(us: 4, them: 6))
}

#Preview("An abandoned match") { outcome(winner: nil, score: SideCounts(us: 3, them: 5)) }

#Preview("In Russian: an abandoned match") {
    outcomeInRussian(winner: nil, score: SideCounts(us: 3, them: 5))
}

#endif
