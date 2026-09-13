import PadelDesign
import PadelScoring
import SwiftUI
import WatchKit

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
/// this page. Each carries its sentence in a capsule, which is what says the
/// half is a button; the ball waits on the net between the two. Everything
/// that is not the one question — the rules, and whether the match goes to
/// Health — is a scroll down, on ``StartPages``' second page: a setting asked
/// before every match is a tax paid for something that happens twice a year.
struct StartView: View {
    /// Starts the match with the given first server.
    let onStart: (Side) -> Void

    /// Which way the ball is leaning — see ``lean``.
    @State private var leaning = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        court
            // Above the net, as the board draws it, and below the ball.
            .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
            .overlay { ball }
            .ignoresSafeArea()
    }

    // MARK: The court

    /// Their half, the net, ours — the same three pieces in the same order as
    /// on the score screen, and for the same reason: the halves meet on the
    /// tape and no seam of `night` opens down the middle.
    ///
    /// Built out of ``PadelDesign/CourtHalf`` and ``PadelDesign/NetLine``
    /// rather than out of ``PadelDesign/Court``, because each half here is a
    /// button and `Court` takes no content.
    private var court: some View {
        VStack(spacing: 0) {
            half(.them)

            NetLine().zIndex(1)

            half(.us)
        }
    }

    /// One half of the court, as the thing you tap to start the match.
    ///
    /// The opponents on top, us at the bottom — the same as on the score
    /// screen and the same as on court: they are across the net, in front of
    /// us. The colors are the same too, so the half the player will be tapping
    /// for their own points all match is recognizable before the first rally.
    /// **The capsule is the button and the court around it is inert.** A
    /// control has to light because it was touched, or the light means
    /// nothing.
    ///
    /// **A `Button` and not a gesture**, which the page below depends on: a
    /// `DragGesture` tracking the finger takes the `TabView`'s swipe with it,
    /// attached plainly and simultaneously alike, where a button's press is
    /// cancelled by the scroll instead of competing with it. It also gives
    /// VoiceOver its button back — no traits are put on by hand here.
    ///
    /// The two paddings sit outside the button: inside the style they would
    /// grow what the finger can hit.
    private func half(_ side: Side) -> some View {
        CourtHalf(side: side)
            .overlay(alignment: side == .them ? .bottom : .top) {
                Button {
                    start(side)
                } label: {
                    Text(Self.serves(side))
                }
                .buttonStyle(ServeCapsule(side: side))
                .padding(.horizontal, Board.capsuleInset)
                .padding(side == .them ? .bottom : .top, Board.netGap)
            }
    }

    /// Names the serving side and starts the match, with the app's one haptic
    /// under it: a match starting is worth one, a rally scored is not.
    ///
    /// `WKInterfaceDevice` and not SwiftUI's `.sensoryFeedback`: that watches
    /// a value, and the value would change in the same update that replaces
    /// this screen with the match — a view being torn down never plays its
    /// feedback.
    private func start(_ side: Side) {
        WKInterfaceDevice.current().play(.start)

        onStart(side)
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

    // MARK: The ball

    /// The ball on the net, leaning toward one half and then the other.
    ///
    /// Centred in the court, which is the middle of the tape: the two halves
    /// are equal and the net is between them. It means what it means
    /// everywhere else in the app — *this is yours, or this is chosen*
    /// (ADR-0006) — and before a match nothing is either, hence the lean
    /// rather than a resting place in one half.
    ///
    /// It does not travel anywhere on the tap: the match screen is up by then.
    ///
    /// **It is never in the hit test**: a ball that swallowed a press would be
    /// a ball that decided who serves.
    private var ball: some View {
        Ball(size: Board.ball)
            .offset(y: lean)
            .animation(
                .easeInOut(duration: Board.leanPeriod).repeatForever(autoreverses: true),
                value: lean)
            .allowsHitTesting(false)
            .onAppear { leaning = true }
    }

    /// How far the ball is leaning, and which way. Toggled once, reversed
    /// forever by the animation above; Reduce Motion pins it to the tape.
    private var lean: CGFloat {
        guard !reduceMotion else { return 0 }

        return leaning ? Board.lean : -Board.lean
    }
}

/// The sentence in the capsule that says the half can be tapped.
///
/// Both capsules stand the same distance from the net, so they read as a pair
/// and the ball has the gap between them to itself. They are anchored to the
/// net and grow away from it, which keeps that gap fixed as the type grows.
///
/// Pressed, the capsule is what ``PadelDesign/ChoiceCapsule`` draws for a
/// chosen option — `ballWash` behind a `ball` label inside a `ball` ring.
/// Choosing a half is what this button does, and the ball's yellow means
/// exactly that (ADR-0006).
private struct ServeCapsule: ButtonStyle {
    let side: Side

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.display)
            .multilineTextAlignment(.center)
            // Two lines are expected rather than tolerated — see `serves(_:)`.
            .lineLimit(2)
            .minimumScaleFactor(Board.sentenceMinimumScale)
            // Left to itself, their capsule grows into the clock. The ceiling
            // is where two lines of the longer language still stop short of
            // it, measured on a 42mm — the least room of the sizes.
            .dynamicTypeSize(...Board.largestType)
            .padding(.horizontal, Board.capsulePadding)
            .padding(.vertical, Board.capsulePaddingVertical)
            // The one capsule in the app that is not a `ChoiceCapsule` — the
            // sentences here are `display` and hug their own width — so it
            // borrows the look rather than redrawing it. The ring at rest is
            // what says the half can be tapped; it takes the hit test with it,
            // and the corners stay court.
            .choiceCapsule(
                isChosen: configuration.isPressed,
                restingInk: .courtInk(side),
                isRingedAtRest: true)
            .animation(.easeOut(duration: Board.press), value: configuration.isPressed)
    }
}

/// What the start board drew that no token covers, with its pixels halved —
/// the watch artboards were 2x (`docs/design/README.md`, "Reading the
/// boards"). The board was deleted when this screen shipped.
///
/// The court itself comes out of `PadelDesign` and is not here. What is left
/// is the ball resting on the net, the capsule each half carries, and the
/// timings — which no board drew, a canvas holding one frame.
private enum Board {
    /// The ball waiting on the net. 40px.
    static let ball: CGFloat = 20

    /// How far a sentence may shrink to stay inside its capsule.
    ///
    /// Not a number off the board — the board is drawn at one Dynamic Type
    /// setting out of twelve and never meets this.
    static let sentenceMinimumScale: CGFloat = 0.6

    /// Between the net and the capsule nearest it, each side. It clears the
    /// ball at rest — half the ball plus its lean — and is the same number on
    /// both halves, which is what makes the pair read as centred on the net.
    static let netGap: CGFloat = 16

    /// Left and right of a sentence inside its capsule.
    static let capsulePadding: CGFloat = 10

    /// Above and below it.
    static let capsulePaddingVertical: CGFloat = 5

    /// Left and right of the capsule itself. Wide enough to clear the page
    /// indicator at the trailing edge.
    static let capsuleInset: CGFloat = 14

    /// The largest type the sentences are set at — see ``ServeCapsule`` for
    /// why there is a ceiling at all.
    static let largestType: DynamicTypeSize = .accessibility2

    /// How long the capsule takes to light under a finger and to go out.
    static let press: TimeInterval = 0.12

    /// How far the ball tips toward a half while neither has been chosen. Any
    /// further and it stops reading as resting on the net.
    static let lean: CGFloat = 4

    /// How long one lean takes. Slow: the screen breathing, not the ball
    /// bouncing.
    static let leanPeriod: TimeInterval = 1.6

    /// How much light the corner spends. The board's 0.17, the top of the
    /// range `Floodlight` documents: this is the one board whose light has a
    /// whole court to cross rather than a half.
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

// Reduce Motion has no preview: `accessibilityReduceMotion` is read-only in
// the environment. It is checked on a simulator with the setting on.

private let court = StartView(onStart: { _ in })

#Preview("The court") { court }

#Preview("In Russian") { inRussian(court) }

#Preview("At the largest type") { atLargestType(court) }

#Preview("In Russian, at the largest type") { atLargestType(inRussian(court)) }

#endif
