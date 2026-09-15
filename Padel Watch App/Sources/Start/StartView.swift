import PadelDesign
import PadelScoring
import SwiftUI
import WatchKit

struct StartView: View {
    let onStart: (Side) -> Void

    @State private var leaning = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        court
            .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
            .overlay { ball }
            .ignoresSafeArea()
    }

    // MARK: The court

    /// Assembled from ``PadelDesign/CourtHalf`` and ``PadelDesign/NetLine``
    /// rather than ``PadelDesign/Court``: each half here carries a button and
    /// `Court` takes no content.
    private var court: some View {
        VStack(spacing: 0) {
            half(.them)

            NetLine().zIndex(1)

            half(.us)
        }
    }

    /// A `Button` and not a gesture: a `DragGesture` tracking the finger takes
    /// ``StartPages``' swipe with it, where a press is merely cancelled by the
    /// scroll. The two paddings sit outside the button — inside the style they
    /// would grow what the finger can hit.
    private func half(_ side: Side) -> some View {
        CourtHalf()
            .overlay(alignment: side == .them ? .bottom : .top) {
                Button {
                    start(side)
                } label: {
                    Text(Self.serves(side))
                }
                .buttonStyle(ServeCapsule())
                .padding(.horizontal, Board.capsuleInset)
                .padding(side == .them ? .bottom : .top, Board.netGap)
            }
    }

    /// `WKInterfaceDevice` and not `.sensoryFeedback`: that watches a value,
    /// and the value changes in the same update that replaces this screen with
    /// the match — a view being torn down never plays its feedback.
    private func start(_ side: Side) {
        WKInterfaceDevice.current().play(.start)

        onStart(side)
    }

    /// A whole sentence per side, not a name dropped into a frame: English
    /// puts the side before the verb and Russian after it. The board's two
    /// lines are one sentence here, free to wrap to two of its own.
    private static func serves(_ side: Side) -> LocalizedStringKey {
        side == .us ? "We serve" : "Opponents serve"
    }

    // MARK: The ball

    /// Never in the hit test: it sits over both capsules, and a ball that
    /// swallowed a press would be a ball deciding who serves.
    private var ball: some View {
        Ball(size: Board.ball)
            .offset(y: lean)
            .animation(
                .easeInOut(duration: Board.leanPeriod).repeatForever(autoreverses: true),
                value: lean)
            .allowsHitTesting(false)
            .onAppear { leaning = true }
    }

    private var lean: CGFloat {
        guard !reduceMotion else { return 0 }

        return leaning ? Board.lean : -Board.lean
    }
}

private struct ServeCapsule: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.display)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(Board.sentenceMinimumScale)
            // Left to itself, their capsule grows into the clock. The ceiling
            // is where two lines of the longer language still stop short of
            // it, measured on a 42mm — the least room of the sizes.
            .dynamicTypeSize(...Board.largestType)
            .padding(.horizontal, Board.capsulePadding)
            .padding(.vertical, Board.capsulePaddingVertical)
            // The ring at rest is what says the half can be tapped, and it
            // carries the hit test with it.
            .choiceCapsule(
                isChosen: configuration.isPressed,
                restingInk: .courtInk,
                isRingedAtRest: true)
            .animation(.easeOut(duration: Board.press), value: configuration.isPressed)
    }
}

/// The start board's pixels halved — the watch artboards were 2x
/// (`docs/design/README.md`, "Reading the boards"). The timings are nobody's
/// board: a canvas holds one frame.
private enum Board {
    /// 40px.
    static let ball: CGFloat = 20

    /// Not a number off the board, which is drawn at one Dynamic Type setting
    /// out of twelve.
    static let sentenceMinimumScale: CGFloat = 0.6

    /// Clears the ball at rest: half the ball plus its lean.
    static let netGap: CGFloat = 16

    static let capsulePadding: CGFloat = 10

    static let capsulePaddingVertical: CGFloat = 5

    /// Wide enough to clear the page indicator at the trailing edge.
    static let capsuleInset: CGFloat = 14

    static let largestType: DynamicTypeSize = .accessibility2

    static let press: TimeInterval = 0.12

    static let lean: CGFloat = 4

    static let leanPeriod: TimeInterval = 1.6

    /// The board's 0.17, the top of the range ``Floodlight`` documents: the
    /// one board whose light crosses a whole court rather than a half.
    static let floodlight: Double = 0.17
}

#if DEBUG

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

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
