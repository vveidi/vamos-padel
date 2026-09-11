import os
import PadelDelivery
import PadelScoring
import PadelStorage
import SwiftUI

/// The root of the app: start → score → outcome and start again.
///
/// Here lives the single question the app answers at launch: is a match already
/// running or is there none yet. If one is, the watch returns straight to the
/// score, skipping the start: a player whose app was unloaded between games did
/// not order a start screen.
struct RootView: View {
    /// The match currently being played, as it began. `nil` means there is no
    /// match and the start screen is up.
    ///
    /// From then on the match lives in the match screen and never comes back
    /// here: it is enough for the root to know that a match exists. Handing the
    /// screen a `Binding` to this optional would look more honest — one value
    /// instead of two — but SwiftUI force-unwraps such a binding on every read.
    /// The "New match" button clears the match, the still-alive match screen
    /// reads its `Binding`, and the app crashes out of nowhere — that is how
    /// the fix after the ticket started.
    @State private var match: SavedMatch?

    /// The ruleset the next match will start with. The previous match's rules
    /// arrive here from the store first; after that the rules screen changes
    /// them.
    @State private var ruleset = Ruleset.defaultClassic

    /// Whether a match is written to Health as a workout. On unless somebody
    /// turned it off on the settings page.
    ///
    /// In `UserDefaults` rather than in the store, and that is not the store's
    /// rule being broken. `lastRuleset()` argues that the previous match's
    /// rules must not be kept beside the matches, because they are already
    /// *in* a match and a second copy would diverge from the first. This is
    /// the other kind of value: nothing about any match says it, no match can
    /// be asked for it, and it is a preference about the app rather than a
    /// fact about padel.
    @AppStorage("records-to-health") private var recordsToHealth = true

    /// The store does not answer instantly, and until it does it is not even
    /// known which screen to show. Flashing the start screen under the hand of
    /// a player who came back to a running match is a sure way to start a new
    /// one instead.
    @State private var isRestored = false

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

    /// The store, the workout and the delivery come from outside rather than
    /// being created here: a preview must neither ask for health access, nor
    /// create a database, nor bring up a session to the phone.
    init(store: any MatchStore, workout: any Workout, delivery: MatchDelivery) {
        self.store = store
        _workout = State(initialValue: workout)
        self.delivery = delivery
    }

    var body: some View {
        Group {
            if !isRestored {
                ProgressView()
            } else if let match {
                MatchView(
                    match: match,
                    store: store,
                    workout: workoutForThisMatch,
                    delivery: delivery,
                    onFinish: startOver)
                    // A different match means a different screen, from a clean
                    // slate. Without this, a match started right after the
                    // previous one would land on a screen holding the last
                    // one's state.
                    .id(match.id)
            } else {
                // The settings page gets the switch and not the workout: a
                // screen holding a `Workout` is a screen that could start one,
                // and this one only says whether the next match should.
                StartPages(
                    ruleset: $ruleset,
                    recordsToHealth: $recordsToHealth,
                    onStart: start(servedBy:))
            }
        }
        .task { restore() }
    }

    /// The workout the match runs inside, which is no workout at all when the
    /// switch is off.
    ///
    /// Turning it off is answered by handing over a `NoWorkout` rather than by
    /// teaching `HealthKitWorkout` to do nothing: that is precisely what
    /// `NoWorkout` is for, and the match screen goes on calling `start()` and
    /// `end()` without being told which of the two it is holding.
    ///
    /// Read once, when the match screen is built. Nobody can reach the switch
    /// while a match is running — the settings page is behind the start screen
    /// — so there is no setting to honour mid-match.
    private var workoutForThisMatch: any Workout {
        recordsToHealth ? workout : NoWorkout()
    }

    /// The match begins here and will reach the store with its very first
    /// rally. The ruleset is already immutable by then: a match whose rules
    /// changed mid-play is a different match.
    private func start(servedBy firstServer: Side) {
        match = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: .now)
    }

    /// Returns to the start screen. The match just played is already written
    /// down and there is nothing to lose here; the ruleset stays the same — the
    /// next match is almost certainly played by the same rules as the last.
    private func startOver() {
        match = nil
    }

    /// Restores what the app remembers: the match begun before it was
    /// unloaded, and the previous match's rules.
    ///
    /// A read failure never reaches here — for the same reason write and
    /// workout failures never reach the match: starting a new match from the
    /// defaults is worse than continuing the old one, and still better than
    /// starting nothing at all.
    private func restore() {
        do {
            match = try store.matchInProgress()
            ruleset = try store.lastRuleset() ?? .defaultClassic
        } catch {
            logger.error("the previous match was not restored: \(error.localizedDescription)")
        }

        isRestored = true
    }
}

#Preview {
    RootView(
        store: NoMatchStore(),
        workout: NoWorkout(),
        delivery: MatchDelivery(queue: NoMatchStore(), sender: NoMatchTransport()))
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
