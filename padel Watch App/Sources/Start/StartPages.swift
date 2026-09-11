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
/// The `NavigationStack` is around the pages rather than inside one, so that
/// the rules screen pushed from the settings page covers the paging instead of
/// being pushed underneath the page indicator. Its bar is hidden: neither page
/// has a title on the board, and hiding the bar costs nothing — the edge-swipe
/// back belongs to the stack and not to the bar.
struct StartPages: View {
    /// The ruleset the match will start with. The rules screen changes it and
    /// the store remembers it: it arrives here from the previous match.
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
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// The page under the court: what is chosen once and then left alone.
///
/// `night` with a light on it rather than more court — the language the rules
/// board is drawn in. A court means *a match is about to be played on it*, and
/// this page is where somebody has stopped to change something instead.
private struct StartSettings: View {
    @Binding var ruleset: Ruleset

    @Binding var recordsToHealth: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Board.titleGap) {
            // The board's 0.8, which is `control` to two hundredths. Borrowing
            // a control's name for a title is the ink vocabulary's gap rather
            // than this page's — `ScoreView` says the same about the sets
            // digit it draws at the same weight.
            Text("Settings")
                .textStyle(.display)
                .foregroundStyle(.ink.weight(.control))
                .lineLimit(1)

            SettingsCard {
                NavigationLink {
                    RulesetView(ruleset: $ruleset)
                } label: {
                    rules
                }
                .buttonStyle(.plain)

                health
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Board.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            Color.night
                // The rules board's light: softer than the court's, and from
                // the same corner. It is what keeps a page of `night` from
                // being a black rectangle with a card on it.
                .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
                .ignoresSafeArea()
        }
    }

    /// The rules are visible without needing to be touched: the row says what
    /// we are playing by today, and opens the screen where that is changed.
    ///
    /// **The one chevron in the app.** `ChoiceRow` argues at length that a
    /// value drawn in `ball` is its own affordance and a chevron beside it
    /// would be the system's furniture back again. That row shows what is
    /// chosen; this one shows what is *set* and leads somewhere else entirely,
    /// and it is the only row here that leads anywhere. The board draws the
    /// chevron on this row alone.
    private var rules: some View {
        HStack(spacing: Board.rowGapToChevron) {
            VStack(alignment: .leading, spacing: Board.rulesGap) {
                Text(Self.name(of: ruleset))
                    .textStyle(.control)
                    .foregroundStyle(.ink)
                    // A name is one line by right: it is short in both
                    // languages, and a name broken across two would stop
                    // looking like one.
                    .lineLimit(1)

                // The numbers below take a second line rather than an
                // ellipsis. At the largest type this row does not fit one line
                // in either language — "2 sets · No golden point" is as long as
                // "2 сета · Без золотого очка" — and of the two ways out, the
                // one that hides the golden point is the wrong one.
                Self.parameters(of: ruleset)
                    .textStyle(.caption)
                    .foregroundStyle(.ink.weight(.secondary))
                    .lineLimit(2)
            }
            .multilineTextAlignment(.leading)
            .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            chevron
        }
        .frame(maxWidth: .infinity, minHeight: Board.rowHeight, alignment: .leading)
        .contentShape(Rectangle())
        // One stop and not two: VoiceOver reading the name and then the
        // numbers as separate rows is a way of hearing this and not knowing it
        // opens anything.
        .accessibilityElement(children: .combine)
    }

    /// The chevron in its well.
    ///
    /// The system's glyph, unlike the ball: a chevron is not a character this
    /// app has an opinion about, it is the mark every platform uses for "this
    /// leads somewhere", and `chevron.forward` turns itself round in a
    /// right-to-left layout for free.
    ///
    /// It does not grow with the type beside it. The well is furniture at the
    /// end of a row, and at the largest setting a circle that kept pace with
    /// the sentence would take the row the sentence needs.
    private var chevron: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: Board.chevron, weight: .semibold))
            .foregroundStyle(.ink.weight(.control))
            .frame(width: Board.chevronWell, height: Board.chevronWell)
            // The board's 0.14. `surface` is 0.12 and is the weight this
            // vocabulary has for a translucent panel — two hundredths apart is
            // one weight drawn twice, which is the rule `InkWeight` states
            // about its own collapses.
            .background(Circle().fill(.ink.weight(.surface)))
    }

    /// Whether the match is written to Health.
    ///
    /// A `Toggle` tinted `ball`, which is the one system control the redesign
    /// keeps — see ``PadelDesign/SettingsCard``, whose doc comment makes that
    /// argument and names the knob colour to check it against.
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
        .tint(.ball)
        .frame(minHeight: Board.rowHeight)
    }

    // MARK: The words for a ruleset

    /// The name of the ruleset. Numbers are not substituted in: "Scoring to 21
    /// points" would have to decline the noun, whereas "Point scoring" is a
    /// name — it says how the match is scored and leaves how far it runs to
    /// the row below.
    ///
    /// It is the name the screens use and not the glossary's own. `CONTEXT.md`
    /// calls this ruleset "the match to N points", which is what the code says
    /// throughout; the letters are notation for reading the source and were
    /// never much of a name to be shown a player.
    ///
    /// The phone names a ruleset too, and says something else on purpose: here
    /// one is about to be chosen and the numbers stay out of its name, there a
    /// match is already played and the numbers are what make its score
    /// readable. The shared catalog puts the phone's "Classic scoring · 2 sets"
    /// within reach and does not make it this sentence.
    private static func name(of ruleset: Ruleset) -> LocalizedStringKey {
        switch ruleset {
        case .classic: "Classic scoring"
        case .pointsTo: "Point scoring"
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
            // Clauses, like the classic side above, and for the same reason:
            // both nouns are declined by the catalog. This row used to read
            // "N = 16 · X = 4", which was the notation the name above and the
            // rules screen called these two numbers by — and neither says a
            // letter any more.
            Text("\(target) points")
                + Text(verbatim: " · ")
                + Text("Serve changes every \(serveChangesEvery) rallies")
        }
    }

    /// Whether the golden point is on. The phone says this on its card about a
    /// match already played, and it is the same sentence rather than a copy of
    /// one: the rule has one name, whichever screen names it.
    private static func goldenPoint(_ isOn: Bool) -> LocalizedStringKey {
        isOn ? "Golden point" : "No golden point"
    }
}

/// What `Main.dc.html` and `WatchRules.dc.html` draw on a settings page that no
/// token covers, with the board's pixels halved — the watch artboards are 2x
/// (the spec's "Reading the boards").
///
/// The card, its radius and its dividers come out of `PadelDesign`. What is
/// left is the chevron in its well, the row it sits at the end of, and the
/// page's own margins.
private enum Board {
    /// Left and right of the page. `WatchRules.dc.html`'s 16px.
    static let inset: CGFloat = 8

    /// Between the title and the card under it. The rules board gives the
    /// title a 46px band and starts the controls under it.
    static let titleGap: CGFloat = 10

    /// A row in the card: 64px on the rules board, and the least the row may
    /// be rather than its height. Two lines of the ramp are already taller
    /// than it at the default setting; at the smallest of the twelve they are
    /// not, and a row that shrank with them would stop being a target.
    static let rowHeight: CGFloat = 32

    /// Between the ruleset's name and its numbers. 2px.
    static let rulesGap: CGFloat = 1

    /// Between what a row says and the chevron at its trailing edge. 10px.
    static let rowGapToChevron: CGFloat = 5

    /// The well the chevron sits in. 26px.
    static let chevronWell: CGFloat = 13

    /// The chevron in it.
    ///
    /// The board's is a 14px box holding a glyph 12 units of 24 tall — about
    /// 3.5pt of actual chevron. SF's is measured by type size rather than by
    /// its box, and 9pt is where it lands on about the same height.
    static let chevron: CGFloat = 9

    /// How much light the corner spends. The rules board's 0.12, which is the
    /// bottom of the range `Floodlight` documents: there is no court here for
    /// it to cross.
    static let floodlight: Double = 0.12
}

#if DEBUG

/// Every ruleset in both languages, because the row under the name is where
/// this page runs out of width: it is a caption already leaning on
/// `minimumScaleFactor`, and the two languages are longer than each other in
/// different places — "Classic scoring" is shorter than "Классический счёт",
/// "Point scoring" shorter than "Счёт по очкам", and the row under the match
/// to N points carries two declined clauses.
///
/// The default ruleset is one set, which is the shortest this row ever gets
/// and the one form of the noun Russian shares with English. Two sets is here
/// as well, for the wider line and the declined noun.
private func start(_ ruleset: Ruleset, recordsToHealth: Bool = true) -> some View {
    StartScreen(ruleset: ruleset, recordsToHealth: recordsToHealth)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

/// The largest of the twelve Dynamic Type settings, which is where the rules
/// row finds its second and third lines and the switch's own label finds its
/// second.
private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

/// The pages with a ruleset and a switch of their own to change, so that a
/// preview can scroll down, push into the rules screen and come back.
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
// Two sets rather than one, because it is the wider of the two classic rows in
// both languages.

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
