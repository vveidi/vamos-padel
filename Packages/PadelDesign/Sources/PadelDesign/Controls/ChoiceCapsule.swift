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
    /// Where the capsule is standing, which is the only thing that differs
    /// between the two — and it differs in one number, its height.
    enum Place {
        /// Beside its twin, in the phone's ``SegmentedChoice``.
        case besideItsTwin

        /// Down the page the watch's ``ChoiceRow`` opens.
        case downThePage

        /// The least the capsule stands.
        ///
        /// A capsule on the page is as tall as the row that opened it —
        /// ``ControlMetrics/stackedRowHeight``, two texts — so that tapping a
        /// row does not swap a column of one size for a column of another.
        /// It holds one text and keeps the height anyway, the way the golden
        /// point does among the rows.
        var minHeight: CGFloat {
            switch self {
            case .besideItsTwin: ControlMetrics.segmentHeight
            case .downThePage: ControlMetrics.stackedRowHeight
            }
        }
    }

    let label: Text
    let isChosen: Bool
    let place: Place

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
            .frame(maxWidth: .infinity, minHeight: place.minHeight)
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
