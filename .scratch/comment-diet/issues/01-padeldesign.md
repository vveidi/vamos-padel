# 01: PadelDesign

**What to build:** `Packages/PadelDesign` held to `CLAUDE.md`'s rewritten
"Writing comments" — 39 files, 4,886 lines, 1,426 doc-comment lines and 248
inline, the heaviest area in the repo.

**Blocked by:** None

**Status:** done

- [x] Every `.swift` file under `Packages/PadelDesign` — `Sources/` and
      `Tests/` both — is read and its comments held to the rule: the default is
      no comment, and what survives names a precondition, a unit, a threading or
      ownership rule, a failure mode, where a measured number came from, or what
      a workaround is working around
- [x] The **90 doc-comment blocks of 6 or more lines, 985 lines between them**,
      are gone or cut to four. They are the bulk of the work and most of the win
- [x] No `public` symbol is exempt. `/// The court's surface.` over
      `public static let court` is the name again in a sentence and goes
- [x] Deleted, not reworded. A comment that needs rewriting to fit the rule is
      one the rule says should not be there
- [x] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched — it is
      navigation and Xcode's jump bar reads it
- [x] Anything genuinely load-bearing that a deletion would lose moves to
      `docs/adr/` or to the ticket that owns it, rather than to the bin. The
      closing note lists every rescue and where it went
- [x] The diff contains **no line of code** — comments, and the blank lines and
      orphaned `- Parameter` callouts a deletion strands, and nothing else
- [x] `swift test --package-path Packages/PadelDesign` is clean and both app
      schemes build, which is what proves the previous criterion
- [x] The closing note states the area's doc and inline line counts **before and
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

## Comments

**Done.** 38 `.swift` files under `Sources/` and `Tests/`, read in full and cut.

| | before | after |
| ---------------- | ----: | ----: |
| total lines | 4,839 | 3,638 |
| doc comments | 1,419 | 333 |
| inline comments | 233 | 122 |
| comment share | 34% | 12.5% |

`// MARK:` is untouched: 39 lines before and after. No `TODO:` or `FIXME:`
existed to convert. The counts are `Sources/` plus `Tests/`, excluding
`Package.swift` and `.build/` — the ticket's 39 files and 4,886 lines counted
`Package.swift` in, which this pass leaves alone.

**The diff contains no line of code**, checked mechanically rather than by eye:
every file was stripped of comments and blank lines before and after the pass
and the two compared, and the comparison is empty. `swift test` is clean and
both app schemes build on a simulator destination.

- **One rescue: ADR-0012, "A court with no painted lines."** `CourtHalf`'s
  sixteen-line argument about why the service lines and the outline were
  removed — the half is a letterbox, so a line at its correct fraction lands in
  the right fraction of the wrong shape, and a padel court's edge is glass
  rather than paint. It took `CourtColors`'s "nothing here takes a `Side`" and
  `CourtMetrics`'s "the one proportion it used to hold was the service line's"
  with it, since all three are one decision. `CourtHalf` now cites the ADR in
  two lines.

- **Nothing else was rescued.** Everything else that read as an argument was
  either already in ADR-0006 or ADR-0011, or was narration rather than a
  decision.

- **Names left looking thin, for a later ticket.** `InkWeight`'s ten cases lost
  their glosses, and `strong`, `secondary` and `tertiary` no longer say where
  each is spent; `ControlMetrics`'s paddings lost the word that said which axis
  they are on — `segmentPadding` and `pillPadding` are horizontal,
  `pillPaddingVertical` says so. Renaming is out of this feature's scope by its
  spec.

- **One deleted comment was wrong.** `PillButton.Variant.ink` claimed to colour
  "the ball's seams with it"; the seams come from `Finish.seam` and never from
  the variant's ink. Deleting it was right for two reasons.

- **Two deleted comments had gone stale.** `ChoiceRow`'s header and
  `ControlsTests`'s chevron test both said "the brief allows no chevron" — the
  row has worn one since `court-surface`. `PackageIsolationTests`'s parser test
  explained itself by pointing at prose in its own file header that this pass
  removed.

- **Kept, against the general cut:** the measured numbers. `CourtDimming`'s
  0.119-against-0.079 luminance reading, `CourtMetrics`'s CSS-blur-is-twice-
  SwiftUI's conversion, `Ball`'s cubic-midpoint derivation of `seamBow`,
  `RenderingTests`'s finding that macOS has no Dynamic Type at all, and the
  thresholds in `Raster`, `NetTests` and `PaletteTests` that were calibrated
  against a specific shadow or drift. Those are what the rule exists to keep.

- **Not driven on a simulator, and it should not be.** The ticket's own proof
  is `swift test` plus both schemes building; there is no state to put on
  screen, because no line of code moved.
