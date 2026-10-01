# 03: The watch's words

**What to build:** Every sentence the watch says, into the catalog ticket 02 created.

The watch is where the layout risk lives. `StartView` already leans on `lineLimit(1)` and `minimumScaleFactor(0.7)` in Russian alone, which means it is at the edge before English arrives — and truncation on a 41mm watch is the defect nobody reports and everybody sees.

The files: `StartView.swift`, `ScoreView.swift`, `ScorePages.swift`, `RulesetView.swift`, `OutcomeView.swift`.

**Blocked by:** 02

**Status:** done

- [x] Every string the watch says stands in the source in English, with a Russian translation in the shared catalog
- [x] `StartView.sets` is gone: the form of the noun comes from the catalog
- [x] `ScoreView.accessibilityValue` no longer builds its sentence with `+=` over bare fragments — each clause is its own key, joined by a separator
- [x] The start screen, the rules screen, the score screen and the outcome screen were seen in both languages on the smallest watch at the largest Dynamic Type, with nothing truncated and nothing scaled past reading
- [x] The previews of the watch's screens run in both languages
- [x] The watch still says what it means to say rather than what the phone already says: a key reused from the phone is only correct where the sentence is genuinely the same one

## Notes

**On the last criterion.** `CONTEXT.md` and `MatchWording` both hold that the two targets word things differently on purpose — the watch names a ruleset about to be chosen and keeps the numbers out of it, the phone names one already played and puts the numbers in. A shared catalog makes reuse effortless, which is exactly why it has to be a decision each time and not a default. `"Us"` and `"Opponents"` are shared correctly. `"Classic scoring"` and `"Classic scoring · 2 sets"` are two sentences and stay two.

## Comments

**Done.** Twenty-three keys added, no Cyrillic left in any of the five files,
and two lines that had been truncating on the smallest watch since before this
ticket now reach their end.

- **The keys were checked against the compiler, not against my eyes.** The same
  sweep ticket 02 ended on: build both targets with `SWIFT_EMIT_LOC_STRINGS`,
  read every `.stringsdata` back, compare the set with the catalog. The two are
  equal — 52 keys, nothing in the code missing from the catalog, nothing in the
  catalog unreachable from the code, and every key with a Russian translation.
  It caught the same stray this project's `%lld` keys always are: `Text("\(games)")`
  and `Text("\(sets)")` in the score zone were putting a key of `"%lld"` into the
  catalog. A drawn numeral is not a sentence; both are `Text(verbatim:)` now, as
  are the three pickers' values on the rules screen and both scores on the
  outcome screen.
- **`StartView.sets` is gone.** The count of the sets is `"%lld sets"`, four
  Russian forms in the catalog, and the same key serves the spoken score on the
  score screen — "1 set · Golden point" and "2 сета · Без золотого очка" come
  out of the same entry as VoiceOver's ", 2 sets".
- **The spoken score is a list of clauses.** `accessibilityValue` returns `Text`
  rather than a `String` built with `+=`: "геймов 3" was a noun and a number
  glued together, and the noun a count governs is exactly the thing Russian has
  four forms of. Now `"%lld games"`, `"%lld sets"` and `"serving"` are three
  keys joined by a `", "` that belongs to no language. `accessibilityLabel` had
  to become a `LocalizedStringKey` too — the `String` overload does not
  localize, and it was silently taking the literal as text.
- **Six keys are shared with the phone, and two deliberately are not.** Shared,
  because they are the same sentence: `"Golden point"` / `"No golden point"` —
  the rule has one name; `"We won"` / `"Opponents won"` and `"Match unfinished"` —
  a win is a win on either screen; `"us %lld, opponents %lld"` — the spoken
  score. Not shared, because they are two sentences: the watch names a ruleset
  about to be chosen (`"Classic scoring"`, `"Match to N points"`) and the phone
  one already played, with the numbers in it (`"Classic scoring · %lld sets"`,
  `"Scoring to %lld points"`). The sweep prints the sharing, so the next reader
  can see it rather than take it on trust.
- **`"Match to N points"`, not `"Scoring to N points"`.** The glossary's own
  name for the ruleset, and the shorter of the two on a row that has no width
  to spare.
- **Seen on a real watch face, not reasoned about.** Apple Watch SE 3 (40mm) —
  smaller than the 41mm the ticket names — at `.accessibility5`, every screen
  in both languages, and again at the ordinary text size. The app was pointed
  at a temporary harness for the length of the check, one screen per launch,
  the language set with `-AppleLanguages`; the harness is deleted and the entry
  point is back as it was. Three things had to be fixed to make the criterion
  true, and two of them were already false in Russian before this ticket:
  - **The rules row on the start screen** truncated to "2 sets · No golden po…"
    in English and "2 сета · Без золотог…" in Russian. `lineLimit(1)` moved off
    the row and onto the name alone; the numbers under it take a second line.
  - **The outcome headline** truncated in all three outcomes in both languages —
    "Opponents…", "Выиграли с…", "Матч не до…". The screen does not scroll, so
    the line gives way instead: two lines, and a floor of half size, which at
    the largest type is about the size the line has at the ordinary one.
    "Выиграли соперники" is the one outcome that uses both.
  - **The start screen's title.** `"Start a match"` took two lines at the
    largest type and the list scrolled over the second one; `"Начать матч"` did
    not. The title is `"New match"` now — the same words the outcome screen's
    button promises, so the button and the screen it leads to agree.
- **What could not be photographed.** The confirmation's cancel button sits
  below the fold on a 40mm at the largest type. It was reached by dropping the
  other two lines of the sheet for one build: "Keep playing" and "Играть
  дальше" both fit.
- **The previews come in pairs**, the way the card's do: twenty-four across the
  five files, every English one with a Russian twin. Two states that had no
  preview in either language got one, because a screen nobody can look at
  cannot be looked at in two languages — a defeat, which is the only way to see
  "Выиграли соперники", and the start screen with two sets, which is the only
  way to see the declined noun and the widest this screen's rules row gets.
- **The picker values are capitalized in both languages now** — "Classic" /
  "Классический", "To N points" / "До N очков". They were lowercase in Russian,
  which reads well in Russian and wrong in English; and the toggle directly
  under them ("Золотое очко") was capitalized already.

Nothing in the packages was touched, so their tests were not re-run. Ticket 04
(the Health prompts) is unaffected by any of this; ticket 05 is now unblocked
and inherits three plural-bearing keys more than it was written for —
`"%lld sets"`, `"%lld games"` and the ones already there.
