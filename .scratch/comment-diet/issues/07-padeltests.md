# 07: PadelTests

**What to build:** `PadelTests` held to `CLAUDE.md`'s rewritten "Writing
comments" — 3 files, 373 lines, 153 doc-comment lines and no inline ones.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Every `.swift` file under `PadelTests/` is read and its comments held to
      the rule
- [ ] The **13 doc-comment blocks of 6 or more lines, 112 lines between them**,
      are gone or cut to four
- [ ] Deleted, not reworded
- [ ] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [ ] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [ ] The diff contains **no line of code** — and here that includes every
      string literal in an assertion. The Russian sentences are the subject of
      the test, not prose about it, and a "fixed" letter in one is a broken
      test that still passes
- [ ] `PadelTests` passes under the `Padel` scheme on an iOS simulator — this
      target is the project's, not a package's, so `swift test` does not reach
      it
- [ ] The closing note states the area's doc and inline line counts **before and
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
