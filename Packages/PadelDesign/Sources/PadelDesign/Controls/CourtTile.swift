import PadelScoring
import SwiftUI

/// A match in the history, cut from the court rather than ruled as a table
/// row.
///
/// **The ground is the control's whole argument: you can read the season by
/// color before reading a single number.** There are four of them and they
/// spend one hue between them. A win is the court, with the ball's light
/// spilling into a corner. A loss is `night` with a hairline around it and
/// nothing else — the quietest thing on the list, which is what a loss should
/// be, and the price is that a month of losses is a very quiet screen. A match
/// stopped early is that same `night` lifted into a card and left unlit: no
/// result, and no light on it either. A match still running is `courtLit` —
/// *this court is live*, the same statement a rally landing makes.
///
/// It takes ``PadelScoring/MatchOutcome`` and not a `TileStyle` of its own.
/// The domain already draws this distinction, has already argued it — "an
/// abandoned match is not a win, not a loss, and not a game still going" — and
/// a second four-way enum here would be that argument written twice, in the
/// package that is meant to know less (ADR-0006).
///
/// The content is handed in. `MatchCard` keeps the course of the score and
/// this gives it something to draw it on — the seam the spec names.
///
/// ```swift
/// CourtTile(outcome: match.state.outcome, action: { open(match) }) {
///     MatchRow(match: match)
/// }
/// ```
public struct CourtTile<Content: View>: View {
    private let outcome: MatchOutcome
    private let action: (() -> Void)?
    private let content: Content

    /// - Parameter action: What tapping the tile does, if anything. Given one,
    ///   the tile is a real `Button` and VoiceOver is told so without being
    ///   told; given none it is a surface, which is what it is inside a
    ///   `NavigationLink` that is already the button.
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
                    // the edge and would lose its outer half to the clip —
                    // the same border `PillButton` draws.
                    RoundedRectangle(cornerRadius: .tile)
                        .strokeBorder(.ink.weight(.hairline))
                }
            }
    }

    private var ground: some View {
        ZStack {
            Rectangle().fill(tint)

            if isLifted {
                // A layer and not a lighter hex: `night` is the app's ground,
                // and a match stopped early is that ground raised into a card.
                // No floodlight over it — a match with no result gets no light
                // on it either, which is what separates it from the one still
                // being played.
                Rectangle().fill(.ink.weight(.surfaceQuiet))
            }

            // The same texture as the surface it is cut from — the court's
            // own, at the court's own weight.
            Weave(stripe: CourtMetrics.weave)
                .fill(Color.courtWeave())
                .clipped()

            if isWon { glow }
        }
    }

    /// The `ball` glow a won match carries, hung off the top trailing corner
    /// so that only its inner quarter falls on the tile — which is what makes
    /// it light spilling in rather than a dot stuck on.
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
