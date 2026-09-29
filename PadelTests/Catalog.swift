import Foundation

/// Resolving a key in a language the test process is not running in takes both
/// a bundle and a locale: the bundle picks the `.lproj` — *which words* — and
/// the locale picks the plural rule — *which of the words*. Either alone
/// returns a wrong answer that passes, which is what lets "22 гейма" through.
enum Catalog {
    /// - Note: The Russian assertions carry the proof. English is the source
    ///   language, so a key that resolved to nothing comes back as its own
    ///   English text and the English assertion passes anyway.
    static func text(_ key: String.LocalizationValue, in language: Language) -> String {
        String(localized: key, bundle: language.bundle, locale: language.locale)
    }
}

enum Language: String, CaseIterable, Sendable {
    case en
    case ru

    var locale: Locale { Locale(identifier: rawValue) }

    /// - Warning: Without the `.lproj` every assertion fails with the same
    ///   wrong answer — the English key echoed back — and none of them says why.
    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            fatalError(
                "Padel.app carries no \(rawValue).lproj. "
                    + "Is Shared/Localizable.xcstrings still a member of the Padel target?"
            )
        }

        return bundle
    }
}
