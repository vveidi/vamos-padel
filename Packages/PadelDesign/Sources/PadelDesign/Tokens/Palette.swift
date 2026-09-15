import PadelScoring
import SwiftUI

/// The app's colors, read off the boards in `docs/design/`.
///
/// - Important: Dark only — there is no light variant (ADR-0006). The phone
///   pins `.dark`; the watch is dark already.
extension Color {
    // MARK: The ground and the court

    public static let night = Color(hex: 0x04_18_1F)

    public static let court = Color(hex: 0x17_40_6F)

    public static let courtLit = Color(hex: 0x2C_70_AE)

    // MARK: The one accent

    public static let ball = Color(hex: 0xDD_F3_5C)

    public static let onBall = Color(hex: 0x16_26_0A)

    public static let ballWash = Color.ball.opacity(0.14)

    public static let knob = Color(hex: 0x0B_2B_26)

    static let ballSeam = Color(hex: 0x14_28_12).opacity(0.4)

    /// The ball drawn the other way round — dark felt, bright seams — for the
    /// one place it sits on a `ball`-yellow button.
    static let ballSeamCutOut = Color.ball.opacity(0.8)

    // MARK: The net

    static let netTape = Color.ink.weight(.tape)

    static let netPost = Color.ink.weight(.post)

    static let shadow = Color.black.opacity(0.5)

    // MARK: The ink

    public static let ink = Color(hex: 0xEE_F7_F5)

    /// Ink for text standing *on* the court, where ``ink`` reads gray.
    public static let courtInk = Color(hex: 0xE6_EE_F8)

    // MARK: The light

    /// - Important: Spent as a gradient — see
    ///   ``SwiftUI/Gradient/floodlight(strength:)`` — never as a fill, which
    ///   would give the app a second accent.
    public static let floodlight = Color(hex: 0xFF_F8_D6)
}

// MARK: - Weights

/// The ink at a named weight — the boards spend one hex at a dozen opacities.
///
/// - Note: Cases sharing a number move independently: `hairline`/`surface` at
///   0.12, `tape`/`control` at 0.82.
public enum InkWeight: Sendable, CaseIterable {
    case primary

    case post

    case tape

    case control

    case strong

    case secondary

    case tertiary

    case hairline

    case surface

    case surfaceQuiet

    public var opacity: Double {
        switch self {
        case .primary: 1
        case .post: 0.9
        case .tape: 0.82
        case .control: 0.82
        case .strong: 0.65
        case .secondary: 0.55
        case .tertiary: 0.4
        case .hairline: 0.12
        case .surface: 0.12
        case .surfaceQuiet: 0.08
        }
    }
}

extension Color {
    public func weight(_ weight: InkWeight) -> Color {
        opacity(weight.opacity)
    }
}

// MARK: - Reading the boards

extension Color {
    /// A color from the `#rrggbb` the boards are written in.
    ///
    /// Deliberately not `public`: a screen that can build a color from a hex
    /// is a screen that can invent one.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - The same tokens, as shape styles

/// The public tokens again in `some ShapeStyle` position, where implicit member
/// syntax looks up statics on `ShapeStyle` rather than on `Color`. SwiftUI
/// declares its own colors twice for the same reason.
extension ShapeStyle where Self == Color {
    public static var night: Color { Color.night }

    public static var court: Color { Color.court }

    public static var courtLit: Color { Color.courtLit }

    public static var ball: Color { Color.ball }

    public static var onBall: Color { Color.onBall }

    public static var ballWash: Color { Color.ballWash }

    public static var knob: Color { Color.knob }

    public static var ink: Color { Color.ink }

    public static var courtInk: Color { Color.courtInk }

    public static var floodlight: Color { Color.floodlight }

    /// - Important: The defaulted `dimmed:` is mirrored, not dropped. Without
    ///   it this overload wins bare `courtSurface()` and forwards to itself.
    public static func courtSurface(dimmed: Bool = false) -> Color {
        Color.courtSurface(dimmed: dimmed)
    }

    public static func courtInk(_ outcome: MatchOutcome) -> Color { Color.courtInk(outcome) }

    public static func courtWeave(dimmed: Bool = false) -> Color {
        Color.courtWeave(dimmed: dimmed)
    }
}
