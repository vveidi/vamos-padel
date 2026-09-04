import PadelScoring
import PadelStorage
import PadelDelivery
import SwiftUI
import os

/// The match in progress: the score while it is not over, the outcome as soon
/// as it is.
///
/// The match arrives from outside already begun: the start screen asked for the
/// ruleset and the first server, and the root of the app decided to continue an
/// interrupted one. From then on the match lives here and never goes back out —
/// it is enough for the root to know that it exists.
///
/// Here too it acquires what lets it survive an hour and a half on court: a
/// workout that runs for exactly as long as the match, a write to the store
/// after every rally, and the send to the phone as soon as it is over.
struct MatchView: View {
    /// The match and the time it was played at.
    @State private var saved: SavedMatch

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

    /// Leads away from the match to the start screen. Called only from the
    /// outcome screen: starting a new match in the middle of a running one
    /// means stopping it, and there is a control page for that.
    private let onFinish: () -> Void

    /// The store, the workout and the delivery come from outside rather than
    /// being created here: a preview must neither ask for health access, nor
    /// create a database, nor bring up a session to the phone.
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
                    onRallyWon: record(rallyWonBy:),
                    onUndo: undo,
                    onAbandon: abandon)
            }
        }
        // The workout runs exactly when the match runs. The condition is
        // written through `.inProgress` rather than through "there is a
        // winner", and so closes the workout the same way for a match played
        // out and for one stopped early: the latter has no winner, but play in
        // it has ended, and there is no point holding Always-On and a woken app
        // for its sake.
        //
        // The reverse transition is not there for nothing: undoing the last
        // rally brings back into play a match finished by a mistaken tap
        // (ticket 05), and a new workout starts then. What is left in Health is
        // two records instead of one — the price of a match played out after an
        // undo not being left without Always-On and without protection from
        // being unloaded. A match stopped early does not come back into play,
        // and its workout is closed once.
        .onChange(of: state.outcome == .inProgress, initial: true) { _, isInProgress in
            if isInProgress {
                workout.start()
            } else {
                workout.end()
            }
        }
    }

    /// The set score is shown only where it says something: in a match to one
    /// set it stays 0:0 until the last rally, while in a match to two the games
    /// lie without it — they reset with every set. This is asked of the ruleset
    /// and not of what was played: an abandoned match to two sets may not count
    /// a single one, and that is no reason to pass the current set's score off
    /// as the match's.
    private func setsWorthShowing(_ state: MatchState) -> SideCounts? {
        saved.match.ruleset.isMultiSet ? state.sets : nil
    }

    private func record(rallyWonBy side: Side) {
        saved.record(rallyWonBy: side, at: .now)

        persist()
    }

    private func undo() {
        saved.match.undo()

        persist()
    }

    /// The match is already written down, and stopping appends one mark to it.
    /// The outcome screen and the end of the workout follow by themselves: both
    /// look at the outcome, and it is abandoned now.
    ///
    /// The confirmation is asked for by the control page, not by this method:
    /// what arrives here is already decided.
    private func abandon() {
        saved.match.abandon()

        persist()
    }

    /// A write after every rally, not at the end of the match: a match
    /// interrupted halfway is restored precisely because it is already written
    /// down.
    ///
    /// A write failure never reaches the match — for the same reason a workout
    /// failure never does: on court the score matters more than everything it
    /// is being written down for.
    private func persist() {
        do {
            try store.save(saved)
        } catch {
            logger.error("the match was not saved: \(error.localizedDescription)")
        }

        // The match is over — time to carry it to the phone, and the player
        // presses nothing for that. It is asked here rather than in the
        // delivery itself only so as not to go to the database for the queue
        // after every point: while the match is running the queue is empty for
        // certain.
        //
        // The send comes after the write and not before: the delivery queue is
        // the store itself, and only what is written down can leave.
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
