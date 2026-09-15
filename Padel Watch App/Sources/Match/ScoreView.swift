import PadelDesign
import PadelScoring
import SwiftUI

struct ScoreView: View {
    let points: Points

    /// `nil` in a match to N points, which has no games.
    let games: SideCounts?

    /// `nil` in a match of one set.
    let sets: SideCounts?

    let servingSide: Side

    /// In the server's own frame, mirrored for the screen by
    /// ``serveAlignment(for:from:)``. `nil` on a golden point, where the
    /// receivers choose and the app is not told.
    let servingHalf: ServingHalf?

    let onRallyWon: (Side) -> Void

    let onUndo: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            zone(for: .them)

            // Between the two halves rather than over them, so its shadow
            // falls on the surface — the order `PadelDesign.Court` uses.
            NetLine().zIndex(1)

            zone(for: .us)
        }
        .ignoresSafeArea()
    }

    private func zone(for side: Side) -> some View {
        ScoreZone(
            side: side,
            pointsLabel: points.label(for: side),
            games: games?[side],
            sets: sets?[side],
            isServing: side == servingSide,
            servingHalf: servingHalf,
            onRallyWon: onRallyWon,
            onUndo: onUndo)
    }
}

private struct ScoreZone: View {
    let side: Side

    /// A label precisely, and not a number: in a game it reads "40" or "AD".
    let pointsLabel: String

    let games: Int?
    let sets: Int?
    let isServing: Bool

    /// The same value in both zones; only the serving one reads it.
    let servingHalf: ServingHalf?

    let onRallyWon: (Side) -> Void
    let onUndo: () -> Void

    var body: some View {
        content
            // Gestures rather than a `Button`: a button fires on release and
            // would award a point at the end of the long press too.
            .onTapGesture { onRallyWon(side) }
            .onLongPressGesture(minimumDuration: 0.5) { onUndo() }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityAction(named: "Undo the last rally", onUndo)
    }

    private var content: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(pointsLabel)
                .textStyle(.score)
                .minimumScaleFactor(0.4)
                .foregroundStyle(.courtInk)

            if let games {
                // Verbatim: a bare numeral is not a sentence, and a catalog
                // key of "%lld" would carry nothing to translate.
                Text(verbatim: "\(games)")
                    .textStyle(.scoreAside)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color.courtInk.weight(.secondary))
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            ServeIndicator(alignment: isServing ? serveAlignment(for: side, from: servingHalf) : nil)
        }
        .overlay(alignment: .trailing) {
            if let sets {
                // The board draws this digit at 0.8–0.85 against the games'
                // 0.5; `control` is the 0.82 the ink already has a name for.
                Text(verbatim: "\(sets)")
                    .textStyle(.scoreAside)
                    .padding(.trailing, 12)
                    .foregroundStyle(Color.courtInk.weight(.control))
            }
        }
        .background { court }
        // Otherwise the gestures catch only the score itself, not the whole
        // half.
        .contentShape(Rectangle())
    }

    private var court: some View {
        CourtHalf()
            // The board lights our near corner and leaves their half unlit.
            .overlay {
                if side == .us {
                    Floodlight(corner: .bottomTrailing)
                }
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
    /// mirroring below is never spoken.
    private var servingClause: LocalizedStringKey {
        switch servingHalf {
        case .right: "serving from the right"
        case .left: "serving from the left"
        case nil: "serving"
        }
    }
}

/// Converts the server's own half into the viewer's frame, where the two zones
/// mirror each other (ADR-0013). One case per ``ServingHalf`` is the wrong
/// correction and no test in this target catches it.
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

/// - Parameter alignment: the corner the ball belongs in, or `nil` when the
///   other side serves and this zone draws nothing.
private struct ServeIndicator: View {
    let alignment: Alignment?

    /// Follows ``alignment`` one fade behind and keeps its last value rather
    /// than going `nil`: the ball needs a corner to fade out from.
    @State private var corner: Alignment = .center

    @State private var isVisible = false

    private static let fade: TimeInterval = 0.15

    var body: some View {
        Ball(size: 10)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner)
            // SwiftUI interpolates alignment like any other layout, including
            // inside an animation already in flight. Without this exclusion
            // the ball slides between corners instead of fading.
            .animation(nil, value: corner)
            .opacity(isVisible ? 0.9 : 0)
            .animation(.easeInOut(duration: Self.fade), value: isVisible)
            .task(id: alignment) { await move(to: alignment) }
    }

    /// Out fully, then in — never a crossfade, which would put a ball in both
    /// halves of the court for the length of it.
    private func move(to alignment: Alignment?) async {
        if isVisible {
            isVisible = false

            try? await Task.sleep(for: .seconds(Self.fade))

            // A rally scored mid-fade cancels this task; the one replacing it
            // brings the ball back. Falling through instead of returning would
            // restore it at the corner it was leaving.
            guard !Task.isCancelled else { return }
        }

        guard let alignment else { return }

        corner = alignment
        isVisible = true
    }
}

#if DEBUG

private func inRussian(_ view: ScoreView) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func serving(_ side: Side, from half: ServingHalf?) -> ScoreView {
    ScoreView(
        points: .game(SideCounts(us: 3, them: 2)),
        games: SideCounts(us: 4, them: 5),
        sets: nil,
        servingSide: side,
        servingHalf: half,
        onRallyWon: { _ in },
        onUndo: {})
}

private let goldenPoint = ScoreView(
    points: .game(SideCounts(us: 3, them: 3)),
    games: SideCounts(us: 4, them: 5),
    sets: nil,
    servingSide: .us,
    servingHalf: nil,
    onRallyWon: { _ in },
    onUndo: {})

private let twoSets = ScoreView(
    points: .game(SideCounts(us: 4, them: 3)),
    games: SideCounts(us: 2, them: 4),
    sets: SideCounts(us: 1, them: 0),
    servingSide: .them,
    servingHalf: .right,
    onRallyWon: { _ in },
    onUndo: {})

private let pointsTo = ScoreView(
    points: .count(SideCounts(us: 12, them: 9)),
    games: nil,
    sets: nil,
    servingSide: .them,
    servingHalf: .left,
    onRallyWon: { _ in },
    onUndo: {})

#Preview("We serve from our right (screen right)") { serving(.us, from: .right) }

#Preview("In Russian: we serve from our right") { inRussian(serving(.us, from: .right)) }

#Preview("We serve from our left (screen left)") { serving(.us, from: .left) }

#Preview("In Russian: we serve from our left") { inRussian(serving(.us, from: .left)) }

#Preview("The opponents serve from their right (screen left)") { serving(.them, from: .right) }

#Preview("In Russian: the opponents serve from their right") { inRussian(serving(.them, from: .right)) }

#Preview("The opponents serve from their left (screen right)") { serving(.them, from: .left) }

#Preview("In Russian: the opponents serve from their left") { inRussian(serving(.them, from: .left)) }

#Preview("The golden point: no half to name") { goldenPoint }

#Preview("In Russian: the golden point") { inRussian(goldenPoint) }

#Preview("A match to two sets") { twoSets }

#Preview("In Russian: a match to two sets") { inRussian(twoSets) }

#Preview("The match to N points") { pointsTo }

#Preview("In Russian: the match to N points") { inRussian(pointsTo) }

#endif
