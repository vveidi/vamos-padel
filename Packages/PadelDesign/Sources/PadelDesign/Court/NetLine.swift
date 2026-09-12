import SwiftUI

/// The net, seen from directly above: a bright tape with a post standing at
/// each end.
///
/// It is not a mesh, not a dashed line and not a `Divider()`. The posts are
/// the whole of what makes it read as a net seen from above rather than as a
/// rule drawn across the screen — a tape on its own is a divider, and the app
/// has five screens split in two that would all read as one.
///
/// **The posts stand proud of the tape and take no room for it.** They are an
/// overlay, so the net's height in a layout is the tape's and the two halves
/// meet on it exactly. A post that pushed the halves apart would open a seam
/// down the middle of every screen.
public struct NetLine: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color.netTape(dimmed: isLuminanceReduced))
            .frame(height: CourtMetrics.tape)
            .overlay(alignment: .leading) { post }
            .overlay(alignment: .trailing) { post }
            // Without it the net looks painted on the court rather than
            // strung above it, which is the one thing the posts are for. A
            // dimmed screen gets none: being strung above is atmosphere.
            .shadow(
                color: isLuminanceReduced ? .clear : .shadow,
                radius: CourtMetrics.shadowRadius,
                y: CourtMetrics.shadowOffset)
    }

    /// A post: one tape wide, three tapes long, standing across the line.
    ///
    /// Centered on the tape, as the boards draw it — it rises into their half
    /// and drops into ours by the same amount, because a post seen from
    /// directly overhead has no near end.
    private var post: some View {
        Rectangle()
            .fill(Color.netPost(dimmed: isLuminanceReduced))
            .frame(width: CourtMetrics.tape, height: CourtMetrics.tape * 3)
    }
}
