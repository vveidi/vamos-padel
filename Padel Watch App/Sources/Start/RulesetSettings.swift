import PadelDesign
import PadelScoring
import SwiftUI

/// The only place the rules are bounded: ``PadelScoring`` passes no judgment
/// on a ruleset, and plays a match to zero sets out as a match to one rather
/// than trapping on court.
struct RulesetSettings: View {
    @Binding var ruleset: Ruleset

    /// Both rulesets' numbers, so that glancing at the other one and coming
    /// back does not cost what was already dialled into this one.
    @State private var numbers: Numbers

    init(ruleset: Binding<Ruleset>) {
        _ruleset = ruleset
        _numbers = State(initialValue: Numbers(ruleset.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Board.sentenceGap) {
            card

            sentence
        }
        .onChange(of: numbers.ruleset, initial: false) { _, edited in ruleset = edited }
    }

    private var card: some View {
        SettingsCard {
            ChoiceRow(
                Text("Scoring"),
                selection: $numbers.isClassic,
                options: [
                    .init(Text("Classic"), value: true),
                    .init(Text("By points"), value: false),
                ])

            if numbers.isClassic {
                ChoiceRow(Text("Sets"), value: $numbers.setsToWin, in: Self.setsToWin)

                Toggle(isOn: $numbers.goldenPoint) {
                    Text("Golden point")
                        .textStyle(.body)
                        .foregroundStyle(.ink.weight(.control))
                }
                .toggleStyle(.ball)
            } else {
                ChoiceRow(Text("Points to win"), value: $numbers.target, in: Self.targets)

                ChoiceRow(
                    Text("Serve changes every"), value: $numbers.serveChangesEvery,
                    in: Self.serveChanges)
            }
        }
    }

    private var sentence: some View {
        Self.sentence(for: numbers.ruleset)
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.secondary))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Whole clauses, so the catalog declines the counted noun. The two
    /// `pointsTo` keys are the phone's own: shared deliberately, because here
    /// they say exactly what they say there.
    private static func sentence(for ruleset: Ruleset) -> Text {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            // Six games and the tiebreak at 6:6 are ``ClassicReplay``'s, not
            // the player's — hence inside the clause rather than a row.
            Text("First to \(setsToWin) sets. A set is 6 games, a tiebreak at 6:6.")
                + Text(verbatim: " ")
                + Text(Self.deuce(goldenPoint))

        case .pointsTo(let target, let serveChangesEvery):
            Text("Scoring to \(target) points")
                + Text(verbatim: ". ")
                + Text("Serve changes every \(serveChangesEvery) rallies")
                + Text(verbatim: ".")
        }
    }

    private static func deuce(_ goldenPoint: Bool) -> LocalizedStringKey {
        goldenPoint ? "Deuce is one point." : "Deuce is played out to a two-point lead."
    }

    /// Three sets won is five played, padel's full professional format, and
    /// the score screen sizes the set digit for one column.
    private static let setsToWin = 1...3

    /// Below five points the match ends before the serve changes hands once.
    private static let targets = 5...40

    /// "In different groups it is 2 or 4" — the spec.
    private static let serveChanges = 1...6

    private struct Numbers {
        var isClassic = true
        var setsToWin = 0
        var goldenPoint = false
        var target = 0
        var serveChangesEvery = 0

        init(_ ruleset: Ruleset) {
            take(.defaultClassic)
            take(.defaultPointsTo)

            // Last, because `take` also sets which of the two is selected.
            take(ruleset)
        }

        var ruleset: Ruleset {
            isClassic
                ? .classic(setsToWin: setsToWin, goldenPoint: goldenPoint)
                : .pointsTo(target: target, serveChangesEvery: serveChangesEvery)
        }

        /// Takes the numbers of a ruleset without touching the other's.
        private mutating func take(_ ruleset: Ruleset) {
            switch ruleset {
            case .classic(let setsToWin, let goldenPoint):
                isClassic = true
                self.setsToWin = setsToWin
                self.goldenPoint = goldenPoint
            case .pointsTo(let target, let serveChangesEvery):
                isClassic = false
                self.target = target
                self.serveChangesEvery = serveChangesEvery
            }
        }
    }

    private enum Board {
        /// The rules board's 12px halved — the watch artboards were 2x
        /// (`docs/design/README.md`, "Reading the boards").
        static let sentenceGap: CGFloat = 6
    }
}

#if DEBUG

private func rules(_ ruleset: Ruleset) -> some View {
    RulesSection(ruleset: ruleset)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private struct RulesSection: View {
    @State var ruleset: Ruleset

    var body: some View {
        NavigationStack {
            ScrollView {
                RulesetSettings(ruleset: $ruleset).padding(.horizontal, 8)
            }
            .background(Color.night.ignoresSafeArea())
        }
    }
}

#Preview("Classic scoring") { rules(.classic(setsToWin: 2, goldenPoint: true)) }

#Preview("In Russian: classic scoring") {
    inRussian(rules(.classic(setsToWin: 2, goldenPoint: true)))
}

#Preview("A single set") { rules(.classic(setsToWin: 1, goldenPoint: false)) }

#Preview("In Russian: a single set") {
    inRussian(rules(.classic(setsToWin: 1, goldenPoint: false)))
}

#Preview("The match to N points") { rules(.defaultPointsTo) }

#Preview("In Russian: the match to N points") { inRussian(rules(.defaultPointsTo)) }

#Preview("At the largest type") {
    atLargestType(rules(.classic(setsToWin: 2, goldenPoint: true)))
}

#Preview("In Russian, at the largest type") {
    atLargestType(inRussian(rules(.classic(setsToWin: 2, goldenPoint: true))))
}

#Preview("In Russian, at the largest type: the match to N points") {
    atLargestType(inRussian(rules(.defaultPointsTo)))
}

#endif
