import SwiftUI

/// The whole court: their half, the net, ours — the two halves equal.
///
/// The convenience for the four screens that want all of it and nothing in it.
/// It is empty on purpose: a screen that fills each half — the score screens
/// put a number in each — asks for ``CourtHalf`` and ``NetLine`` itself and
/// overlays its own content. That is one line more at those call sites and one
/// generic parameter fewer here, and it keeps both doors open.
public struct Court: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            CourtHalf()

            // Drawn above our half rather than under it, so the tape's shadow
            // falls on the surface — the boards' `z-index: 1`. A `VStack` draws
            // its children in order, and the order puts our half last.
            NetLine().zIndex(1)

            CourtHalf()
        }
    }
}
