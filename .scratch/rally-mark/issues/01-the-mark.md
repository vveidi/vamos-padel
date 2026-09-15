# 01: The mark

**What to build:** the rally mark as a primitive in `PadelDesign` — a half
brightening to `courtLit` and falling back — and the one strength it is drawn
at.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `Packages/PadelDesign/Sources/PadelDesign/Court/RallyMark.swift` holds it,
      and it knows nothing about a match: a `Side`, a tier, and a trigger that
      changes when a rally lands. ADR-0006's seam — the package is asked for a
      marked half and nothing more
- [ ] It is laid **over** a half and takes no room from the layout, the guarantee
      `Floodlight` and `ServeIndicator` both state in their doc comments and for
      the same reason: the court under it is full-bleed
- [ ] The half brightens in the **surface's own** color — `courtLit`, the court
      lifted in value with its hue kept. Not white, not `floodlight`, not
      `ball`. Four of the five candidates in `docs/design/RallyMark.html` also
      get brighter; being the same color afterwards is what distinguishes this
      one
- [ ] The mark is a **fill** of `courtLit` animated 0 → 1 → 0, not a blend mode
      over the surface. `court-surface` 01 added the token and `PaletteTests`
      already pins its hue against `court`, so what is left here is the one
      strength — whether the peak sits below full `courtLit` — settled by eye at
      watch size, with a doc comment saying what was measured, as `CourtDimming`
      does
- [ ] Two tiers, differing in **time only** — a rally, and a rally that took a
      game or a set, which holds at its peak before it falls. Strength is the
      surface's and a tier must not touch it
- [ ] The view splits: **what it looks like at a given strength** is renderable
      on its own, and **when it plays** wraps it. The first is what the tests and
      the previews use; the second is tested by nobody
- [ ] Raster tests in `Tests/PadelDesignTests/Court/`, mirroring the source
      folder: at peak the marked half is measurably brighter than unmarked; its
      **hue is unchanged**; the other half is untouched to the pixel; and the
      half's weave measures the same with the mark and without, which is the
      overlay guarantee stated as a number
- [ ] **No `isLuminanceReduced` anywhere in the file**, and a doc comment saying
      why there is no dimmed variant when every other court primitive has one
      (ADR-0011: the mark is never on screen with the luminance reduced)
- [ ] **No `accessibilityReduceMotion` either**, and a comment giving the reason,
      because without one this reads as an omission and gets "fixed"
- [ ] Previews: both halves, both tiers, held at peak
- [ ] `swift test --package-path Packages/PadelDesign` is clean

## Notes

**Why the split into two views is a requirement and not a suggestion.**
`ImageRenderer` draws a static view, so an animation is not raster-testable and a
preview of one shows its resting state — which for this mark is nothing at all. A
mark that can only be seen by playing it can be neither tested nor reviewed. The
inner view takes a strength and draws it; the outer one decides when, and owns
the two durations.

**The test that matters is the hue test.** "It got brighter" is satisfied by the
floodlight burst, by the paint flare, by the ball wash and by the competitor's
green. What was chosen is the one that gets brighter *without changing color*,
and that is the claim worth a number. Compare the marked half's channel ratios
against the unmarked half's, not its luminance alone.

**Where the strength number comes from.** By eye, at the size the screen is read
at, and written into the doc comment with what was seen — `CourtDimming.surface`
is the model, and its doc comment says what it was settled against rather than
what its value is. A number in this repo says what it was settled against.

**Nothing here is built for the themes.** They are near-term, and they still get
no seam: every court color is already one answer in one file, so a surface
threaded through `CourtColors.swift` threads this with it. A seam built here
would be a second one beside the one that already exists.
