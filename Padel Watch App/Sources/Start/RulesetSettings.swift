import PadelDesign
import PadelScoring
import SwiftUI

/// The rules, set on the page they are read from.
///
/// **A section and not a screen.** It was a pushed screen until the bar came
/// off it: hiding the navigation bar takes the Back button with it, and the
/// edge swipe did not bring the player back — a rules screen you cannot leave
/// is worse than any layout it was hiding. The rules are four controls a group
/// changes twice a year, and ``StartPages``' settings page has room for them
/// under its own title.
///
/// Every one of them is a ``PadelDesign/ChoiceRow``: a row naming its value,
/// and a page listing what that value could be. One control for the ruleset
/// and for all three numbers, because on a 198pt screen they are the same
/// act — see that control for why there is no segmented choice here and no ±
/// anywhere, and for what the crown does now that it no longer spins a
/// `Picker` in place. Those pages keep watchOS's own bar, which is what leaves
/// them a way back, and each row wears a chevron so that it says it opens one
/// before it is tapped.
///
/// The bounds on the values are set here, and that is not belt-and-braces: the
/// engine deliberately passes no judgment on what it was handed
/// (`MatchState`) — it will play a match to zero sets out as a match to one
/// rather than crash the app on court. Whether the numbers make sense is a
/// question for the screen they are chosen on.
struct RulesetSettings: View {
    @Binding var ruleset: Ruleset

    /// The numbers of both rulesets at once.
    ///
    /// The page also remembers what the player set in the other ruleset:
    /// glancing at the neighbouring case and coming back must not cost the sets
    /// already dialled in. What leaves here, though, is a single ruleset — the
    /// selected one.
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
        // What was chosen is kept at once rather than on a "Done" button:
        // there is nothing to confirm here, and the page it would sit on is
        // the one a player scrolls past on the way to a match.
        .onChange(of: numbers.ruleset, initial: false) { _, edited in ruleset = edited }
    }

    /// The ruleset and its numbers, in one card.
    ///
    /// The ruleset heads the card rather than standing above it: what it
    /// switches is the two rows under it, and a row that changes its
    /// neighbours belongs among them. Which two those are is the whole of the
    /// difference between the rulesets — the card is otherwise the same card.
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

                // The same sentence the phone puts under the score of a match
                // played by it: one rule, one name for it.
                Toggle(isOn: $numbers.goldenPoint) {
                    Text("Golden point")
                        .textStyle(.body)
                        .foregroundStyle(.ink.weight(.control))
                }
                // The rows beside it stand two texts tall and this one has a
                // switch where their value is; standing as tall as they do
                // comes with the style.
                .toggleStyle(.ball)
            } else {
                // The label names what is being counted, because what stands
                // with it is a bare numeral: "21" under "Points to win" needs
                // no letter in brackets to tie it to the ruleset's name.
                ChoiceRow(Text("Points to win"), value: $numbers.target, in: Self.targets)

                // The sentence the history already uses for this number —
                // "Serve changes every %lld rallies" — with the count left to
                // the value under it.
                ChoiceRow(
                    Text("Serve changes every"), value: $numbers.serveChangesEvery,
                    in: Self.serveChanges)
            }
        }
    }

    /// What the match will be, in words.
    ///
    /// The rows above are four settings and the reader assembles the match out
    /// of them; this says the match back. It is the one thing on the page that
    /// is read rather than aimed at, and it is set in the ramp's running text
    /// for exactly that reason.
    private var sentence: some View {
        Self.sentence(for: numbers.ruleset)
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.secondary))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The chosen rules as a sentence, generated from the ruleset rather than
    /// written out four times: the numbers in it move with the rows above.
    ///
    /// Clauses, and the counted noun is declined by the catalog — the same
    /// mechanism `MatchWording` uses on the phone, for the same reason.
    /// Russian counts a match to one set with a different noun than a match to
    /// two, and none of that is arithmetic a screen should be doing.
    ///
    /// **The match to N points borrows the phone's two clauses.** `Scoring to
    /// 16 points` and `Serve changes every 4 rallies` are already in the
    /// shared catalog, already pinned across both their ranges, and say here
    /// exactly what they say there. `MatchWording`'s rule is that the two
    /// targets must not share a key where they say *different* things; this is
    /// the other case, which that comment calls the one where a single key is
    /// right.
    private static func sentence(for ruleset: Ruleset) -> Text {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            // Six games and a tiebreak at 6:6 are `ClassicReplay`'s and not the
            // player's, which is why they are inside the clause the sets are
            // counted in rather than a row of their own.
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

    /// What the golden point does to a game, which is the clause the switch
    /// above turns over.
    private static func deuce(_ goldenPoint: Bool) -> LocalizedStringKey {
        goldenPoint ? "Deuce is one point." : "Deuce is played out to a two-point lead."
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

    /// The one gap this section owns. The card, the rows and the switch come
    /// out of `PadelDesign`, and the page's margins belong to the page.
    private enum Board {
        /// Between the card and the sentence about it. The rules board's 12px,
        /// halved — the watch artboards were 2x (`docs/design/README.md`,
        /// "Reading the boards").
        static let sentenceGap: CGFloat = 6
    }
}

#if DEBUG

/// Both rulesets in both languages, and both again at the largest type.
///
/// The section on its own ground, which is how the sentence is read: it is
/// four lines of Russian where it is three of English, and every number in it
/// moves with a row above. ``StartPages`` previews the whole page this sits
/// on, including the switch under it.
private func rules(_ ruleset: Ruleset) -> some View {
    RulesSection(ruleset: ruleset)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

/// The largest of the twelve Dynamic Type settings.
private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

/// The section with a ruleset of its own to edit, on the page's ground and
/// inside the stack the rows push their lists onto.
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

/// One set, which is the default and the shortest the sentence ever gets — and
/// the form of the noun the two languages share. Without the golden point, for
/// the longer of the two clauses about deuce.
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
