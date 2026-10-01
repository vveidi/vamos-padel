import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

struct MatchCard: View {
    let match: SavedMatch

    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summary.padding(.top, Board.titleGap)

                course.padding(.top, Board.courseGap)
            }
            .frame(maxWidth: .readableColumn)
            .padding(.horizontal, Board.inset)
            .padding(.bottom, Board.inset)
            .frame(maxWidth: .infinity)
        }
        .background { ground }
        .navigationTitle(day)
    }

    private var state: MatchState { match.match.state }

    // MARK: When it was played

    private var day: String { match.day(in: locale) }

    // MARK: How it ended

    private var summary: some View {
        CourtTile(outcome: state.outcome) {
            VStack(alignment: .leading, spacing: Board.lineGap) {
                Text(headline)
                    .textStyle(.control)
                    .foregroundStyle(headlineInk)

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

    private var headline: LocalizedStringKey {
        switch state.outcome {
        case .finished(let winner): winner == .us ? "We won" : "Opponents won"
        case .abandoned: "Match unfinished"
        case .inProgress: "Match in progress"
        }
    }

    private var headlineInk: Color {
        state.outcome.winner == .us ? .ball : .ink.weight(.strong)
    }

    // MARK: How it came about

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

    private func block<Content: View>(
        titled title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        block(heading: heading(title, score: nil), content: content)
    }

    private func block<Content: View>(
        heading: some View,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Board.headingGap) {
            heading

            content()
        }
    }

    /// Whether a set is numbered is the ruleset's answer and not the count of
    /// the sets played: a match to two sets stopped inside its first one is
    /// still a match of two.
    private func heading(of set: SetCourse, number: Int) -> some View {
        let numbered = match.match.ruleset.isMultiSet

        return heading(
            numbered ? "Set \(number)" : "How it went", score: numbered ? set.score : nil)
    }

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

    private func games(of set: SetCourse, isLast: Bool) -> some View {
        VStack(spacing: Board.stepGap) {
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

    private func counts(_ score: SideCounts, taken: Side) -> Text {
        numeral(score[.us], lit: taken == .us)
            + Text(verbatim: " : ").foregroundStyle(Color.courtInk.weight(.tertiary))
            + numeral(score[.them], lit: taken == .them)
    }

    /// Verbatim: a numeral standing on its own is not a sentence, and a catalog
    /// that carried a key of "%lld" would be carrying nothing.
    private func numeral(_ count: Int, lit: Bool) -> Text {
        Text(verbatim: "\(count)")
            .foregroundStyle(Color.courtInk.weight(lit ? .primary : .secondary))
    }

    /// - Parameter written: Written out by the caller, because the two callers
    ///   hold two types — a tiebreak is `SideCounts` and an unfinished game is
    ///   `Points`, and all they share is that the phone can write both.
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

    private func won(by side: Side) -> Text {
        side == .us ? Text("we won") : Text("opponents won")
    }

    private var wasStoppedMidGame: Bool { !state.points.isEmpty }

    /// Inside a set, points are a game's — except at 6:6, where they are a
    /// tiebreak's, and a tiebreak is not a game.
    private var unfinishedTitle: LocalizedStringKey {
        switch state.points {
        case .game: "Game unfinished"
        case .count: "Tiebreak unfinished"
        }
    }

    private var nothingPlayed: some View {
        Text("No rallies played")
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.secondary))
    }

    // MARK: The ground

    private var ground: some View {
        Color.night
            .overlay { Floodlight(corner: .topTrailing, strength: Board.floodlight) }
            .ignoresSafeArea()
    }
}

/// The card has no board of its own: the page's numbers are the history
/// board's, the screen this one is opened from, and the bands' are its tiles'
/// brought down to the size of a line.
private enum Board {
    static let inset: CGFloat = 20

    static let titleGap: CGFloat = 8

    static let courseGap: CGFloat = 28

    static let blockGap: CGFloat = 22

    static let headingGap: CGFloat = 10

    static let lineGap: CGFloat = 6

    static let stepGap: CGFloat = 3

    static let runGap: CGFloat = 12

    static let bandHeight: CGFloat = 34

    static let bandPadding: CGFloat = 14

    /// A band's corner. The history tile's 24 is a radius for something the
    /// size of a card; at a band's height it would be a capsule.
    static let bandRadius: CGFloat = 10

    static let floodlight: Double = 0.13
}

#if DEBUG

private func card(_ match: SavedMatch) -> some View {
    NavigationStack { MatchCard(match: match) }
}

private func cardInRussian(_ match: SavedMatch) -> some View {
    inRussian(card(match))
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

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

#Preview("In a wide window", traits: .landscapeLeft) { card(.preview(twoSetsWonBy: .us)) }

#Preview("In Russian, in a wide window", traits: .landscapeLeft) {
    cardInRussian(.preview(twoSetsWonBy: .us))
}

#Preview("At the largest type") { atLargestType(card(.preview(pointsTo: 16))) }

#Preview("In Russian, at the largest type") {
    atLargestType(cardInRussian(.preview(twoSetsWonBy: .us)))
}

#Preview("In Russian, at the largest type: stopped early") {
    atLargestType(cardInRussian(.previewAbandonedInTieBreak))
}

#endif
