import PadelScoring
import SwiftUI

/// A rally that has just landed, as the court is told about it.
///
/// - Important: ``trigger`` must change with every rally that lands and with
///   nothing else: equal marks in a row play once. A journal's length is not
///   such a trigger — an undo and a rally back to the same side repeat it.
public struct RallyMark: Equatable, Sendable {
    public enum Tier: Sendable, CaseIterable {
        case rally
        case gameOrSet
    }

    public let side: Side
    public let tier: Tier
    public let trigger: Int

    public init(side: Side, tier: Tier, trigger: Int) {
        self.side = side
        self.tier = tier
        self.trigger = trigger
    }
}

/// The half lifted to ``SwiftUI/Color/courtLit``, weave and all. An overlay, so
/// it takes no room from the layout.
///
/// - Note: No dimmed variant: the mark only fires on a screen that is awake,
///   so it is never drawn with the luminance reduced — ADR-0011.
public struct RallyMarkFill: View {
    private let level: Double

    /// - Parameter level: 0 is the court as it is, 1 is the mark at its peak.
    /// - Note: Nonisolated because `keyframeAnimator` builds its content off
    ///   the main actor.
    public nonisolated init(level: Double) {
        self.level = level
    }

    public var body: some View {
        Rectangle()
            .fill(Color.courtLit)
            .overlay { CourtWeave(dimmed: false) }
            .opacity(level * CourtMark.peak)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension View {
    /// Lights this view, the half `side` plays on, each time `mark` changes to
    /// a rally `side` won. A view appearing with a mark already set lights
    /// nothing.
    public func rallyMark(_ mark: RallyMark?, on side: Side) -> some View {
        modifier(RallyMarkPlayer(mark: mark, side: side))
    }
}

// Not gated on Reduce Motion: this is already a crossfade on a still rectangle,
// which is what that setting replaces motion with — ADR-0011.
struct RallyMarkPlayer: ViewModifier {
    let mark: RallyMark?
    let side: Side

    @State private var plays = 0
    @State private var tier = RallyMark.Tier.rally

    /// Read off `docs/design/RallyMark.html`: a 520ms mark peaking at 14% of it,
    /// each leg on the study's `cubic-bezier(0.16, 0.9, 0.3, 1)`.
    private static let rise: TimeInterval = 0.073
    private static let fall: TimeInterval = 0.447
    private static let curve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.16, y: 0.9),
        endControlPoint: UnitPoint(x: 0.3, y: 1))

    /// The study draws one tier, so the hold is by eye on the previews' filmstrip:
    /// long enough to read as a pause at the peak, not yet as a second mark.
    private static func hold(_ tier: RallyMark.Tier) -> TimeInterval {
        switch tier {
        case .rally: 0
        case .gameOrSet: 0.4
        }
    }

    @KeyframesBuilder<Double>
    static func keyframes(_ tier: RallyMark.Tier) -> some Keyframes<Double> {
        LinearKeyframe(1, duration: rise, timingCurve: curve)
        LinearKeyframe(1, duration: hold(tier))
        LinearKeyframe(0, duration: fall, timingCurve: curve)
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                Color.clear
                    .keyframeAnimator(initialValue: 0.0, trigger: plays) { view, level in
                        view.overlay { RallyMarkFill(level: level) }
                    } keyframes: { _ in
                        Self.keyframes(tier)
                    }
                    .allowsHitTesting(false)
            }
            .onChange(of: mark) { _, mark in
                guard let mark, mark.side == side else { return }

                tier = mark.tier
                plays += 1
            }
    }
}
