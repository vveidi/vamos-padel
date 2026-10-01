# 07: PadelTests

**What to build:** `PadelTests` held to `CLAUDE.md`'s rewritten "Writing
comments" — 3 files, 373 lines, 153 doc-comment lines and no inline ones.

**Blocked by:** None

**Status:** done

- [x] Every `.swift` file under `PadelTests/` is read and its comments held to
      the rule
- [x] The **13 doc-comment blocks of 6 or more lines, 112 lines between them**,
      are gone or cut to four
- [x] Deleted, not reworded
- [x] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [x] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [x] The diff contains **no line of code** — and here that includes every
      string literal in an assertion. The Russian sentences are the subject of
      the test, not prose about it, and a "fixed" letter in one is a broken
      test that still passes
- [x] `PadelTests` passes under the `Padel` scheme on an iOS simulator — this
      target is the project's, not a package's, so `swift test` does not reach
      it
- [x] The closing note states the area's doc and inline line counts **before and
      after**

## Notes

**Why this ticket exists.** The feature's spec puts the test targets in scope —
"every `.swift` file under `Packages/` and both app targets, including the test
targets" — and ticket 04's criteria and line count were `Padel/Sources/` alone.
`PadelTests` is hosted by the phone app and sits beside it rather than under it,
so it fell between 04 and the packages' tickets and belongs to neither.

**It is the densest area in the repo: 41% comments, and the highest share of
them earn it.** These files assert sentences, and a sentence in Russian in an
`#expect` says nothing about why it is that sentence. Go slower than 373 lines
suggests, and expect to keep more of this area than of any other.

**`Catalog`'s two-things rule is the clearest keep in the feature.** A key
resolved in a language the test process is not running in needs both a bundle
and a locale: the bundle picks *which words*, the locale picks *which of the
words*. Either alone returns a wrong answer that passes — English text counted
by Russian rules, or Russian text counted by English ones, which is what would
let "22 гейма" through. That is a failure mode and the thing every assertion in
the suite rests on. Eleven lines today; cut it to four, do not delete it.

**`Language.bundle`'s `fatalError` keeps its reason too.** Without the `.lproj`
every assertion fails with the same wrong answer — the English key echoed back —
and none of them says why. That is why it stops rather than reports. Two lines
will hold it.

**The genitive after "до" is a fact about Russian and lives nowhere else.**
Counted the ordinary way the noun agrees with the numeral, so 21 takes *очко*
and 22 *очка*; after "до" the noun goes into the genitive and the pair turns
around — 21 takes *очка*, 22 takes *очков*. The shorter word belongs to the
larger number, which is precisely the pair an edit swaps. The test name says
what is asserted, not why it is surprising. Keep it, at four lines.

**"Written out, and not computed" is a precondition on the next person adding a
`Reading`.** A test that derived the expected form from a rule would be the
deleted hand-written table standing again on the far side of the assertion,
agreeing with itself about the numbers it already got wrong. Keep the rule, lose
the history of the table it replaced.

**What goes is the narration, and there is a lot of it.** Where a key is drawn
on screen, which row used to push which screen, that a test's subject "used to
be Point scoring", that the forms "were computed until the catalog" — all of it
is git's. So are the paragraphs arguing why a particular key was chosen as the
witness: the assertion names the key, and `SharedCatalogTests`' suite comment
already says what the whole file is for.

**ADR-0005 is the home for anything that turns out to be a decision**, not a new
ADR. It already owns the shared catalog, the plural forms belonging to the
catalog rather than to us, and English as the source language — three of the
four things this suite's prose keeps re-explaining.

## Comments

**Done.** All three `.swift` files read in full and cut.

| | before | after |
| ---------------- | ---: | ---: |
| total lines | 373 | 248 |
| doc comments | 153 | 28 |
| inline comments | 0 | 0 |
| `// MARK:` | 1 | 1 |
| comment share | 41.3% | 11.7% |

**All 13 doc-comment blocks of 6 or more lines are gone or cut to four.** Nine
blocks survive, at 4/3/2 lines in `Catalog.swift`, 4/4/2 in `PluralFormsTests`
and 4/3/2 in `SharedCatalogTests`; nothing five lines or longer is left,
checked mechanically. There was no `TODO:` or `FIXME:` to convert, and the one
`// MARK:` — the genitive after "до" — is untouched.

**The diff contains no line of code.** Checked two ways: the diff with doc
comments and blank lines filtered out is empty, and every double-quoted literal
in the three files was extracted and sorted before and after. The comparison
has no additions at all, and its removals are every one of them a fragment
quoted inside a deleted comment — `"Point scoring"`, `"N = 16"`, `"every 1
rally"`, `"these numbers say this"`. No assertion sentence changed a character
in either language.

**`PadelTests` passes under the `Padel` scheme** on an iPhone 17 simulator
(iOS 26.5): `passed_tests: 14`, `failed_tests: 0`, no warnings. Run twice —
once before `code-review` and once after its fix. There is no screen to drive
and no language or Dynamic Type state to walk: the diff is comments in a test
target.

**The four keeps the notes named all survive, at the lengths asked for.**
`Catalog`'s two-things rule at four lines, with the bundle/locale split and
"22 гейма" intact. `Language.bundle`'s `fatalError` reason at two, as a
`- Warning:` callout. The genitive after "до" at four, with the whole fact —
21 takes *очка*, 22 takes *очков*, the shorter word to the larger number.
"Written out, and not computed" folded into `PluralFormsTests`' suite comment
as the precondition on the next `Reading`.

- **No rescue to `docs/adr/` was needed, and none was made.** The two
  candidates were already owned. The serving half's frame of reference is
  ADR-0013's own consequence — "VoiceOver speaks the server's frame, not the
  screen's… the mirroring is a drawing concern" — so the three-line comment
  that survives on `theServingHalf` cites the ADR rather than re-arguing it.
  English as the source language is ADR-0005's, and the catalog being a member
  of both targets is ADR-0005's "One catalog, two targets".

- **Also kept, cut to two or three lines each:** that Health is Apple's product
  name and already translated, so the Russian is Здоровье and not a word for
  health; that the keys in `SharedCatalogTests` are the watch's alone, which is
  what makes the suite a check on the shared file rather than an assumption;
  and that `Reading.pointsTo` walks its range whole rather than sampling it,
  because Russian changes form on the last two digits.

- **One line was added rather than deleted**, on `code-review`'s finding. The
  deleted prose on `theWatchsRulesLabel` said that the Russian assertions are
  what carry the proof: English being the source language, a key that resolved
  to nothing comes back as its own English text and the English assertion
  passes anyway. That is a failure mode of every assertion in both files, it is
  a consequence of ADR-0005 rather than a restatement of it, and after the
  first pass nothing said it. It is now three lines on `Catalog.text`, the one
  call every assertion goes through.

### The feature, measured

`PadelTests` was the last of the seven. Across the whole scope — the spec's six
areas and this one:

| | before | after |
| ---------------- | -----: | -----: |
| total lines | 14,152 | 10,677 |
| doc comments | 3,868 | 775 |
| inline comments | 784 | 408 |
| comment share | 32.9% | 11.1% |

**10.3% with `// MARK:` excluded, which is the figure the spec's target should
be read against** — its "what is not in" section puts the MARK lines out of
scope. That is 0.3 points over the under-10% target, about 35 lines, and
ticket 06's closing note says where they are: `PadelDesign` at 13.2% and the
watch app at 12.8% carry the whole remainder, and a second pass over
`PadelDesign` alone would clear it. That is not a missed ticket and it has no
ticket of its own.

**Three things for the owner.**

- **A relocation, not a deletion.** The reason `pointsTo` walks 5…40 rather
  than sampling it moved off the test and onto `Reading.pointsTo`, where the
  ranges are and where someone about to trim them would look. The spec permits
  shortening a comment that passes on substance and fails on length; it does
  not discuss moving one, and the spec axis called this scope creep. The twin
  note on `Reading.points` was deleted outright rather than moved. Say the word
  and it goes back, or goes entirely.

- **One clause was dropped that nothing else says.** `SharedCatalogTests`'
  suite comment used to add that the shared catalog "is why the watch needs no
  test target of its own". It is narration by the letter of the rule and the
  notes did not name it as a keep, but it is the only statement anywhere of why
  the watch is untested. ADR-0005's "One catalog, two targets" bullet is where
  it would belong if it belongs anywhere.

- **The two review axes disagreed about `theServingHalf`.** Standards called
  the ADR-0013 citation the best-shaped comment in the change — a frame of
  reference, which `CLAUDE.md` names as earning its lines. Spec called it a
  restatement of the ADR's own consequence and would have cut it to a bare
  pointer or nothing. It was left as written, three lines, on the standards
  reading.
