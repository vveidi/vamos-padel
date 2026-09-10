# 02: The court, the net and the ball

**What to build:** The three shapes the boards keep repeating, as views in
`PadelDesign`: a court half, the net seen from above, and the ball. Plus the
two light effects that sit over them.

**Blocked by:** 01

**Status:** done

- [x] `CourtHalf(side:)` draws the tinted surface, the weave, the service line,
      the center line and the outline — mirrored correctly for the top half
- [x] `NetLine()` is a bright tape with a post at **each end**, not a band of
      mesh
- [x] `Ball(size:)` is drawn, not `Image(systemName: "tennisball.fill")`
- [x] `Floodlight(corner:)` and `NightScrim(edge:)` exist as overlays that take
      no room from the layout
- [x] A `Court` convenience composes half · net · half for the four screens
      that want the whole thing
- [x] Nothing in the package imports anything from `PadelScoring` but `Side`
- [x] Previews cover both halves, the net at watch and phone scale, the ball at
      every size it is used at, and the whole court on both platforms

## The geometry

Read off the boards, in fractions rather than pixels — these are drawn on two
screen sizes and must not be a table of magic numbers.

**Their half (top):** service line at **30%** from the top, center line running
from the service line **down** to the net, outline inset ~5% on the left, right
and top with no bottom edge — the net is the bottom edge.

**Our half (bottom):** service line at **30%** from the bottom, center line
running from the net **down** to the service line (70% of the half), outline
inset on left, right and bottom with no top edge.

The mirror is the point: the two halves are the same court seen from our end,
which is the same argument `ScoreView`'s `serveAlignment(for:from:)` makes
about the ball. Write it as one view with a `side` rather than two views that
happen to look alike, or the mirror will be "fixed" in one of them.

**The weave** is `repeating-linear-gradient(115deg, …)` at 2px on, 4px off, in
white at 0.028 (theirs) and 0.032 (ours). It is texture, not pattern: at a
glance it should read as a surface and not as stripes. On watch it may need to
be coarser to survive the smaller screen — check it on a device, not in a
preview.

**The line weights** are 2px on both boards. At 2x on the watch that is 1pt,
which is a hairline and probably right; on the phone the board is 1x and 2pt is
right. Take them per platform rather than sharing one number.

## The net

The single most repeated shape in the design and the one most likely to be got
wrong. From the boards:

```
  ▌ ────────────────────────────────────────── ▐   ← tape, ink at 0.82
  ↑                                            ↑
  post, ink at 0.9, extending above the tape
```

Tape 4px on the watch board (2pt), 3px on the phone (3pt). The posts are the
tape's own width, roughly 3× its height, and they extend **above** the line
(toward their half) — that is what makes it read as seen from above rather than
as a divider. A drop shadow underneath (`0 3px 9px` black at 0.5) lifts it off
the court; without it the net looks painted on.

It is not a mesh, not a dashed line, and not a `Divider()`.

## The ball

Today it is `Image(systemName: "tennisball.fill")` at 10×10, white. It becomes
a drawn ball: a filled circle in `ball` yellow with **two seam arcs** in dark
green at ~0.4 opacity, curving in from the left and right edges.

```
    ╭───────────╮
   ╱ )         ( ╲
  │  )         (  │
  │  )         (  │
   ╲ )         ( ╲
    ╰───────────╯
```

From the board's SVG, on a 24-unit box: circle at `(12, 12)` r `11`; arcs
`M3.6 4.3c3.9 3 3.9 12.4 0 15.4` and its mirror at `x = 20.4`, stroked at 1.5.
A `Path` in a `Canvas` or a `Shape` — either is fine, but it must scale, since
it is drawn at 10pt in a score zone and at 21pt on a button.

Sizes it appears at: watch score corner (the size the dot has today), watch
start screen on the net (40px board = 20pt), phone tile and button (21–34pt).

**It is yellow now, not white.** `ScoreView`'s current comment argues for white
— "a fifth color on a screen that has three would be spent on the smallest
thing on it". That argument is retired by this design: the ball's yellow *is*
the app's only color, and the smallest thing on screen is exactly what it is
spent on. Delete the comment rather than leaving it to contradict the code.

## The light

**`Floodlight(corner:)`** — a radial gradient of warm white, from one corner,
falling to clear by ~60% of the way across. Which corner varies by board (top
left on the watch start and phone new match, bottom right on the score screens,
top right on the history); pass it in.

It is a **light**, not a hue. If it starts reading as a second accent colour,
it is too strong or too saturated.

**`NightScrim(edge:)`** — the `night` gradient that lets the court run full
bleed *under* floating controls while keeping them legible. Top edge on the
phone score board, bottom edge under the buttons on four boards.

Both are overlays. Neither may affect layout — `ScoreView`'s comment about the
serve indicator ("an overlay is the whole of that guarantee — it takes no room
from the layout") applies to these for the same reason.

## Notes

**On `Court` versus composing by hand.** Four screens want half · net · half
with the two halves equal. One view for it, and the screens that want something
else — the phone's new-match board frames the court in a rounded card, the
score screens fill each half with a number — get the halves and the net
separately. Both doors stay open.

**On what this ticket must not grow into.** No `ScoreZone`, no tap handling, no
`Points`. A court that knows a rally has been won is over the seam. The test
from the spec: could a screen that has never heard of a rally use it?

**On Always-On.** Ticket 10 gives these primitives a dimmed variant. Do not
pre-empt it here, but do not paint yourself out of it either: keep the weave,
the floodlight and the surface tints separable, so that 10 can drop them
without unpicking the geometry.

## Comments

### Closing note

Seven files in `Packages/PadelDesign/Sources/PadelDesign`: `CourtMetrics`,
`CourtHalf` (with `PaintedLine` and `Weave`), `NetLine`, `Court`, `Ball`,
`Light` (`Floodlight` and `NightScrim`) and `CourtPreviews`. No screen was
touched — the package is the whole of it, and tickets 04–09 are where it lands
on glass.

**How each criterion was checked.** Geometry does not show up in a value, so
the suites render the views and read the pixels back: `Tests/…/Raster.swift`
runs `ImageRenderer` on the Mac and samples patches out of the bitmap, and
`CourtTests`, `NetTests`, `BallTests` and `LightTests` assert against it — 22
new cases, 40 in the package. They measure the service line at 30% of each
half, that the centre line stops at it, that the outline has three sides and
the net edge is bare, that the tape spans the width with the same post at each
end, that the posts add no height to the layout, that the ball is `ball` yellow
with two seams and is 22/24 of its frame at all seven sizes it is drawn at, and
that neither light changes the size of what it is laid over. The mirror is
checked head-on: every row carrying a line across their half must carry one
across ours at the mirrored row and nowhere else. Flipping `scaleX: 1, y: -1`
to `y: 1` was tried, and it fails seven cases — the suite is not vacuous.

Both app targets build against the package (watchOS 26.5 and iOS simulators),
`swiftlint` is clean across `PadelDesign`, and `grep` over the sources finds
`Side` and no other `PadelScoring` symbol.

**Departures from the ticket as written.**

- **The posts are centred on the tape, not only above it.** The prose says they
  "extend **above** the line (toward their half)"; every board draws them
  symmetric — `top: -4px` on a 4px tape, 12px tall — so a post rises into their
  half and drops into ours by the same amount. The boards won: seen from
  directly overhead a post has no near end, and the asymmetry would read as a
  perspective the rest of the court does not have.
- **The floodlight is an `EllipticalGradient`, not a radial one.** The boards
  give the light a width and a height of its own (`85% 55%`, `70% 32%`), and a
  circle centred on the corner of a screen twice as tall as it is wide lights a
  very different shape. The falloff stays in the token, which is clear by 62%.
- **`Ball` gained a `Finish`.** The history board draws the ball inverted —
  dark felt, `ball`-coloured seams — because on the yellow primary button the
  court's own ball is yellow on yellow. Two cases, `.onCourt` and `.cutOut`,
  and a `ballSeamCutOut` token beside `ballSeam` in `Palette`. Without it
  ticket 03 has to redraw the ball, which is the drift ADR-0006 exists to
  prevent.
- **`NightScrim` takes a `depth`.** The band is 150px on the watch board and
  120–130 on the phone's; the default resolves per platform and the parameter
  is there for the boards that differ.
- **The outline's inset is points, not a fraction.** The board's 10px is 5pt on
  the watch at 2x and 10pt on the phone at 1x — about 2.5% of the width and 4%
  of the half's height, so "~5%" could not be one number in both directions
  without the margin looking wider at the top than at the sides. It follows the
  rule the radii already document.

**Left open.** The weave is at the board's 2px on, 4px off, which the watch
takes as 1pt/2pt — back to exactly 2 and 4 physical pixels at 2x. Whether a
stripe that fine survives a wrist is the one thing the ticket says to check on
a device, and there is no screen drawing a court yet to check it on; ticket 04
is the first chance. If it needs coarsening it is `CourtMetrics.weave`, one
number.

`ScoreView`'s comment arguing for a white ball is still there. Ticket 04 owns
that line and already says so in its own notes, so deleting it from here would
have meant touching a screen this ticket has no business in.
