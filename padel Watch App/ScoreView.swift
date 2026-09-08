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

    /// The half the serving side serves from, in the server's own frame; `nil`
    /// on a golden point, where the receivers choose and the app is not told.
    ///
    /// The zone it is drawn in mirrors it or not according to which side
    /// serves — see `serveAlignment(for:from:)`, which is the only place that
    /// knows the screen is drawn from our end of the court.
    let servingHalf: ServingHalf?

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
            servingHalf: servingHalf,
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

    /// The serving side's half, in the server's own frame — the same value in
    /// both zones, and read by the zone that serves.
    let servingHalf: ServingHalf?

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
            .accessibilityAction(named: "Undo the last rally", onUndo)
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
                // A numeral drawn on its own is not a sentence, and a catalog
                // carrying a key of "%lld" would be carrying nothing. The
                // spoken score below says the word that goes with it.
                Text(verbatim: "\(games)")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The ball sits in a corner and not on the line with the score:
        // otherwise the digit would slide off the center of the zone on every
        // change of serve, and the eye would have to find it again. An overlay
        // is the whole of that guarantee — it takes no room from the layout in
        // either zone, whether it draws a ball or nothing.
        .overlay {
            ServeIndicator(alignment: isServing ? serveAlignment(for: side, from: servingHalf) : nil)
        }
        // The sets stand at the opposite edge rather than as a third number on
        // the score line: next to the games, a second small digit would read as
        // part of the game score, and "4 1" would have to be puzzled out.
        // Position is the only thing that tells them apart, and it is also what
        // keeps them from pushing the points off the center of the zone.
        .overlay(alignment: .trailing) {
            if let sets {
                Text(verbatim: "\(sets)")
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

    /// What the half is, said as what tapping it does rather than as whose
    /// half it is: "us" on its own is a name, and a name is what the two
    /// languages decline differently.
    private var accessibilityLabel: LocalizedStringKey {
        switch side {
        case .us: "Point to us"
        case .them: "Point to the opponents"
        }
    }

    /// The score this half is showing, as a list of clauses.
    ///
    /// Each clause is whole and the comma between them belongs to no language:
    /// "геймов 3" used to be a noun and a number glued together here, and the
    /// noun a count governs is exactly what Russian has four forms of. The
    /// catalog picks the form; this only puts the clauses in order.
    private var accessibilityValue: Text {
        // The points are a label rather than a number — "40", "AD" — and are
        // padel's own notation in both languages.
        var value = Text(verbatim: pointsLabel)

        func add(_ clause: LocalizedStringKey) {
            value = value + Text(verbatim: ", ") + Text(clause)
        }

        if let games { add("\(games) games") }
        if let sets { add("\(sets) sets") }
        if isServing { add(servingClause) }

        return value
    }

    /// "Serving", said with the half it is served from.
    ///
    /// Three whole clauses rather than "serving" with a fragment appended to
    /// it, for the reason the comment above gives: what the two languages put
    /// where is the catalog's business and not this file's.
    ///
    /// The right and the left are the server's own, which is what the players
    /// say to each other on court — the mirror below is the screen's problem
    /// and nobody speaks it. On a golden point the clause falls back to plain
    /// "serving": less, rather than something false.
    private var servingClause: LocalizedStringKey {
        switch servingHalf {
        case .right: "serving from the right"
        case .left: "serving from the left"
        case nil: "serving"
        }
    }
}

/// Where in `side`'s zone the ball sits when that side serves from `half`.
///
/// The screen draws the court as it is seen from our end, so the two zones
/// mirror each other: our right half is at screen trailing, and the opponents'
/// right half at screen **leading**, because they are facing us. A serve then
/// reads as a diagonal across the screen — our bottom right to their top left —
/// which is what a serve is.
///
/// So one enum case gives two opposite alignments below, and that is not a
/// copy-paste slip. The correction not to make is flattening it to
///
///     case (_, .right): .trailing
///     case (_, .left):  .leading
///
/// which puts both balls on the same side of the screen and draws our serve to
/// the opponents' box as a straight line up it, a serve padel does not have.
/// Nothing goes red for it: no test reaches this target. The app is simply
/// wrong about the opponents' half from then on, in a way only somebody
/// standing on a court notices.
///
/// The corner is always the zone's **inner** one — our zone's top, the
/// opponents' bottom. The vertical position carries no meaning; the outer
/// corners would have been truthful, since the server does stand at the back
/// of the court, but the watch's clock is drawn over the opponents' top right
/// and cannot be hidden by a third-party app, and the page dots of
/// `ScorePages` sit over our bottom. The inner corners are clear of both, they
/// keep their distance from the sets digit, and they put the two balls either
/// side of the center divider, mirroring each other the way the halves do.
///
/// A `nil` half is the golden point: the ball goes to the middle of the inner
/// edge, still saying who serves and no longer saying from where.
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

/// The ball in the serving side's zone: `alignment` is the corner it belongs
/// in, or `nil` when the other side serves and this zone shows nothing.
///
/// A move fades. The ball at the old corner fades out, and only once it is
/// gone does the new one fade in — never both at once, because a crossfade
/// would put a ball in both halves of the court for the length of it, and that
/// is the one thing this indicator must never say. There is no motion
/// continuity to protect: a fade has already given up the reading that the
/// ball travelled.
///
/// The jump between the zones on a change of serve is the same animation seen
/// from two sides — one zone's `alignment` goes `nil` while the other's stops
/// being `nil`, and each zone runs its own half of the sequence.
///
/// The half flips on every rally, so this runs on every tap. If it turns out
/// to be noise on a wrist rather than on a simulator, the answer is a shorter
/// fade, not a slide.
///
/// **The ball never travels.** Opacity is the only thing animated here, and the
/// corner is kept out of the animation on purpose — `.animation(nil, value:)`
/// below is that, and it is not decoration. A corner is an alignment, an
/// alignment is layout, and layout is the one thing SwiftUI will happily
/// interpolate: hand a new corner to a ball that is on screen, or to one whose
/// fade is still running, and it slides across the zone instead of appearing in
/// it. That was the first version of this view, and it read as a serve
/// travelling to the other half — the exact reading a fade is chosen to give
/// up.
private struct ServeIndicator: View {
    let alignment: Alignment?

    /// The corner the ball is drawn in, which follows `alignment` one fade
    /// behind and only ever changes while the ball is invisible.
    ///
    /// It keeps the last corner rather than going `nil` with the ball: a
    /// corner the ball no longer has still has to hold it while it fades out.
    @State private var corner: Alignment = .center

    @State private var isVisible = false

    private static let fade: TimeInterval = 0.15

    var body: some View {
        Image(systemName: "tennisball.fill")
            .resizable()
            // The size the dot had, and white for contrast against both
            // backgrounds — a fifth color on a screen that has three would be
            // spent on the smallest thing on it.
            .frame(width: 10, height: 10)
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner)
            // The corner is excluded from every animation, including one
            // already in flight around it. Without this the ball travels; with
            // it, it can only be somewhere or nowhere.
            .animation(nil, value: corner)
            .opacity(isVisible ? 0.9 : 0)
            .animation(.easeInOut(duration: Self.fade), value: isVisible)
            .task(id: alignment) { await move(to: alignment) }
    }

    private func move(to alignment: Alignment?) async {
        if isVisible {
            isVisible = false

            try? await Task.sleep(for: .seconds(Self.fade))

            // A rally scored mid-fade cancels this task and starts the next
            // one, which finds the ball already going and brings it back at the
            // new corner. Returning here rather than falling through is the
            // point: the cancelled task would otherwise put the ball back at
            // the corner it was leaving.
            guard !Task.isCancelled else { return }
        }

        guard let alignment else { return }

        corner = alignment
        isVisible = true
    }
}

#if DEBUG

/// Both languages, though only VoiceOver hears a word of this screen: the
/// numbers on it are the same in either, and everything that is a sentence is
/// spoken rather than drawn. A preview is still the only place the spoken
/// score can be read in Russian without a watch on a wrist.
private func inRussian(_ view: ScoreView) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

/// One classic score, served from wherever the preview needs it served from.
///
/// The four corner previews below differ in nothing else, which is what makes
/// them readable side by side: the ball is the only thing that moves.
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

/// The one place the ball and the sets digit share a zone: the ball at the
/// opponents' bottom leading corner, the digit at their trailing edge.
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

// The four corners are named for the surprise rather than for the state: what
// is worth checking against a picture is that the opponents' right is at
// screen left, and the name is what puts that in front of the person about to
// straighten out `serveAlignment(for:from:)`.

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
