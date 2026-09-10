import PadelScoring
import SwiftUI

/// A match in the history, cut from the court rather than ruled as a table
/// row.
///
/// **The tint is the control's whole argument: you can read the season by
/// color before reading a single number.** Won is the turf we play on, lost
/// is the cold glass across the net, and a match stopped early is neither —
/// it is the ground the court stands on, lifted just enough to be a card and
/// holding a trace of the floodlight.
///
/// It takes ``PadelScoring/MatchOutcome`` and not a `TileStyle` of its own.
/// The domain already draws this distinction, has already argued it — "an
/// abandoned match is not a win, not a loss, and not a game still going" — and
/// a second three-way enum here would be that argument written twice, in the
/// package that is meant to know less (ADR-0006, and ticket 01's `Side`).
///
/// A match still in progress is drawn as an abandoned one. It has no result
/// either, which is exactly what that tint says; the two are told apart by the
/// words the caller puts on the tile, not by the ground under them.
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
    }

    private var ground: some View {
        ZStack {
            Rectangle().fill(tint)

            if isLifted {
                // Two layers and not a lighter hex: `night` is the app's
                // ground, and a match stopped early is that ground raised into
                // a card and lit from the same corner as everything else.
                Rectangle().fill(.ink.weight(.surfaceQuiet))
                Floodlight(corner: .topTrailing, strength: 0.1)
            }

            // The same texture as the surface it is cut from — the court's
            // own, at the court's own weight.
            Weave(stripe: CourtMetrics.weave)
                .fill(Color.courtWeave(on: weaveSide))
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
        case .finished(winner: .us): .ourHalf
        case .finished(winner: .them): .theirHalf
        case .abandoned, .inProgress: .night
        }
    }

    /// Which half's weave lies over the tint.
    ///
    /// The two weaves are four thousandths of white apart, and the tile that
    /// has no half takes the fainter: `night` is darker than either surface,
    /// and the texture over it has the furthest to go before it stops reading
    /// as a surface and starts reading as stripes.
    private var weaveSide: Side {
        switch outcome {
        case .finished(let winner): winner
        case .abandoned, .inProgress: .them
        }
    }

    private var isWon: Bool { outcome == .finished(winner: .us) }

    private var isLifted: Bool { outcome.winner == nil }
}
