# 01: Scaffolding — the watchOS target and the PadelScoring package

**What to build:** An Apple Watch app that installs and launches, and a local Swift package `PadelScoring` holding the rules engine, which the app references. The ticket adds no user-facing behavior — it is a prefactor that makes all the others possible.

The package holds the domain types from the glossary: **ruleset**, **rally**, **rally journal**, **match state**. There is no scoring logic in it yet, only the shapes ticket 02 will rest on.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The watch app builds and launches on the watchOS simulator
- [x] The `PadelScoring` package is linked into the watch target and the iPhone target
- [x] The package has at least one passing test that runs without a simulator
- [x] The package imports nothing beyond what is explicitly allowed: GRDB and the frameworks unavailable on macOS are caught by the compiler, SwiftUI and SwiftData by an allowlist guard test
- [x] The iPhone target still builds

## Comments

Done. Every criterion checked:

- **The watch builds and launches**: `xcodebuild` under the `watchOS Simulator` built
  `padel Watch App.app`; the app was installed and launched on an Apple Watch Series 11
  (46mm, watchOS 26.5), and the screenshot shows the app's screen. `WKApplication = true`,
  `MinimumOSVersion = 11.0`, `WKCompanionAppBundleIdentifier = com.vveidi.padel`.
- **The package is linked into both targets**: checked by compiling and running — both
  `ContentView`s reach for `Side.allCases` from the package, and on the watch that is
  visible on screen.
- **A test without a simulator**: 16 tests in 5 suites, `swift test`, 0.001 seconds.
- **Nothing extra is imported**: the allowlist is empty, checked against a live violation —
  an `import Foundation` in a source file fails the guard.
- **The iPhone still builds**: the `padel` scheme built; the watch app is embedded
  into `padel.app/Watch/`.

A deviation from the original wording: the criterion about imports was rewritten. The old
text claimed that `import SwiftUI` would not compile — that is wrong, SwiftUI is available
to any Apple target without explicit linking.

The minimum versions were lowered to iOS 18 / watchOS 11 along the way (see the
"Minimum versions" section of the spec).

### Following /code-review

The review ran along two axes and found eight remarks about the spec and one hard
violation of the standards. What was fixed:

- **`Rally` against the glossary.** `CONTEXT.md` forbade the word `rally` for the rally
  term, while the types are named `Rally`/`RallyJournal`. It was decided that the
  mistake was in the glossary: `rally` is a legitimate English identifier, just as `Side`
  is for a side. The ban was lifted from `rally` and kept on "point".
- **`MatchState` deleted.** The rationale "we do not write the score so as not to prejudge
  ticket 02" applied to exactly one field: `servingSide` (ticket 04) and the winner (02/03)
  were being shipped regardless. The struct was constructed nowhere and covered by nothing.
  The match state will be defined in full by ticket 02.
- **`Completion` → `MatchOutcome`**, and the term "Match outcome" was added to the glossary.
  The old name read like a completion handler.
- **`Codable` removed from every domain type.** The serialization format is ticket 07's
  decision, and fixing it here would have prejudged the migrations.
- **The guard strengthened.** Checking imports is not enough: a dependency can be declared
  in the manifest and never imported. A structural check was added that the package declares
  no external dependencies.
- **The schemes were committed** into `xcshareddata/`. They used to be auto-created and live
  in `xcuserdata/`, which is in `.gitignore` — that is, the build was reproducible only on
  the author's machine.
- **The spec:** the tiebreak stopped being listed as a parameter of the ruleset; it is a rule
  of padel.

Accepted as is: `removeLast()` and the default values 16/4/1 formally belong to tickets 05,
02 and 04. A journal without undo is an incomplete type, and constants are cheaper to keep
next to the ruleset than to scatter across the call sites.
