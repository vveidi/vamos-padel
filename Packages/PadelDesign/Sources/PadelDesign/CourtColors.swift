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

/// The colors that belong to the court itself.
///
/// They live here rather than in the court primitive (ticket 02) for the same
/// reason every other token does: a color defined where it is first drawn is a
/// color that gets redrawn slightly differently the second time. Ticket 02
/// owns the geometry; this file owns what the geometry is painted in.
///
/// All four take a ``PadelScoring/Side`` because the two halves are not one
/// surface tinted twice — they are cool glass and warm turf, and their lines,
/// their ink and their weave all differ. Taking the domain's `Side` rather
/// than inventing a local `CourtSide` is ADR-0006's decision: `CONTEXT.md`
/// has already named this thing and already listed what not to call it.
extension Color {
    /// The surface of a half: glass blue for theirs, turf green for ours.
    public static func courtSurface(_ side: Side) -> Color {
        switch side {
        case .them: .theirHalf
        case .us: .ourHalf
        }
    }

    /// The ink for text sitting *inside* a half, where the ground is no longer
    /// `night` and the ink on `night` would read gray.
    public static func courtInk(_ side: Side) -> Color {
        switch side {
        case .them: .inkTheirHalf
        case .us: .inkOurHalf
        }
    }

    /// A painted line on a half.
    ///
    /// Ours is the brighter pair — the boards light the near half more, and
    /// the difference is small on purpose: two clearly different whites would
    /// read as two courts rather than as one seen from our end.
    public static func courtLine(_ line: CourtLine, on side: Side) -> Color {
        let paint: Color =
            switch side {
            case .them: .lineTheirHalf
            case .us: .lineOurHalf
            }

        return paint.opacity(lineOpacity(line, on: side))
    }

    /// The court's weave — the faint diagonal texture over the surface.
    ///
    /// It is texture and not pattern: at a glance it must read as a surface,
    /// never as stripes, which is why it is thousandths of white and not
    /// hundredths.
    public static func courtWeave(on side: Side) -> Color {
        switch side {
        case .them: .white.opacity(0.028)
        case .us: .white.opacity(0.032)
        }
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
