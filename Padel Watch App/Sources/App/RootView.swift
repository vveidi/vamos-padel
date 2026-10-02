import os
import PadelDelivery
import PadelScoring
import PadelStorage
import SwiftUI
import WatchKit

struct RootView: View {
    /// Passed to the match screen by value, never as a `Binding`: SwiftUI
    /// force-unwraps a bound optional on every read, so clearing this while
    /// the match screen is still alive would crash it.
    @State private var match: SavedMatch?

    /// The paired match on screen, as it first arrived. The screen follows the
    /// phone from there.
    @State private var pairedMatch: SavedMatch?

    /// While it runs, whether or not it is on screen.
    @State private var phonesPairedMatch: SavedMatch?

    @State private var isWaitingForPhone = false

    /// Who serves in the match last asked of the phone, for starting it alone.
    @State private var askedOfPhone: Side?

    @State private var refusal: PhoneRefusal?

    @State private var ruleset = Ruleset.defaultClassic

    @AppStorage("records-to-health") private var recordsToHealth = true

    @AppStorage("tap-mode") private var tapMode = TapMode.multiTap

    @AppStorage("starts-paired") private var startsPaired = false

    @State private var isRestored = false

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

    private let remote: MatchRemote

    private let pairedWorkout: PairedWorkout

    init(
        store: any MatchStore, workout: any Workout, delivery: MatchDelivery, remote: MatchRemote,
        pairedWorkout: PairedWorkout
    ) {
        self.store = store
        _workout = State(initialValue: workout)
        self.delivery = delivery
        self.remote = remote
        self.pairedWorkout = pairedWorkout
    }

    var body: some View {
        Group {
            if !isRestored {
                ProgressView()
            } else if let match {
                MatchView(
                    match: match,
                    scoring: .alone(store: store, delivery: delivery),
                    workout: workoutForThisMatch,
                    tapMode: $tapMode,
                    onFinish: startOver)
                    // Without this a match started right after the previous one
                    // lands on a screen still holding the last one's state.
                    .id(match.id)
            } else if let pairedMatch {
                MatchView(
                    match: pairedMatch,
                    scoring: .paired(remote),
                    // `pairedWorkout` runs it, from the start to the match's end.
                    workout: NoWorkout(),
                    tapMode: $tapMode,
                    onFinish: startOver)
                    .id(pairedMatch.id)
            } else if isWaitingForPhone {
                WaitingForPhone { isWaitingForPhone = false }
            } else if let refusal, let askedOfPhone {
                PhoneCannotPair(
                    refusal: refusal,
                    onStartAlone: { startAlone(servedBy: askedOfPhone) },
                    onCancel: {
                        self.refusal = nil
                        pairedWorkout.standDown()
                    })
            } else {
                StartPages(
                    ruleset: $ruleset,
                    recordsToHealth: $recordsToHealth,
                    startsPaired: $startsPaired,
                    tapMode: $tapMode,
                    onStart: start(servedBy:))
            }
        }
        // Restored first, so a match of the watch's own wins over the phone's.
        .task {
            restore()

            await followPhone()
        }
        .task { await followReachability() }
    }

    private var workoutForThisMatch: any Workout {
        recordsToHealth ? workout : NoWorkout()
    }

    private func start(servedBy firstServer: Side) {
        startsPaired ? askPhoneToStart(servedBy: firstServer) : startAlone(servedBy: firstServer)
    }

    private func startAlone(servedBy firstServer: Side) {
        refusal = nil
        pairedWorkout.standDown()

        let started = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: .now)
        match = started

        // At once rather than on the first rally: the phone may raise the watch
        // before then, and ``PairedWorkout`` asks the store whether one runs.
        do {
            try store.save(started)
        } catch {
            logger.error("the new match was not saved: \(error.localizedDescription)")
        }
    }

    private func askPhoneToStart(servedBy firstServer: Side) {
        askedOfPhone = firstServer

        do {
            try remote.send(.start(ruleset: ruleset, firstServer: firstServer))

            isWaitingForPhone = true
            pairedWorkout.begin()
        } catch {
            refuse(.unreachable)
        }
    }

    private func startOver() {
        match = nil
        pairedMatch = nil

        takeUpPhonesMatch()
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

    // MARK: The phone's match

    private func followPhone() async {
        for await update in remote.updates() {
            switch update {
            case .match(let held, isPaired: true, _) where !held.match.state.outcome.isOver:
                phonesPairedMatch = held
            case .match, .noMatch:
                phonesPairedMatch = nil
            }

            // First, so a start refused because a paired match already runs
            // joins that match instead of failing.
            takeUpPhonesMatch()

            // Refused, the start leaves a match the phone scores alone: a
            // paired one was joined just above.
            switch update {
            case .match(_, _, let echo?), .noMatch(let echo?):
                if case .start = echo.intent, !echo.accepted, isWaitingForPhone {
                    stopWaiting(.scoringItsOwnMatch)
                }
            default: break
            }
        }
    }

    /// Never over a match of the watch's own, never one the phone scores
    /// alone, and never one that has ended: an outcome on the wrist is only
    /// ever reached by playing to it here.
    private func takeUpPhonesMatch() {
        guard match == nil, pairedMatch == nil, let phonesPairedMatch else { return }

        pairedMatch = phonesPairedMatch
        isWaitingForPhone = false
        refusal = nil
    }

    private func followReachability() async {
        for await isReachable in remote.reachabilityChanges() where !isReachable && isWaitingForPhone {
            stopWaiting(.unreachable)
        }
    }

    private func stopWaiting(_ refusal: PhoneRefusal) {
        isWaitingForPhone = false
        refuse(refusal)
    }

    private func refuse(_ refusal: PhoneRefusal) {
        self.refusal = refusal

        WKInterfaceDevice.current().play(.failure)
    }
}

#Preview {
    let remote = MatchRemote(link: NoMatchTransport())

    RootView(
        store: NoMatchStore(),
        workout: NoWorkout(),
        delivery: MatchDelivery(queue: NoMatchStore(), sender: NoMatchTransport()),
        remote: remote,
        pairedWorkout: PairedWorkout(
            workout: NoWorkout(), remote: remote, savesToHealth: { false }, isScoringAlone: { false }))
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
