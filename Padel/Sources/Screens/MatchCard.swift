import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

/// The match card: how the score came about, and not only how it ended.
///
/// Nothing here is read out of the store beyond the ruleset and the rally
/// journal. The course of the score is rebuilt from them by the same engine
/// that counted the match on the watch — that is what the journal is stored
/// for instead of the final score (ADR-0001), and what the engine lives in a
/// shared package for.
///
/// It is the tile it was opened from, opened out: the same `night` under the
/// same light, and the summary standing on a ``PadelDesign/CourtTile`` of the
/// same tint and the same radius. Nothing here is a `List` — the course of the
/// score runs down the page as bands cut from the half that took each step,
/// which is the same colour vocabulary the history's column is read by.
struct MatchCard: View {
    let match: SavedMatch

    /// The language and region the card is being read in. Everything dated on
    /// it is formatted with this rather than with `Locale.current`, so that the
    /// dates follow the same language as the words beside them — the app's in
    /// the app, and the chosen one in a preview.
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summary.padding(.top, Board.titleGap)

                course.padding(.top, Board.courseGap)
            }
            .padding(.horizontal, Board.inset)
            .padding(.bottom, Board.inset)
        }
        .background { ground }
        .navigationTitle(day)
    }

    /// The score and the outcome are asked of the engine every time rather
    /// than kept in a `@State`: recomputing them costs a walk over a journal
    /// of a few hundred rallies, and a copy would be one more thing that can
    /// disagree with the journal.
    private var state: MatchState { match.match.state }

    // MARK: When it was played

    /// The day the match was played, which is the card's title.
    ///
    /// A large title like the history's, so it scrolls away rather than
    /// holding a quarter of the screen for the whole reading — a date is long
    /// enough in Russian to need the room back.
    private var day: String { match.day(in: locale) }

    // MARK: How it ended

    /// The summary, on a tile of the outcome's tint — the same three tints the
    /// history's column is read by, at the same radius, so that opening a tile
    /// enlarges it rather than replacing it with a screen.
    private var summary: some View {
        CourtTile(outcome: state.outcome) {
            VStack(alignment: .leading, spacing: Board.lineGap) {
                Text(headline)
                    .textStyle(.control)
                    .foregroundStyle(headlineInk)

                // Our side first, the same as in the history's row: the card is
                // opened from that row, and a score that swapped sides on the
                // way in would have to be read twice.
                score

                Text(match.match.ruleset.name)
                    .textStyle(.body)
                    .foregroundStyle(.ink.weight(.secondary))

                footnote
                    .textStyle(.caption)
                    .foregroundStyle(.ink.weight(.tertiary))
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The final score at the size the app sets a score at.
    ///
    /// The ramp's largest entry, shrunk to whatever the tile's width leaves —
    /// "2 : 1" gets all of it and "16 : 14" gets about three quarters, which is
    /// still the largest thing on the card by a long way. The watch's outcome
    /// screen fits its score the same way and for the same reason: the number
    /// of digits is the match's to decide, not the screen's.
    private var score: some View {
        Text(state.finalScore.written)
            .textStyle(.score)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.3)
            .foregroundStyle(Color.courtInk(state.outcome))
            .accessibilityLabel(Text(state.finalScore.spoken))
    }

    /// What the match was played by, when it started and how long it went on —
    /// three whole things with a separator between them, and not one sentence
    /// assembled out of words. The separator is the only part of it that is not
    /// somebody's sentence, which is why it is the only part written here.
    private var footnote: Text {
        Text(match.match.ruleset.manner)
            + Text(verbatim: " · \(match.timeOfDay(in: locale)) · \(match.lasted(in: locale))")
    }

    /// An abandoned match is said to be one in as many words, and not by the
    /// absence of a winner: "counts as neither a win nor a loss" is a result
    /// of its own, and a card that simply stayed silent about the outcome
    /// would read as a card that lost it.
    ///
    /// The mark the history's row carries has no place next to this line — it
    /// would be the same sentence twice. The row needs it because a score in a
    /// column of results must not pass for a win at a glance; here the outcome
    /// is already spelled out where a win would have been announced.
    private var headline: LocalizedStringKey {
        switch state.outcome {
        case .finished(let winner): winner == .us ? "We won" : "Opponents won"
        case .abandoned: "Match unfinished"
        case .inProgress: "Match in progress"
        }
    }

    /// The ink the sentence is set in: the accent on a win, and the app's own
    /// ink on the two outcomes that are not one.
    ///
    /// The ball marks what is yours (ADR-0006), and a win is the one outcome
    /// that is. What the tile is tinted with does not come into it — the line
    /// is a label above the score, and it takes the weight the lines under it
    /// take, not the half's ink the score itself is set in.
    private var headlineInk: Color {
        state.outcome.winner == .us ? .ball : .ink.weight(.strong)
    }

    // MARK: How it came about

    /// The course of the score, read down the page.
    ///
    /// Handed the course once rather than reading it again per section: it is a
    /// walk over the journal, and every set asking for a copy of its own would
    /// be asking the engine the same question five times over.
    @ViewBuilder private var course: some View {
        let course = match.match.course

        if course.isEmpty {
            block(titled: "How it went") { nothingPlayed }
        } else {
            switch course {
            case .points(let steps):
                block(titled: "How it went") { rallies(steps) }

            case .sets(let sets):
                VStack(alignment: .leading, spacing: Board.blockGap) {
                    ForEach(Array(sets.enumerated()), id: \.offset) { number, set in
                        block(heading: heading(of: set, number: number + 1)) {
                            games(of: set, isLast: number == sets.count - 1)
                        }
                    }
                }
            }
        }
    }

    /// A heading and whatever runs under it.
    private func block<Content: View>(
        titled title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        block(heading: heading(title, score: nil), content: content)
    }

    /// The same, for a heading the caller has already built.
    private func block<Content: View>(
        heading: some View,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Board.headingGap) {
            heading

            content()
        }
    }

    /// A set's line above its games: which set it is and how it ended.
    ///
    /// In a match of one set there is no number worth saying — there is
    /// nothing to tell it apart from — and no score either: it would be the
    /// match's own, already standing in large type above. Which of the two
    /// this is, is the ruleset's answer and not the count of the sets played:
    /// a match to two sets stopped inside its first one is still a match of
    /// two, and saying otherwise would hide the set it was stopped in.
    private func heading(of set: SetCourse, number: Int) -> some View {
        let numbered = match.match.ruleset.isMultiSet

        return heading(
            numbered ? "Set \(number)" : "How it went", score: numbered ? set.score : nil)
    }

    /// What a block of the course is called, with the score it ended on at the
    /// trailing edge when there is one worth saying.
    private func heading(_ title: LocalizedStringKey, score: SideCounts?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Board.headingGap) {
            Text(title)
                .foregroundStyle(.ink.weight(.secondary))

            if let score {
                Spacer(minLength: 0)

                Text(score.written)
                    .monospacedDigit()
                    .foregroundStyle(.ink.weight(.strong))
                    .accessibilityLabel(Text(score.spoken))
            }
        }
        .textStyle(.control)
    }

    /// The games of a set, the tiebreak that decided it, and whatever was left
    /// unfinished in it.
    ///
    /// - Parameter isLast: Whether this is the set the match was left standing
    ///   in. What was left unfinished belongs to that set and no other: a set
    ///   played in is part of the course from its first rally, whether or not a
    ///   game in it was carried to its end.
    private func games(of set: SetCourse, isLast: Bool) -> some View {
        VStack(spacing: Board.stepGap) {
            // A set stopped in before its first game has no games to draw, and
            // the lines below are the whole of what happened in it.
            ForEach(Array(set.games.enumerated()), id: \.offset) { number, game in
                band(game, named: .game(number + 1))
            }

            if let tieBreak = set.tieBreak {
                note("Tiebreak", written: tieBreak.written, spoken: tieBreak.spoken)
            }

            if isLast, wasStoppedMidGame {
                note(unfinishedTitle, written: state.points.written, spoken: state.points.spoken)
            }
        }
    }

    /// Every rally of a match to N points, grouped into the runs one side
    /// served.
    ///
    /// The gap between two runs is where the serve changed hands. It says
    /// *when* and not *who*, which is what a gap can honestly say, and the
    /// footnote above it has already given the number it counts by.
    private func rallies(_ steps: [ScoreStep]) -> some View {
        VStack(spacing: Board.runGap) {
            ForEach(serveRuns(over: steps.count), id: \.lowerBound) { run in
                VStack(spacing: Board.stepGap) {
                    ForEach(run, id: \.self) { number in
                        band(steps[number], named: .rally(number + 1))
                    }
                }
            }
        }
    }

    /// The rallies split at every change of serve.
    private func serveRuns(over rallies: Int) -> [Range<Int>] {
        // Classic scoring does not reach here — its steps are games, and a
        // game is already one side's serve — so it takes the one undivided run
        // rather than a number that would be a guess.
        guard case .pointsTo(_, let serveChangesEvery) = match.match.ruleset else {
            return rallies > 0 ? [0..<rallies] : []
        }

        // The floor is the engine's own: `PointsToReplay` counts the changes of
        // serve by the same number and refuses a zero for the same reason.
        let run = max(serveChangesEvery, 1)

        return stride(from: 0, to: rallies, by: run).map { $0..<min($0 + run, rallies) }
    }

    /// One step of the course: what the score became, on the half that took it.
    ///
    /// The score after the step and not the name of whoever took it, because
    /// the question the card is opened with is "was it close" — and a column of
    /// names answers it only by being counted up in the reader's head. Every
    /// band is the one court, so who took the step is said by which of the two
    /// numbers is left at full strength.
    private func band(_ step: ScoreStep, named name: StepName) -> some View {
        counts(step.score, taken: step.winner)
            .textStyle(.control)
            .monospacedDigit()
            .padding(.horizontal, Board.bandPadding)
            .frame(maxWidth: .infinity, minHeight: Board.bandHeight, alignment: .leading)
            .background(
                Color.courtSurface(),
                in: RoundedRectangle(cornerRadius: Board.bandRadius))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(name.spoken)
            .accessibilityValue(
                Text(step.score.spoken) + Text(verbatim: ", ") + won(by: step.winner))
    }

    /// The two numbers, ours first, with the one that just moved at full
    /// strength.
    private func counts(_ score: SideCounts, taken: Side) -> Text {
        numeral(score[.us], lit: taken == .us)
            + Text(verbatim: " : ").foregroundStyle(Color.courtInk.weight(.tertiary))
            + numeral(score[.them], lit: taken == .them)
    }

    /// One side's count, lit if it is the one that just moved.
    ///
    /// Verbatim: a numeral standing on its own is not a sentence, and a catalog
    /// that carried a key of "%lld" would be carrying nothing.
    private func numeral(_ count: Int, lit: Bool) -> Text {
        Text(verbatim: "\(count)")
            .foregroundStyle(Color.courtInk.weight(lit ? .primary : .secondary))
    }

    /// A line that is not a step of the course: the tiebreak's points, or where
    /// inside a game the match was stopped.
    ///
    /// Neither of them is a half taking something, so neither stands on a half.
    /// They are the surface the app puts a panel on, which is what keeps them
    /// legible as asides to the column of bands above them.
    ///
    /// - Parameters:
    ///   - written: The score as it is drawn. Handed in rather than taken as a
    ///     value, because the two askers hold two types — a set's tiebreak is
    ///     `SideCounts` and an unfinished game is `Points`, and the only thing
    ///     they have in common is that the phone knows how to write both.
    ///   - spoken: The same score for VoiceOver, where the order alone says
    ///     nothing about whose number is whose.
    private func note(_ title: LocalizedStringKey, written: String, spoken: LocalizedStringKey)
        -> some View
    {
        HStack(alignment: .firstTextBaseline, spacing: Board.headingGap) {
            Text(title)
                .textStyle(.body)
                .foregroundStyle(.ink.weight(.secondary))

            Spacer(minLength: 0)

            Text(written)
                .textStyle(.control)
                .monospacedDigit()
                .foregroundStyle(.ink.weight(.strong))
        }
        .padding(.horizontal, Board.bandPadding)
        .frame(maxWidth: .infinity, minHeight: Board.bandHeight, alignment: .leading)
        .background(
            .ink.weight(.surfaceQuiet), in: RoundedRectangle(cornerRadius: Board.bandRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(spoken))
    }

    /// Which step of the course a band is, for the only reader who is told:
    /// on screen the bands are told apart by the heading they run under.
    ///
    /// A whole sentence per kind of step, because English puts the number after
    /// the noun and there is no promise the next language will.
    private enum StepName {
        case game(Int)
        case rally(Int)

        var spoken: Text {
            switch self {
            case .game(let number): Text("Game \(number)")
            case .rally(let number): Text("Rally \(number)")
            }
        }
    }

    /// Who took the step, as a clause and not as a name: "we won" and "the
    /// opponents" cannot be told apart by a frame, because English puts the
    /// side before the verb and Russian after it.
    private func won(by side: Side) -> Text {
        side == .us ? Text("we won") : Text("opponents won")
    }

    /// Where inside a game the match was stopped.
    ///
    /// A game carried no further than 40:30 wins nobody anything and is
    /// therefore no step of the course — but it is exactly where an abandoned
    /// match was left standing, and the card would otherwise end on the last
    /// game that did finish, as if play had stopped on a clean boundary.
    ///
    /// Nothing to say in a match played out to the end: its last rally closes
    /// a game, so no points are left over.
    private var wasStoppedMidGame: Bool { !state.points.isEmpty }

    /// What exactly was left unfinished.
    ///
    /// Inside a set the points are a game's — except at 6:6, where they are a
    /// tiebreak's, and a tiebreak is not a game: the engine says as much where
    /// it refuses to let the golden point into one. Which of the two it is
    /// counting, `Points` already knows, and inside a set counted points can
    /// mean nothing else.
    private var unfinishedTitle: LocalizedStringKey {
        switch state.points {
        case .game: "Game unfinished"
        case .count: "Tiebreak unfinished"
        }
    }

    /// A match with an empty journal. It has no business on the phone — the
    /// watch does not send one — but a card that drew a blank block instead of
    /// saying so would hide the arrival of one.
    private var nothingPlayed: some View {
        Text("No rallies played")
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.secondary))
    }

    // MARK: The ground

    /// `night` with the history's light in the same corner, so that the card
    /// reads as the tile it was opened from rather than as somewhere else.
    private var ground: some View {
        Color.night
            .overlay { Floodlight(corner: .topTrailing, strength: Board.floodlight) }
            .ignoresSafeArea()
    }
}

/// The card's own spacing. This screen has no board (the spec's "What is in,
/// and what is not"), so the page's numbers are the history board's — the
/// screen it is opened from — and the bands' are its tiles' brought down to the
/// size of a line.
///
/// What the tile, the light and the type are drawn out of comes from
/// `PadelDesign`, and none of it is here.
private enum Board {
    /// Left and right of the page, and under the last band. The history
    /// board's.
    static let inset: CGFloat = 20

    /// Between the navigation bar and the summary. The history's own gap under
    /// its title, because the two screens carry the same bar.
    static let titleGap: CGFloat = 8

    /// Between the summary and the first heading of the course. The page's one
    /// real break, with how it ended above and how it came about below.
    static let courseGap: CGFloat = 28

    /// Between one set's block and the next.
    static let blockGap: CGFloat = 22

    /// Between a heading and what runs under it, and between the two halves of
    /// a heading.
    static let headingGap: CGFloat = 10

    /// Between the lines of the summary.
    static let lineGap: CGFloat = 6

    /// Between one step of the course and the next. Small enough that a run of
    /// bands reads as a run rather than as a list of cards.
    static let stepGap: CGFloat = 3

    /// Between two runs of serve — a break wide enough to be seen in a column
    /// of `stepGap`, and no wider.
    static let runGap: CGFloat = 12

    /// A band's height, and a minimum like every height in the app: turn
    /// Dynamic Type up and the score inside it grows past this.
    static let bandHeight: CGFloat = 34

    /// Left and right of what a band holds.
    static let bandPadding: CGFloat = 14

    /// A band's corner. The history tile's 24 is a radius for something the
    /// size of a card; at a band's height it would be a capsule.
    static let bandRadius: CGFloat = 10

    /// How much light the corner spends. The history board's 0.13, because it
    /// is the same lamp.
    static let floodlight: Double = 0.13
}

#if DEBUG

/// One card, read in the language the phone is set to — which for a phone set
/// to neither of ours is English.
private func card(_ match: SavedMatch) -> some View {
    NavigationStack { MatchCard(match: match) }
}

/// The same card in the other language.
///
/// Every preview below comes as a pair, because a card looked at in one
/// language is a card half checked: the two are equal on screen, Russian is the
/// longer of them, and the numbers on this screen change the words around them.
/// Between them the pairs say everything the card can say — a win and a defeat,
/// one set and two, a match to N points, the three ways a match is left
/// unfinished, and a journal with nothing in it at all.
private func cardInRussian(_ match: SavedMatch) -> some View {
    inRussian(card(match))
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

/// The largest of the twelve Dynamic Type settings, which is where the score
/// shrinks to fit the tile and a heading's two halves stop fitting one line.
private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("A win") { card(.preview(classicWonBy: .us)) }

#Preview("In Russian: a win") { cardInRussian(.preview(classicWonBy: .us)) }

#Preview("A defeat") { card(.preview(classicWonBy: .them)) }

#Preview("In Russian: a defeat") { cardInRussian(.preview(classicWonBy: .them)) }

#Preview("Two sets and a tiebreak") { card(.preview(twoSetsWonBy: .us)) }

#Preview("In Russian: two sets and a tiebreak") { cardInRussian(.preview(twoSetsWonBy: .us)) }

#Preview("The match to N points") { card(.preview(pointsTo: 16)) }

#Preview("In Russian: the match to N points") { cardInRussian(.preview(pointsTo: 16)) }

#Preview("Stopped early") { card(.previewClassicAbandoned) }

#Preview("In Russian: stopped early") { cardInRussian(.previewClassicAbandoned) }

#Preview("Stopped early, in the second set") { card(.previewAbandonedInSecondSet) }

#Preview("In Russian: stopped early, in the second set") {
    cardInRussian(.previewAbandonedInSecondSet)
}

#Preview("Stopped early, in a tiebreak") { card(.previewAbandonedInTieBreak) }

#Preview("In Russian: stopped early, in a tiebreak") {
    cardInRussian(.previewAbandonedInTieBreak)
}

#Preview("Stopped early, to N points") { card(.preview(pointsTo: 21, abandonedAfter: 9)) }

#Preview("In Russian: stopped early, to N points") {
    cardInRussian(.preview(pointsTo: 21, abandonedAfter: 9))
}

#Preview("Nothing played") { card(.previewNothingPlayed) }

#Preview("In Russian: nothing played") { cardInRussian(.previewNothingPlayed) }

/// The far end of the type range, on the two cards it is hardest on: the score
/// with the most digits, and the longest heading in the longer language.
#Preview("At the largest type") { atLargestType(card(.preview(pointsTo: 16))) }

#Preview("In Russian, at the largest type") {
    atLargestType(cardInRussian(.preview(twoSetsWonBy: .us)))
}

#Preview("In Russian, at the largest type: stopped early") {
    atLargestType(cardInRussian(.previewAbandonedInTieBreak))
}

#endif
