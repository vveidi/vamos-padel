import Foundation

/// The catalog read the way a screen reads it: one key, one language, the
/// sentence that comes out.
///
/// Two things have to be said to resolve a key in a language the test process
/// is not itself running in, and neither is enough on its own. The bundle
/// picks the `.lproj` — *which words*. The locale picks the plural rule —
/// *which of the words*. `String(localized:)` given a Russian locale alone
/// returns English text counted by Russian rules; given a Russian bundle alone
/// it returns Russian text counted by English ones, which is the same mistake
/// wearing the other coat and the one that would let "22 гейма" pass.
enum Catalog {
    /// What the app says for a key in a language.
    ///
    /// The words come out of `Padel.app` itself — `Bundle.main`, because these
    /// tests are hosted by the app and run inside it. That is what makes the
    /// assertions statements about the app rather than about a second copy of
    /// the catalog: the strings are the ones compiled into the build, in the
    /// form the App Store will get them.
    static func text(_ key: String.LocalizationValue, in language: Language) -> String {
        String(localized: key, bundle: language.bundle, locale: language.locale)
    }
}

/// The two languages the app declares.
enum Language: String, CaseIterable, Sendable {
    case en
    case ru

    /// The locale that counts: it decides the plural category a number falls
    /// into — one of two in English, one of four in Russian.
    var locale: Locale { Locale(identifier: rawValue) }

    /// The `.lproj` inside the built app, which decides the words.
    ///
    /// A missing one is worth stopping on rather than reporting: every
    /// assertion in the suite would then fail with the same wrong answer — the
    /// English key, echoed back untranslated — and none of them would say why.
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
