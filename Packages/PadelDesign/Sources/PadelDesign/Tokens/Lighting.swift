import SwiftUI

extension Gradient {
    /// - Note: The boards vary the strength between 0.12 and 0.17 by how much
    ///   court the corner has to cross, and the light is gone by roughly two
    ///   thirds of the way — hence the stop at 0.62.
    public static func floodlight(strength: Double = 0.14) -> Gradient {
        Gradient(stops: [
            .init(color: .floodlight.opacity(strength), location: 0),
            .init(color: .floodlight.opacity(0), location: 0.62),
        ])
    }

    /// `night` fading in, so the court can run full bleed *under* a floating
    /// control. Written for the bottom edge; the top-edge variant is this
    /// gradient with its stops flipped, not a second token.
    public static let nightScrim = Gradient(stops: [
        .init(color: .night.opacity(0), location: 0),
        .init(color: .night.opacity(0.82), location: 0.46),
        .init(color: .night.opacity(0.95), location: 1),
    ])

    public static let ballGlow = Gradient(stops: [
        .init(color: .ball.opacity(0.16), location: 0),
        .init(color: .ball.opacity(0), location: 0.7),
    ])
}
