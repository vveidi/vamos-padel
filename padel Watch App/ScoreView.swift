import PadelScoring
import SwiftUI

/// The score screen: two equal zones filling the display, one per side.
///
/// The opponents on top, us at the bottom — the same as on court: they are
/// across the net, in front of us. Hitting your own half has to work without
/// looking and with a wet hand, so the zones split the screen in half and hold
/// nothing but the score.
struct ScoreView: View {
    /// Our side is recognized by color rather than by a label: a label would
    /// take room from the digit the watch is being looked at for. The color
    /// lives here and not in the app's accent color, because it is a decision
    /// of the score screen.
    static let ourColor = Color(red: 0.188, green: 0.820, blue: 0.345)

    let points: Points

    /// The games of the current set; in a match to N points there are none,
    /// and then the zone holds points alone.
    let games: SideCounts?

    /// The sets won; `nil` everywhere except in a match longer than one set.
    /// The ruleset decides that, not the screen.
    let sets: SideCounts?

    let servingSide: Side

    let onRallyWon: (Side) -> Void

    let onUndo: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            zone(for: .them)
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
            onRallyWon: onRallyWon,
            onUndo: onUndo)
    }
}

/// The half of the screen belonging to one side: its score and its tap.
private struct ScoreZone: View {
    let side: Side

    /// A label precisely, and not a number: in a game it reads "40" or "AD".
    let pointsLabel: String

    let games: Int?
    let sets: Int?
    let isServing: Bool
    let onRallyWon: (Side) -> Void
    let onUndo: () -> Void

    var body: some View {
        content
            // A tap awards a point, a long press undoes the last one. Long was
            // chosen for how it differs from a mis-tap: a wet palm brushes the
            // screen in passing, whereas half a second of holding is intent.
            // The gesture rests on `onTapGesture` rather than on a `Button`: a
            // button fires on release and would award a point after the undo
            // as well.
            //
            // The spec (the "Score screen" section) leaves the exact gesture to
            // the prototype — it has to be tried with a sweaty hand, not in a
            // simulator. Until then the choice is provisional.
            .onTapGesture { onRallyWon(side) }
            .onLongPressGesture(minimumDuration: 0.5) { onUndo() }
            // The zone stopped being a button, so everything a button gave
            // VoiceOver is put back by hand.
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityAction(named: "Отменить последний розыгрыш", onUndo)
    }

    private var content: some View {
        // The games stand next to the points rather than on a line of their
        // own in the middle of the screen: the half stays one object to look
        // at, and the vertical is not spent on a third tier. A shared baseline
        // holds them as one score rather than two adjacent numbers.
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            // The type size and the shrink limit are the ones the points had
            // before the games appeared: the games took their place alongside,
            // but they must not squeeze the digit the watch is being looked at
            // for.
            Text(pointsLabel)
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.4)
                .foregroundStyle(.white)

            if let games {
                Text("\(games)")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The dot sits at the edge and not on the line with the score:
        // otherwise the digit would slide off the center of the zone on every
        // change of serve, and the eye would have to find it again. The room
        // for the dot is always taken — the visibility changes, the layout does
        // not.
        .overlay(alignment: .leading) {
            Circle()
                .frame(width: 10, height: 10)
                .padding(.leading, 12)
                .foregroundStyle(.white)
                .opacity(isServing ? 0.9 : 0)
        }
        // The sets stand at the opposite edge rather than as a third number on
        // the score line: next to the games, a second small digit would read as
        // part of the game score, and "4 1" would have to be puzzled out.
        // Position is the only thing that tells them apart, and it is also what
        // keeps them from pushing the points off the center of the zone.
        .overlay(alignment: .trailing) {
            if let sets {
                Text("\(sets)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .padding(.trailing, 12)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .background(background)
    // Otherwise the gesture catches only the score itself, not the whole half.
    .contentShape(Rectangle())
    }

    private var background: Color {
        switch side {
        case .us: ScoreView.ourColor.opacity(0.35)
        case .them: .white.opacity(0.1)
        }
    }

    private var accessibilityLabel: String {
        switch side {
        case .us: "Очко нам"
        case .them: "Очко соперникам"
        }
    }

    private var accessibilityValue: String {
        var value = pointsLabel

        if let games { value += ", геймов \(games)" }
        if let sets { value += ", сетов \(sets)" }
        if isServing { value += ", подача" }

        return value
    }
}

#Preview("Classic scoring") {
    ScoreView(
        points: .game(SideCounts(us: 3, them: 2)),
        games: SideCounts(us: 4, them: 5),
        sets: nil,
        servingSide: .us,
        onRallyWon: { _ in },
        onUndo: {})
}

#Preview("A match to two sets") {
    ScoreView(
        points: .game(SideCounts(us: 4, them: 3)),
        games: SideCounts(us: 2, them: 4),
        sets: SideCounts(us: 1, them: 0),
        servingSide: .them,
        onRallyWon: { _ in },
        onUndo: {})
}

#Preview("The match to N points") {
    ScoreView(
        points: .count(SideCounts(us: 12, them: 9)),
        games: nil,
        sets: nil,
        servingSide: .them,
        onRallyWon: { _ in },
        onUndo: {})
}
