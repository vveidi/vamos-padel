# 02: The shared catalog, and the phone's words

**What to build:** The String Catalog itself, and every sentence the phone says moved into it — English in the source, Russian as the translation.

Three things bent around having one language get straightened here rather than left for later, because the files holding them are being rewritten anyway: the hand-written Russian plural table, the pinned `ru_RU`, and the strings the phone builds by gluing words together.

The files: `MatchWording.swift`, `MatchCard.swift`, `HistoryView.swift`, `MatchRow.swift`.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `Shared/Localizable.xcstrings` exists, is a member of both targets, and `ru` is among the project's known regions
- [ ] Every string the phone says stands in the source in English, written as an English app's string rather than as a translation of the Russian, and has a Russian translation in the catalog
- [ ] The plural forms come from the catalog: `plural`, `points`, `sets` and `rallies` are gone from `Ruleset`, and "до 21 очка" / "до 22 очков" still read correctly
- [ ] `MatchWording` no longer pins `ru_RU`; a phone set to English shows English words and its own regional format for the day, the hour and the duration
- [ ] No sentence is assembled from words: every composed string is whole clauses joined by a mechanical separator, and `"…, выиграли мы"` in `MatchCard`'s score strip is two whole keys rather than a frame with a noun dropped into it
- [ ] The previews of the phone's screens run in both languages
- [ ] `MatchWording`'s doc comment says that a shared catalog does not license the watch and the phone to share a sentence — the friction that used to enforce "two targets, two sentences" is gone, and only the rule is left

## Notes

**On the English.** It is read by someone for whom it is the only language. `"История не читается"` is `"Can't load your history"`, not `"The history is unreadable"`; `"не доигран"` is `"unfinished"`. Short, plain, the register the Russian screens already have.

**American, not British.** This ticket owns the one word in the app where the two differ: `"Тай-брейк"` is `"Tiebreak"`, one word, not `"Tie-break"`. It appears four times in `MatchCard` — the labeled row, its VoiceOver twin, and the unfinished-tiebreak line.

**On collisions.** If two different meanings want the same English sentence, do not bend one of them — give one an explicit `key:` and `defaultValue:` (ADR-0005).

**Not in this ticket.** Nothing but the catalog goes into `Shared/`. The color defined twice across the two targets stays defined twice.
