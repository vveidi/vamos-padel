import os
import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI
import UIKit

struct ScoreboardView: View {
    @State private var saved: SavedMatch

    private let store: any MatchStore

    private let onLeave: () -> Void

    /// Held here and written nowhere else, so it lasts as long as the board is
    /// up and no longer.
    @State private var isMirrored: Bool

    @State private var isConfirmingEnd = false

    @Environment(\.locale) private var locale

    /// - Parameter mirrored: The court's facing to open on. Ours is on the left
    ///   unless the players are standing the other way round.
    init(
        match: SavedMatch, store: any MatchStore, mirrored: Bool = false,
        onLeave: @escaping () -> Void
    ) {
        _saved = State(initialValue: match)
        self.store = store
        _isMirrored = State(initialValue: mirrored)
        self.onLeave = onLeave
    }

    var body: some View {
        // The reader sits inside the safe area and reads it; the board then
        // ignores it, so the court bleeds while the words keep clear of the
        // sensor housing, which in landscape is inset from both long edges.
        GeometryReader { geometry in
            board(
                Arrangement(window: geometry.size, safeArea: geometry.safeAreaInsets),
                safeArea: geometry.safeAreaInsets
            )
            .ignoresSafeArea()
        }
        .background(Color.night)
        // An alert and not the watch's confirmation dialog, which in landscape
        // drops its cancel button and leaves "End" standing on its own.
        .alert(
            "End the match?",
            isPresented: $isConfirmingEnd
        ) {
            Button("End", role: .destructive) {
                abandon()

                onLeave()
            }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("The match will be saved as unfinished.")
        }
        .onAppear { takeTheScreen() }
        .onDisappear { releaseTheScreen() }
    }

    /// The half drawn first: the left one side by side, the top one stacked.
    private func firstSide(in arrangement: Arrangement) -> Side {
        switch arrangement {
        case .sideBySide: isMirrored ? .them : .us
        case .stacked: isMirrored ? .us : .them
        }
    }

    private func board(_ arrangement: Arrangement, safeArea: EdgeInsets) -> some View {
        let state = saved.match.state
        let first = firstSide(in: arrangement)

        // Identified by what they are rather than by their slot, so a rotation
        // that changes which half comes first moves each half to its place
        // instead of handing its slot to the other one.
        return arrangement.layout {
            ForEach([CourtPiece.half(first), .net, .half(first.opposite)], id: \.self) { piece in
                switch piece {
                case .half(let side): zone(side, state, arrangement, safeArea: safeArea)
                case .net: NetLine(arrangement.net).zIndex(1)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .overlay { Floodlight(corner: arrangement.floodlit, strength: Board.floodlight) }
        .overlay { NightScrim(edge: .top) }
        .overlay { NightScrim(edge: .bottom) }
        .overlay(alignment: .top) { strip(safeArea: safeArea) }
        .overlay(alignment: .bottom) { controls(arrangement, safeArea: safeArea) }
    }

    // MARK: The two halves

    private func zone(
        _ side: Side, _ state: MatchState, _ arrangement: Arrangement, safeArea: EdgeInsets
    ) -> some View {
        let isFirst = side == firstSide(in: arrangement)

        return ScoreZone(
            side: side,
            pointsLabel: state.points.label(for: side),
            games: state.games?[side],
            sets: setsWorthShowing(state)?[side],
            // A finished match is served by nobody; the ball would otherwise
            // stand there naming a serve that will not be played.
            isServing: !state.outcome.isOver && side == state.servingSide,
            servingHalf: state.servingHalf,
            setsEdge: arrangement == .sideBySide && isFirst ? .leading : .trailing,
            setsInset: arrangement == .sideBySide && isFirst ? safeArea.leading : safeArea.trailing,
            ballCorner: ballCorner(
                for: side, from: state.servingHalf, in: arrangement, mirrored: isMirrored),
            ballFromTheEnd: arrangement.ballFromTheEnd,
            onRallyWon: record(rallyWonBy:),
            onUndo: undo)
        .accessibilitySortPriority(side == .us ? 1 : 0)
    }

    /// Asked of the ruleset, not of the sets played: a multi-set match
    /// abandoned inside its first set still needs the row, or its games read
    /// as the match's.
    private func setsWorthShowing(_ state: MatchState) -> SideCounts? {
        saved.match.ruleset.isMultiSet ? state.sets : nil
    }

    // MARK: The strip along the top

    private func strip(safeArea: EdgeInsets) -> some View {
        HStack(spacing: Board.stripGap) {
            wayOut

            Text(saved.match.ruleset.name)
                .textStyle(.caption)
                .foregroundStyle(.ink.weight(.strong))
                .lineLimit(1)

            Spacer(minLength: Board.stripGap)

            clock
        }
        .padding(.top, safeArea.top + Board.stripInset)
        .padding(.leading, safeArea.leading + Board.inset)
        .padding(.trailing, safeArea.trailing + Board.inset)
    }

    private var wayOut: some View {
        Button(action: onLeave) {
            Image(systemName: "chevron.backward")
                .font(.system(size: Board.chevron, weight: .semibold))
                .foregroundStyle(.ink.weight(.control))
                .frame(width: Board.chevronWell, height: Board.chevronWell)
                .background(Circle().fill(.ink.weight(.surface)))
                .frame(width: Board.chevronHit, height: Board.chevronHit)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to your matches")
    }

    private var clock: some View {
        HStack(spacing: Board.dotGap) {
            Circle()
                .fill(.ball)
                .frame(width: Board.dot, height: Board.dot)

            duration
                .textStyle(.caption)
                .foregroundStyle(.ink.weight(.strong))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time played")
    }

    /// While the match runs the clock is the wall's, and it restarts at the
    /// first rally: that is the moment ``SavedMatch/startedAt`` moves to.
    @ViewBuilder private var duration: some View {
        if saved.match.state.outcome.isOver {
            Text(saved.lasted(in: locale))
        } else {
            Text(saved.startedAt, style: .timer)
        }
    }

    // MARK: The controls along the bottom

    /// Side by side the three keep their own widths, centred under the net;
    /// stacked they span the window, as the stacked board draws them.
    @ViewBuilder
    private func controls(_ arrangement: Arrangement, safeArea: EdgeInsets) -> some View {
        switch arrangement {
        case .sideBySide:
            HStack(spacing: Board.controlGap) { controlButtons }
                .fixedSize(horizontal: true, vertical: false)
                .padding(.bottom, safeArea.bottom + Board.controlInset)

        case .stacked:
            SpanningRow(spacing: Board.controlGap) { controlButtons }
                // One word a label, so a squeeze shrinks it rather than
                // breaking "Завершить" across two lines.
                .lineLimit(1)
                .minimumScaleFactor(Board.controlMinimumScale)
                .padding(.leading, safeArea.leading + Board.inset)
                .padding(.trailing, safeArea.trailing + Board.inset)
                .padding(.bottom, safeArea.bottom + Board.controlInset)
        }
    }

    @ViewBuilder private var controlButtons: some View {
        PillButton(Text("Undo"), variant: .quiet, action: undo)
            .accessibilityLabel("Undo the last rally")

        PillButton(Text("Mirror"), variant: .quiet) { isMirrored.toggle() }
            .accessibilityLabel("Mirror the board")

        PillButton(Text("End"), variant: .quiet) { isConfirmingEnd = true }
    }

    // MARK: The writes

    /// The write lands before the digits move: `@State` redraws once this has
    /// returned, not on the mutation.
    private func record(rallyWonBy side: Side) {
        saved.record(rallyWonBy: side, at: .now)

        persist()
    }

    private func undo() {
        saved.undo(at: .now)

        persist()
    }

    /// Already confirmed by the alert when this is called.
    private func abandon() {
        saved.abandon()

        persist()
    }

    /// A write failure is logged and swallowed: on court the score on the
    /// screen matters more than the record of it.
    private func persist() {
        do {
            try store.save(saved)
        } catch {
            logger.error("the match was not saved: \(error.localizedDescription)")
        }
    }

    // MARK: The screen itself

    private func takeTheScreen() {
        UIApplication.shared.isIdleTimerDisabled = true

        turn(to: .landscape)
    }

    private func releaseTheScreen() {
        UIApplication.shared.isIdleTimerDisabled = false

        turn(to: .allButUpsideDown)
    }

    /// The narrowing comes first and the request second: UIKit re-reads the
    /// app's own answer when it is told to, and refuses a request for an
    /// orientation that answer does not name.
    private func turn(to orientations: UIInterfaceOrientationMask) {
        AppDelegate.orientations = orientations

        scene?.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

        scene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { error in
            logger.error("the screen would not turn: \(error.localizedDescription)")
        }
    }

    /// - Returns: `nil` in a preview, which runs in no scene of its own.
    private var scene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}

// MARK: - One half of the board

private struct ScoreZone: View {
    let side: Side

    let pointsLabel: String

    let games: Int?
    let sets: Int?
    let isServing: Bool

    /// The same value in both halves; only the serving one reads it.
    let servingHalf: ServingHalf?

    /// Away from the net side by side, and the trailing edge stacked, as the
    /// watch has it: either way the corners by the net are left to the ball.
    let setsEdge: HorizontalAlignment

    /// What the notch takes off ``setsEdge`` in landscape.
    let setsInset: CGFloat

    let ballCorner: Alignment

    /// Off the half's top and bottom, whichever of them the net is.
    let ballFromTheEnd: CGFloat

    let onRallyWon: (Side) -> Void
    let onUndo: () -> Void

    var body: some View {
        content
            .onTapGesture { onRallyWon(side) }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityAction(named: "Undo the last rally", onUndo)
    }

    private var content: some View {
        score
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: Alignment(horizontal: setsEdge, vertical: .center)) { setsWon }
            .overlay { ball }
            .background { CourtHalf() }
            // Otherwise the gesture catches only the score itself, not the
            // whole half.
            .contentShape(Rectangle())
    }

    private var score: some View {
        HStack(alignment: .firstTextBaseline, spacing: Board.gamesGap) {
            Text(pointsLabel)
                .textStyle(.score)
                .minimumScaleFactor(Board.scoreMinimumScale)
                .foregroundStyle(.courtInk)

            if let games {
                // Verbatim: a bare numeral is not a sentence, and a catalog
                // key of "%lld" would carry nothing to translate.
                Text(verbatim: "\(games)")
                    .textStyle(.scoreAside)
                    .minimumScaleFactor(Board.asideMinimumScale)
                    .foregroundStyle(Color.courtInk.weight(.secondary))
            }
        }
        .lineLimit(1)
        .padding(.horizontal, Board.scoreInset)
    }

    @ViewBuilder private var setsWon: some View {
        if let sets {
            Text(verbatim: "\(sets)")
                .textStyle(.scoreAside)
                .foregroundStyle(Color.courtInk.weight(.control))
                .padding(setsEdge == .leading ? .leading : .trailing, setsInset + Board.inset)
        }
    }

    @ViewBuilder private var ball: some View {
        if isServing {
            Ball(size: Board.ball)
                .padding(.horizontal, Board.ballFromTheSide)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: ballCorner)
                // Both ends and not one, or a golden point's ball leaves the
                // middle of the edge it belongs on.
                .padding(.vertical, ballFromTheEnd)
        }
    }

    /// Said as what the tap does rather than as whose half it is: a bare "us"
    /// is a name, and the two languages decline names differently.
    private var accessibilityLabel: LocalizedStringKey {
        switch side {
        case .us: "Point to us"
        case .them: "Point to the opponents"
        }
    }

    /// Each clause is whole, and only the comma between them is assembled
    /// here: Russian has four forms of the noun a count governs, so the
    /// catalog has to see the number and its noun together.
    private var accessibilityValue: Text {
        var value = Text(verbatim: pointsLabel)

        func add(_ clause: LocalizedStringKey) {
            value = value + Text(verbatim: ", ") + Text(clause)
        }

        if let games { add("\(games) games") }
        if let sets { add("\(sets) sets") }
        if isServing { add(servingClause) }

        return value
    }

    /// The right and the left are the server's own, not the screen's: the
    /// turning below is never spoken.
    private var servingClause: LocalizedStringKey {
        switch servingHalf {
        case .right: "serving from the right"
        case .left: "serving from the left"
        case nil: "serving"
        }
    }
}

// MARK: - The stacked controls

/// A row as wide as it is offered, each view at its own width plus an equal
/// share of what is left. Short of room, all of them narrow by the same ratio.
private struct SpanningRow: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let widths = widths(across: proposal.width, of: subviews)
        let height = zip(subviews, widths)
            .map { $0.sizeThatFits(ProposedViewSize(width: $1, height: proposal.height)).height }
            .max() ?? 0

        return CGSize(width: widths.reduce(0, +) + gaps(subviews), height: height)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        var x = bounds.minX

        for (subview, width) in zip(subviews, widths(across: bounds.width, of: subviews)) {
            subview.place(
                at: CGPoint(x: x, y: bounds.midY), anchor: .leading,
                proposal: ProposedViewSize(width: width, height: bounds.height))

            x += width + spacing
        }
    }

    /// - Parameter width: `nil` asks for the ideal row, with nothing to share.
    private func widths(across width: CGFloat?, of subviews: Subviews) -> [CGFloat] {
        let ideal = subviews.map { $0.sizeThatFits(.unspecified).width }
        let total = ideal.reduce(0, +)

        guard let width, total > 0 else { return ideal }

        let room = max(width - gaps(subviews), 0)

        return room >= total
            ? ideal.map { $0 + (room - total) / CGFloat(ideal.count) }
            : ideal.map { $0 * room / total }
    }

    private func gaps(_ subviews: Subviews) -> CGFloat {
        spacing * CGFloat(max(subviews.count - 1, 0))
    }
}

// MARK: - The arrangement

private enum CourtPiece: Hashable {
    case half(Side)
    case net
}

/// Which way the net runs: across the long axis of the board's window, so a
/// half is never the narrow one (ADR-0015).
private enum Arrangement {
    case sideBySide
    case stacked

    /// - Parameters:
    ///   - window: The size inside `safeArea`, which is added back: the board
    ///     bleeds to the window's edges and is shaped by them.
    init(window: CGSize, safeArea: EdgeInsets) {
        let width = window.width + safeArea.leading + safeArea.trailing
        let height = window.height + safeArea.top + safeArea.bottom

        self = width > height ? .sideBySide : .stacked
    }

    /// One layout that changes kind rather than two stacks, so the board keeps
    /// its identity and moves with the system's rotation.
    var layout: AnyLayout {
        switch self {
        case .sideBySide: AnyLayout(HStackLayout(spacing: 0))
        case .stacked: AnyLayout(VStackLayout(spacing: 0))
        }
    }

    var net: Axis {
        switch self {
        case .sideBySide: .vertical
        case .stacked: .horizontal
        }
    }

    /// Side by side the ends are where the strip and the controls are, and the
    /// ball clears them; stacked they are the net, and it sits as near as it
    /// sits to the side.
    var ballFromTheEnd: CGFloat {
        switch self {
        case .sideBySide: Board.ballFromTheEnd
        case .stacked: Board.ballFromTheSide
        }
    }

    /// Our near corner, the watch's, turned with the court.
    var floodlit: Floodlight.Corner {
        switch self {
        case .sideBySide: .bottomLeading
        case .stacked: .bottomTrailing
        }
    }
}

// MARK: - The corners

/// The watch's corners, turned with the court: a quarter turn clockwise lays it
/// side by side, and mirroring is a half turn, so the ends swap with the halves
/// and the corners with them.
private func ballCorner(
    for side: Side, from half: ServingHalf?, in arrangement: Arrangement, mirrored: Bool
) -> Alignment {
    var corner = serveAlignment(for: side, from: half)

    if arrangement == .sideBySide { corner = corner.quarterTurned }
    if mirrored { corner = corner.quarterTurned.quarterTurned }

    return corner
}

/// The watch's own frame, unturned: our half below the net, our right at screen
/// trailing and theirs at screen leading, which draws a serve as a diagonal
/// (ADR-0013). One case per ``ServingHalf`` is the wrong correction.
private func serveAlignment(for side: Side, from half: ServingHalf?) -> Alignment {
    switch (side, half) {
    case (.us, .right): .topTrailing
    case (.us, .left): .topLeading
    case (.us, nil): .top
    case (.them, .right): .bottomLeading
    case (.them, .left): .bottomTrailing
    case (.them, nil): .bottom
    }
}

extension Alignment {
    /// A quarter turn clockwise on the screen: the top goes to the trailing
    /// edge and the trailing edge to the bottom.
    fileprivate var quarterTurned: Alignment {
        let horizontal: HorizontalAlignment =
            switch self.vertical {
            case .top: .trailing
            case .bottom: .leading
            default: .center
            }

        let vertical: VerticalAlignment =
            switch self.horizontal {
            case .leading: .top
            case .trailing: .bottom
            default: .center
            }

        return Alignment(horizontal: horizontal, vertical: vertical)
    }
}

/// What the score board drew around the court, in its pixels — the phone
/// boards are 1x (`docs/design/README.md`, "Reading the boards").
private enum Board {
    static let inset: CGFloat = 22

    /// The board's 58 less the status bar it was measured under; in landscape
    /// there is none and the safe area is the whole of it.
    static let stripInset: CGFloat = 14

    static let stripGap: CGFloat = 12

    static let dot: CGFloat = 7

    static let dotGap: CGFloat = 8

    /// The chevron and its well are the board's alone — it draws no way out —
    /// and neither scales: furniture does not grow with the type beside it.
    static let chevron: CGFloat = 16

    static let chevronWell: CGFloat = 34

    /// What the finger has to hit, larger than the circle drawn under it.
    static let chevronHit: CGFloat = 44

    /// The board's `margin-left: 12px` between the score and the games beside
    /// it, spent again to keep the pair off the half's edges.
    static let gamesGap: CGFloat = 12

    static let scoreInset: CGFloat = gamesGap

    /// Not numbers off the board, which is drawn at one Dynamic Type setting
    /// out of twelve. The watch's own, and it has the same "AD" to fit.
    static let scoreMinimumScale: CGFloat = 0.4

    static let asideMinimumScale: CGFloat = 0.5

    static let ball: CGFloat = 34

    static let ballFromTheSide: CGFloat = 22

    /// Measured, not turned off the board: what clears the controls, the strip
    /// and the scrims they sit on, which is as far into the corners as the
    /// furniture at both ends leaves room for.
    static let ballFromTheEnd: CGFloat = 108

    static let controlGap: CGFloat = 10

    /// Enough for the Russian labels three abreast on a portrait phone at the
    /// largest type, where they come back to about their default size.
    /// Measured on the simulator, not read off the board.
    static let controlMinimumScale: CGFloat = 0.3

    /// The board's 34 from the foot of a portrait screen, where the home
    /// indicator takes none of it and the safe area here does.
    static let controlInset: CGFloat = 12

    static let floodlight: Double = 0.13
}

#if DEBUG

// MARK: Side by side

// The four corners, named for the surprise rather than for the state: our
// right is the bottom of the board and theirs is the top, and no test in this
// target catches it if they stop mirroring (ADR-0013).

#Preview("We serve from our right (board bottom)", traits: .landscapeLeft) {
    board(.preview(serving: .us, from: .right))
}

#Preview("We serve from our left (board top)", traits: .landscapeLeft) {
    board(.preview(serving: .us, from: .left))
}

#Preview("The opponents serve from their right (board top)", traits: .landscapeLeft) {
    board(.preview(serving: .them, from: .right))
}

#Preview("The opponents serve from their left (board bottom)", traits: .landscapeLeft) {
    board(.preview(serving: .them, from: .left))
}

#Preview("Mirrored, we serve from our right (board top)", traits: .landscapeLeft) {
    board(.preview(serving: .us, from: .right), mirrored: true)
}

#Preview("Mirrored, the opponents serve from their right (board bottom)", traits: .landscapeLeft) {
    board(.preview(serving: .them, from: .right), mirrored: true)
}

#Preview("A game in play", traits: .landscapeLeft) { board(.previewInPlay) }

#Preview("In Russian: a game in play", traits: .landscapeLeft) {
    inRussian(board(.previewInPlay))
}

#Preview("Mirrored: ours on the right", traits: .landscapeLeft) {
    board(.previewInPlay, mirrored: true)
}

#Preview("In Russian, mirrored", traits: .landscapeLeft) {
    inRussian(board(.previewInPlay, mirrored: true))
}

#Preview("A tiebreak", traits: .landscapeLeft) { board(.previewInTieBreak) }

#Preview("A golden point: no half to name", traits: .landscapeLeft) {
    board(.previewAtGoldenPoint)
}

#Preview("A match to two sets", traits: .landscapeLeft) { board(.previewInSecondSet) }

#Preview("In Russian: a match to two sets", traits: .landscapeLeft) {
    inRussian(board(.previewInSecondSet))
}

#Preview("The match to N points", traits: .landscapeLeft) { board(.previewCountingPoints) }

#Preview("In Russian: the match to N points", traits: .landscapeLeft) {
    inRussian(board(.previewCountingPoints))
}

#Preview("At the largest type", traits: .landscapeLeft) { atLargestType(board(.previewInPlay)) }

#Preview("In Russian, at the largest type", traits: .landscapeLeft) {
    atLargestType(inRussian(board(.previewCountingPoints)))
}

// MARK: Stacked

// Named for the surprise again: stacked, our right is the top trailing corner
// of our half and theirs the bottom leading corner of theirs (ADR-0013).

#Preview("Stacked, we serve from our right (our top trailing)", traits: .portrait) {
    board(.preview(serving: .us, from: .right))
}

#Preview("Stacked, we serve from our left (our top leading)", traits: .portrait) {
    board(.preview(serving: .us, from: .left))
}

#Preview("Stacked, the opponents serve from their right (their bottom leading)", traits: .portrait) {
    board(.preview(serving: .them, from: .right))
}

#Preview("Stacked, the opponents serve from their left (their bottom trailing)", traits: .portrait) {
    board(.preview(serving: .them, from: .left))
}

#Preview("Stacked and mirrored, we serve from our right (our bottom leading)", traits: .portrait) {
    board(.preview(serving: .us, from: .right), mirrored: true)
}

#Preview(
    "Stacked and mirrored, the opponents serve from their right (their top trailing)",
    traits: .portrait
) {
    board(.preview(serving: .them, from: .right), mirrored: true)
}

#Preview("Stacked: a game in play", traits: .portrait) { board(.previewInPlay) }

#Preview("Stacked, in Russian: a game in play", traits: .portrait) {
    inRussian(board(.previewInPlay))
}

#Preview("Stacked and mirrored: ours on top", traits: .portrait) {
    board(.previewInPlay, mirrored: true)
}

#Preview("Stacked, in Russian, mirrored", traits: .portrait) {
    inRussian(board(.previewInPlay, mirrored: true))
}

#Preview("Stacked: a golden point", traits: .portrait) { board(.previewAtGoldenPoint) }

#Preview("Stacked: a match to two sets", traits: .portrait) { board(.previewInSecondSet) }

#Preview("Stacked, in Russian: a match to two sets", traits: .portrait) {
    inRussian(board(.previewInSecondSet))
}

#Preview("Stacked: the match to N points", traits: .portrait) {
    board(.previewCountingPoints)
}

#Preview("Stacked, in Russian: the match to N points", traits: .portrait) {
    inRussian(board(.previewCountingPoints))
}

#Preview("Stacked, at the largest type", traits: .portrait) {
    atLargestType(board(.previewInSecondSet))
}

#Preview("Stacked, in Russian, at the largest type", traits: .portrait) {
    atLargestType(inRussian(board(.previewCountingPoints)))
}

#Preview("Split View half: a match to two sets", traits: splitViewHalf) {
    board(.previewInSecondSet)
}

#Preview("Split View half, in Russian, mirrored: a golden point", traits: splitViewHalf) {
    inRussian(board(.previewAtGoldenPoint, mirrored: true))
}

#Preview("Split View half: the match to N points", traits: splitViewHalf) {
    board(.previewCountingPoints)
}

#Preview("Split View half, in Russian, at the largest type", traits: splitViewHalf) {
    atLargestType(inRussian(board(.previewInSecondSet)))
}

#Preview("Split View half, at the largest type, mirrored", traits: splitViewHalf) {
    atLargestType(board(.previewCountingPoints, mirrored: true))
}

/// Half of a phone opened flat, about: no Duo simulator exists to measure one.
private let splitViewHalf: PreviewTrait<Preview.ViewTraits> = .fixedLayout(width: 340, height: 720)

private func board(_ match: SavedMatch, mirrored: Bool = false) -> some View {
    ScoreboardView(match: match, store: NoMatchStore(), mirrored: mirrored, onLeave: {})
        .preferredColorScheme(.dark)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

#endif

private let logger = Logger(subsystem: "com.vveidi.padel", category: "scoreboard")
