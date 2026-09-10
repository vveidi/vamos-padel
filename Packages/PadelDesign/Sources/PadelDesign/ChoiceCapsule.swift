import SwiftUI

/// One option of a choice, drawn: a rounded capsule that says what it is and
/// whether it is the one chosen.
///
/// **The two platforms choose differently and look the same doing it.** The
/// phone puts two of these side by side (``SegmentedChoice``); the watch puts
/// as many as there are down a page it pushes (``ChoiceRow``). What must not
/// differ between them is what "chosen" looks like — `ballWash` behind a
/// `ball` label inside a `ball` ring — because it is the same act on the same
/// app, and a player who learns it on one wrist should not have to learn it
/// again in their hand.
///
/// It draws no interaction of its own. Whoever puts it on screen wraps it in a
/// real `Button`, so the trait and the tap arrive from the platform rather
/// than from here.
struct ChoiceCapsule: View {
    let label: Text
    let isChosen: Bool

    var body: some View {
        label
            .textStyle(.control)
            // The unselected side is a shade lighter as well as dimmer: it is
            // a choice not taken, and the two have to be told apart at a
            // glance from across a court.
            .fontWeight(isChosen ? .semibold : .medium)
            .foregroundStyle(isChosen ? Color.ball : .ink.weight(.strong))
            .multilineTextAlignment(.center)
            .padding(.horizontal, ControlMetrics.segmentPadding)
            .padding(.vertical, ControlMetrics.rowPaddingVertical)
            .frame(maxWidth: .infinity, minHeight: ControlMetrics.segmentHeight)
            .background(background)
            .contentShape(RoundedRectangle(cornerRadius: .segment))
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: .segment)
            .fill(isChosen ? Color.ballWash : .ink.weight(.surface))
            .overlay {
                // Inset rather than drawn around the outside, so that ringing
                // a capsule does not move it or its neighbour.
                if isChosen {
                    RoundedRectangle(cornerRadius: .segment)
                        .strokeBorder(.ball, lineWidth: ControlMetrics.segmentRing)
                }
            }
    }
}
