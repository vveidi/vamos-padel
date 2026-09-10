import PadelScoring
import SwiftUI

// The five controls, drawn.
//
// Two boards and four previews, and the four are the point. These controls
// are where the app's words live — every one of them is handed a phrase by a
// screen — and a control is only as good as the longest phrase it is handed.
// So each board is drawn twice over, once in each language, and again at the
// largest Dynamic Type setting: "Serve after (X)" against "Подача через (X)"
// is the widest pair in the app, and the rules screen at the largest setting
// is where it has historically run out of width.
//
// What to look for at `.accessibility5`: nothing clipped and nothing cut off.
// The segments drop under each other, the stepper rows put their ± under the
// label, and the pills grow rather than trimming their verb.
//
// The words are `Text(verbatim:)` and not keys. This package owns no catalog —
// the screens do the speaking (see `SegmentedChoice.Option`) — so the Russian
// here is the same Russian `Shared/Localizable.xcstrings` holds, copied in as
// the words these controls will really be given.

// MARK: - The words

/// One board's worth of phrases.
private struct Words {
    /// What the ruleset choice says.
    ///
    /// A type and not a tuple, because it is three fields and the third is the
    /// one only one board spends: the watch names the choice on its row before
    /// opening the page, and the phone's segments carry no label above them.
    struct Scoring {
        let label: String
        let classic: String
        let toNPoints: String
    }

    let scoring: Scoring
    let sets: String
    let points: String
    let serveAfter: String
    let goldenPoint: String
    let newMatch: String
    let end: String
    let keepPlaying: String
    let ruleset: (classic: String, toNPoints: String)
    let stopped: String
    let day: String
    let duration: String

    static let english = Words(
        scoring: .init(label: "Scoring", classic: "Classic", toNPoints: "To N points"),
        sets: "Sets",
        points: "Points (N)",
        serveAfter: "Serve after (X)",
        goldenPoint: "Golden point",
        newMatch: "New match",
        end: "End",
        keepPlaying: "Keep playing",
        ruleset: (classic: "Classic scoring · 2 sets", toNPoints: "Scoring to 21 points"),
        stopped: "Match unfinished",
        day: "9 September",
        duration: "1 h 12 min")

    static let russian = Words(
        scoring: .init(label: "Счёт", classic: "Классический", toNPoints: "До N очков"),
        sets: "Сеты",
        points: "Очков (N)",
        serveAfter: "Подача через (X)",
        goldenPoint: "Золотое очко",
        newMatch: "Новый матч",
        end: "Завершить",
        keepPlaying: "Играть дальше",
        ruleset: (classic: "Классический счёт · 2 сета", toNPoints: "Счёт до 21 очка"),
        stopped: "Матч не доигран",
        day: "9 сентября",
        duration: "1 ч 12 мин")
}

/// The one system control the redesign keeps, tinted — what ``SettingsCard``
/// documents rather than wraps.
///
/// Shared by both boards on purpose: the golden point is the one row that does
/// *not* part company between the platforms, and drawing it twice is how two
/// rows that ought to match drift apart.
@MainActor private func toggle(words: Words, isOn: Binding<Bool>) -> some View {
    Toggle(isOn: isOn) {
        Text(verbatim: words.goldenPoint)
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.control))
    }
    .tint(.ball)
    // The watch's rows stand two texts tall, and this one has a switch where
    // their value is: asking for their height is what keeps the last row of
    // the card from sitting short. On the phone the number is `rowHeight`.
    .frame(minHeight: ControlMetrics.stackedRowHeight)
}

// MARK: - The watch's rows

#if os(watchOS)

    /// The watch's whole rules screen worth of furniture: four rows in a card,
    /// each one opening a page. Nothing here is a segment and nothing is a ± .
    ///
    /// What to look for: every row two texts tall, the chosen value lit in
    /// `ball` on the second line — the only lit thing on the row, and the
    /// whole of the affordance, because the brief allows no chevron — and the
    /// golden point standing as tall as the four rows above it with only its
    /// own label to fill the height. Then open "Points (N)" and check that the
    /// page arrives already scrolled to 16 rather than at 5.
    private struct RowsBoard: View {
        let words: Words

        @State private var isClassic = true
        @State private var sets = 2
        @State private var points = 16
        @State private var serveAfter = 4
        @State private var goldenPoint = true

        var body: some View {
            NavigationStack {
                ScrollView {
                    SettingsCard {
                        ChoiceRow(
                            Text(verbatim: words.scoring.label),
                            selection: $isClassic,
                            options: [
                                .init(Text(verbatim: words.scoring.classic), value: true),
                                .init(Text(verbatim: words.scoring.toNPoints), value: false),
                            ])

                        ChoiceRow(Text(verbatim: words.sets), value: $sets, in: 1...3)

                        // The row the pushed page exists for: 36 values, which
                        // is 35 taps of a ± and one turn of the crown.
                        ChoiceRow(Text(verbatim: words.points), value: $points, in: 5...40)

                        ChoiceRow(
                            Text(verbatim: words.serveAfter), value: $serveAfter, in: 1...6)

                        toggle(words: words, isOn: $goldenPoint)
                    }
                    .padding()
                }
                .background(Color.night)
            }
        }
    }

    #Preview("The rows") { RowsBoard(words: .english) }

    #Preview("The rows, in Russian") { RowsBoard(words: .russian) }

    #Preview("The rows, largest type") {
        RowsBoard(words: .russian).environment(\.dynamicTypeSize, .accessibility5)
    }

#endif

// MARK: - The phone's controls

#if !os(watchOS)

/// The choice, the card and the two buttons — the phone's furniture, live: the
/// segments switch and the ± move.
private struct ControlsBoard: View {
    let words: Words

    @State private var isClassic = true
    @State private var sets = 2
    @State private var points = 16
    @State private var serveAfter = 4
    @State private var goldenPoint = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SegmentedChoice(
                    selection: $isClassic,
                    .init(Text(verbatim: words.scoring.classic), value: true),
                    .init(Text(verbatim: words.scoring.toNPoints), value: false))

                SettingsCard {
                    StepperRow(Text(verbatim: words.sets), value: $sets, in: 1...3)

                    // 36 values behind a ± , which a thumb can cross and a
                    // wrist cannot — the reason the watch opens a page for
                    // this row instead.
                    StepperRow(Text(verbatim: words.points), value: $points, in: 5...40)

                    StepperRow(
                        Text(verbatim: words.serveAfter), value: $serveAfter, in: 1...6)

                    toggle(words: words, isOn: $goldenPoint)
                }

                PillButton(Text(verbatim: words.newMatch), carriesBall: true) {}

                PillButton(Text(verbatim: words.end), variant: .quiet) {}

                PillButton(Text(verbatim: words.keepPlaying), variant: .quiet) {}
            }
            .padding()
        }
        .background(Color.night)
    }
}

#Preview("The controls") { ControlsBoard(words: .english) }

#Preview("In Russian") { ControlsBoard(words: .russian) }

#Preview("The controls, largest type") {
    ControlsBoard(words: .english).environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("In Russian, largest type") {
    ControlsBoard(words: .russian).environment(\.dynamicTypeSize, .accessibility5)
}

#endif

// MARK: - The history

/// The three tints in a column, which is the only way to see the argument they
/// make: a won match, a lost one and one stopped early, read as a season
/// before a number has been read.
private struct TilesBoard: View {
    let words: Words

    private let outcomes: [MatchOutcome] = [
        .finished(winner: .us), .finished(winner: .them), .abandoned,
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Array(outcomes.enumerated()), id: \.offset) { _, outcome in
                    CourtTile(outcome: outcome, action: {}, content: { tile(outcome) })
                }
            }
            .padding()
        }
        .background(Color.night)
    }

    /// What ticket 08 will really put on a tile: the score, the rules that
    /// make it readable, and when it was played.
    private func tile(_ outcome: MatchOutcome) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: score(outcome))
                    .textStyle(.tileScore)
                    .foregroundStyle(ink(outcome))

                Text(verbatim: outcome == .abandoned ? words.stopped : words.ruleset.classic)
                    .textStyle(.caption)
                    .foregroundStyle(.ink.weight(.secondary))
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(verbatim: words.day)
                    .textStyle(.caption)
                    .foregroundStyle(.ink.weight(.strong))

                Text(verbatim: words.duration)
                    .textStyle(.caption)
                    .foregroundStyle(.ink.weight(.tertiary))
            }
        }
    }

    private func score(_ outcome: MatchOutcome) -> String {
        switch outcome {
        case .finished(winner: .us): "2 : 1"
        case .finished(winner: .them): "0 : 2"
        case .abandoned, .inProgress: "9 : 12"
        }
    }

    /// A won score is read at full strength and the other two are not, which
    /// is the tint's argument said again in the ink.
    private func ink(_ outcome: MatchOutcome) -> Color {
        outcome == .finished(winner: .us) ? .inkOurHalf : .ink.weight(.strong)
    }
}

#Preview("The history tiles") { TilesBoard(words: .english) }

#Preview("The history tiles, in Russian") { TilesBoard(words: .russian) }

#Preview("The history tiles, largest type") {
    TilesBoard(words: .russian).environment(\.dynamicTypeSize, .accessibility5)
}
