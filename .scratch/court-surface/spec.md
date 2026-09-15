# The court surface: one blue, no lines, and the icon that follows

Status: ready-for-agent

## Problem Statement

The court is drawn as two surfaces with three painted lines on each half. Both
halves of that sentence are now wrong.

**A real padel court is one color.** Ours is two — glass blue across the net,
turf green on our side — and the second color was never decoration: it is what
says which half is ours, on both score screens and on every tile in the history.
That was a good answer to a question nobody else had asked. It is still not what
a court looks like.

**The lines are geometrically honest and visually wrong.** The service line sits
at 30% of the half, which is where it sits on a real court. But a real padel half
is 10m by 10m — square — and the half on a watch is 198pt wide and about 120pt
deep. Every line lands in its correct *fraction* of a shape that is not the
court's shape, so the service boxes are letterboxes and the line a player looks
for is nowhere near where they look. The outline is worse than misplaced: it is a
tennis import. A padel court's edge is glass and mesh, and a painted sideline
inside the half draws a boundary that does not exist.

At watch size, on a screen tapped with a wet hand between rallies, all of that is
attention spent on nothing. This feature spends it back.

## What is in, and what is not

In:

- **One surface**, `#17406F`, on both halves and on both devices.
- **No painted lines.** `CourtLine`, `PaintedLine` and `CourtMetrics.serviceLine`
  are deleted, not left unused.
- **One ink**, `#E6EEF8`, for anything standing on the court.
- **`courtLit`** — the court brightened: what a rally mark is made of, and what a
  match still running is drawn on.
- **The history tile's four grounds**, now that won-and-lost can no longer be two
  hues.
- **The weave**, kept, at one value; and **the Always-On dimming**, re-tuned now
  that it answers to burn-in alone.
- **The app icon**: a study holding two candidates, and the winner shipped to
  both targets.

Not in:

- **Themes.** `RallyMark.html` fires four surfaces and three of them do not
  exist. This feature does not build them and does not build a seam for them.
- **A light mode.** ADR-0006 stands.
- **Any change to `night`.** The ground stays the ground: it is what the ball
  glows against, what every screen outside the match stands on, and — as of this
  feature — what a lost match is drawn on.
- **A new ADR.** Weighed and declined: of the three tests an ADR is held to, this
  fails *hard to reverse*. It is one palette value and a handful of deleted
  shapes, and git holds the lines. The reasoning lands as doc comments on the
  surface token and on `CourtHalf`, which is where the next person looks before
  re-adding a service line.
- **The live tile.** `phone-scoring` 05 owns showing a running match in the
  history. This feature only decides what ground it will stand on when it arrives.
- **Re-tuning the rally mark.** `rally-mark` 01 owns the mark. This feature hands
  it a brighter base and names the re-check; it does not do it.

## The design, in words

**One court, because a court is one color.** The two surfaces go and `#17406F`
takes both halves. It is the darker of the two blues in `docs/design/RallyMark.html`'s
`hard` theme, chosen over the lighter `#215687` and over a real turf blue after
seeing all three full-bleed at watch size.

**What the second color was doing, something else now does.** Which half is ours
was said by turf green against glass blue. It is now said by position — theirs
above the net, ours below, the same as when you stand on court — and by the net
between them. That is the arrangement every screen already had; it simply stops
having a spare signal on top of it.

**No lines, and the code goes with them.** Dead public API in a design package is
not free: it is rediscovered a year later and half-used. The court with lines
survives in exactly one place, which is the icon, where a court is a picture
rather than a surface to be read at a glance.

**Light means live.** The mark and a match in progress are the same statement —
*this court is live* — so they are the same color: `courtLit`, the surface
brightened against itself. One token, read by both. This also simplifies
`rally-mark` 01: the mark stops being a blend mode and becomes a fill animated
0 → 1 → 0, which is the same pixels and one concept fewer.

**The tile keeps four grounds and spends no new hue.** A win is the court. A loss
is `night` with a hairline and nothing else — no lift, no light, the quietest
thing on the list, which is what a loss should be. An abandoned match is the gray
lift it already has, unlit: no result, and no light on it either. A match still
running is `courtLit`.

## Solution

### The palette

`Color.theirHalf` and `Color.ourHalf` collapse into **`Color.court`**.
`Color.inkTheirHalf` and `Color.inkOurHalf` collapse into one ink.
`Color.lineTheirHalf` and `Color.lineOurHalf` are deleted outright. A new
**`Color.courtLit`** is added beside them.

`courtSurface(_:dimmed:)`, `courtInk(_:)` and `courtWeave(on:dimmed:)` keep their
names and lose their `Side`. `courtLine(_:on:dimmed:)` and the private
`lineOpacity(_:on:)` go. `CourtDimming.paint` stays — the net still dims by it.

### The geometry

`CourtHalf` keeps its name and loses its parameter. The half stays a type because
three unbuilt features need to name one: the mark brightens it, the scoreboard
taps it, the floodlight sits on it. Losing a parameter is not losing a type.

`Court` is unchanged in shape — half, net, half.

### The tests

Six assertions become false by construction and are deleted rather than
weakened. `PaletteTests` asserts the two halves differ in surface, ink, line and
weave; `TileTests` asserts a won tile is `ourHalf` and a lost one `theirHalf`.
They were written to pin a rule this feature retires, and a test kept alive by
loosening it is a test that no longer says anything.

What replaces them is the new rule stated as numbers: one surface, one ink, and a
tile whose four grounds are four measurably different things.

## Implementation Decisions

### `#17406F`, and it was looked at before it was chosen

Three blues were rendered full-bleed at watch size with the score on them — the
study's `#215687`, the study's `#17406F`, and `#1E5A8C`, which is close to real
blue padel turf under lights. The darker one won on being the more interesting
surface and pays two dividends beside: more contrast under the ink, and more room
for the Always-On dim to fall.

### The lines were not thinned, and not re-placed

Two smaller fixes were available — re-place the lines for the shape the screen
actually has, or drop the outline and keep the two lines padel really has. Both
were declined. The half is not a court to scale and cannot be made into one, and
a court drawn correct-but-tiny is still attention spent on a thing nobody reads
between rallies.

### `CourtDimming.surface` is re-picked, and its doc comment is rewritten

Its current number was settled against a constraint that no longer exists — "at
0.72 the two halves measured 0.021 apart in luminance and read as one black
rectangle". With one surface there is nothing to merge. The number now answers
only to burn-in and to whether the score is still readable, and the doc comment
has to say the new thing it was settled against, not the old one.

### The reasoning goes in doc comments, not in an ADR

The thing worth writing down is not "the court is blue" — anyone can see that.
It is that **the lines were removed on purpose and correctly**, because the next
reader will look at a court with no service line and reach for the fix. That
belongs on `CourtHalf` and on `Color.court`, one paragraph each, where it is hit
by whoever is about to write the line back.

## Consequences, stated plainly

- **`rally-mark`'s spec is now partly wrong and gets corrected here.** It
  specifies a *per-side* strength and lists "the mark sits on a surface whose
  color is the only thing saying whose surface it is" as a consequence to be paid
  later. With one surface the strength is one number and that debt is settled
  before it was ever owed.
- **ADR-0011's candidate B becomes unbuildable.** "The court's three painted
  lines flaring to full strength" was one of the four rejected marks; there are
  no lines to flare. The study keeps it — a rejected alternative is a record of
  an argument, not a proposal — with one line saying the court it was fired
  against no longer exists.
- **`phone-scoring` 04 draws the plain surface from the start** rather than
  drawing lines and deleting them in the next ticket.
- **A lost tile and the app's ground are the same color.** A hairline is the only
  thing between them. That is deliberate and it is the option that was drawn and
  picked against two alternatives, but it means the history of a bad month is a
  very quiet screen.
- **Two built screens change appearance.** The watch's score screen and the
  phone's history are shipped code; this feature re-drives both on a simulator
  rather than trusting that they still look right.

## The tickets

```
01  the one surface
02  the icon
```

01 depends on nothing. 02 depends on nothing either — the icon is drawn against
the same blue but touches none of the same files — though 01 going first means
the icon is chosen next to a court that already looks the way it will ship.

Both go ahead of `rally-mark`, `phone-scoring` 04 and `watch-tap-mode` 04, all of
which draw this surface.
