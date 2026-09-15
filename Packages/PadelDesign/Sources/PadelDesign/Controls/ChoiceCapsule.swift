import SwiftUI

/// One option of a choice, drawn. It carries no interaction of its own — the
/// caller wraps it in a real `Button`, so the trait and the tap arrive from
/// the platform.
struct ChoiceCapsule: View {
    enum Place {
        case besideItsTwin

        case downThePage

        /// A capsule on the page is as tall as the row that opened it, so that
        /// tapping a row does not swap a column of one size for another.
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
            .fontWeight(isChosen ? .semibold : .medium)
            .multilineTextAlignment(.center)
            .padding(.horizontal, ControlMetrics.segmentPadding)
            .padding(.vertical, ControlMetrics.rowPaddingVertical)
            .frame(maxWidth: .infinity, minHeight: place.minHeight)
            .choiceCapsule(isChosen: isChosen)
    }
}

// MARK: - The look, apart from the control

extension View {
    /// Draws this label as one option of a choice. Size and padding stay with
    /// the caller; the fill, the ring, the radius and the ink come from here.
    /// `isRingedAtRest` is false among its own kind, true on the court.
    public func choiceCapsule(
        isChosen: Bool,
        restingInk: Color = Color.ink.weight(.strong),
        isRingedAtRest: Bool = false
    ) -> some View {
        foregroundStyle(isChosen ? Color.ball : restingInk)
            .background {
                RoundedRectangle(cornerRadius: .segment)
                    .fill(isChosen ? Color.ballWash : .ink.weight(.surface))
                    .overlay {
                        // Inset rather than drawn around the outside, so that
                        // ringing a capsule does not move it or its neighbour.
                        if isChosen || isRingedAtRest {
                            RoundedRectangle(cornerRadius: .segment)
                                .strokeBorder(
                                    // `strong` and not the `hairline` a border
                                    // would take: 0.12 of the ink disappears
                                    // on a lit court.
                                    isChosen ? Color.ball : .ink.weight(.strong),
                                    lineWidth: ControlMetrics.segmentRing)
                        }
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: .segment))
    }
}
