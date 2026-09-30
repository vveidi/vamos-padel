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
            board(safeArea: geometry.safeAreaInsets).ignoresSafeArea()
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

    private var leftSide: Side { isMirrored ? .them : .us }

    private func board(safeArea: EdgeInsets) -> some View {
        let state = saved.match.state

        return HStack(spacing: 0) {
            zone(leftSide, state, safeArea: safeArea)

            NetLine(.vertical).zIndex(1)

            zone(leftSide.opposite, state, safeArea: safeArea)
        }
        .overlay { Floodlight(corner: .bottomLeading, strength: Board.floodlight) }
        .overlay { NightScrim(edge: .top) }
        .overlay { NightScrim(edge: .bottom) }
        .overlay(alignment: .top) { strip(safeArea: safeArea) }
        .overlay(alignment: .bottom) { controls(safeArea: safeArea) }
    }

    // MARK: The two halves

    private func zone(_ side: Side, _ state: MatchState, safeArea: EdgeInsets) -> some View {
        let isOnTheLeft = side == leftSide
        let netEdge: HorizontalAlignment = isOnTheLeft ? .trailing : .leading

        return ScoreZone(
            side: side,
            pointsLabel: state.points.label(for: side),
            games: state.games?[side],
            sets: setsWorthShowing(state)?[side],
            // A finished match is served by nobody; the ball would otherwise
            // stand there naming a serve that will not be played.
            isServing: !state.outcome.isOver && side == state.servingSide,
            servingHalf: state.servingHalf,
            netEdge: netEdge,
            // Composed here and not in the half, so the edge the ball sits on
            // and the end it sits at cannot come to disagree.
            ballCorner: Alignment(
                horizontal: netEdge,
                vertical: serveEnd(for: side, from: state.servingHalf, mirrored: isMirrored)),
            outerInset: isOnTheLeft ? safeArea.leading : safeArea.trailing,
            onRallyWon: record(rallyWonBy:),
            onUndo: undo)
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

    private func controls(safeArea: EdgeInsets) -> some View {
        HStack(spacing: Board.controlGap) {
            PillButton(Text("Undo"), variant: .quiet, action: undo)
                .accessibilityLabel("Undo the last rally")

            PillButton(Text("Mirror"), variant: .quiet) { isMirrored.toggle() }
                .accessibilityLabel("Mirror the board")

            PillButton(Text("End"), variant: .quiet) { isConfirmingEnd = true }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.bottom, safeArea.bottom + Board.controlInset)
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

    /// The half's edge against the net. The sets digit stands at the other one,
    /// which leaves the corners by the net to the ball.
    let netEdge: HorizontalAlignment

    let ballCorner: Alignment

    /// What the notch takes off this half's outer edge in landscape.
    let outerInset: CGFloat

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
            .overlay(alignment: Alignment(horizontal: outerEdge, vertical: .center)) { setsWon }
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
                .padding(outerEdge == .leading ? .leading : .trailing, outerInset + Board.inset)
        }
    }

    @ViewBuilder private var ball: some View {
        if isServing {
            Ball(size: Board.ball)
                .padding(.horizontal, Board.ballFromTheSide)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: ballCorner)
                // Both ends and not one, or a golden point's ball leaves the
                // middle of the edge it belongs on.
                .padding(.vertical, Board.ballFromTheEnd)
        }
    }

    private var outerEdge: HorizontalAlignment { netEdge == .trailing ? .leading : .trailing }

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

// MARK: - The corners

/// The watch's serve corners turned a quarter turn: the server's right and left
/// are the *ends* of a half rather than its sides, and our right shares an end
/// with their left, which is what draws a serve as a diagonal (ADR-0013).
/// Mirroring is a half turn of the court, so the ends swap with the halves.
private func serveEnd(
    for side: Side, from half: ServingHalf?, mirrored: Bool
) -> VerticalAlignment {
    switch (side, half) {
    case (.us, .right), (.them, .left): mirrored ? .top : .bottom
    case (.us, .left), (.them, .right): mirrored ? .bottom : .top
    case (_, nil): .center
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

    /// The board's 34 from the foot of a portrait screen, where the home
    /// indicator takes none of it and the safe area here does.
    static let controlInset: CGFloat = 12

    static let floodlight: Double = 0.13
}

#if DEBUG

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
