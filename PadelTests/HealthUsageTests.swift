import Foundation
import Testing

/// A paired match asks for Health on the phone, and iOS terminates an app that
/// asks without saying why. The words come from build settings and from
/// `Padel/Resources/InfoPlist.xcstrings`, so the built app is the only place to
/// see them together.
@Suite("The phone's Health usage strings")
struct HealthUsageTests {
    @Test("Both reasons are in the app, in both languages", arguments: Language.allCases)
    func bothReasons(_ language: Language) {
        for key in ["NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription"] {
            #expect(Bundle.main.object(forInfoDictionaryKey: key) is String)

            let text = language.bundle.localizedString(forKey: key, value: nil, table: "InfoPlist")
            #expect(text != key)
            #expect((language == .ru) == text.contains("часы"), "\(key) in \(language.rawValue): \(text)")
        }
    }

    @Test("The app may run on in the background through a mirrored workout")
    func theWorkoutBackgroundMode() {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]

        #expect(modes?.contains("workout-processing") == true)
    }
}
