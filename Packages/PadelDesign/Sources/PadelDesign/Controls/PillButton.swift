import SwiftUI

/// The button at the foot of a screen: `ball`-yellow when it is the thing to
/// do, quiet when it is the thing available.
public struct PillButton: View {
    public enum Variant: Sendable, CaseIterable {
        /// At most one on a screen — a second would be a screen that has not
        /// decided.
        case primary

        case quiet
    }

    private let label: Text
    private let variant: Variant
    private let carriesBall: Bool
    private let action: () -> Void

    /// - Parameter carriesBall: Whether the ball rides beside the label. Which
    ///   way round it is drawn follows the variant and is not a second
    ///   decision.
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
    var ink: Color {
        switch self {
        case .primary: .onBall
        case .quiet: .ink
        }
    }

    var finish: Ball.Finish {
        switch self {
        case .primary: .cutOut
        case .quiet: .onCourt
        }
    }
}
