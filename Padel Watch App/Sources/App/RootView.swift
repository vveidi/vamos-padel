import os
import PadelDelivery
import PadelScoring
import PadelStorage
import SwiftUI

struct RootView: View {
    /// Passed to the match screen by value, never as a `Binding`: SwiftUI
    /// force-unwraps a bound optional on every read, so clearing this while
    /// the match screen is still alive would crash it.
    @State private var match: SavedMatch?

    @State private var ruleset = Ruleset.defaultClassic

    @AppStorage("records-to-health") private var recordsToHealth = true

    @State private var isRestored = false

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

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
                    // Without this a match started right after the previous one
                    // lands on a screen still holding the last one's state.
                    .id(match.id)
            } else {
                StartPages(
                    ruleset: $ruleset,
                    recordsToHealth: $recordsToHealth,
                    onStart: start(servedBy:))
            }
        }
        .task { restore() }
    }

    private var workoutForThisMatch: any Workout {
        recordsToHealth ? workout : NoWorkout()
    }

    private func start(servedBy firstServer: Side) {
        match = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: .now)
    }

    private func startOver() {
        match = nil
    }

    /// A read failure leaves the defaults in place and the start screen up:
    /// starting from scratch beats refusing to start at all.
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
