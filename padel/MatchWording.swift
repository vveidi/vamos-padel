import Foundation
import PadelScoring
import PadelStorage

/// The words the phone says about a match: its score, the rules that score has
/// to be read by, and when it was played.
///
/// One home for two screens — the row of the history and the match card — so
/// that a match does not describe itself one way in the list and another way
/// when it is opened.
///
/// The watch has wording of its own, and deliberately different: there a
/// ruleset is being chosen and the numbers stay out of its name, here the match
/// is already played and the numbers are exactly what makes its score
/// readable. Two targets, two sentences — not one sentence copied twice.
extension Ruleset {
    /// The rules the score has to be read by: the name with the number that
    /// shapes the score filled into it.
    ///
    /// "16 : 14" is a strange tennis result and an ordinary match to 16 points,
    /// and only this line says which of the two it is.
    var name: String {
        switch self {
        case .classic(let setsToWin, _):
            "Классический счёт · \(setsToWin) \(Self.sets(setsToWin))"
        case .pointsTo(let target, _):
            "Счёт до \(target) \(Self.points(target))"
        }
    }

    /// What decided how the match was played rather than how its score reads.
    ///
    /// It has no place in the history's row — a column of results is scanned,
    /// not read — but on the card there is one match and room to say what it
    /// was played by.
    var manner: String {
        switch self {
        case .classic(_, let goldenPoint):
            goldenPoint ? "Золотое очко" : "Без золотого очка"
        case .pointsTo(_, let serveChangesEvery):
            "Смена подачи через \(serveChangesEvery) \(Self.rallies(serveChangesEvery))"
        }
    }

    /// The rules screen offers no more than three sets, so "сетов" is
    /// unreachable — the general rule costs no more code than the two cases it
    /// covers, and does not have to be revisited if the screen ever offers
    /// five.
    private static func sets(_ count: Int) -> String {
        plural(count, "сет", "сета", "сетов")
    }

    /// The rules screen offers between one and six rallies between service
    /// changes.
    private static func rallies(_ count: Int) -> String {
        plural(count, "розыгрыш", "розыгрыша", "розыгрышей")
    }

    /// Not the general rule, because "до" governs the genitive and the noun
    /// stops agreeing with the numeral the ordinary way: "до 21 очка", but
    /// "до 22 очков" — where "22 очка" would be right on its own.
    private static func points(_ count: Int) -> String {
        count % 10 == 1 && count % 100 != 11 ? "очка" : "очков"
    }

    /// The form of a Russian noun that goes with a number: one сет, two сета,
    /// five сетов — with the teens as the exception they always are.
    private static func plural(_ count: Int, _ one: String, _ few: String, _ many: String) -> String
    {
        let last = count % 10
        let teens = count % 100

        if teens >= 12 && teens <= 14 { return many }
        if last == 1 { return one }
        if last >= 2 && last <= 4 { return few }

        return many
    }
}

/// The score as the phone writes it, and as it reads it out.
///
/// Our side first, always — including in a match we lost. The history is read
/// as a column rather than row by row, and a score whose sides swap places by
/// the outcome cannot be scanned down; the card is opened out of that column
/// and must not swap them back. Which side is which is then said by the order
/// alone: "4 : 6" is a defeat.
extension SideCounts {
    var written: String { "\(self[.us]) : \(self[.them])" }

    /// The same score for VoiceOver, where the order alone says nothing.
    ///
    /// Lower case, because it is read out both on its own and after something
    /// else — "Тай-брейк: у нас 7, у соперников 5" — and of the two, a capital
    /// in the middle of a sentence is the one that reads wrong.
    var spoken: String { "у нас \(self[.us]), у соперников \(self[.them])" }
}

/// The points of a game the same way, except that they are named rather than
/// counted: "40", "AD". The engine names them — that notation is padel's own,
/// not a translation.
extension Points {
    var written: String { "\(label(for: .us)) : \(label(for: .them))" }

    var spoken: String { "у нас \(label(for: .us)), у соперников \(label(for: .them))" }
}

/// When the match was played, and for how long.
///
/// The shape of both is the system's to choose — the order of the day and the
/// month, the abbreviation for an hour — but the language is ours. The app
/// writes in Russian and has no second language to switch to, so a phone set to
/// English would otherwise put "1 hr, 35 min" in the middle of a Russian row.
///
/// The calendar and the time zone stay the reader's own: it is the language
/// that is fixed here, not where in the world the owner is.
extension SavedMatch {
    /// The day and the hour together, joined the way the language joins them.
    var whenPlayed: String {
        startedAt.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Self.language))
    }

    /// The day alone — what one match is called among the others.
    var day: String {
        startedAt.formatted(Date.FormatStyle(date: .abbreviated, locale: Self.language))
    }

    /// The hour alone.
    var timeOfDay: String {
        startedAt.formatted(Date.FormatStyle(time: .shortened, locale: Self.language))
    }

    /// How long the match lasted — the first rally to the last, and not up to
    /// "now": a match cut short by a dead battery lasted until its last point.
    var lasted: String {
        Duration.seconds(duration)
            .formatted(
                .units(allowed: [.hours, .minutes], width: .abbreviated)
                    .locale(Self.language))
    }

    /// The language the app speaks — the one its own strings are written in.
    private static let language = Locale(identifier: "ru_RU")
}
