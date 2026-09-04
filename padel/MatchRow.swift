import PadelScoring
import PadelStorage
import SwiftUI

/// One match in the history: the score it ended on, the rules it was played
/// by, the day it was played and how long it lasted.
///
/// The rules are on the row and not only inside the match card (ticket 12),
/// because without them the score cannot be read: "16 : 14" is a strange
/// tennis result and an ordinary match to 16 points, and only the line beneath
/// says which of the two it is.
struct MatchRow: View {
    let match: SavedMatch

    var body: some View {
        let state = match.match.state
        let score = state.finalScore
        let isAbandoned = state.outcome == .abandoned

        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                // Our side first, always — including in a match we lost. The
                // history is read as a column rather than row by row, and a
                // score whose sides swap places by the outcome cannot be
                // scanned down. Which side is which is then said by the order
                // alone: "4 : 6" is a defeat.
                Text("\(score[.us]) : \(score[.them])")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isAbandoned ? .secondary : .primary)
                    .accessibilityLabel(
                        "У нас \(score[.us]), у соперников \(score[.them])")

                Spacer(minLength: 8)

                if isAbandoned { abandoned }
            }

            Text(Self.rules(of: match.match.ruleset))
                .font(.subheadline)

            Text(when)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        // The row is one thing to read out, not four: VoiceOver walking
        // separately over a score, a ruleset and a date is a way of hearing
        // everything about a match and learning nothing.
        .accessibilityElement(children: .combine)
    }

    /// The mark that has to be caught by the eye without reading the row.
    ///
    /// An abandoned match counts as neither a win nor a loss, and in a column
    /// of results its score must not pass for one — so it is dimmed and
    /// labelled at once. Grey rather than red: the same colour the watch marks
    /// it with on the outcome screen, and being stopped early is not an error
    /// to warn about.
    private var abandoned: some View {
        Text("не доигран")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.fill.tertiary, in: Capsule())
    }

    /// When it was played and for how long.
    ///
    /// The shape of both is the system's to choose — the order of the day and
    /// the month, the abbreviation for an hour — but the language is ours. The
    /// app writes in Russian and has no second language to switch to, so a
    /// phone set to English would otherwise put "1 hr, 35 min" in the middle
    /// of a Russian row.
    ///
    /// The calendar and the time zone stay the reader's own: it is the
    /// language that is fixed here, not where in the world the owner is.
    ///
    /// The duration is counted from the first rally to the last (`SavedMatch`)
    /// and not up to "now": a match cut short by a dead battery lasted until
    /// its last point.
    private var when: String {
        let played = match.startedAt.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Self.language))

        let lasted = Duration.seconds(match.duration)
            .formatted(
                .units(allowed: [.hours, .minutes], width: .abbreviated)
                    .locale(Self.language))

        return "\(played) · \(lasted)"
    }

    /// The language the app speaks — the one its own strings are written in.
    private static let language = Locale(identifier: "ru_RU")

    /// The rules the match was played by, in the words of the start screen on
    /// the watch — with the numbers filled in.
    ///
    /// The watch deliberately keeps the N out of the name ("Счёт до N очков"):
    /// there it names a ruleset about to be chosen, and a number in it would
    /// need declension. Here the match is already played, the N is exactly
    /// what makes its score readable, and the declension is worth the two
    /// cases it costs.
    ///
    /// Only the parameter that shapes the final score is named: the golden
    /// point and the interval between service changes decide how the match was
    /// played, not how the number in front of the reader is to be read. They
    /// belong on the match card (ticket 12), which shows a single match rather
    /// than a column of them.
    private static func rules(of ruleset: Ruleset) -> String {
        switch ruleset {
        case .classic(let setsToWin, _):
            "Классический счёт · \(sets(setsToWin))"
        case .pointsTo(let target, _):
            "Счёт до \(target) \(points(target))"
        }
    }

    /// The rules screen offers no more than three sets, so there are exactly
    /// two grammatical cases to handle.
    private static func sets(_ count: Int) -> String {
        count == 1 ? "1 сет" : "\(count) сета"
    }

    /// The rules screen offers between 5 and 40 points, and in that range only
    /// numbers ending in one ask for a case of their own: "до 21 очка", but
    /// "до 16 очков".
    private static func points(_ count: Int) -> String {
        count % 10 == 1 && count % 100 != 11 ? "очка" : "очков"
    }
}

#if DEBUG

#Preview {
    List {
        MatchRow(match: .preview(classicWonBy: .us))
        MatchRow(match: .preview(classicWonBy: .them))
        MatchRow(match: .preview(pointsTo: 16))
        MatchRow(match: .preview(pointsTo: 21, abandonedAfter: 9))
    }
}

extension SavedMatch {
    /// A match for the previews: a rally a minute, so that the length of a
    /// preview match is the length of a real one — rallies and the walking
    /// between them included.
    ///
    /// It goes through the engine rather than being assembled from a ready
    /// score, because there is no way to assemble one: the score is computed
    /// from the rally journal (ADR-0001), and a preview showing a score nobody
    /// could have played is worth nothing.
    static func preview(_ winners: [Side], ruleset: Ruleset, abandoned: Bool = false) -> SavedMatch {
        let start = Date(timeIntervalSinceNow: -3 * 24 * 60 * 60)

        var saved = SavedMatch(match: Match(ruleset: ruleset), startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(
                rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played) * 60))
        }

        if abandoned { saved.match.abandon() }

        return saved
    }

    /// A single set taken 6 : 4 — six games to the winner, four to the other
    /// side, four straight points in each.
    static func preview(classicWonBy winner: Side) -> SavedMatch {
        let games = Array(repeating: winner.opposite, count: 4 * 4)
            + Array(repeating: winner, count: 6 * 4)

        return .preview(games, ruleset: .classic(setsToWin: 1, goldenPoint: true))
    }

    /// A match to N points, taken by one point — the closest thing there is to
    /// a "16 : 14" that looks like a tennis score.
    static func preview(pointsTo target: Int, abandonedAfter stopped: Int? = nil) -> SavedMatch {
        var rallies = Array(repeating: [Side.us, .them], count: target - 2).flatMap { $0 }
        rallies.append(.us)
        rallies.append(.us)

        return .preview(
            Array(rallies.prefix(stopped ?? rallies.count)),
            ruleset: .pointsTo(target: target, serveChangesEvery: 4),
            abandoned: stopped != nil)
    }
}

#endif
