# 03: PadelScoring

**What to build:** `Packages/PadelScoring` held to `CLAUDE.md`'s rewritten
"Writing comments" — 26 files, 2,503 lines, 538 doc-comment lines and 56 inline.

**Blocked by:** None

**Status:** done

- [x] Every `.swift` file under `Packages/PadelScoring` — `Sources/` and
      `Tests/` both — is read and its comments held to the rule
- [x] The **34 doc-comment blocks of 6 or more lines, 284 lines between them**,
      are gone or cut to four
- [x] No `public` symbol is exempt
- [x] Deleted, not reworded
- [x] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [x] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [x] The diff contains **no line of code**
- [x] `swift test --package-path Packages/PadelScoring` is clean
- [x] The closing note states the area's doc and inline line counts **before and
      after**

## Notes

**`CONTEXT.md` is the glossary, and this package is what it is a glossary of.**
Every domain term here — `Side`, `Points`, `ServingHalf`, `Match`,
`MatchOutcome`, the rally journal — already has a paragraph in `CONTEXT.md`
saying what it is and what not to call it. A doc comment restating that entry is
the glossary written twice, and the copy in the source is the one that goes
stale. Delete it; the glossary is one file away and is where the project has
agreed the definition lives.

**What survives here is mostly rules, not definitions.** "Both rulesets' walks
finish with the same `Side?` in hand" is a precondition. "An abandoned match has
no winner, and yet play in it has ended" is an invariant the type cannot
express. Those are the keeps — one or two lines each.

**The two replays are the one place to be slow.** `Rules/` walks the journal
twice, and the comments there encode which walk answers which question. Where
that is a precondition on the caller it stays; where it argues why the journal
is the source of truth, that is ADR-0001 and it goes.

**This is the package with no `import SwiftUI` and an isolation test proving
it.** If that test's doc comment explains *why the package must not depend on
anything*, that is ADR-0006 and goes. If it explains *how* the test detects a
violation, that is a failure mode and stays.

## Comments

**Done.** 25 `.swift` files under `Sources/` and `Tests/`, read in full and cut.

| | before | after |
| ---------------- | ----: | ----: |
| total lines | 2,482 | 2,055 |
| doc comments | 538 | 129 |
| inline comments | 54 | 36 |
| comment share | 24% | 8% |

`// MARK:` is untouched: 28 lines before and after. No `TODO:` or `FIXME:`
existed to convert. The counts are `Sources/` plus `Tests/`, excluding
`Package.swift` — the ticket's 26 files, 2,503 lines and 56 inline comments
counted it in, and this pass leaves it alone. **No doc block of five lines or
more is left**, checked mechanically.

**The diff contains no line of code**, checked the same way ticket 01 was: every
file stripped of comments and blank lines before and after the pass, and the two
compared. The comparison is empty. `swift test --package-path
Packages/PadelScoring` is clean — 102 cases, no warnings. The apps were not
built, and there is nothing for a build to catch that the byte-for-byte
comparison of the code does not.

- **One rescue: ADR-0001 gains a consequence.** `Match.undo()`'s fourteen-line
  block held one rule that is nowhere else in the repo — undo does not lift the
  abandoned mark, because stopping is not a rally, and a stray tap on stop is
  guarded by the confirmation on screen rather than by undo. It was written
  twice, on `undo()` and again on `MatchTests.undoDoesNotResumeAnAbandonedMatch`.
  It is now a bullet in ADR-0001, next to the one that already owns the
  abandoned mark, and the test name alone carries the behaviour.

- **Nothing else was rescued.** Everything else that argued was ADR-0001 in
  other words — the journal is the truth, the score is not stored beside it, the
  engine is a pure function of the two — or `CONTEXT.md`'s glossary written a
  second time, which is what the notes above predicted for this package.

- **Kept, as the notes asked:** the preconditions and the unknowables.
  `MatchOutcome.init(winner:)`'s "both rulesets' walks finish with the same
  `Side?` in hand", `isOver`'s "an abandoned match has none, and yet play in it
  has ended", both clamps (`serveChangesEvery` against a division by zero,
  `setsToWin` against a match that can be neither started nor finished),
  `ClassicReplay.serveChanges`'s tiebreak rhythm — the one place the serve does
  not move on game boundaries — the golden point's `nil` half on both
  `ClassicReplay` and `MatchState`, `gamesPlayed` counting the match and not the
  set, `Ruleset.setsToWin` being sets to win and not sets to play, and
  `gameIsWon`'s proof that the golden point reduces the rule to "first to four".

- **Kept in the tests: the fixtures, not the arguments.** A journal of `.us` and
  `.them` says nothing about the deuce, the set boundary or the tiebreak it was
  built to cross, so the lines that say which chunk is which stayed, as did the
  ones deriving an expected value — "twelve games in, it is our turn again", the
  99-point target that keeps a match alive, the traded tiebreak points. What went
  was the narration over an assertion that the assertion already makes.

- **Two comments were stale.** `MatchTests`'s last case said "there is no start
  screen yet and the app opens straight onto the score" — the watch has had a
  `Start/` folder since before this feature opened. `ServingSideTests` and
  `ServingHalfTests` both pointed at "ticket 06" for where X comes from, which
  is `watch-scoring` 06 and closed; `PointsToReplay`'s clamp note says the same
  thing without the reference, and it is the one that stayed.

- **One judgment call left for the owner.** `ClassicReplay.setsPlayed` lost
  twelve lines saying what makes a set one that was played — the set the walk
  stands in is not in the course until a rally lands in it. The guard says it in
  code, and `MatchCourseTests` keeps the two cases and a two-line note on each,
  so the rule is locked; but this is the subtlest thing in the package and the
  place a reader would have looked. If it should be a doc comment rather than a
  test, it wants an ADR instead — say so and I will write it.
