import SwiftUI

/// The net, seen from directly above: a bright tape with a post at each end.
/// The posts are an overlay and take no room, so the net takes only the tape's
/// thickness from a layout and the two halves meet on it exactly.
public struct NetLine: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private let axis: Axis

    /// - Parameter axis: The way the tape runs, and with it which pair of edges
    ///   the posts stand at. A court crosses the long axis of its screen, so a
    ///   landscape one turns the net.
    public init(_ axis: Axis = .horizontal) {
        self.axis = axis
    }

    public var body: some View {
        Rectangle()
            .fill(Color.netTape(dimmed: isLuminanceReduced))
            .frame(
                width: axis == .vertical ? CourtMetrics.tape : nil,
                height: axis == .horizontal ? CourtMetrics.tape : nil)
            .overlay(alignment: axis == .horizontal ? .leading : .top) { post }
            .overlay(alignment: axis == .horizontal ? .trailing : .bottom) { post }
            // The boards' downward shadow, turned with the net: a quarter turn
            // clockwise lands it on the leading side.
            .shadow(
                color: isLuminanceReduced ? .clear : .shadow,
                radius: CourtMetrics.shadowRadius,
                x: axis == .vertical ? -CourtMetrics.shadowOffset : 0,
                y: axis == .vertical ? 0 : CourtMetrics.shadowOffset)
    }

    private var post: some View {
        Rectangle()
            .fill(Color.netPost(dimmed: isLuminanceReduced))
            .frame(
                width: axis == .horizontal ? CourtMetrics.tape : CourtMetrics.tape * 3,
                height: axis == .horizontal ? CourtMetrics.tape * 3 : CourtMetrics.tape)
    }
}
