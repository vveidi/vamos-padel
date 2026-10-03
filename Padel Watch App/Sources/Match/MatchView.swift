import os
import PadelDelivery
import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI
import WatchKit

/// Which device is the scorer of the match on screen (ADR-0017).
enum Scoring {
    case alone(store: any MatchStore, delivery: MatchDelivery)

    /// The phone holds the match; the watch asks and draws what comes back.
    case paired(MatchRemote)
}

struct MatchView: View {
    /// In a paired match, the phone's last word and nothing of the watch's own.
    @State private var saved: SavedMatch

    private let scoring: Scoring

    @State private var workout: any Workout

    @Binding private var tapMode: TapMode

    private let onFinish: () -> Void

    /// `nil` until a rally lands while the match is on screen: one that landed
    /// before it appeared marks nothing.
    @State private var mark: RallyMark?

    @State private var isPhoneReachable = true

    /// Sent and not yet answered, oldest first. An echo of anything else was
    /// not asked by this screen, and is not its to answer.
    @State private var unanswered: [MatchIntent] = []

    @State private var refusals = 0

    init(
        match: SavedMatch,
        scoring: Scoring,
        workout: any Workout,
        tapMode: Binding<TapMode>,
        onFinish: @escaping () -> Void
    ) {
        _saved = State(initialValue: match)
        self.scoring = scoring
        _workout = State(initialValue: workout)
        _tapMode = tapMode
        self.onFinish = onFinish
    }

    var body: some View {
        let state = saved.match.state

        Group {
            if state.outcome.isOver {
                OutcomeView(
                    winner: state.outcome.winner,
                    score: state.finalScore,
                    onUndo: undoFromTheOutcome,
                    onFinish: onFinish)
            } else {
                ScorePages(
                    points: state.points,
                    games: state.games,
                    sets: setsWorthShowing(state),
                    servingSide: state.servingSide,
                    servingHalf: state.servingHalf,
                    tapMode: $tapMode,
                    mark: mark,
                    isPhoneUnreachable: !isPhoneReachable,
                    refusals: refusals,
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
        // A paired match marks from the phone's answer instead: ADR-0011's
        // "a device marks the rallies it awarded".
        .onChange(of: saved.match.journal) { old, new in
            guard !isPaired, new.count > old.count else { return }

            markLastRally()
        }
        .task { await followUpdates() }
        .task { await followReachability() }
    }

    private var isPaired: Bool {
        if case .paired = scoring { true } else { false }
    }

    private var undoFromTheOutcome: (() -> Void)? {
        guard !isPaired else { return nil }

        return { undo() }
    }

    private func markLastRally() {
        guard let rally = saved.match.journal.last else { return }

        mark = RallyMark(side: rally.winner, tier: tierOfLastRally(), trigger: (mark?.trigger ?? 0) + 1)
    }

    /// A match to N points has no games and no sets, so all its rallies are
    /// one tier.
    private func tierOfLastRally() -> RallyMark.Tier {
        let match = saved.match
        let journal = RallyJournal(match.journal.rallies.dropLast())
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

    // MARK: What a tap does

    private func record(rallyWonBy side: Side) {
        guard isPhoneReachable else { return }

        WKInterfaceDevice.current().play(side == .us ? .directionDown : .directionUp)

        switch scoring {
        case .alone:
            saved.record(rallyWonBy: side, at: .now)

            persist()
        case .paired(let remote):
            ask(.rally(wonBy: side, base: saved.match.journal.count), of: remote)
        }
    }

    private func undo() {
        guard isPhoneReachable else { return }

        switch scoring {
        case .alone:
            let ralliesBefore = saved.match.journal.count

            saved.undo(at: .now)

            if saved.match.journal.count < ralliesBefore {
                WKInterfaceDevice.current().play(.retry)
            }

            persist()
        case .paired(let remote):
            ask(.undo(base: saved.match.journal.count), of: remote)
        }
    }

    /// Already confirmed by the control page when this is called.
    private func abandon() {
        guard isPhoneReachable else { return }

        switch scoring {
        case .alone:
            saved.abandon()

            persist()
        case .paired(let remote):
            ask(.end(base: saved.match.journal.count), of: remote)
        }
    }

    // MARK: Scored alone

    /// A write failure is logged and swallowed: on court the score on the
    /// screen matters more than the record of it.
    private func persist() {
        guard case .alone(let store, let delivery) = scoring else { return }

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

    // MARK: Paired

    /// Nothing is drawn here: what the intent did arrives as an update, or
    /// never does.
    private func ask(_ intent: MatchIntent, of remote: MatchRemote) {
        do {
            try remote.send(intent)

            unanswered.append(intent)
        } catch {
            refuse()
        }
    }

    private func followUpdates() async {
        guard case .paired(let remote) = scoring else { return }

        for await update in remote.updates() {
            switch update {
            case .match(let match, let echo) where match.id == saved.id:
                let before = saved.match.journal

                saved = match

                if let echo { answer(echo, after: before) }
            case .match, .noMatch:
                // The phone holds this match no longer. One that ended stays
                // up until the player leaves it.
                if !saved.match.state.outcome.isOver { onFinish() }
            }
        }
    }

    private func answer(_ echo: Echo, after journal: RallyJournal) {
        guard let sent = unanswered.firstIndex(of: echo.intent) else { return }

        unanswered.remove(at: sent)

        guard echo.accepted else { return refuse() }

        switch echo.intent {
        case .rally where saved.match.journal.count > journal.count: markLastRally()
        case .undo: WKInterfaceDevice.current().play(.retry)
        default: break
        }
    }

    private func refuse() {
        WKInterfaceDevice.current().play(.failure)

        refusals += 1
    }

    /// Nothing asked before the link went is answered after it: the phone
    /// sends the match as it stands instead.
    private func followReachability() async {
        guard case .paired(let remote) = scoring else { return }

        for await isReachable in remote.reachabilityChanges() {
            isPhoneReachable = isReachable

            if !isReachable { unanswered.removeAll() }
        }
    }
}

#if DEBUG

/// A phone holding a paired match, answering every intent at once.
private final class PreviewPhone: RemoteLink, @unchecked Sendable {
    let isReachable: Bool

    private var held: SavedMatch
    private let refusesEverything: Bool
    private var receive: (@Sendable (MatchUpdate) -> Void)?

    init(holding match: SavedMatch, isReachable: Bool = true, refusesEverything: Bool = false) {
        held = match
        self.isReachable = isReachable
        self.refusesEverything = refusesEverything
    }

    func onReachabilityChange(_ change: @escaping @Sendable (Bool) -> Void) {}

    func onUpdate(_ receive: @escaping @Sendable (MatchUpdate) -> Void) {
        self.receive = receive

        receive(.match(held, echo: nil))
    }

    func send(_ intent: MatchIntent) throws {
        guard isReachable else { throw LiveLinkError.unreachable }

        let accepted = !refusesEverything && apply(intent)

        receive?(.match(held, echo: Echo(intent: intent, accepted: accepted)))
    }

    private func apply(_ intent: MatchIntent) -> Bool {
        switch intent {
        case .rally(let side, let base) where base == held.match.journal.count:
            held.record(rallyWonBy: side, at: .now)
        case .undo(let base) where base == held.match.journal.count:
            held.undo(at: .now)
        case .end(let base) where base == held.match.journal.count:
            held.abandon()
        default:
            return false
        }

        return true
    }
}

private func playing() -> SavedMatch {
    var match = SavedMatch(match: Match(ruleset: .defaultClassic), scoring: .paired, startedAt: .now)

    for side in [Side.us, .us, .them, .us, .them] { match.record(rallyWonBy: side, at: .now) }

    return match
}

private func ended() -> SavedMatch {
    var match = SavedMatch(
        match: Match(ruleset: .pointsTo(target: 3, serveChangesEvery: 2)), scoring: .paired,
        startedAt: .now)

    for _ in 0..<3 { match.record(rallyWonBy: .us, at: .now) }

    return match
}

private func paired(
    _ match: SavedMatch, isReachable: Bool = true, refusesEverything: Bool = false
) -> MatchView {
    let phone = PreviewPhone(holding: match, isReachable: isReachable, refusesEverything: refusesEverything)

    return MatchView(
        match: match,
        scoring: .paired(MatchRemote(link: phone)),
        workout: NoWorkout(),
        tapMode: .constant(.tapZones),
        onFinish: {})
}

#Preview("Scored alone") {
    MatchView(
        match: SavedMatch(match: Match(ruleset: .defaultClassic), scoring: .aloneOnWatch, startedAt: .now),
        scoring: .alone(
            store: NoMatchStore(),
            delivery: MatchDelivery(queue: NoMatchStore(), sender: NoMatchTransport())),
        workout: NoWorkout(),
        tapMode: .constant(.multiTap),
        onFinish: {})
}

#Preview("Paired") { paired(playing()) }

#Preview("Paired, the phone unreachable") { paired(playing(), isReachable: false) }

#Preview("In Russian: paired, the phone unreachable") {
    paired(playing(), isReachable: false).environment(\.locale, Locale(identifier: "ru"))
}

#Preview("Paired, every tap refused") { paired(playing(), refusesEverything: true) }

#Preview("Paired, the match over") { paired(ended()) }

#endif

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
