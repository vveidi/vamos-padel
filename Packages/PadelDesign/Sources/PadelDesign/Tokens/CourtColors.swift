import PadelScoring
import SwiftUI

/// How far each part of the court falls when the screen's luminance is reduced.
///
/// - Important: Opaque surfaces mix toward ``SwiftUI/Color/night``; paint goes
///   thinner instead, because mixing would move its alpha along with its hue.
enum CourtDimming {
    /// Measured: the dimmed surface lands at 0.119 luminance against `night`'s
    /// 0.079, stays blue at rgb(7, 34, 51), and holds `courtInk` at 5.8 : 1. A
    /// wrist has not confirmed it
    /// (`.scratch/court-surface/issues/03-the-dimming-on-a-wrist.md`).
    static let surface = 0.72

    static let felt = 0.15

    static let paint = 0.5
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
