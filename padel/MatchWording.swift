import Foundation
import PadelScoring
import PadelStorage
import SwiftUI

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
///
/// The catalog is shared and does not license the two to share a sentence. What
/// used to enforce that rule was friction — two targets, two sets of literals,
/// no way to reach across — and `Shared/Localizable.xcstrings` has removed it:
/// a key put here is in reach of the watch, and one put on the watch is in
/// reach of here. Where the phone and the watch genuinely say the same thing —
/// "Us", "Opponents" — one key is right. Where they say different things, the
/// only thing keeping them apart now is that this comment says so.
extension Ruleset {
    /// The rules the score has to be read by: the name with the number that
    /// shapes the score filled into it.
    ///
    /// "16 : 14" is a strange tennis result and an ordinary match to 16 points,
    /// and only this line says which of the two it is.
    ///
    /// A key rather than a `String`, here and below, because a key is resolved
    /// against the locale of the screen it is drawn on rather than against the
    /// process's — which is what lets a preview be read in either language.
    var name: LocalizedStringKey {
        switch self {
        case .classic(let setsToWin, _):
            "Classic scoring · \(setsToWin) sets"
        case .pointsTo(let target, _):
            "Scoring to \(target) points"
        }
    }

    /// What decided how the match was played rather than how its score reads.
    ///
    /// It has no place in the history's row — a column of results is scanned,
    /// not read — but on the card there is one match and room to say what it
    /// was played by.
    var manner: LocalizedStringKey {
        switch self {
        case .classic(_, let goldenPoint):
            goldenPoint ? "Golden point" : "No golden point"
        case .pointsTo(_, let serveChangesEvery):
            "Serve changes every \(serveChangesEvery) rallies"
        }
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
    /// Two numerals and a colon — the same in both languages, and so not a key.
    var written: String { "\(self[.us]) : \(self[.them])" }

    /// The same score for VoiceOver, where the order alone says nothing.
    ///
    /// Lower case, because it is read out both on its own and after something
    /// else — "Tiebreak: us 7, opponents 5" — and of the two, a capital in the
    /// middle of a sentence is the one that reads wrong.
    var spoken: LocalizedStringKey { "us \(self[.us]), opponents \(self[.them])" }
}

/// The points of a game the same way, except that they are named rather than
/// counted: "40", "AD". The engine names them — that notation is padel's own,
/// not a translation.
extension Points {
    var written: String { "\(label(for: .us)) : \(label(for: .them))" }

    var spoken: LocalizedStringKey { "us \(label(for: .us)), opponents \(label(for: .them))" }
}

/// When the match was played, and for how long.
///
/// Both the shape and the language are the reader's to choose. The locale is
/// asked for rather than taken from `Locale.current`, so that it can be the one
/// the screen is being drawn with: in the app the two are the same, and in a
/// preview the screen's is the one that was asked for.
///
/// This is where a pinned `ru_RU` used to stand. With one language, an English
/// phone would have put "1 hr, 35 min" in the middle of a Russian row; with
/// two, the words and the format agree by themselves — a Russian speaker in
/// Spain gets Russian words and the local order of the day and the month.
extension SavedMatch {
    /// The day and the hour together, joined the way the language joins them.
    func whenPlayed(in locale: Locale) -> String {
        startedAt.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale))
    }

    /// The day alone — what one match is called among the others.
    func day(in locale: Locale) -> String {
        startedAt.formatted(Date.FormatStyle(date: .abbreviated, locale: locale))
    }

    /// The hour alone.
    func timeOfDay(in locale: Locale) -> String {
        startedAt.formatted(Date.FormatStyle(time: .shortened, locale: locale))
    }

    /// How long the match lasted — the first rally to the last, and not up to
    /// "now": a match cut short by a dead battery lasted until its last point.
    func lasted(in locale: Locale) -> String {
        Duration.seconds(duration)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated).locale(locale))
    }
}
