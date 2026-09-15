import PadelScoring
import SwiftUI

/// A match in the history, cut from the court rather than ruled as a table row.
/// The ground is the control's whole argument: the season can be read by color
/// before a single number is.
public struct CourtTile<Content: View>: View {
    private let outcome: MatchOutcome
    private let action: (() -> Void)?
    private let content: Content

    /// - Parameter action: What tapping the tile does, if anything. Given one,
    ///   the tile is a real `Button`; given none it is a surface, which is what
    ///   it is inside a `NavigationLink` that is already the button.
    public init(
        outcome: MatchOutcome,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.outcome = outcome
        self.action = action
        self.content = content()
    }

    public var body: some View {
        if let action {
            Button(action: action) { surface }
                .buttonStyle(.plain)
        } else {
            surface
        }
    }

    private var surface: some View {
        content
            .padding(.horizontal, ControlMetrics.tilePadding)
            .padding(.vertical, ControlMetrics.tilePaddingVertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ground)
            .clipShape(RoundedRectangle(cornerRadius: .tile))
            .contentShape(RoundedRectangle(cornerRadius: .tile))
            .overlay {
                if isLost {
                    // The one ground that is the same color as the list under
                    // it, so this hairline is the whole of what makes it a
                    // tile. `strokeBorder` and not `stroke`, which straddles
                    // the edge and would lose its outer half to the clip.
                    RoundedRectangle(cornerRadius: .tile)
                        .strokeBorder(.ink.weight(.hairline))
                }
            }
    }

    private var ground: some View {
        ZStack {
            Rectangle().fill(tint)

            if isLifted {
                Rectangle().fill(.ink.weight(.surfaceQuiet))
            }

            Weave(stripe: CourtMetrics.weave)
                .fill(Color.courtWeave())
                .clipped()

            if isWon { glow }
        }
    }

    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: .ballGlow,
                    center: .center,
                    startRadius: 0,
                    endRadius: ControlMetrics.tileGlow / 2))
            .frame(width: ControlMetrics.tileGlow, height: ControlMetrics.tileGlow)
            .offset(x: ControlMetrics.tileGlowOffset, y: -ControlMetrics.tileGlowOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var tint: Color {
        switch outcome {
        case .finished(winner: .us): .court
        case .finished(winner: .them), .abandoned: .night
        case .inProgress: .courtLit
        }
    }

    private var isWon: Bool { outcome == .finished(winner: .us) }

    private var isLost: Bool { outcome == .finished(winner: .them) }

    private var isLifted: Bool { outcome == .abandoned }
}
