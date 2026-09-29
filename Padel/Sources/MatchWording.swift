import Foundation
import PadelScoring
import PadelStorage
import SwiftUI

// The catalog is shared, so a key written here is in reach of the watch and
// one written there is in reach of here. Where the two say different things,
// keeping them apart is a rule and not a constraint (ADR-0005).

extension Ruleset {
    /// A key rather than a `String`, here and below: a key is resolved against
    /// the locale of the screen it is drawn on rather than the process's.
    var name: LocalizedStringKey {
        switch self {
        case .classic(let setsToWin, _):
            "Classic scoring · \(setsToWin) sets"
        case .pointsTo(let target, _):
            "Scoring to \(target) points"
        }
    }

    var manner: LocalizedStringKey {
        switch self {
        case .classic(_, let goldenPoint):
            goldenPoint ? "Golden point" : "No golden point"
        case .pointsTo(_, let serveChangesEvery):
            "Serve changes every \(serveChangesEvery) rallies"
        }
    }
}

/// Our side first, always — including in a match we lost. Which side is which
/// is said by the order alone: "4 : 6" is a defeat.
extension SideCounts {
    /// Two numerals and a colon — the same in both languages, and so not a key.
    var written: String { "\(self[.us]) : \(self[.them])" }

    /// Lower case: it is read out after something else as often as on its own
    /// — "Tiebreak: us 7, opponents 5".
    var spoken: LocalizedStringKey { "us \(self[.us]), opponents \(self[.them])" }
}

extension Points {
    var written: String { "\(label(for: .us)) : \(label(for: .them))" }

    var spoken: LocalizedStringKey { "us \(label(for: .us)), opponents \(label(for: .them))" }
}

/// The locale is asked for rather than taken from `Locale.current`, so that a
/// date follows the screen it is drawn on — the chosen one in a preview.
extension SavedMatch {
    func whenPlayed(in locale: Locale) -> String {
        startedAt.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale))
    }

    func day(in locale: Locale) -> String {
        startedAt.formatted(Date.FormatStyle(date: .abbreviated, locale: locale))
    }

    func timeOfDay(in locale: Locale) -> String {
        startedAt.formatted(Date.FormatStyle(time: .shortened, locale: locale))
    }

    func lasted(in locale: Locale) -> String {
        Duration.seconds(duration)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated).locale(locale))
    }
}
