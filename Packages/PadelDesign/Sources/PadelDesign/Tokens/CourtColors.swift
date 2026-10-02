import PadelScoring
import SwiftUI

/// How far each part of the court falls when the screen's luminance is reduced.
///
/// - Important: Opaque surfaces mix toward ``SwiftUI/Color/night``; paint goes
///   thinner instead, because mixing would move its alpha along with its hue.
enum CourtDimming {
    /// Settled on a real Apple Watch in Always-On, mid-match at arm's length: the
    /// court still reads as a court, and the score is findable without raising
    /// the wrist.
    static let surface = 0.72

    static let felt = 0.15

    static let paint = 0.5
}

/// How much of ``SwiftUI/Color/courtLit`` a rally mark reaches at its peak — a
/// property of the surface, not of the mark (ADR-0011).
enum CourtMark {
    /// Settled by eye on stills at watch size against 0.4, 0.6 and 0.8: below
    /// full the half reads as a slightly different blue rather than as lit. At
    /// full it is still blue and the score on it still reads.
    static let peak = 1.0
}

extension Color {
    public static func courtSurface(dimmed: Bool = false) -> Color {
        dimmed ? Color.court.towardNight(CourtDimming.surface) : .court
    }

    public static func courtInk(_ outcome: MatchOutcome) -> Color {
        switch outcome {
        case .finished(winner: .us), .inProgress: .courtInk
        case .finished(winner: .them), .abandoned: .ink.weight(.control)
        }
    }

    /// The court's weave — the faint diagonal texture over the surface, and
    /// thousandths of white so that it never reads as stripes.
    public static func courtWeave(dimmed: Bool = false) -> Color {
        dimmed ? .clear : .white.opacity(0.03)
    }

    static func netTape(dimmed: Bool = false) -> Color {
        dimmed ? .netTape.opacity(CourtDimming.paint) : .netTape
    }

    static func netPost(dimmed: Bool = false) -> Color {
        dimmed ? .netPost.opacity(CourtDimming.paint) : .netPost
    }

    /// - Parameter dimmed: Only `.onCourt` answers to it. The cut-out is a hole
    ///   in a button whose ground is still full-strength `ball`.
    static func ballFelt(_ finish: Ball.Finish, dimmed: Bool = false) -> Color {
        switch finish {
        case .onCourt: dimmed ? Color.ball.towardNight(CourtDimming.felt) : .ball
        case .cutOut: .onBall
        }
    }

    /// This color mixed `fraction` of the way into `night`. Only for the opaque
    /// surfaces — see ``CourtDimming``.
    func towardNight(_ fraction: Double) -> Color {
        mix(with: .night, by: fraction)
    }
}
