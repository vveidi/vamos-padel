import PadelScoring
import SwiftUI

/// The rules screen: the ruleset and its parameters.
///
/// It only opens if the player went here themselves — and so it can afford a
/// list of controls, whereas the start screen can afford nothing beyond a
/// single tap.
///
/// The bounds on the values are set here, and that is not belt-and-braces: the
/// engine deliberately passes no judgment on what it was handed
/// (`MatchState`) — it will play a match to zero sets out as a match to one
/// rather than crash the app on court. Whether the numbers make sense is a
/// question for the screen they are chosen on.
struct RulesetView: View {
    @Binding var ruleset: Ruleset

    /// The numbers of both rulesets at once.
    ///
    /// The screen also remembers what the player set in the other ruleset:
    /// glancing at the neighbouring case and coming back must not cost the sets
    /// already dialled in. What leaves the screen, though, is a single
    /// ruleset — the selected one.
    @State private var numbers: Numbers

    init(ruleset: Binding<Ruleset>) {
        _ruleset = ruleset
        _numbers = State(initialValue: Numbers(ruleset.wrappedValue))
    }

    var body: some View {
        List {
            Picker("Счёт", selection: $numbers.isClassic) {
                Text("классический").tag(true)
                Text("до N очков").tag(false)
            }

            if numbers.isClassic {
                Picker("Сеты", selection: $numbers.setsToWin) {
                    ForEach(Self.setsToWin, id: \.self) { Text("\($0)") }
                }

                Toggle("Золотое очко", isOn: $numbers.goldenPoint)
            } else {
                Picker("Очков (N)", selection: $numbers.target) {
                    ForEach(Self.targets, id: \.self) { Text("\($0)") }
                }

                Picker("Подача через (X)", selection: $numbers.serveChangesEvery) {
                    ForEach(Self.serveChanges, id: \.self) { Text("\($0)") }
                }
            }
        }
        .navigationTitle("Правила")
        // What was chosen leaves at once rather than on a "Done" button: there
        // is nothing to confirm on this screen, and an extra tap is the very
        // thing it is hidden behind a push for.
        .onChange(of: numbers.ruleset, initial: false) { _, edited in ruleset = edited }
    }

    /// A match to three sets won is up to five played, the full format of
    /// professional padel. An amateur group plays no further than that, and the
    /// set score on the score screen is sized for a single digit.
    private static let setsToWin = 1...3

    /// The lower bound is not arithmetical but sporting: a match shorter than
    /// five points ends before the serve manages to change hands even once. The
    /// upper one is taken with room to spare above the longest thing agreed on
    /// on court.
    private static let targets = 5...40

    /// "In different groups it is 2 or 4" — the spec. One makes sense too: the
    /// serve passes after every rally.
    private static let serveChanges = 1...6

    /// The parameters of both rulesets separately — in the form they are
    /// edited in by the controls: each number has one of its own, while the
    /// ruleset is only assembled from them as a whole.
    private struct Numbers {
        var isClassic = true
        var setsToWin = 0
        var goldenPoint = false
        var target = 0
        var serveChangesEvery = 0

        /// The unoccupied half is filled with defaults, and they are taken
        /// from `Ruleset` itself rather than written out as numbers again:
        /// "N = 16, X = 4, one set" lives there, and it must have no second
        /// copy.
        init(_ ruleset: Ruleset) {
            take(.defaultClassic)
            take(.defaultPointsTo)

            // The selected one last: it sets not only its own numbers but also
            // which of the two rulesets is selected.
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
}

#Preview("Classic scoring") {
    @Previewable @State var ruleset = Ruleset.defaultClassic

    NavigationStack { RulesetView(ruleset: $ruleset) }
}

#Preview("The match to N points") {
    @Previewable @State var ruleset = Ruleset.defaultPointsTo

    NavigationStack { RulesetView(ruleset: $ruleset) }
}
