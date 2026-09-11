import PadelDesign
import PadelScoring
import SwiftUI

/// The screen a match starts from: the court before anybody has played on it,
/// and nothing else.
///
/// Speed is what matters here. A group plays by the same rules for months, so
/// the previous match's rules are already filled in and the only thing asked is
/// what changes every time — whose serve is first. That same answer starts the
/// match: the tap by which the player names the serving side is exactly the
/// "start with one tap". A separate "Start" button next to the serve choice
/// would be a second tap that says nothing new, which is why the board draws
/// none.
///
/// So the two halves of the court *are* the control, and they are the whole of
/// this page. The ball waits on the net between them. Everything that is not
/// the one question — the rules, and whether the match goes to Health — is a
/// scroll down, on ``StartPages``' second page: a setting asked before every
/// match is a tax paid for something that happens twice a year.
struct StartView: View {
    /// Starts the match with the given first server.
    let onStart: (Side) -> Void

    var body: some View {
        // The whole page ignores the safe area, and the geometry is read for
        // what it ignored: the clock stands in the top inset and the sentence
        // on their half has to start below it.
        GeometryReader { screen in
            court(below: screen.safeAreaInsets.top)
                // The light is over the whole court rather than over a half,
                // which is what makes this board different from the score
                // screen's: there the near half is lit and the far one is not,
                // here one floodlight in the top left crosses the net and both
                // halves. Drawn above the net, as the board draws it, and
                // below the ball.
                .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
                .overlay { ball }
                // Inside the reader rather than around it: the reader is laid
                // out in the safe rect and so can say what it is, and the
                // court is what runs past it to the glass.
                .ignoresSafeArea()
        }
    }

    // MARK: The court

    /// Their half, the net, ours — the same three pieces in the same order as
    /// on the score screen, and for the same reason: the halves meet on the
    /// tape and no seam of `night` opens down the middle.
    ///
    /// Built out of ``PadelDesign/CourtHalf`` and ``PadelDesign/NetLine``
    /// rather than out of ``PadelDesign/Court``, because each half here is a
    /// button and `Court` takes no content.
    ///
    /// - Parameter clock: how much of the top of the screen the system's own
    ///   clock stands in. Their sentence starts below it; ours is nowhere near
    ///   it and is given nothing to clear.
    private func court(below clock: CGFloat) -> some View {
        VStack(spacing: 0) {
            half(.them, clearing: clock)

            NetLine().zIndex(1)

            half(.us, clearing: 0)
        }
    }

    /// One half of the court, as the thing you tap to start the match.
    ///
    /// The opponents on top, us at the bottom — the same as on the score
    /// screen and the same as on court: they are across the net, in front of
    /// us. The colors are the same too, so the half the player will be tapping
    /// for their own points all match is recognizable before the first rally.
    /// **A tap gesture and not a `Button`**, for the reason `ScoreView` gives
    /// for the same choice: this page lives inside a `TabView` whose next page
    /// is a swipe down the court, and a half that is a button is a half that
    /// starts a match out of the swipe on its way past. The score screen has
    /// been two tap zones inside that same paging since ticket 04 without
    /// scoring a point by accident.
    ///
    /// Everything a button gave VoiceOver is put back by hand below.
    private func half(_ side: Side, clearing obstruction: CGFloat) -> some View {
        CourtHalf(side: side)
            .overlay { sentence(for: side, clearing: obstruction) }
            // Otherwise the tap catches the painted surface but not the
            // texture and the lines over it.
            .contentShape(Rectangle())
            .onTapGesture { onStart(side) }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(Self.serves(side)))
    }

    /// Whose serve it is, near the top of its own half rather than in the
    /// middle of it.
    ///
    /// The ball is centred on the net, so a sentence centred in its half would
    /// sit against it. The board drops each sentence about a fifth into its
    /// half, which reads as two different things and is why the two fractions
    /// are not one: their half's top is the top of the screen, so theirs lands
    /// under the clock, while ours counts from the net and lands just clear of
    /// the ball.
    private func sentence(for side: Side, clearing obstruction: CGFloat) -> some View {
        GeometryReader { proxy in
            let drop = max(obstruction, proxy.size.height * Board.sentenceDrop(side))

            Text(Self.serves(side))
                .textStyle(.display)
                .multilineTextAlignment(.center)
                // Two lines are expected rather than tolerated — see
                // `serves(_:)`. The scale factor and the room below it are for
                // the far end of the Dynamic Type range, where the sentence
                // shrinks into its own half rather than growing across the
                // net.
                .lineLimit(2)
                .minimumScaleFactor(Board.sentenceMinimumScale)
                .foregroundStyle(.courtInk(side))
                .padding(.horizontal, Board.sentenceInset)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: max(0, proxy.size.height - drop),
                    alignment: .top)
                .padding(.top, drop)
        }
        // The sentence is what the button says; it must not be a second thing
        // to hit inside it.
        .allowsHitTesting(false)
    }

    /// Whose serve it is, as a whole sentence per side rather than a side's
    /// name dropped into a frame: English puts the side before the verb and
    /// Russian after it, and there is no frame that survives the move.
    ///
    /// The board draws "Them" over "to serve", which is a two-line English
    /// arrangement and not a sentence in two parts — translated piecewise it
    /// reads "Они / подавать", which is not Russian. So the board's two lines
    /// are one sentence here, free to wrap to two of its own.
    private static func serves(_ side: Side) -> LocalizedStringKey {
        side == .us ? "We serve" : "Opponents serve"
    }

    /// The ball, waiting on the net.
    ///
    /// Centred in the court, which is the middle of the tape: the two halves
    /// are equal and the net is between them, so the court's centre is the
    /// net's. It means what it means everywhere else in the app — *this is
    /// yours, or this is chosen* (ADR-0006) — and before a match nothing is
    /// either, which is exactly why it is sitting still in the middle.
    private var ball: some View {
        Ball(size: Board.ball)
            .allowsHitTesting(false)
    }
}

/// What `Main.dc.html` draws that no token covers, with the board's pixels
/// halved — the watch artboards are 2x (the spec's "Reading the boards").
///
/// The court itself comes out of `PadelDesign` and is not here. What is left
/// is the two things this board is the only board to draw: a ball resting on
/// the net, and a sentence high in each half.
private enum Board {
    /// The ball waiting on the net. 40px.
    static let ball: CGFloat = 20

    /// How far down its own half a side's sentence starts, as a fraction of
    /// the half.
    ///
    /// **Two numbers and not one drawn twice.** The board's 21% and 16% look
    /// five hundredths apart and are measuring from opposite ends of the
    /// court: a half's top is the top of the screen for them and the net for
    /// us, so theirs puts a sentence near the outer edge and ours puts one
    /// just under the ball — 8pt under it, on the board.
    static func sentenceDrop(_ side: Side) -> CGFloat {
        switch side {
        case .them: 0.21
        case .us: 0.16
        }
    }

    /// Left and right of a sentence, so that the longer of the two languages
    /// clears the outline painted round the half instead of running into it.
    static let sentenceInset: CGFloat = 10

    /// How far a sentence may shrink to stay inside its half.
    ///
    /// Not a number off the board — the board is drawn at one Dynamic Type
    /// setting out of twelve and never meets this.
    static let sentenceMinimumScale: CGFloat = 0.6

    /// How much light the corner spends.
    ///
    /// The board's 0.17, which is the top of the range `Floodlight` documents:
    /// this is the one board whose light has a whole court to cross rather
    /// than a half.
    static let floodlight: Double = 0.17
}

#if DEBUG

/// Both languages, because the sentences are the page: "Opponents serve" is
/// one line in English and "Подают соперники" is two on a small watch, and
/// which of them wraps is the only thing this page can get wrong.
private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

/// The largest of the twelve Dynamic Type settings, which is where both
/// sentences find their second line.
private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private let court = StartView(onStart: { _ in })

#Preview("The court") { court }

#Preview("In Russian") { inRussian(court) }

#Preview("At the largest type") { atLargestType(court) }

#Preview("In Russian, at the largest type") { atLargestType(inRussian(court)) }

#endif
