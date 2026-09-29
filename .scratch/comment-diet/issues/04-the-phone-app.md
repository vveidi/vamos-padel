# 04: The phone app

**What to build:** `Padel` held to `CLAUDE.md`'s rewritten "Writing comments" —
6 files, 1,467 lines, 462 doc-comment lines and 46 inline.

**Blocked by:** None

**Status:** done

- [x] Every `.swift` file under `Padel/Sources/` is read and its comments held
      to the rule
- [x] The **30 doc-comment blocks of 6 or more lines, 276 lines between them**,
      are gone or cut to four. Six files carry them, so the density per file is
      the highest in the repo
- [x] Deleted, not reworded
- [x] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [x] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [x] The diff contains **no line of code**
- [x] The `Padel` scheme builds, `PadelTests` passes, and the history is driven
      once on a simulator to prove nothing moved
- [x] The closing note states the area's doc and inline line counts **before and
      after**

## Notes

**`HistoryView` and `MatchCard` are most of the weight.** Both argue their
layout at length — why the history is not a `List`, why the card shows the score
after each step rather than who took it, why the separator is the only part of
the footnote written in code. The third is a localization constraint and stays.
The first two are design arguments with no ADR behind them: if they are worth
keeping, they are worth an ADR, and if they are not, they go. Decide per
comment rather than rescuing both by reflex.

**`MatchWording.swift` and `MatchFixtures.swift` sit at the sources root because
they belong to both screens.** `CLAUDE.md` already says that, so a doc comment
repeating it goes.

**`MatchFixtures` has one comment worth keeping** — that every fixture goes
through the engine rather than being assembled from a ready score, because the
score is computed from the journal and a made-up course would check nothing.
That is a precondition on anyone adding a fixture. Four lines.

**`PadelApp.swift`'s init is the ownership case.** Reception subscribes before
the session comes up, because a parcel arriving into an app without a handler
does not arrive twice. That is a failure mode and an ordering rule — the
clearest keep in the area.

## Comments

**Done.** The six `.swift` files under `Padel/Sources/`, read in full and cut.

| | before | after |
| ---------------- | ----: | ----: |
| total lines | 1,467 | 1,035 |
| doc comments | 462 | 46 |
| inline comments | 54 | 38 |
| comment share | 35% | 8% |

`// MARK:` is untouched: 9 lines before and after, and they are inside both
inline counts, so the inline comments a reader actually reads went 45 to 29. No
`TODO:` or `FIXME:` existed to convert. **The 30 doc blocks of 6 lines or more
— 276 lines between them — are gone**, and no comment block of five lines or
more is left anywhere in the area, checked mechanically.

**The diff contains no line of code**, checked the way tickets 01 and 03 were:
every file stripped of comments and blank lines before and after the pass, and
the two compared. The comparison is empty on all six. The `Padel` scheme builds
clean and `PadelTests` passes — 14 cases, no warnings.

**Driven on an iPhone 17 simulator, on a seeded store.** A fresh phone has no
history, so four matches were written straight into `matches.sqlite` in the app
container — a 6:4 win, a two-set defeat decided on a tiebreak, a 16:14 match to
N points and one stopped mid-game. All four tiles drew, the count returned to
the bar, the two-set card drew both sets with their headings, scores, bands and
the tiebreak aside, and the abandoned card drew "Game unfinished 40 : 0" under
a single unnumbered "How it went". Checked in Russian at the default type size
and in English at `accessibility5`, where the tile's two columns stack as they
are meant to. The seeded matches are still on that simulator.

- **One rescue: ADR-0006 gains a consequence.** The history's "nothing here is
  a `List`" argument was the one design argument in the area worth keeping, and
  it had no home. It is now a bullet next to the one that already says what the
  court costs the screens in free accessibility: a `List` would rule a table
  over the court, a tile's tint already says where one match ends, and the
  laziness is what is kept of it.

- **The card's "score after each step, not who took it" argument was let go**,
  which the ticket's Notes permit. It argues what a reader wants to know rather
  than stating anything the code cannot; the lit numeral says who took the step
  on screen, and `band`'s VoiceOver value says it in words.

- **Kept, as the Notes asked:** the footnote's separator — the only part of that
  line nobody translates — `MatchFixtures`'s precondition that every fixture is
  played through the engine, and `PadelApp`'s init ordering. `reception`'s
  lifetime went with the first cut and came back after the review: nothing reads
  the property, so only a comment says why it is held.

- **Kept beyond those:** the localization constraints (a key resolves against
  the screen's locale, not the process's; `Text(verbatim:)` on a lone numeral;
  a whole sentence per `StepName` because the number's place moves by language;
  `spoken` in lower case because it is read out mid-sentence), the shared
  catalog's rule from ADR-0005, "our side first" as the only thing saying which
  number is whose, the two `Board` enums' provenance, `bandRadius`'s deviation
  from the tile's 24, `titleGap`'s from the board's 22, the observation's
  failure mode in `watch()`'s catch, the two `#available` and `.buttonStyle`
  workarounds, `serveRuns`' floor matching the engine's, and the two domain
  traps — a set is numbered by the ruleset and not by how many were played, and
  points inside a set are a game's except at 6:6.

- **Two judgment calls left for the owner.** `MatchRow` keeps "walked once" on
  its `let state` while `MatchCard` lost the same note from `state` and
  `course`; the row is the one drawn a few hundred times down a column, but the
  two could be argued to the same answer. And the new ADR-0006 bullet names
  `LazyVStack` and "a column of bands", so it will read oddly if the view type
  ever changes — ADR-0006 already names `List`, `Picker` and `Toggle`, so this
  followed the file, but say the word and it can be written without the types.

- **`PadelTests` is not in this ticket and is in no other.** The feature's spec
  puts test targets in scope — "every `.swift` file under `Packages/` and both
  app targets, including the test targets" — but this ticket's criteria and its
  1,467 lines are `Padel/Sources/` alone. `PadelTests/` is 373 lines with 153
  doc-comment lines and belongs to no ticket. It wants one, or an amendment
  here.
