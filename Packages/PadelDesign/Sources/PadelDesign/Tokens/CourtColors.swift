import PadelScoring
import SwiftUI

/// How far each part of the court falls when the screen's luminance is
/// reduced.
///
/// A surface is opaque and goes darker, mixed toward ``SwiftUI/Color/night``;
/// paint on a surface already carries a weight and goes thinner instead.
/// Mixing paint would move its alpha along with its hue and leave both wrong.
/// ADR-0006's consequences say why there is a dimmed court at all.
enum CourtDimming {
    /// Measured, not seen: the dimmed surface lands at 0.119 luminance against
    /// `night`'s 0.079, stays blue at rgb(7, 34, 51), and holds `courtInk` at
    /// 5.8 : 1. A wrist has not confirmed it
    /// (`.scratch/court-surface/issues/03-the-dimming-on-a-wrist.md`).
    static let surface = 0.72

    /// How far the ball's felt falls toward `night`.
    ///
    /// Much less than the court, because the ball has to still read as yellow
    /// once the court around it has gone dark.
    static let felt = 0.15

    /// What is left of the net's weight.
    ///
    /// Halved rather than dropped: the tape's contrast against its surface
    /// rises as the surface falls, which is what pays for thinning it.
    static let paint = 0.5
}

/// The colors that belong to the court itself.
///
/// They live here rather than in the court primitive for the same reason every
/// other token does: a color defined where it is first drawn is a color that
/// gets redrawn slightly differently the second time. ``CourtHalf`` owns the
/// geometry; this file owns what the geometry is painted in.
///
/// **Nothing here takes a ``PadelScoring/Side``.** The court is one surface
/// with one ink and one weave, and which half is ours is said by position and
/// by the net rather than by a second hue — see ``SwiftUI/Color/court``. The
/// one function that takes a domain type takes a
/// ``PadelScoring/MatchOutcome``, and answers the same way ``CourtTile`` picks
/// its ground.
extension Color {
    /// The court's surface.
    ///
    /// - Parameter dimmed: Whether the screen's luminance is reduced, in which
    ///   case the surface falls most of the way to `night` — see
    ///   ``CourtDimming``.
    public static func courtSurface(dimmed: Bool = false) -> Color {
        dimmed ? Color.court.towardNight(CourtDimming.surface) : .court
    }

    /// The ink for text standing on a tile drawn for a match's outcome.
    ///
    /// ``CourtTile`` takes the same ``PadelScoring/MatchOutcome`` to choose its
    /// ground, and this is the other half of that answer: a match won and a
    /// match still running stand on the court, so they take the court's ink; a
    /// match lost and a match stopped early stand on `night`, where the ink is
    /// the weight this app sets a title in.
    ///
    /// Here rather than at a call site because two screens read a match off a
    /// tile — the history's row and the match card — and an answer written in
    /// both is an answer that drifts in one.
    public static func courtInk(_ outcome: MatchOutcome) -> Color {
        switch outcome {
        case .finished(winner: .us), .inProgress: .courtInk
        case .finished(winner: .them), .abandoned: .ink.weight(.control)
        }
    }

    /// The court's weave — the faint diagonal texture over the surface.
    ///
    /// It is texture and not pattern: at a glance it must read as a surface,
    /// never as stripes, which is why it is thousandths of white and not
    /// hundredths. With the painted lines gone it is the only texture left on
    /// the surface, and it stays at the weight it had rather than being asked
    /// to do their work.
    ///
    /// - Parameter dimmed: Whether the screen's luminance is reduced, in which
    ///   case there is no weave at all. It is the clearest case of atmosphere
    ///   in the package: thousandths of white that say "surface" and nothing a
    ///   glance could read.
    public static func courtWeave(dimmed: Bool = false) -> Color {
        dimmed ? .clear : .white.opacity(0.03)
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
}
