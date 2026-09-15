# 03: PadelScoring

**What to build:** `Packages/PadelScoring` held to `CLAUDE.md`'s rewritten
"Writing comments" — 26 files, 2,503 lines, 538 doc-comment lines and 56 inline.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Every `.swift` file under `Packages/PadelScoring` — `Sources/` and
      `Tests/` both — is read and its comments held to the rule
- [ ] The **34 doc-comment blocks of 6 or more lines, 284 lines between them**,
      are gone or cut to four
- [ ] No `public` symbol is exempt
- [ ] Deleted, not reworded
- [ ] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [ ] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [ ] The diff contains **no line of code**
- [ ] `swift test --package-path Packages/PadelScoring` is clean
- [ ] The closing note states the area's doc and inline line counts **before and
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
