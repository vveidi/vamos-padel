import os
import PadelDelivery
import PadelScoring
import PadelStorage
import SwiftUI

struct MatchView: View {
    @State private var saved: SavedMatch

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

    private let onFinish: () -> Void

    init(
        match: SavedMatch,
        store: any MatchStore,
        workout: any Workout,
        delivery: MatchDelivery,
        onFinish: @escaping () -> Void
    ) {
        _saved = State(initialValue: match)
        self.store = store
        _workout = State(initialValue: workout)
        self.delivery = delivery
        self.onFinish = onFinish
    }

    var body: some View {
        let state = saved.match.state

        Group {
            if state.outcome.isOver {
                OutcomeView(
                    winner: state.outcome.winner,
                    score: state.finalScore,
                    onUndo: undo,
                    onFinish: onFinish)
            } else {
                ScorePages(
                    points: state.points,
                    games: state.games,
                    sets: setsWorthShowing(state),
                    servingSide: state.servingSide,
                    servingHalf: state.servingHalf,
                    onRallyWon: record(rallyWonBy:),
                    onUndo: undo,
                    onAbandon: abandon)
            }
        }
        // `.inProgress` rather than "has a winner", so a match stopped early
        // closes its workout too. Undoing the last rally starts a second
        // workout, which leaves two records in Health for that match — the
        // price of not losing Always-On for the rest of the play.
        .onChange(of: state.outcome == .inProgress, initial: true) { _, isInProgress in
            if isInProgress {
                workout.start()
            } else {
                workout.end()
            }
        }
    }

    /// Asked of the ruleset, not of the sets played: a multi-set match
    /// abandoned inside its first set still needs the row, or its games read
    /// as the match's.
    private func setsWorthShowing(_ state: MatchState) -> SideCounts? {
        saved.match.ruleset.isMultiSet ? state.sets : nil
    }

    private func record(rallyWonBy side: Side) {
        saved.record(rallyWonBy: side, at: .now)

        persist()
    }

    private func undo() {
        saved.undo(at: .now)

        persist()
    }

    /// Already confirmed by the control page when this is called.
    private func abandon() {
        saved.abandon()

        persist()
    }

    /// A write failure is logged and swallowed: on court the score on the
    /// screen matters more than the record of it.
    private func persist() {
        do {
            try store.save(saved)
        } catch {
            logger.error("the match was not saved: \(error.localizedDescription)")
        }

        // After the write, never before: the delivery queue is the store, so
        // only what is written down can leave.
        if saved.match.state.outcome.isOver {
            delivery.deliverPending()
        }
    }
}

#Preview {
    MatchView(
        match: SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: .now),
        store: NoMatchStore(),
        workout: NoWorkout(),
        delivery: MatchDelivery(queue: NoMatchStore(), sender: NoMatchTransport()),
        onFinish: {})
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
