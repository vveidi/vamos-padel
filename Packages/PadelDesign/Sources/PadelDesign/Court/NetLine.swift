import SwiftUI

/// The net, seen from directly above: a bright tape with a post at each end.
/// The posts are an overlay and take no room, so the net's height in a layout
/// is the tape's and the two halves meet on it exactly.
public struct NetLine: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color.netTape(dimmed: isLuminanceReduced))
            .frame(height: CourtMetrics.tape)
            .overlay(alignment: .leading) { post }
            .overlay(alignment: .trailing) { post }
            .shadow(
                color: isLuminanceReduced ? .clear : .shadow,
                radius: CourtMetrics.shadowRadius,
                y: CourtMetrics.shadowOffset)
    }

    private var post: some View {
        Rectangle()
            .fill(Color.netPost(dimmed: isLuminanceReduced))
            .frame(width: CourtMetrics.tape, height: CourtMetrics.tape * 3)
    }
}
