import os
import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

struct NewMatchView: View {
    private let store: any MatchStore

    private let onStart: (SavedMatch) -> Void

    @State private var firstServer = Side.us

    /// Both rulesets' numbers, so that glancing at the other one and coming
    /// back does not cost what was already dialled into this one.
    @State private var numbers: Numbers

    init(store: any MatchStore, onStart: @escaping (SavedMatch) -> Void) {
        self.store = store
        self.onStart = onStart
        _numbers = State(initialValue: Numbers(Self.lastRuleset(of: store)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heading("Who serves first?").padding(.top, Board.titleGap)

                court.padding(.top, Board.headingGap)

                heading("Rules").padding(.top, Board.sectionGap)

                scoring.padding(.top, Board.headingGap)

                card.padding(.top, Board.cardGap)

                sentence.padding(.top, Board.sentenceGap)
            }
            .frame(maxWidth: .readableColumn)
            .padding(.horizontal, Board.inset)
            .padding(.bottom, Board.inset)
            .frame(maxWidth: .infinity)
        }
        .background { ground }
        .safeAreaInset(edge: .bottom) { start }
        .navigationTitle("New match")
    }

    private func heading(_ words: LocalizedStringKey) -> some View {
        Text(words)
            .textStyle(.caption)
            .foregroundStyle(.ink.weight(.secondary))
    }

    // MARK: Who serves first

    /// Assembled from ``PadelDesign/CourtHalf`` and ``PadelDesign/NetLine``
    /// rather than ``PadelDesign/Court``: each half here carries a button and
    /// `Court` takes no content.
    private var court: some View {
        VStack(spacing: 0) {
            half(.them)

            NetLine().zIndex(1)

            half(.us)
        }
        .clipShape(RoundedRectangle(cornerRadius: .card))
        .overlay {
            RoundedRectangle(cornerRadius: .card).strokeBorder(.ink.weight(.hairline))
        }
    }

    private func half(_ side: Side) -> some View {
        let isChosen = firstServer == side

        return Button {
            firstServer = side
        } label: {
            Text(Self.name(of: side))
                .textStyle(.tileScore)
                .foregroundStyle(isChosen ? Color.courtInk : .courtInk.weight(.strong))
                // One word per side in both languages, so it shrinks rather
                // than wraps: "Соперники" at the largest setting is wider than
                // a half and breaks mid-word.
                .lineLimit(1)
                .minimumScaleFactor(Board.nameMinimumScale)
                .padding(.horizontal, Board.inset)
                .padding(.vertical, Board.halfPadding)
                .frame(maxWidth: .infinity, minHeight: Board.half)
                .background { CourtHalf() }
                .overlay(alignment: side == .us ? .bottomTrailing : .topTrailing) {
                    ball(isChosen)
                }
                .overlay { ring(side, isChosen) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(Self.serves(side)))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    private func ball(_ isChosen: Bool) -> some View {
        Ball(size: Board.ball)
            .padding(Board.ballInset)
            .opacity(isChosen ? 1 : 0)
    }

    /// Square where the two halves meet and round where the court is, so that
    /// ringing a half draws no corner the court does not have.
    private func ring(_ side: Side, _ isChosen: Bool) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: side == .them ? .card : 0,
            bottomLeadingRadius: side == .us ? .card : 0,
            bottomTrailingRadius: side == .us ? .card : 0,
            topTrailingRadius: side == .them ? .card : 0
        )
        .strokeBorder(Color.ball, lineWidth: Board.ring)
        .opacity(isChosen ? 1 : 0)
    }

    private static func name(of side: Side) -> LocalizedStringKey {
        side == .us ? "Us" : "Opponents"
    }

    /// What tapping the half does. The halves are heard one after the other
    /// and neither name answers the question the screen is asking.
    private static func serves(_ side: Side) -> LocalizedStringKey {
        side == .us ? "We serve" : "Opponents serve"
    }

    // MARK: The rules

    private var scoring: some View {
        SegmentedChoice(
            selection: $numbers.isClassic,
            .init(Text("Classic"), value: true),
            .init(Text("By points"), value: false))
    }

    private var card: some View {
        SettingsCard {
            if numbers.isClassic {
                StepperRow(Text("Sets to win"), value: $numbers.setsToWin, in: Self.setsToWin)

                Toggle(isOn: $numbers.goldenPoint) {
                    Text("Golden point")
                        .textStyle(.body)
                        .foregroundStyle(.ink.weight(.control))
                }
                .toggleStyle(.ball)
            } else {
                StepperRow(Text("Points to win"), value: $numbers.target, in: Self.targets)

                StepperRow(
                    Text("Serve changes every"), value: $numbers.serveChangesEvery,
                    in: Self.serveChanges)
            }
        }
    }

    private var sentence: some View {
        Self.sentence(for: numbers.ruleset)
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.secondary))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Whole clauses, so the catalog declines the counted noun.
    private static func sentence(for ruleset: Ruleset) -> Text {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            Text("First to \(setsToWin) sets. A set is 6 games, a tiebreak at 6:6.")
                + Text(verbatim: " ")
                + Text(Self.deuce(goldenPoint))

        case .pointsTo(let target, let serveChangesEvery):
            Text("Scoring to \(target) points")
                + Text(verbatim: ". ")
                + Text("Serve changes every \(serveChangesEvery) rallies")
                + Text(verbatim: ".")
        }
    }

    private static func deuce(_ goldenPoint: Bool) -> LocalizedStringKey {
        goldenPoint ? "Deuce is one point." : "Deuce is played out to a two-point lead."
    }

    /// Three sets won is five played, padel's full professional format.
    private static let setsToWin = 1...3

    /// Below five points the match ends before the serve changes hands once.
    private static let targets = 5...40

    /// "In different groups it is 2 or 4" — the spec.
    private static let serveChanges = 1...6

    // MARK: Starting

    private var start: some View {
        PillButton(Text("Start match"), action: startMatch)
            .frame(maxWidth: .readableColumn)
            .padding(.horizontal, Board.inset)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(gradient: .nightScrim, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
    }

    /// Written down before it is handed on, so a match begun and then
    /// backgrounded comes back from the store. A write that fails is logged
    /// and the match starts unsaved: refusing to start would be worse.
    private func startMatch() {
        let saved = SavedMatch(
            match: Match(ruleset: numbers.ruleset, firstServer: firstServer), startedAt: .now)

        do {
            try store.save(saved)
        } catch {
            logger.error("the new match was not saved: \(error.localizedDescription)")
        }

        onStart(saved)
    }

    /// A read failure leaves the defaults in place: starting a match on
    /// yesterday's rules matters less than starting one at all.
    private static func lastRuleset(of store: any MatchStore) -> Ruleset {
        do {
            return try store.lastRuleset() ?? .defaultClassic
        } catch {
            logger.error("the last ruleset was not read: \(error.localizedDescription)")

            return .defaultClassic
        }
    }

    // MARK: The ground

    private var ground: some View {
        Color.night
            .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
            .ignoresSafeArea()
    }

    private struct Numbers {
        var isClassic = true
        var setsToWin = 0
        var goldenPoint = false
        var target = 0
        var serveChangesEvery = 0

        init(_ ruleset: Ruleset) {
            take(.defaultClassic)
            take(.defaultPointsTo)

            // Last, because `take` also sets which of the two is selected.
            take(ruleset)
        }

        var ruleset: Ruleset {
            isClassic
                ? .classic(setsToWin: setsToWin, goldenPoint: goldenPoint)
                : .pointsTo(target: target, serveChangesEvery: serveChangesEvery)
        }

        /// Takes the numbers of a ruleset without touching the other's.
        private mutating func take(_ ruleset: Ruleset) {
            switch ruleset {
            case .classic(let setsToWin, let goldenPoint):
                isClassic = true
                self.setsToWin = setsToWin
                self.goldenPoint = goldenPoint
            case .pointsTo(let target, let serveChangesEvery):
                isClassic = false
                self.target = target
                self.serveChangesEvery = serveChangesEvery
            }
        }
    }
}

/// What the new match board drew around the controls, in its pixels — the
/// phone boards are 1x (`docs/design/README.md`, "Reading the boards").
private enum Board {
    static let inset: CGFloat = 20

    /// Short of the board's 20 because the large title brings its own
    /// baseline-to-content gap with it.
    static let titleGap: CGFloat = 8

    static let headingGap: CGFloat = 12

    static let sectionGap: CGFloat = 26

    static let cardGap: CGFloat = 10

    static let sentenceGap: CGFloat = 14

    /// Half the board's 210px court, less the net it does not include.
    static let half: CGFloat = 103

    static let halfPadding: CGFloat = 12

    /// Not a number off the board, which is drawn at one Dynamic Type setting
    /// out of twelve.
    static let nameMinimumScale: CGFloat = 0.6

    static let ball: CGFloat = 24

    /// The board's 16 from the side and 14 from the end, in one number.
    static let ballInset: CGFloat = 15

    /// The board's `inset 0 0 0 3px`.
    static let ring: CGFloat = 3

    static let floodlight: Double = 0.14
}

#if DEBUG

#Preview("A new match") { screen(lastRuleset: nil) }

#Preview("The last match's rules") { screen(lastRuleset: .pointsTo(target: 21, serveChangesEvery: 2)) }

#Preview("In Russian: a new match") { inRussian(screen(lastRuleset: nil)) }

#Preview("In Russian: the match to N points") {
    inRussian(screen(lastRuleset: .defaultPointsTo))
}

#Preview("In a wide window", traits: .landscapeLeft) { screen(lastRuleset: nil) }

#Preview("In Russian, in a wide window", traits: .landscapeLeft) {
    inRussian(screen(lastRuleset: nil))
}

#Preview("At the largest type") { atLargestType(screen(lastRuleset: nil)) }

#Preview("In Russian, at the largest type") {
    atLargestType(inRussian(screen(lastRuleset: nil)))
}

#Preview("In Russian, at the largest type: the match to N points") {
    atLargestType(inRussian(screen(lastRuleset: .defaultPointsTo)))
}

private func screen(lastRuleset: Ruleset?) -> some View {
    NavigationStack {
        NewMatchView(store: PreviewMatchStore(last: lastRuleset), onStart: { _ in })
    }
    .preferredColorScheme(.dark)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private struct PreviewMatchStore: MatchStore {
    let last: Ruleset?

    func save(_ match: SavedMatch) throws {}

    func matchInProgress() throws -> SavedMatch? { nil }

    func match(id: UUID) throws -> SavedMatch? { nil }

    func lastRuleset() throws -> Ruleset? { last }

    func matches() throws -> [SavedMatch] { [] }

    func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

#endif

private let logger = Logger(subsystem: "com.vveidi.padel", category: "new match")
