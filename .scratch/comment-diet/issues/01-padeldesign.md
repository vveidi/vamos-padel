# 01: PadelDesign

**What to build:** `Packages/PadelDesign` held to `CLAUDE.md`'s rewritten
"Writing comments" — 39 files, 4,886 lines, 1,426 doc-comment lines and 248
inline, the heaviest area in the repo.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Every `.swift` file under `Packages/PadelDesign` — `Sources/` and
      `Tests/` both — is read and its comments held to the rule: the default is
      no comment, and what survives names a precondition, a unit, a threading or
      ownership rule, a failure mode, where a measured number came from, or what
      a workaround is working around
- [ ] The **90 doc-comment blocks of 6 or more lines, 985 lines between them**,
      are gone or cut to four. They are the bulk of the work and most of the win
- [ ] No `public` symbol is exempt. `/// The court's surface.` over
      `public static let court` is the name again in a sentence and goes
- [ ] Deleted, not reworded. A comment that needs rewriting to fit the rule is
      one the rule says should not be there
- [ ] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched — it is
      navigation and Xcode's jump bar reads it
- [ ] Anything genuinely load-bearing that a deletion would lose moves to
      `docs/adr/` or to the ticket that owns it, rather than to the bin. The
      closing note lists every rescue and where it went
- [ ] The diff contains **no line of code** — comments, and the blank lines and
      orphaned `- Parameter` callouts a deletion strands, and nothing else
- [ ] `swift test --package-path Packages/PadelDesign` is clean and both app
      schemes build, which is what proves the previous criterion
- [ ] The closing note states the area's doc and inline line counts **before and
      after**, and names any symbol whose deleted comment left the name looking
      thin — the rename is a later ticket's, not this one's

## Notes

**`court-surface` planted essays here on purpose, and they are in scope.** That
feature's spec chose doc comments over an ADR — "the reasoning lands as doc
comments on the surface token and on `CourtHalf`, which is where the next person
looks before re-adding a service line". `CourtHalf`'s comment is sixteen lines
of argument about why the painted lines were deleted. It is a real decision and
it is in the wrong container: rescue it to an ADR and leave the code with the
four lines a reader needs.

**The three preview files are the densest and the least load-bearing.**
`Tokens/Previews.swift`, `Court/CourtPreviews.swift` and
`Controls/ControlPreviews.swift` carry file-level preambles explaining what each
board is for. A `#Preview("The halves")` names itself.

**`Tests/PadelDesignTests/Raster.swift` is the exception to look at twice.** Its
preamble explains why the suites rasterize at all and why the assertions are
written in fractions rather than points — that is a constraint a test author
would otherwise get wrong, which is exactly what the rule keeps. Cut it to four
lines; do not delete it.

**The test suites' `///` blocks are mostly argument.** A `@Test` already carries
a sentence in its name. Where the doc comment above it restates that name, it
goes; where it records the measured threshold a test was calibrated against, it
stays, cut short.
