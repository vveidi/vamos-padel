# 01: The one surface

**What to build:** the court as a single blue with no painted lines — the
palette collapsed, the line geometry deleted, `courtLit` added, and the history
tile's four grounds redrawn on top of it.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `Color.court` is `#17406F` and replaces `theirHalf` and `ourHalf`, which are
      deleted. Its doc comment says the court is one color because a court is one
      color, and that which half is ours is said by position and the net
- [ ] `Color.courtInk` is `#E6EEF8` and replaces `inkTheirHalf` and `inkOurHalf`
- [ ] `Color.courtLit` is added — the surface brightened against itself, about
      `#2C70AE` — with a doc comment saying it means *this court is live* and is
      read by two things: a rally landing, and a match still running
- [ ] `courtSurface(dimmed:)`, `courtInk`, `courtInk(_ outcome:)` and
      `courtWeave(dimmed:)` keep their names and lose their `Side`. The
      `ShapeStyle` mirror in `Palette.swift` follows every one of them
- [ ] `courtLine(_:on:dimmed:)`, `lineOpacity(_:on:)`, `Color.lineTheirHalf` and
      `Color.lineOurHalf` are deleted. `CourtDimming.paint` stays — the net's
      tape and posts still dim by it
- [ ] `CourtLine`, `PaintedLine` and `CourtMetrics.serviceLine` are deleted, along
      with `CourtMetrics.line` and `CourtMetrics.outlineInset` if nothing else
      reads them. Deleted, not left unused: dead public API in a design package
      gets half-used a year later
- [ ] `CourtHalf` keeps its name and loses its `side` parameter. Its doc comment
      carries the paragraph that matters most in this ticket — **the lines were
      removed deliberately**: a real padel half is square, the drawn half is a
      letterbox, so every line landed in the right fraction of the wrong shape,
      and the outline was a tennis import for an edge that is glass. Without that
      paragraph the next reader writes the service line back
- [ ] `Court` is unchanged in shape — half, net, half — and every call site that
      passed a `Side` to a half stops passing one
- [ ] `courtWeave` is one value. Pick one of the two it collapses (0.028 / 0.032)
      or the round number between them, and say in the comment that the weave is
      now the only texture on the surface
- [ ] `CourtDimming.surface` is re-picked on a device and its doc comment
      **rewritten**. The current sentence — "at 0.72 the two halves measured 0.021
      apart in luminance and read as one black rectangle" — is about a constraint
      this ticket removes, and must not be left standing
- [ ] `CourtTile` draws four grounds and no new hue: **won** is `court` with the
      ball's glow it already has; **lost** is `night` with a `hairline` border and
      nothing else — no lift, no floodlight; **abandoned** is the existing
      `surfaceQuiet` lift **without** the floodlight; **in progress** is
      `courtLit`. Its doc comment's "won is the turf we play on, lost is the cold
      glass across the net" is rewritten to what the tile now says
- [ ] The six assertions that pin the old rule are **deleted, not loosened**:
      `PaletteTests`' four per-side differences (surface, ink, line, weave) and
      `TileTests`' `won == .ourHalf` / `lost == .theirHalf`
- [ ] New tests in their place: the surface and the ink each resolve to one value;
      `courtLit` is measurably brighter than `court` **at the same hue** (channel
      ratios, not luminance alone — luminance alone is satisfied by any lift); and
      the tile's four grounds are four measurably different fills
- [ ] `NetTests`' two pixel probes (`.theirHalf` above, `.ourHalf` below) are
      updated to the one surface, and `CourtTests`' line-geometry assertions go
      with the lines
- [ ] Every string and doc comment naming the old colors is corrected:
      `ScoreView`'s "turf green against their glass blue", `docs/design/README.md`'s
      "turf green against glass blue", and anything `grep -rn "turf\|glass blue"`
      turns up in `Packages` and both app targets
- [ ] `CONTEXT.md`'s **Rally mark** entry drops "in its own color" for the
      surface's own color. **Court half** and **Serving half** are already
      written and need nothing here — read them before touching a doc comment, so
      the code says "court half" where it means the ground and never a bare
      "half", which now belongs to neither cut on its own
- [ ] `docs/design/RallyMark.html` gets one line saying the night court it fires
      against is no longer what ships, and that candidate B — the painted lines
      flaring — is now unbuildable rather than merely rejected
- [ ] `.scratch/rally-mark/spec.md` and `issues/01-the-mark.md` are corrected
      where this ticket makes them wrong: the per-side strength becomes one
      number, `Color.rallyMark(on:)` becomes `Color.courtLit`, the mark becomes a
      fill rather than a blend, and the consequence about a half's identity
      resting on its color is settled rather than deferred
- [ ] `swift test --package-path Packages/PadelDesign` is clean, and so is the
      whole package suite
- [ ] Both app schemes build, and the two shipped screens are **driven on a
      simulator** and screenshotted: the watch's score screen mid-match, and the
      phone's history with a won, a lost and an abandoned match in it

## Notes

**Why `courtLit` is one token and not two light blues.** A rally landing and a
match still running are the same statement — *this court is live* — and two
places picking their own light blue drift a shade apart the first time one is
re-tuned. It also removes a concept from `rally-mark` 01: with a token to fill
with, the mark is an opacity animation on a rectangle rather than a `mix-blend-mode`
argument that has to be re-derived by whoever reads it next.

**The hue test is the one worth writing.** `courtLit` must be brighter *and the
same color*. "It got brighter" is satisfied by white, by the floodlight and by
the ball — the three candidates ADR-0011 rejected. Compare channel ratios against
`court`, the way `rally-mark` 01 already asks for.

**What the loss tile costs, and why it was still chosen.** A lost match is
`night` on a `night` list, separated by a 0.12 hairline and nothing else. Three
schemes were drawn; the two alternatives put a loss and an abandoned match within
eight hundredths of each other, which fails at exactly the glance the tint exists
for. The quiet loss was picked with its cost known: a month of losses is a very
quiet screen.

**The `Side` does not leave the package.** `PadelDesign` still depends on
`PadelScoring` and still takes a `Side` wherever a side is genuinely meant — the
tile's outcome, the serve indicator, the score zones. What goes is the `Side`
passed to things that are no longer different per side. ADR-0006's seam is
untouched.

**Re-drive, do not re-reason.** Both changed screens are shipped code with real
users' matches behind them. The dimming number in particular cannot be settled
from a canvas: it is an Always-On question and answers only on a watch.
