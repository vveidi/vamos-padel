import PadelScoring
import SwiftUI

/// The lines painted on a padel court, in the order they are read.
///
/// Three lines and no more: the boards draw the service line, the center line
/// that runs from it to the net, and the outline around the half. The net is
/// not one of them — it is a shape with posts, not a line on the ground.
public enum CourtLine: Sendable, CaseIterable {
    /// The line the service box is measured to, at 30% of the half.
    case service

    /// The line between the two service boxes, running from the service line
    /// to the net.
    case center

    /// The edge of the half — three sides of it, since the net is the fourth.
    case outline
}

/// How far each part of the court falls when the screen's luminance is
/// reduced.
///
/// A surface is opaque and goes darker, mixed toward ``SwiftUI/Color/night``;
/// paint on a surface already carries a weight and goes thinner instead.
/// Mixing paint would move its alpha along with its hue and leave both wrong.
/// ADR-0006's consequences say why there is a dimmed court at all.
enum CourtDimming {
    /// How far the two half tints fall toward `night`.
    ///
    /// Settled by eye at watch size: at 0.72 the two halves measured 0.021
    /// apart in luminance and read as one black rectangle.
    static let surface = 0.55

    /// How far the ball's felt falls toward `night`.
    ///
    /// Much less than the court, because the ball has to still read as yellow
    /// once the court around it has gone dark.
    static let felt = 0.15

    /// What is left of a painted line's weight, and of the net's.
    ///
    /// Halved rather than dropped: a line's contrast against its surface rises
    /// as the surface falls, which is what pays for thinning it.
    static let paint = 0.5
}

/// The colors that belong to the court itself.
///
/// They live here rather than in the court primitive (ticket 02) for the same
/// reason every other token does: a color defined where it is first drawn is a
/// color that gets redrawn slightly differently the second time. Ticket 02
/// owns the geometry; this file owns what the geometry is painted in.
///
/// They take a ``PadelScoring/Side`` because the two halves are not one
/// surface tinted twice — they are cool glass and warm turf, and their lines,
/// their ink and their weave all differ. Taking the domain's `Side` rather
/// than inventing a local `CourtSide` is ADR-0006's decision: `CONTEXT.md`
/// has already named this thing and already listed what not to call it. The
/// one that takes a ``PadelScoring/MatchOutcome`` instead is the tile's, and
/// answers the same way ``CourtTile`` picks its tint.
extension Color {
    /// The surface of a half: glass blue for theirs, turf green for ours.
    ///
    /// - Parameter dimmed: Whether the screen's luminance is reduced, in which
    ///   case the tint falls most of the way to `night` — see ``CourtDimming``.
    public static func courtSurface(_ side: Side, dimmed: Bool = false) -> Color {
        let surface: Color =
            switch side {
            case .them: .theirHalf
            case .us: .ourHalf
            }

        return dimmed ? surface.towardNight(CourtDimming.surface) : surface
    }

    /// The ink for text sitting *inside* a half, where the ground is no longer
    /// `night` and the ink on `night` would read gray.
    public static func courtInk(_ side: Side) -> Color {
        switch side {
        case .them: .inkTheirHalf
        case .us: .inkOurHalf
        }
    }

    /// The ink for text standing on a tile tinted by a match's outcome.
    ///
    /// ``CourtTile`` takes the same ``PadelScoring/MatchOutcome`` to choose the
    /// tint, and this is the other half of that answer: a won tile is turf and
    /// a lost one is glass, so the ink on it is that half's. A match that
    /// finished on neither half stands on `night`, where the ink is the weight
    /// this app sets a title in.
    ///
    /// Here rather than at a call site because two screens read a match off a
    /// tile — the history's row and the match card — and an answer written in
    /// both is an answer that drifts in one.
    public static func courtInk(_ outcome: MatchOutcome) -> Color {
        guard let winner = outcome.winner else { return .ink.weight(.control) }

        return courtInk(winner)
    }

    /// A painted line on a half.
    ///
    /// Ours is the brighter pair — the boards light the near half more, and
    /// the difference is small on purpose: two clearly different whites would
    /// read as two courts rather than as one seen from our end.
    /// - Parameter dimmed: Whether the screen's luminance is reduced, in which
    ///   case the paint goes thinner but never away — the lines are the
    ///   geometry, and the geometry is what survives the dimming.
    public static func courtLine(
        _ line: CourtLine, on side: Side, dimmed: Bool = false
    ) -> Color {
        let paint: Color =
            switch side {
            case .them: .lineTheirHalf
            case .us: .lineOurHalf
            }

        let weight = lineOpacity(line, on: side)

        return paint.opacity(dimmed ? weight * CourtDimming.paint : weight)
    }

    /// The court's weave — the faint diagonal texture over the surface.
    ///
    /// It is texture and not pattern: at a glance it must read as a surface,
    /// never as stripes, which is why it is thousandths of white and not
    /// hundredths.
    ///
    /// - Parameter dimmed: Whether the screen's luminance is reduced, in which
    ///   case there is no weave at all. It is the clearest case of atmosphere
    ///   in the package: thousandths of white that say "surface" and nothing a
    ///   glance could read.
    public static func courtWeave(on side: Side, dimmed: Bool = false) -> Color {
        guard !dimmed else { return .clear }

        switch side {
        case .them: return .white.opacity(0.028)
        case .us: return .white.opacity(0.032)
        }
    }

    /// The net's tape.
    ///
    /// - Parameter dimmed: Whether the screen's luminance is reduced, in which
    ///   case the tape goes thinner but never away — the net is geometry, not
    ///   atmosphere.
    static func netTape(dimmed: Bool = false) -> Color {
        dimmed ? .netTape.opacity(CourtDimming.paint) : .netTape
    }

    /// The post at each end of the tape.
    ///
    /// - Parameter dimmed: Whether the screen's luminance is reduced. Thinned
    ///   by the same fraction as the tape, so the post stays the brighter of
    ///   the two.
    static func netPost(dimmed: Bool = false) -> Color {
        dimmed ? .netPost.opacity(CourtDimming.paint) : .netPost
    }

    /// The ball's felt.
    ///
    /// Here rather than on ``Ball/Finish`` for the reason every other court
    /// color is here: this file owns what the geometry is painted in.
    ///
    /// - Parameter dimmed: Whether the screen's luminance is reduced. Only the
    ///   ball on the court answers to it. The cut-out is a hole in a button,
    ///   and dimming it would leave half a control dark on a ground that is
    ///   still full-strength `ball`.
    static func ballFelt(_ finish: Ball.Finish, dimmed: Bool = false) -> Color {
        switch finish {
        case .onCourt: dimmed ? Color.ball.towardNight(CourtDimming.felt) : .ball
        case .cutOut: .onBall
        }
    }

    /// This color mixed `fraction` of the way into `night`.
    ///
    /// Only for the opaque surfaces — see ``CourtDimming``.
    func towardNight(_ fraction: Double) -> Color {
        mix(with: .night, by: fraction)
    }

    /// The line weights, off the boards.
    ///
    /// The service line is the strongest of the three and the outline the
    /// faintest — the eye is meant to find the service boxes first and the
    /// edge of the court last, because the edge is where the screen already
    /// ends.
    private static func lineOpacity(_ line: CourtLine, on side: Side) -> Double {
        switch (side, line) {
        case (.them, .service): 0.34
        case (.them, .center): 0.28
        case (.them, .outline): 0.20
        case (.us, .service): 0.36
        case (.us, .center): 0.30
        case (.us, .outline): 0.22
        }
    }
}
