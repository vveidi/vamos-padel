# 05: The project's first test target

**What to build:** A test target on the phone, and tests that pin the plural forms in both languages.

Until now the Xcode project has had no test target at all — the tests live in the SPM packages, and the wording layer is covered by nothing. That was tolerable while the forms were computed by a function anyone could read. Once they move into the catalog they are data, and data rots without a sound: nobody notices "до 22 очка" until it is on a screen in front of a player.

Because the catalog is shared between the two targets, this one target reaches the watch's keys as well.

**Blocked by:** 02, 03

**Status:** done

- [x] The project has a test target for `Padel`, and it runs in the ordinary test action
- [x] Every plural-bearing key resolves correctly for every number the rules screen offers — sets 1 to 3, X 1 to 6, and N across its whole range — in both Russian and English
- [x] The genitive after "до" is pinned by a test: "до 21 очка" and "до 22 очков" are different forms, and the test says which is which
- [x] At least one key belonging to the watch is resolved from this target, so that the shared catalog is proven shared rather than assumed to be
- [x] The suite is green

## Notes

**On a test for untranslated keys.** Tempting, and harder than it looks: a key with no translation falls back to its own English text, so "untranslated" and "identical in both languages" are indistinguishable at runtime — and some keys, `"AD"` and `"40"` among them, are legitimately identical. If it can be written without a list of exceptions that has to be maintained, write it. If it cannot, leave it: Xcode's catalog editor reports the same thing, and a test with an exception list rots faster than the data it guards.

## Comments

**Done.** One test target, 117 assertions, and a check that the two apps really
do read one file.

- **`PadelTests`, hosted by `Padel`.** A unit test bundle with
  `TEST_HOST`/`BUNDLE_LOADER` pointing at the app, so the tests are injected
  into it and run inside it. The folder is a synchronized group like `Padel/`
  and `Padel Watch App/` are, so a new test file needs no edit to the project.
  It is listed in the `Padel` scheme's test action, which is what "the ordinary
  test action" means here: `xcodebuild -scheme Padel … test` on an iOS
  simulator runs it, and nothing else has to be named.
- **The host is the point, not a convenience.** The strings are read out of
  `Bundle.main`, which inside a hosted test is `Padel.app` itself — the build
  the App Store would get, `.lproj` folders and all. A test bundle carrying its
  own copy of the catalog would have proved something about a copy.
- **Two things have to be said to read a key in a language the process is not
  running in.** The bundle picks the `.lproj` — which words. The locale picks
  the plural rule — which of the words. Ticket 02 found the first half of this
  the hard way; the second half is the same trap facing the other direction, and
  a Russian bundle read with an English locale would have let "22 гейма"
  through. `Catalog.text(_:in:)` says both, and its doc comment says why.
- **Five plural-bearing keys, every number the screens can produce, both
  languages: 114 cases.** N over 5...40 (72), X over 1...6 (12),
  `Classic scoring · %lld sets` over 1...3 (6), `%lld sets` over 0...3 (8) and
  `%lld games` over 0...7 (16). The last two came with ticket 03 and are the
  spoken score's; their ranges are the score's rather than the rules screen's —
  no sets won yet is 0, and a set won 7:6 is 7.
- **N is walked whole rather than sampled** because Russian changes form on the
  last two digits: 21 and 31 are two separate chances to get the genitive wrong,
  and 22 and 32 two more.
- **The expected sentences are written out, not derived.** Each is stated as a
  range and the sentence its numbers read — `spread(.ru, 22...30, …)`. A test
  that computed the form from a plural rule would be the hand-written table this
  work deleted, standing again on the far side of the assertion and agreeing
  with itself about the numbers it had already got wrong.
- **The genitive has a test of its own,** naming both forms and saying which is
  which: counted the ordinary way Russian says "21 очко" and "22 очка", but
  after "до" the noun goes into the genitive and 21 takes the singular *очка*
  while 22 takes the plural *очков*. The shorter word belongs to the larger
  number, which is exactly the pair a careless edit swaps.
- **The shared catalog is checked, not assumed.** Two keys nothing in `Padel/`
  says — `"Match to N points"` from the watch's start screen and
  `"Undo the last rally"` from two of its screens — are resolved from the
  phone's own bundle. The Russian is what carries the proof: English is the
  source language, so a key that resolved to nothing would still come back as
  its own English text and prove nothing. Two keys from two files rather than
  one, because a single shared sentence could be a coincidence.
- **The suite was proved to fail.** Green tests that assert nothing look exactly
  like green tests. One Russian form was changed to the wrong one for the length
  of a run: 9 of the 72 cases of that key failed — precisely 22 through 30, the
  numbers the edit touched — and the change was reverted. That run is also how
  the case count was read, `xcbeautify --quiet` printing a passing suite as one
  line.
- **The untranslated-keys test was not written, and the note's reasoning turned
  out to understate it.** It is not that the two states are hard to tell apart
  at runtime — it is that one of the two sets does not exist there. English
  being the source language, the built app has no `en.lproj/Localizable.strings`
  at all: only the plural keys get a file, and the rest are their own values.
  There is nothing to compare `ru.lproj` against. Xcode's catalog editor still
  reports it, and as of this ticket it reports nothing: no key is missing its
  Russian, and none is identical to its English.
- **What this suite does not cover.** It pins the catalog's data against the
  keys, not the keys against their call sites: `Ruleset.name` returns a
  `LocalizedStringKey`, which has no public way back to a string, so the test
  spells the key literally the way the screen does. Change the literal in
  `MatchWording.swift` and the suite stays green while the screen goes English.
  Nothing cheap closes that — the build's own `.stringsdata` comparison
  (ticket 02) is the tool for it, and it is run by hand.

Two files changed outside the target: `.swiftlint.yml` gained `PadelTests` among
its included paths, and `CLAUDE.md`'s testing section now says the project has
tests of its own and how to run them — it had said only `swift test` and the
packages.
