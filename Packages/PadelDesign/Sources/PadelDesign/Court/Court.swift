import SwiftUI

/// Their half, the net, ours. Empty on purpose: a screen that fills each half
/// stacks ``CourtHalf`` and ``NetLine`` itself and overlays its own content.
public struct Court: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            CourtHalf()

            // Above our half rather than under it, so the tape's shadow falls
            // on the surface. A `VStack` draws its children in order.
            NetLine().zIndex(1)

            CourtHalf()
        }
    }
}
