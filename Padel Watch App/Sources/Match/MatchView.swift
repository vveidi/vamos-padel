import os
import PadelDelivery
import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI
import WatchKit

struct MatchView: View {
    @State private var saved: SavedMatch

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

    private let tapMode: TapMode

    private let onFinish: () -> Void

    /// `nil` until a rally lands while the match is on screen: one that landed
    /// before it appeared marks nothing.
    @State private var mark: RallyMark?

    init(
        match: SavedMatch,
        store: any MatchStore,
        workout: any Workout,
        delivery: MatchDelivery,
        tapMode: TapMode,
        onFinish: @escaping () -> Void
    ) {
        _saved = State(initialValue: match)
        self.store = store
        _workout = State(initialValue: workout)
        self.delivery = delivery
        self.tapMode = tapMode
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
                    tapMode: tapMode,
                    mark: mark,
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
        // On the journal, never on the tap that plays the haptic — ADR-0011.
        .onChange(of: saved.match.journal) { old, new in
            guard new.count > old.count, let rally = new.last else { return }

            mark = RallyMark(side: rally.winner, tier: tier(ofRallyAfter: old), trigger: (mark?.trigger ?? 0) + 1)
        }
    }

    /// A match to N points has no games and no sets, so all its rallies are
    /// one tier.
    private func tier(ofRallyAfter journal: RallyJournal) -> RallyMark.Tier {
        let match = saved.match
        let before = Match(ruleset: match.ruleset, firstServer: match.firstServer, journal: journal).state
        let after = match.state

        return before.games == after.games && before.sets == after.sets ? .rally : .gameOrSet
    }

    /// Asked of the ruleset, not of the sets played: a multi-set match
    /// abandoned inside its first set still needs the row, or its games read
    /// as the match's.
    private func setsWorthShowing(_ state: MatchState) -> SideCounts? {
        saved.match.ruleset.isMultiSet ? state.sets : nil
    }

    private func record(rallyWonBy side: Side) {
        WKInterfaceDevice.current().play(side == .us ? .directionDown : .directionUp)

        saved.record(rallyWonBy: side, at: .now)

        persist()
    }

    private func undo() {
        let ralliesBefore = saved.match.journal.count

        saved.undo(at: .now)

        if saved.match.journal.count < ralliesBefore {
            WKInterfaceDevice.current().play(.retry)
        }

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
        tapMode: .multiTap,
        onFinish: {})
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
