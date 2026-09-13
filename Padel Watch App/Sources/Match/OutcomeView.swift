import PadelDesign
import PadelScoring
import SwiftUI

/// The match's outcome — what is seen right after the last rally, or after the
/// match was stopped early.
///
/// The ground says which of the three it was, the way a history tile's tint
/// does: the winner's half of the court full-bleed, and `night` under a match
/// that finished on neither half. The court is the one it was just played
/// on — our turf for a win, their glass for a loss — and the ball's yellow
/// marks only the win, because the ball marks what is yours (ADR-0006).
///
/// It scrolls. Nothing here is long, but the headline, the score and the two
/// buttons stand taller than a watch once Dynamic Type is turned up, and a
/// screen whose way on is off the bottom edge is a screen nobody can leave.
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
        ScrollView {
            VStack(spacing: 0) {
                headline

                scoreLine.padding(.top, Board.headlineGap)

                buttons.padding(.top, Board.buttonsGap)
            }
            .padding(.horizontal, Board.inset)
            .padding(.bottom, Board.inset)
        }
        .background { ground }
    }

    // MARK: What happened

    /// The sentence the screen exists to say.
    ///
    /// It has to reach its end — "Opponents…" is not an outcome — so at the
    /// largest type it takes a second line first and shrinks after that.
    private var headline: some View {
        Text(Self.sentence(winner))
            .textStyle(.display)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .foregroundStyle(headlineInk)
    }

    /// The final score, the winner's half of it first.
    ///
    /// The order is the headline's: the line above names the winner, and a
    /// score in the other order would read backwards against the score screen,
    /// where the opponents are on top. VoiceOver hears it in the one order
    /// that needs no headline to be read against — ours, then theirs.
    private var scoreLine: some View {
        counts
            .textStyle(.score)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .accessibilityLabel(Text("us \(score[.us]), opponents \(score[.them])"))
    }

    /// The two numbers themselves, in the order the outcome sets.
    @ViewBuilder private var counts: some View {
        if let winner {
            Text(verbatim: "\(score[winner]) : \(score[winner.opposite])")
                .foregroundStyle(Color.courtInk(winner))
        } else {
            // No winner to put first, so which number is ours is said by the
            // ball's yellow — *this is yours* — and not by a label, which
            // would take the room the score is drawn at this size for.
            (Text(verbatim: "\(score[.us])").foregroundStyle(Color.ball)
                + Text(verbatim: " : \(score[.them])").foregroundStyle(Color.ink))
        }
    }

    /// Who won, as a whole sentence and not as the name of a side handed to a
    /// frame: English puts the side before the verb and Russian after it, so
    /// there is no frame left for a name to be dropped into.
    ///
    /// The phone's card says this about a match already in the history, and it
    /// is the same sentence rather than a copy of one — a win is a win on
    /// either screen.
    private static func sentence(_ winner: Side?) -> LocalizedStringKey {
        switch winner {
        case .us: "We won"
        case .them: "Opponents won"
        case nil: "Match unfinished"
        }
    }

    /// The ink the sentence is set in: the accent on a win, and the weight a
    /// title carries everywhere else in the app on the two outcomes that are
    /// not one.
    private var headlineInk: Color {
        switch winner {
        case .us: .ball
        case .them: Color.courtInk(.them).weight(.control)
        case nil: Color.ink.weight(.control)
        }
    }

    // MARK: What to do next

    /// The way on, and under it the way back into the match.
    private var buttons: some View {
        VStack(spacing: Board.buttonGap) {
            // A button and not a gesture: the player is no longer on serve and
            // is in no hurry, and the match is written down in full by now, so
            // leaving here risks nothing.
            PillButton(Text("New match"), carriesBall: true, action: onFinish)

            if winner != nil { undo }
        }
    }

    /// Takes the last rally back, lifting a match finished by a mistaken tap.
    ///
    /// Only a decided match carries it. Stopping is not a rally and undoing a
    /// point does not lift it, so on an abandoned match this button could only
    /// change the score of a match already stopped — worse than no button at
    /// all, and an accidental stop is what the control page's confirmation is
    /// for.
    ///
    /// It says less than the action VoiceOver speaks for the same act on the
    /// score screen: "Undo the last rally" is three lines of Russian in a pill
    /// this wide, which leaves the quiet button taller than the primary one
    /// above it.
    private var undo: some View {
        PillButton(Text("Undo the rally"), variant: .quiet, action: onUndo)
    }

    // MARK: The ground

    /// The court the match was just played on, lit from a corner and fading
    /// into `night` at the foot so the buttons stay legible over it.
    ///
    /// A won match stands on our half and a lost one on theirs — the tints a
    /// history tile gives the same three outcomes. An abandoned match stands
    /// on neither: `night` with a trace of the floodlight, which is what that
    /// tile is drawn as. The half is the whole court primitive rather than its
    /// colour alone, lines and weave included: what the screen has to read as
    /// is the court, and the court is what draws one.
    private var ground: some View {
        Group {
            if let winner {
                CourtHalf(side: winner)
            } else {
                Color.night
            }
        }
        .overlay { Floodlight(corner: .topTrailing) }
        .overlay { NightScrim(edge: .bottom) }
        .ignoresSafeArea()
    }
}

/// The page's own spacing. This screen has no board (the spec's "What is in,
/// and what is not"), so every number is borrowed from a screen that has one.
///
/// What the court, the light and the buttons are drawn out of comes from
/// `PadelDesign`, and none of it is here.
private enum Board {
    /// Left and right of the page, and under the last button. The settings
    /// page's inset, which is the boards' 16px halved.
    static let inset: CGFloat = 8

    /// Between the sentence and the score it names. The smallest gap on the
    /// page: the two are one statement.
    static let headlineGap: CGFloat = 4

    /// Between the score and the buttons — the page's one real break, with
    /// what happened above it and what to do next below.
    static let buttonsGap: CGFloat = 16

    /// Between the two buttons.
    static let buttonGap: CGFloat = 6
}

#if DEBUG

/// Every outcome in both languages, and every one of them again at the far end
/// of the type range.
///
/// The headline is where this screen is widest, and the longest of the three is
/// the one Russian and English disagree about the order of: "Opponents won"
/// against "Выиграли соперники". At the largest type the page is taller than
/// every watch, so all six of those previews scroll — and the buttons at the
/// foot have to be reachable.
private func outcome(winner: Side?, score: SideCounts) -> OutcomeView {
    OutcomeView(winner: winner, score: score, onUndo: {}, onFinish: {})
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

/// The largest of the twelve Dynamic Type settings, which is where both the
/// headline and the undo button find their second line.
private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private let win = outcome(winner: .us, score: SideCounts(us: 6, them: 4))

private let defeat = outcome(winner: .them, score: SideCounts(us: 4, them: 6))

private let abandoned = outcome(winner: nil, score: SideCounts(us: 3, them: 5))

#Preview("A win") { win }

#Preview("In Russian: a win") { inRussian(win) }

#Preview("At the largest type: a win") { atLargestType(win) }

#Preview("In Russian, at the largest type: a win") { atLargestType(inRussian(win)) }

#Preview("A defeat") { defeat }

#Preview("In Russian: a defeat") { inRussian(defeat) }

#Preview("At the largest type: a defeat") { atLargestType(defeat) }

#Preview("In Russian, at the largest type: a defeat") { atLargestType(inRussian(defeat)) }

#Preview("An abandoned match") { abandoned }

#Preview("In Russian: an abandoned match") { inRussian(abandoned) }

#Preview("At the largest type: an abandoned match") { atLargestType(abandoned) }

#Preview("In Russian, at the largest type: an abandoned match") {
    atLargestType(inRussian(abandoned))
}

#endif
