import PadelDesign
import PadelScoring
import SwiftUI

/// The court a match starts from, and the settings page under it.
///
/// The same arrangement ``ScorePages`` makes for a match already running, and
/// it is made here for the same reason: the screen that matters is one question
/// with no furniture on it, and everything else is a scroll away. On the court
/// there are two halves and a ball; the rules and whether the match goes to
/// Health are on the page below, which is where a player goes twice a year.
///
/// What opens is always the court, never the settings — that is what putting
/// the court first in the `TabView` means.
///
/// The `NavigationStack` is around the pages rather than inside one, so that a
/// list pushed by a rules row covers the paging instead of being pushed
/// underneath the page indicator.
///
/// **Nothing here hides the navigation bar.** The court has no title, which is
/// all it takes for watchOS to reserve no room for one — the court runs to the
/// glass. The settings page names itself and gets the bar, which is where a
/// page's name belongs. Hiding the bar by hand looked identical to having none
/// and cost the stack its bar model — see the comment on the `TabView`. What
/// is pushed keeps its bar, because the bar is where the Back button is and
/// the edge swipe does not answer for it; that is what the rules screen found
/// out, and ``RulesetSettings`` is what it turned into.
struct StartPages: View {
    /// The ruleset the match will start with. The rules on the settings page
    /// change it and the store remembers it: it arrives here from the previous
    /// match.
    @Binding var ruleset: Ruleset

    /// Whether the match about to be played is written to Health as a workout.
    ///
    /// A setting and not a status: the switch on the settings page is this, and
    /// the root reads it to decide whether a match gets a workout at all.
    @Binding var recordsToHealth: Bool

    /// Starts the match with the given first server.
    let onStart: (Side) -> Void

    var body: some View {
        NavigationStack {
            TabView {
                StartView(onStart: onStart)

                StartSettings(ruleset: $ruleset, recordsToHealth: $recordsToHealth)
            }
            // Vertical, because what is being said is "there is more below
            // this". The crown scrolls it, which is the one input a wrist has
            // that a finger does not.
            .tabViewStyle(.verticalPage)
            // The bar is *not* hidden here, and that is the fix rather than an
            // omission. It is drawn per page: the court names nothing and gets
            // no bar, so it still runs to the glass. Hiding it explicitly left
            // the stack with no bar to push from, and every push logged
            // "Transitioning bar did not exist during transition" and
            // "the navigation controller is likely in a bad state" from
            // SaltUICore. The same bad state is what the rules screen's
            // missing way back was made of.
        }
    }
}

/// The page under the court: what is chosen once and then left alone — the
/// rules the match will be played by, and whether it goes to Health.
///
/// `night` with a light on it rather than more court — the language the rules
/// board is drawn in. A court means *a match is about to be played on it*, and
/// this page is where somebody has stopped to change something instead.
///
/// It scrolls, where the court does not. Everything that used to be a screen
/// behind a chevron is on it now, which is more than a watch is tall.
private struct StartSettings: View {
    @Binding var ruleset: Ruleset

    @Binding var recordsToHealth: Bool

    var body: some View {
        // The page scrolls, which the court above it does not: the rules are
        // on it now, and four rows, the sentence and the switch stand taller
        // than a watch. The crown scrolls this; a swipe past its end turns
        // back to the court.
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RulesetSettings(ruleset: $ruleset).padding(.top, Board.titleGap)

                // A card of its own, under the sentence rather than among the
                // rules: what the rules are is one subject, and whether the
                // match is written to Health is another.
                SettingsCard { health }.padding(.top, Board.cardGap)
            }
            .padding(.horizontal, Board.inset)
            .padding(.bottom, Board.inset)
        }
        .background {
            Color.night
                // The rules board's light: softer than the court's, and from
                // the same corner. It is what keeps a page of `night` from
                // being a black rectangle with a card on it.
                .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
                .ignoresSafeArea()
        }
        .navigationTitle("Settings")
    }

    /// Whether the match is written to Health.
    ///
    /// A `Toggle` wearing ``PadelDesign/BallSwitch``, which is the one system
    /// control the redesign keeps — see ``PadelDesign/SettingsCard``, whose
    /// doc comment makes that argument.
    ///
    /// Worded as what the app will do rather than as a name for a feature:
    /// "Health" on its own is a noun two languages decline differently, and
    /// the row has to say what turning it off costs.
    private var health: some View {
        Toggle(isOn: $recordsToHealth) {
            Text("Record to Health")
                .textStyle(.control)
                .foregroundStyle(.ink.weight(.control))
                // Two lines at the default setting already, in both
                // languages: the switch takes a third of the row and what is
                // left is narrower than the sentence. The scale factor is for
                // the settings past that, where a third line would push the
                // switch off the card.
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        // The row's own height comes with the style, which is where the
        // number that keeps a switch standing among taller rows lives.
        .toggleStyle(.ball)
    }
}

/// What the start and rules boards drew on a settings page that no token
/// covers, with their pixels halved — the watch artboards were 2x
/// (`docs/design/README.md`, "Reading the boards"). Both were deleted when
/// these screens shipped.
///
/// The card, its radius and its dividers come out of `PadelDesign`, and the
/// rules bring their own gap. What is left is the page's own margins.
private enum Board {
    /// Left and right of the page, and under the last card. The board's 16px.
    static let inset: CGFloat = 8

    /// Between the navigation bar and the first card. The rules board gave
    /// the title a 46px band and started the controls under it.
    static let titleGap: CGFloat = 10

    /// Between one card and the next. The board's 12px, which is also the gap
    /// the rules leave between their card and the sentence under it.
    static let cardGap: CGFloat = 6

    /// How much light the corner spends. The rules board's 0.12, which is the
    /// bottom of the range `Floodlight` documents: there is no court here for
    /// it to cross.
    static let floodlight: Double = 0.12
}

#if DEBUG

/// Every ruleset in both languages, because the words are what this page is
/// made of: four rows whose labels are longer in Russian — "Смена подачи
/// через" is the widest of them — and under them a sentence that declines its
/// own nouns.
///
/// The default ruleset is one set, which is the shortest the sentence ever
/// gets and the one form of the noun Russian shares with English. Two sets is
/// here as well, for the declined noun and the longer line.
///
/// What to look for is the page's *length*: title, card, sentence and switch
/// are taller than every watch, so all four previews scroll — and the switch
/// at the foot has to be reachable.
private func start(_ ruleset: Ruleset, recordsToHealth: Bool = true) -> some View {
    StartScreen(ruleset: ruleset, recordsToHealth: recordsToHealth)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

/// The largest of the twelve Dynamic Type settings, which is where the rows'
/// labels find their second line and the switch's own label finds its second.
private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

/// The pages with a ruleset and a switch of their own to change, so that a
/// preview can scroll down, open a value's list and come back.
private struct StartScreen: View {
    @State var ruleset: Ruleset

    @State var recordsToHealth: Bool

    var body: some View {
        StartPages(
            ruleset: $ruleset, recordsToHealth: $recordsToHealth, onStart: { _ in })
    }
}

#Preview("Classic scoring") { start(.defaultClassic) }

#Preview("In Russian: classic scoring") { inRussian(start(.defaultClassic)) }

#Preview("Two sets") { start(.classic(setsToWin: 2, goldenPoint: false)) }

#Preview("In Russian: two sets") {
    inRussian(start(.classic(setsToWin: 2, goldenPoint: false)))
}

#Preview("The match to N points") { start(.pointsTo(target: 21, serveChangesEvery: 2)) }

#Preview("In Russian: the match to N points") {
    inRussian(start(.pointsTo(target: 21, serveChangesEvery: 2)))
}

// Both rulesets and both languages again at the far end of the type range.
// Two sets rather than one, because it is the wider of the two classic
// sentences in both languages.

#Preview("At the largest type: two sets") {
    atLargestType(start(.classic(setsToWin: 2, goldenPoint: true)))
}

#Preview("In Russian, at the largest type: two sets") {
    atLargestType(inRussian(start(.classic(setsToWin: 2, goldenPoint: true))))
}

#Preview("At the largest type: the match to N points") {
    atLargestType(start(.pointsTo(target: 21, serveChangesEvery: 2)))
}

#Preview("In Russian, at the largest type: the match to N points") {
    atLargestType(inRussian(start(.pointsTo(target: 21, serveChangesEvery: 2))))
}

/// The switch off, which is the one state of this page the rulesets do not
/// cover.
#Preview("Health turned off") { start(.defaultClassic, recordsToHealth: false) }

#endif
