# 03: The watch's words

**What to build:** Every sentence the watch says, into the catalog ticket 02 created.

The watch is where the layout risk lives. `StartView` already leans on `lineLimit(1)` and `minimumScaleFactor(0.7)` in Russian alone, which means it is at the edge before English arrives — and truncation on a 41mm watch is the defect nobody reports and everybody sees.

The files: `StartView.swift`, `ScoreView.swift`, `ScorePages.swift`, `RulesetView.swift`, `OutcomeView.swift`.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Every string the watch says stands in the source in English, with a Russian translation in the shared catalog
- [ ] `StartView.sets` is gone: the form of the noun comes from the catalog
- [ ] `ScoreView.accessibilityValue` no longer builds its sentence with `+=` over bare fragments — each clause is its own key, joined by a separator
- [ ] The start screen, the rules screen, the score screen and the outcome screen were seen in both languages on the smallest watch at the largest Dynamic Type, with nothing truncated and nothing scaled past reading
- [ ] The previews of the watch's screens run in both languages
- [ ] The watch still says what it means to say rather than what the phone already says: a key reused from the phone is only correct where the sentence is genuinely the same one

## Notes

**On the last criterion.** `CONTEXT.md` and `MatchWording` both hold that the two targets word things differently on purpose — the watch names a ruleset about to be chosen and keeps the numbers out of it, the phone names one already played and puts the numbers in. A shared catalog makes reuse effortless, which is exactly why it has to be a decision each time and not a default. `"Us"` and `"Opponents"` are shared correctly. `"Classic scoring"` and `"Classic scoring · 2 sets"` are two sentences and stay two.
