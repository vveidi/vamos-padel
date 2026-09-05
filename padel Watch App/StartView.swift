import PadelScoring
import SwiftUI

/// The screen a match starts from.
///
/// Speed is what matters here. A group plays by the same rules for months, so
/// the previous match's rules are already filled in and the only thing asked is
/// what changes every time — whose serve is first. That same answer starts the
/// match: the tap by which the player names the serving side is exactly the
/// "start with one tap". A separate "Start" button next to the serve choice
/// would be a second tap that says nothing new.
///
/// The rules screen sits behind a navigation push: a setting asked before every
/// match is a tax paid for something that happens twice a year.
struct StartView: View {
    /// The ruleset the match will start with. The rules screen changes it and
    /// the store remembers it: it arrives here from the previous match.
    @Binding var ruleset: Ruleset

    /// Starts the match with the given first server.
    let onStart: (Side) -> Void

    var body: some View {
        NavigationStack {
            List {
                // The opponents on top, us at the bottom — the same as on the
                // score screen and the same as on court: they are across the
                // net, in front of us. The colors are the same, so the half
                // the player will be tapping for their own points all match is
                // recognizable before the first rally.
                serve(.them)
                serve(.us)

                NavigationLink {
                    RulesetView(ruleset: $ruleset)
                } label: {
                    rules
                }
            }
            // The same words the outcome screen's button promises, and for
            // the same reason it is short: at the largest type "Start a match"
            // takes two lines on the smallest watch and the list scrolls over
            // the second one.
            .navigationTitle("New match")
        }
    }

    private func serve(_ side: Side) -> some View {
        Button {
            onStart(side)
        } label: {
            Text(Self.serves(side))
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(side == .us ? ScoreView.ourColor.opacity(0.35) : .white.opacity(0.12)))
    }

    /// Whose serve it is, as a whole sentence per side rather than a side's
    /// name dropped into a frame: English puts the side before the verb and
    /// Russian after it, and there is no frame that survives the move.
    private static func serves(_ side: Side) -> LocalizedStringKey {
        side == .us ? "We serve" : "Opponents serve"
    }

    /// The rules are visible without needing to be touched: the row says what
    /// we are playing by today, and opens the screen where that is changed.
    private var rules: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(Self.name(of: ruleset))
                .font(.footnote)
                // A name is one line by right: it is short in both languages,
                // and a name broken across two would stop looking like one.
                .lineLimit(1)

            // The numbers below take a second line rather than an ellipsis.
            // At the largest type this row does not fit one line in either
            // language — "2 sets · No golden point" is as long as "2 сета ·
            // Без золотого очка" — and of the two ways out, the one that hides
            // the golden point is the wrong one.
            Self.parameters(of: ruleset)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .minimumScaleFactor(0.7)
    }

    /// The name of the ruleset — the one the glossary gives it. Numbers are
    /// not substituted in: "Scoring to 21 points" would have to decline the
    /// noun, whereas "Match to N points" is a name, and the N in it explains
    /// the row below.
    ///
    /// The phone names a ruleset too, and says something else on purpose: here
    /// one is about to be chosen and the numbers stay out of its name, there a
    /// match is already played and the numbers are what make its score
    /// readable. The shared catalog puts the phone's "Classic scoring · 2 sets"
    /// within reach and does not make it this sentence.
    private static func name(of ruleset: Ruleset) -> LocalizedStringKey {
        switch ruleset {
        case .classic: "Classic scoring"
        case .pointsTo: "Match to N points"
        }
    }

    /// The numbers under the name: whole clauses with a separator between
    /// them, and not a line assembled out of words. The count of the sets is
    /// one such clause, and its noun is declined by the catalog — this row used
    /// to carry a hand-written two of the four forms Russian has.
    private static func parameters(of ruleset: Ruleset) -> Text {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            Text("\(setsToWin) sets")
                + Text(verbatim: " · ")
                + Text(Self.goldenPoint(goldenPoint))

        case .pointsTo(let target, let serveChangesEvery):
            // Letters and not words: N and X are the notation the name above
            // and the rules screen call the two numbers by, and they read the
            // same in both languages.
            Text(verbatim: "N = \(target) · X = \(serveChangesEvery)")
        }
    }

    /// Whether the golden point is on. The phone says this on its card about a
    /// match already played, and it is the same sentence rather than a copy of
    /// one: the rule has one name, whichever screen names it.
    private static func goldenPoint(_ isOn: Bool) -> LocalizedStringKey {
        isOn ? "Golden point" : "No golden point"
    }
}

#if DEBUG

/// Every ruleset in both languages, because the row under the name is where
/// this screen runs out of width: it is a caption already leaning on
/// `minimumScaleFactor`, and the two languages are longer than each other in
/// different places — "Classic scoring" is shorter than "Классический счёт",
/// "Match to N points" longer than "Счёт до N очков".
///
/// The default ruleset is one set, which is the shortest this row ever gets
/// and the one form of the noun Russian shares with English. Two sets is here
/// as well, for the wider line and the declined noun.
private func start(_ ruleset: Ruleset) -> some View {
    StartScreen(ruleset: ruleset)
}

private func startInRussian(_ ruleset: Ruleset) -> some View {
    start(ruleset).environment(\.locale, Locale(identifier: "ru"))
}

/// The screen with a ruleset of its own to change, so that a preview can be
/// pushed into the rules screen and come back.
private struct StartScreen: View {
    @State var ruleset: Ruleset

    var body: some View {
        StartView(ruleset: $ruleset, onStart: { _ in })
    }
}

#Preview("Classic scoring") { start(.defaultClassic) }

#Preview("In Russian: classic scoring") { startInRussian(.defaultClassic) }

#Preview("Two sets") { start(.classic(setsToWin: 2, goldenPoint: false)) }

#Preview("In Russian: two sets") { startInRussian(.classic(setsToWin: 2, goldenPoint: false)) }

#Preview("The match to N points") { start(.pointsTo(target: 21, serveChangesEvery: 2)) }

#Preview("In Russian: the match to N points") {
    startInRussian(.pointsTo(target: 21, serveChangesEvery: 2))
}

#endif
