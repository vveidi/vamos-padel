import SwiftUI

struct QuickTaps {
    let count: Int

    let gap: Duration

    private var run = 0

    private var last: ContinuousClock.Instant?

    init(count: Int, gap: Duration) {
        self.count = count
        self.gap = gap
    }

    /// - Returns: Whether this tap completes the run; the run then starts over.
    mutating func tap(at instant: ContinuousClock.Instant) -> Bool {
        if let last, instant - last <= gap {
            run += 1
        } else {
            run = 1
        }
        last = instant

        guard run == count else { return false }
        run = 0
        last = nil
        return true
    }
}

private struct QuickTapsModifier: ViewModifier {
    @State private var taps: QuickTaps

    let action: () -> Void

    init(count: Int, gap: Duration, action: @escaping () -> Void) {
        _taps = State(initialValue: QuickTaps(count: count, gap: gap))
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .contentShape(.rect)
            .onTapGesture {
                if taps.tap(at: .now) { action() }
            }
    }
}

extension View {
    /// Runs `action` on the `count`th tap in a row, with nothing drawn or felt
    /// along the way; a pause longer than `gap` starts the count over.
    public func onQuickTaps(
        _ count: Int, within gap: Duration = .milliseconds(500),
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(QuickTapsModifier(count: count, gap: gap, action: action))
    }
}
