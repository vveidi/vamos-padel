# 02: The shared catalog, and the phone's words

**What to build:** The String Catalog itself, and every sentence the phone says moved into it — English in the source, Russian as the translation.

Three things bent around having one language get straightened here rather than left for later, because the files holding them are being rewritten anyway: the hand-written Russian plural table, the pinned `ru_RU`, and the strings the phone builds by gluing words together.

The files: `MatchWording.swift`, `MatchCard.swift`, `HistoryView.swift`, `MatchRow.swift`.

**Blocked by:** 01

**Status:** done

- [x] `Shared/Localizable.xcstrings` exists, is a member of both targets, and `ru` is among the project's known regions
- [x] Every string the phone says stands in the source in English, written as an English app's string rather than as a translation of the Russian, and has a Russian translation in the catalog
- [x] The plural forms come from the catalog: `plural`, `points`, `sets` and `rallies` are gone from `Ruleset`, and "до 21 очка" / "до 22 очков" still read correctly
- [x] `MatchWording` no longer pins `ru_RU`; a phone set to English shows English words and its own regional format for the day, the hour and the duration
- [x] No sentence is assembled from words: every composed string is whole clauses joined by a mechanical separator, and `"…, выиграли мы"` in `MatchCard`'s score strip is two whole keys rather than a frame with a noun dropped into it
- [x] The previews of the phone's screens run in both languages
- [x] `MatchWording`'s doc comment says that a shared catalog does not license the watch and the phone to share a sentence — the friction that used to enforce "two targets, two sentences" is gone, and only the rule is left

## Notes

**On the English.** It is read by someone for whom it is the only language. `"История не читается"` is `"Can't load your history"`, not `"The history is unreadable"`; `"не доигран"` is `"unfinished"`. Short, plain, the register the Russian screens already have.

**American, not British.** This ticket owns the one word in the app where the two differ: `"Тай-брейк"` is `"Tiebreak"`, one word, not `"Tie-break"`. It appears four times in `MatchCard` — the labeled row, its VoiceOver twin, and the unfinished-tiebreak line.

**On collisions.** If two different meanings want the same English sentence, do not bend one of them — give one an explicit `key:` and `defaultValue:` (ADR-0005).

**Not in this ticket.** Nothing but the catalog goes into `Shared/`. The color defined twice across the two targets stays defined twice.

## Comments

**Done.** One catalog, thirty keys, and no Cyrillic left anywhere in the phone
target.

- **The catalog.** `Shared/Localizable.xcstrings`, hand-written, source language
  `en`, `ru` as the one translation. `Shared/` is a synchronized folder listed in
  both targets' `fileSystemSynchronizedGroups`, so neither target owns it; both
  built apps come out carrying `en.lproj` and `ru.lproj`, the watch's included.
  `knownRegions` gained `ru`. Nothing else went into `Shared/` — the color
  defined twice is still defined twice.
- **The keys were checked against the compiler, not against my eyes.** With
  `SWIFT_EMIT_LOC_STRINGS` on, the build writes a `.stringsdata` per source file
  listing every key it found. Read back and compared with the catalog, the two
  sets are equal: nothing in the code is missing from the catalog, nothing in the
  catalog is unreachable from the code. That comparison also caught a stray one
  that predates this work — `Text("\(score)")` in the score strip was putting a
  key of `"%lld"` into the catalog. A cell's numeral is not a sentence; it is
  `Text(verbatim:)` now.
- **The plurals live in the catalog, and the genitive stopped being a special
  case.** `plural`, `points`, `sets` and `rallies` are gone from `Ruleset`.
  Three keys carry variations — two English forms, four Russian ones. Resolved
  across everything the rules screen offers (1–3 sets, 5–40 points, 1–6 rallies):
  "Счёт до 21 очка", "Счёт до 22 очков", "Смена подачи через 1 розыгрыш",
  "через 4 розыгрыша", "через 5 розыгрышей". English says "Serve changes every
  rally" for one rather than "every 1 rally" — a category may drop the number,
  and here it should.
- **The wording layer returns keys, not strings.** This is the one decision that
  goes beyond the ticket as written, and the preview criterion is what forced it:
  `String(localized:)` resolves against the *process's* language, and its
  `locale:` argument turns out to pick the plural rule without picking the
  `.lproj` — a Russian locale handed to it returns English text counted by
  Russian rules. `Text` and `LocalizedStringKey` resolve against the environment's
  locale instead, which is what a preview can set. So `Ruleset.name`,
  `Ruleset.manner` and both `spoken` properties are `LocalizedStringKey`, the
  screens compose `Text` rather than `String`, and there is no `String(localized:)`
  on the phone at all.
- **The dates take a locale instead of pinning one.** `whenPlayed`, `day`,
  `timeOfDay` and `lasted` became functions taking a `Locale`, and the two views
  hand them `@Environment(\.locale)`. In the app that is `Locale.current`, which
  is what the spec asked for; in a preview it is the preview's. Checked in the
  simulator: an English phone reads "Sep 3, 2026 at 9:25 PM · 26 min", a Russian
  one "3 сент. 2026 г., 21:25 · 26 мин".
- **Eight glued strings became whole clauses.** The score strip's
  `"…, выиграли мы"` is two keys, `"we won"` and `"opponents won"`, joined to the
  spoken score by `", "`. `ScoreStrip.step` stopped being the word "Гейм" and
  became `Step.game`/`Step.rally`, so that "Game 3" and "Розыгрыш 9" are each one
  sentence rather than a noun dropped into `"%@ %lld"`. The card's footnote and
  the row's date line are `Text` concatenations around a bare `" · "`. The two
  `": "` labels for VoiceOver are the same shape.
- **Tiebreak, one word,** in all four places on the card.
- **Verified on a booted simulator, in both languages**, not only by resolving
  keys: the history and the match card, launched under `-AppleLanguages (en)` and
  `(ru)`. Both cards — a won match with a tiebreak, and one abandoned inside a
  tiebreak — came out right end to end, which covers the plural, the set number,
  the tiebreak line, the unfinished line and the "Ход матча" header. The card was
  reached by pointing the app's root at it for the length of the check; the entry
  point is back as it was.
- **The previews were proved, not assumed.** The same trick: the app run with its
  language set to English and `.environment(\.locale, "ru")` on the root came out
  entirely Russian, words and dates alike. That is exactly what the new Russian
  previews do — nine pairs on the card, one on the rows, two on the history.
- **The card's previews come in pairs, after the review.** The first pass gave
  the card one Russian preview against seven English ones, which left the
  sentence the ticket names by hand — "до 21 очка" — with no Russian preview to
  show it. Every card preview now has a Russian twin. Two states that had no
  preview in either language got one, because a screen nobody can look at cannot
  be looked at in two languages: a defeat, which is the only way to see
  "Выиграли соперники", and a match whose journal is empty, which is the only way
  to see "Матч идёт" and "Ни одного розыгрыша". Both were checked on the
  simulator like the rest. `previewNothingPlayed` is the one fixture this added.
- **`MatchWording`'s doc comment** now says the shared catalog does not license
  the watch and the phone to share a sentence, and that the rule is the only
  thing left holding them apart.

The 154 package tests are still green. The watch still speaks its own Russian
literals — ticket 03.
