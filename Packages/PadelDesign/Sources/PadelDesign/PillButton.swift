import SwiftUI

/// The button at the foot of a screen: `ball`-yellow when it is the thing to
/// do, quiet when it is the thing available.
///
/// Rounded and not a capsule — the boards give it a radius well short of half
/// its height, and at 64pt tall a capsule would read as a lozenge. The radius
/// is ``CoreGraphics/CGFloat/button``.
///
/// **Its height is a floor and not a measurement.** The boards draw one
/// setting out of twelve; at the largest the label wraps and the pill grows
/// under it, because a button that clipped its own verb would be a button
/// nobody could read before pressing.
///
/// ```swift
/// PillButton(Text("New match"), carriesBall: true) { start() }
/// PillButton(Text("End"), variant: .quiet) { end() }
/// ```
public struct PillButton: View {
    /// Which of the two the boards draw.
    public enum Variant: Sendable, CaseIterable {
        /// `ball` yellow, and the one thing this screen is for. There is at
        /// most one on a screen — a second would be a screen that has not
        /// decided.
        case primary

        /// Translucent ink with a hairline round it. What "End" and "Keep
        /// playing" are drawn as.
        case quiet
    }

    private let label: Text
    private let variant: Variant
    private let carriesBall: Bool
    private let action: () -> Void

    /// - Parameter carriesBall: Whether the ball rides beside the label, as it
    ///   does on "New match". Which way round the ball is drawn follows the
    ///   variant and is not a second decision: on the yellow primary it is the
    ///   cut-out — dark felt, bright seams — because the court's own ball
    ///   there would be yellow on yellow, and on the quiet one it is the ball
    ///   off the court.
    public init(
        _ label: Text,
        variant: Variant = .primary,
        carriesBall: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.variant = variant
        self.carriesBall = carriesBall
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: ControlMetrics.pillGap) {
                if carriesBall {
                    Ball(size: ControlMetrics.pillBall, finish: variant.finish)
                }

                label
                    .textStyle(.control)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(variant.ink)
            .padding(.horizontal, ControlMetrics.pillPadding)
            .padding(.vertical, ControlMetrics.pillPaddingVertical)
            .frame(maxWidth: .infinity, minHeight: ControlMetrics.pillHeight)
            .background(background)
            .contentShape(RoundedRectangle(cornerRadius: .button))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var background: some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: .button).fill(.ball)

        case .quiet:
            RoundedRectangle(cornerRadius: .button)
                .fill(.ink.weight(.surface))
                .overlay {
                    RoundedRectangle(cornerRadius: .button)
                        .strokeBorder(.ink.weight(.hairline))
                }
        }
    }
}

extension PillButton.Variant {
    /// The label, and the ball's seams with it.
    var ink: Color {
        switch self {
        case .primary: .onBall
        case .quiet: .ink
        }
    }

    /// Which way round a ball on this button is drawn.
    var finish: Ball.Finish {
        switch self {
        case .primary: .cutOut
        case .quiet: .onCourt
        }
    }
}
