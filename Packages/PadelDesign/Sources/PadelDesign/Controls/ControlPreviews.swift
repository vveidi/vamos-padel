import PadelScoring
import SwiftUI

// MARK: - The words

private struct Words {
    struct Scoring {
        let label: String
        let classic: String
        let byPoints: String
    }

    let scoring: Scoring
    let sets: String
    let points: String
    let serveChange: String
    let goldenPoint: String
    let newMatch: String
    let end: String
    let keepPlaying: String
    let ruleset: (classic: String, byPoints: String)
    let stopped: String
    let day: String
    let duration: String

    static let english = Words(
        scoring: .init(label: "Scoring", classic: "Classic", byPoints: "By points"),
        sets: "Sets",
        points: "Points to win",
        serveChange: "Serve changes every",
        goldenPoint: "Golden point",
        newMatch: "New match",
        end: "End",
        keepPlaying: "Keep playing",
        ruleset: (classic: "Classic scoring · 2 sets", byPoints: "Scoring to 21 points"),
        stopped: "Match unfinished",
        day: "9 September",
        duration: "1 h 12 min")

    static let russian = Words(
        scoring: .init(label: "Счёт", classic: "Классический", byPoints: "По очкам"),
        sets: "Сеты",
        points: "Очков до победы",
        serveChange: "Смена подачи через",
        goldenPoint: "Золотое очко",
        newMatch: "Новый матч",
        end: "Завершить",
        keepPlaying: "Играть дальше",
        ruleset: (classic: "Классический счёт · 2 сета", byPoints: "Счёт до 21 очка"),
        stopped: "Матч не доигран",
        day: "9 сентября",
        duration: "1 ч 12 мин")
}

@MainActor private func toggle(words: Words, isOn: Binding<Bool>) -> some View {
    Toggle(isOn: isOn) {
        Text(verbatim: words.goldenPoint)
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.control))
    }
    .toggleStyle(.ball)
}

// MARK: - The watch's rows

#if os(watchOS)

    private struct RowsBoard: View {
        let words: Words

        @State private var isClassic = true
        @State private var sets = 2
        @State private var points = 16
        @State private var serveChange = 4
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
                                .init(Text(verbatim: words.scoring.byPoints), value: false),
                            ])

                        ChoiceRow(Text(verbatim: words.sets), value: $sets, in: 1...3)

                        ChoiceRow(Text(verbatim: words.points), value: $points, in: 5...40)

                        ChoiceRow(
                            Text(verbatim: words.serveChange), value: $serveChange, in: 1...6)

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

private struct ControlsBoard: View {
    let words: Words

    @State private var isClassic = true
    @State private var sets = 2
    @State private var points = 16
    @State private var serveChange = 4
    @State private var goldenPoint = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SegmentedChoice(
                    selection: $isClassic,
                    .init(Text(verbatim: words.scoring.classic), value: true),
                    .init(Text(verbatim: words.scoring.byPoints), value: false))

                SettingsCard {
                    StepperRow(Text(verbatim: words.sets), value: $sets, in: 1...3)

                    StepperRow(Text(verbatim: words.points), value: $points, in: 5...40)

                    StepperRow(
                        Text(verbatim: words.serveChange), value: $serveChange, in: 1...6)

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

private struct TilesBoard: View {
    let words: Words

    private let outcomes: [MatchOutcome] = [
        .finished(winner: .us), .finished(winner: .them), .abandoned, .inProgress,
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

    private func tile(_ outcome: MatchOutcome) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: score(outcome))
                    .textStyle(.tileScore)
                    .foregroundStyle(Color.courtInk(outcome))

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
        case .abandoned: "9 : 12"
        case .inProgress: "1 : 1"
        }
    }
}

#Preview("The history tiles") { TilesBoard(words: .english) }

#Preview("The history tiles, in Russian") { TilesBoard(words: .russian) }

#Preview("The history tiles, largest type") {
    TilesBoard(words: .russian).environment(\.dynamicTypeSize, .accessibility5)
}
