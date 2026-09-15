# 01: The one surface

**What to build:** the court as a single blue with no painted lines — the
palette collapsed, the line geometry deleted, `courtLit` added, and the history
tile's four grounds redrawn on top of it.

**Blocked by:** None

**Status:** done

- [x] `Color.court` is `#17406F` and replaces `theirHalf` and `ourHalf`, which are
      deleted. Its doc comment says the court is one color because a court is one
      color, and that which half is ours is said by position and the net
- [x] `Color.courtInk` is `#E6EEF8` and replaces `inkTheirHalf` and `inkOurHalf`
- [x] `Color.courtLit` is added — the surface brightened against itself, about
      `#2C70AE` — with a doc comment saying it means *this court is live* and is
      read by two things: a rally landing, and a match still running
- [x] `courtSurface(dimmed:)`, `courtInk`, `courtInk(_ outcome:)` and
      `courtWeave(dimmed:)` keep their names and lose their `Side`. The
      `ShapeStyle` mirror in `Palette.swift` follows every one of them
- [x] `courtLine(_:on:dimmed:)`, `lineOpacity(_:on:)`, `Color.lineTheirHalf` and
      `Color.lineOurHalf` are deleted. `CourtDimming.paint` stays — the net's
      tape and posts still dim by it
- [x] `CourtLine`, `PaintedLine` and `CourtMetrics.serviceLine` are deleted, along
      with `CourtMetrics.line` and `CourtMetrics.outlineInset` if nothing else
      reads them. Deleted, not left unused: dead public API in a design package
      gets half-used a year later
- [x] `CourtHalf` keeps its name and loses its `side` parameter. Its doc comment
      carries the paragraph that matters most in this ticket — **the lines were
      removed deliberately**: a real padel half is square, the drawn half is a
      letterbox, so every line landed in the right fraction of the wrong shape,
      and the outline was a tennis import for an edge that is glass. Without that
      paragraph the next reader writes the service line back
- [x] `Court` is unchanged in shape — half, net, half — and every call site that
      passed a `Side` to a half stops passing one
- [x] `courtWeave` is one value. Pick one of the two it collapses (0.028 / 0.032)
      or the round number between them, and say in the comment that the weave is
      now the only texture on the surface
- [ ] `CourtDimming.surface` is re-picked on a device and its doc comment
      **rewritten**. The current sentence — "at 0.72 the two halves measured 0.021
      apart in luminance and read as one black rectangle" — is about a constraint
      this ticket removes, and must not be left standing
- [x] `CourtTile` draws four grounds and no new hue: **won** is `court` with the
      ball's glow it already has; **lost** is `night` with a `hairline` border and
      nothing else — no lift, no floodlight; **abandoned** is the existing
      `surfaceQuiet` lift **without** the floodlight; **in progress** is
      `courtLit`. Its doc comment's "won is the turf we play on, lost is the cold
      glass across the net" is rewritten to what the tile now says
- [x] The six assertions that pin the old rule are **deleted, not loosened**:
      `PaletteTests`' four per-side differences (surface, ink, line, weave) and
      `TileTests`' `won == .ourHalf` / `lost == .theirHalf`
- [x] New tests in their place: the surface and the ink each resolve to one value;
      `courtLit` is measurably brighter than `court` **at the same hue** (channel
      ratios, not luminance alone — luminance alone is satisfied by any lift); and
      the tile's four grounds are four measurably different fills
- [x] `NetTests`' two pixel probes (`.theirHalf` above, `.ourHalf` below) are
      updated to the one surface, and `CourtTests`' line-geometry assertions go
      with the lines
- [x] Every string and doc comment naming the old colors is corrected:
      `ScoreView`'s "turf green against their glass blue", `docs/design/README.md`'s
      "turf green against glass blue", and anything `grep -rn "turf\|glass blue"`
      turns up in `Packages` and both app targets
- [x] `CONTEXT.md`'s **Rally mark** entry drops "in its own color" for the
      surface's own color. **Court half** and **Serving half** are already
      written and need nothing here — read them before touching a doc comment, so
      the code says "court half" where it means the ground and never a bare
      "half", which now belongs to neither cut on its own
- [x] `docs/design/RallyMark.html` gets one line saying the night court it fires
      against is no longer what ships, and that candidate B — the painted lines
      flaring — is now unbuildable rather than merely rejected
- [x] `.scratch/rally-mark/spec.md` and `issues/01-the-mark.md` are corrected
      where this ticket makes them wrong: the per-side strength becomes one
      number, `Color.rallyMark(on:)` becomes `Color.courtLit`, the mark becomes a
      fill rather than a blend, and the consequence about a half's identity
      resting on its color is settled rather than deferred
- [x] `swift test --package-path Packages/PadelDesign` is clean, and so is the
      whole package suite
- [x] Both app schemes build, and the two shipped screens are **driven on a
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

## Comments

Built and closed, with one criterion left open and three things for the owner to
arbitrate.

**What shipped.** `Color.court` (`#17406F`), `Color.courtInk` (`#E6EEF8`) and
`Color.courtLit` (`#2C70AE`) replace the six per-half tokens. `courtSurface`,
`courtInk`, `courtInk(_ outcome:)` and `courtWeave` kept their names and lost
their `Side`; `courtLine`, `lineOpacity`, `CourtLine`, `PaintedLine`,
`CourtMetrics.serviceLine`, `.line` and `.outlineInset` are deleted. The weave is
one value at 0.03. `CourtHalf` lost its parameter and carries the paragraph
saying the lines went on purpose. Both apps stopped passing a `Side` to a half —
`ScoreView`, `OutcomeView`, `StartView`'s `ServeCapsule` and `MatchCard`.

**The tile's four grounds.** Won is `court` with the glow, lost is `night` inside
a `hairline` with no lift and no light, abandoned is `night` lifted and unlit, in
progress is `courtLit`. `courtInk(_ outcome:)` follows them rather than the
winner: the two on the court take `courtInk`, the two on `night` take
`.ink.weight(.control)`. The ticket did not spell that out, but leaving it on the
old rule would have set a lost tile's score brighter than a won one's.

**Tests.** The six assertions pinning the old rule are deleted. In their place:
the surface, the ink and the weave each resolve once; `courtLit` is brighter than
`court` at the same hue, checked as channel ratios with white, the floodlight and
the ball run through the same check to show it rejects them; the tile's four
grounds are four measurably different fills; and `CourtHalf` carries no line,
checked as no row and no column standing off the surface by more than 0.01.
`swift test` is clean across all four packages, both schemes build, and
`PadelTests` passes.

**Driven.** Watch: start screen, score screen mid-match (40 : 30, two games) and
the outcome screen, in both languages. Phone: the history with a won, a lost and
an abandoned match seeded into the simulator's database, in both languages and at
`accessibility-extra-extra-extra-large`, plus the match card.

**The one criterion left open: `CourtDimming.surface` was not re-picked on a
device.** It is 0.72, up from 0.55 now that there is no second tint for it to
stay clear of. That number was settled from rendered measurements — the dimmed
surface at 0.119 luminance against `night`'s 0.079, still blue at rgb(7, 34, 51),
`courtInk` standing off it at 5.8 : 1 — and the doc comment says exactly that
rather than claiming a wrist. Neither the watch simulator nor `simctl` offers a
way into Always-On, and `simctl ui … content_size` is refused by the watchOS
runtime, so the watch's largest-type pass did not happen either. A `TODO:` naming
this ticket sits above the constant.

**For the owner to arbitrate.**

1. **The match card's course bands are now one colour.** Every band was
   `courtSurface(step.winner)`; with one surface they are all `court`, so who
   took a step is said only by which of the two numerals is left at full
   strength. The ticket asked for the `Side` to go and said nothing about
   replacing the signal, so it went. `courtLit` for the winning side's band
   would restore it at no new hue, and that is a change worth making
   deliberately rather than as a side effect of this one.
2. **`OutcomeView` diverges from the tile.** A win and a loss now stand on the
   same court there, where the tile puts a loss on `night`. Only abandoned is
   `night` on that screen. The ticket's mechanical rule gives this; matching the
   tile would be a design decision it did not ask for.
3. **ADR-0011 is now stale in two places** — it says `courtSurface`, `courtLine`,
   `courtInk` and `courtWeave` "are all per-side answers", and that which half is
   ours "is said today by turf green against glass blue", which is the debt
   `rally-mark`'s spec now records as settled. Per `docs/agents/domain.md` an ADR
   conflict is flagged rather than silently rewritten, so it is untouched and
   named here. It matters because `.scratch/` is emptied when a feature closes
   and the ADR is where the correction would last.

**Also corrected, beyond the listed files:** `.scratch/phone-scoring/spec.md` and
`issues/04`, and `.scratch/watch-tap-mode/spec.md`, all of which stated the
two-colour rule as fact and would have instructed a later agent to rebuild it.

**Review.** `code-review` raised: the `blue > green` guard in `AlwaysOnTests`
passed at any dimming fraction, since `night` is blue-dominant too — fixed, it
now measures the distance between the channels; a duplicated corner patch in
`TileTests` and a vacuous re-pinning of `courtInk`'s hex in `PaletteTests` —
both fixed; and doc comments on `Color.court` and `Color.courtInk` narrating the
superseded two-tone design, against CLAUDE.md's "rationale lives elsewhere" —
trimmed. Left for the owner as judgment calls: that `CourtHalf` now takes no
argument and draws no half (the ticket required the name), that `CourtTile.tint`
keeps a word the rest of the change retired for "ground", and the repeated
`MatchOutcome` switches.
