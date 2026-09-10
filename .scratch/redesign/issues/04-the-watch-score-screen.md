# 04: The watch score screen

**What to build:** `ScoreView` becomes the court. Two halves in glass blue and
turf green, the net between them, the score in `.score`, and the ball in the
serving half's corner.

**Blocked by:** 02

**Status:** done

- [x] Each zone is a `CourtHalf` — its own tint, weave, service line and center
      line — instead of a flat `.white.opacity(0.1)` / `ourColor.opacity(0.35)`
- [x] A `NetLine` sits between the zones, replacing the 2pt `VStack` spacing
- [x] The points use `.score`, the games `.scoreAside` on a shared baseline,
      the sets `.scoreAside` at the trailing edge — no `.system(size:)` left
- [x] The ball is `PadelDesign.Ball`, yellow, at the size the dot has today
- [x] `serveAlignment(for:from:)` is **unchanged** — same six cases, same doc
      comment, still file-private in `padel Watch App/`
- [x] The fade sequence in `ServeIndicator` is unchanged, including
      `.animation(nil, value: corner)`
- [x] `ScoreView.ourColor` is deleted; nothing outside `PadelDesign` names a
      colour
- [x] The page dots of `ScorePages` still sit over our bottom edge, and the
      inner corners are still clear of them and of the clock
- [x] Every VoiceOver label, value and action is exactly what it is today
- [x] All fourteen existing previews still build and still say what they said
- [x] Seen running, not only previewed

## What must not change

This screen carries more hard-won reasoning than any other in the app, and this
ticket is a repaint of it. Three things are load-bearing and are not this
ticket's to touch:

1. **The mirror.** `serveAlignment(for:from:)` maps `.right` to `.topTrailing`
   in our zone and `.bottomLeading` in theirs. It looks like a copy-paste slip,
   it is not, and its doc comment is the longest argument in the app. Do not
   simplify it, do not move it into `PadelDesign`, do not let a court primitive
   "normalize" it on the way past. `serving-half` ticket 02 names this as the
   likeliest thing an agent breaks while tidying.

2. **The fade.** The ball fades out, then in, never both at once, and the
   corner is excluded from every animation. `serving-half` 02's closing note
   records that the first version slid and that it took 100 screenshots at a
   1.2s fade to prove it. Changing the ball's *shape* must not change its
   *motion*.

3. **The gesture.** Tap awards, long press undoes, on `onTapGesture` rather
   than a `Button` because a button fires on release and would award a point
   after the undo. The court under it is still one `contentShape(Rectangle())`
   per zone.

## The type

The board's 92px at 2x reads as 46pt, against the 64pt on screen today. Do not
take either on faith — the spec's "Reading the boards" explains why the boards'
watch type is unreliable. Put `.score` on it, look at it on a device with a
four-character score ("40" beside a games digit beside a sets digit), and set
the ramp's watch value from that. `minimumScaleFactor(0.4)` stays either way.

## The colours the board gives

Their half `#0e3d4c` with text `#dcefe9`; our half `#12564f` with text
`#f4fffb`. Note our half is now a *real* colour rather than the accent green at
35% — `ourColor` was the app's one deliberate colour and it is retired here.
The board also puts a floodlight in the bottom right of our half and none in
theirs.

## Notes

**On the page dots.** The board does not draw them. They stay — see the spec.
The control page is the only way to end a match from the court.

**On seeing it run.** `watch-scoring` 04's note that taps do not reach the app
is **stale**: the tap tool was merely not exposed, and the simulator's taps
work. Score a few rallies by hand and watch the ball cross zones on a change of
serve; that is the one thing a preview cannot show.

**On the ball's colour comment.** `ServeIndicator` currently argues for white
("a fifth color on a screen that has three"). The argument dies with this
design. Delete it rather than leaving it to contradict the yellow.

## Comments

### Closing note

`ScoreView` is the court. Their half, a `NetLine`, ours — `VStack(spacing: 0)`,
so the halves meet on the tape and no seam of `night` runs down the middle. Each
zone's `.background` is a `CourtHalf(side:)`, and our half carries a
`Floodlight(corner: .bottomTrailing)` while theirs carries none, as the board
draws it. The three numbers are `.score`, `.scoreAside` on the shared baseline
and `.scoreAside` at the trailing edge; the ink is `.courtInk(side)` at
`.primary`, `.secondary` and `.strong` — the order the three are read in. The
serve is a `Ball(size: 10)`.

Untouched, as the ticket asks: `serveAlignment(for:from:)` (same six cases, same
doc comment, still file-private here), the whole of `ServeIndicator`'s fade
including `.animation(nil, value: corner)`, the `onTapGesture` /
`onLongPressGesture` pair, the per-zone `contentShape(Rectangle())`, and every
accessibility label, value and action. All fourteen previews build unchanged.

**How each criterion was checked.** Built for watchOS and for iOS; `swift test`
green in `PadelDesign`. Run on the 46mm Series 11 and the 40mm SE 3: a match to
three sets scored by hand to `40` with a games digit and a sets digit, the ball
watched crossing the net on a change of serve (our top trailing → their bottom
leading, i.e. the mirror still holds), the golden point seen putting the ball on
the middle of the inner edge, and a long press seen undoing `40` back to `30`.
The page dots sit over our bottom edge and the inner corners are clear of them
and of the clock in every screenshot.

### The ramp's watch `.score`: kept at 46

The ticket said not to take 46 on faith. It was looked at rather than inherited:
the worst score this screen has — `40` beside a games digit beside a sets digit
— on the smallest watch there is. It clears the zone with room to spare, and the
`40` is about as tall as the service box. The reasoning is now recorded on the
`TypeRamp.score` case, which also loses the line claiming the score is "most of
the screen": on a court it is not, and that is the point of the redesign.
`minimumScaleFactor(0.4)` stays.

### Two departures, both forced by deleting `ourColor`

`ScoreView.ourColor` was not only `ScoreView`'s. Deleting it breaks three call
sites on two screens this ticket does not own, so each was pointed at the
nearest `PadelDesign` token rather than left to be redrawn:

- `StartView`'s two serve rows are now `Color.courtSurface(side)` — the same two
  surfaces the score screen says our side with. Ticket 05 redraws the screen.
- `OutcomeView`'s our-score and our-headline are now `Color.ball`, which is what
  yellow means (ADR-0006). Turf green would have been text on `night`. Ticket 07
  redraws the screen.

Neither is this ticket's design; both keep the app building and stop any colour
being named outside `PadelDesign`. After them the watch target has no colour
literal left anywhere, and no `.system(size:)` outside `OutcomeView`'s 44pt
score, which is ticket 07's.

### After the review: the sets digit and a stale doc

Two findings from `/code-review` against `e1754cc`, fixed in a follow-up commit.
Both axes reached the sets digit independently, which is why it moved:

- The ink was `.strong` (0.65) where the board draws the digit at 0.8 for their
  half and 0.85 for ours, and the screen shipped it at 0.9 before this ticket.
  The spec's "Layout, proportion and hierarchy transfer from the boards" governs
  a weight, so it is now `.control` — the 0.82 the ink already names. Borrowing a
  control's name for a number on a court is the ink vocabulary's gap rather than
  this screen's, and the call site says so.
- `TypeRamp`'s enum doc argued for the ramp by citing `ScoreView`'s
  `.system(size: 64, …)` "as `ScoreView` does today". This ticket is what made
  that false. The argument now stands in the past tense, which is also the
  better argument.

Left alone: the points are still spelled `.courtInk(side)` without an explicit
`.weight(.primary)` beside two siblings that spell theirs. Consistency says
spell it; the paragraph above says the trio's weights are three decisions and
not one. Worth a minute from whoever next opens the file.

### One thing deliberately not changed

The ball's `opacity(0.9)` at the visible end of the fade was written for a white
glyph. It stays, because it is a term in the fade expression and the ticket says
the fade sequence is unchanged. If the ball ever wants its full yellow, that is
one number and it belongs to whoever revisits the fade.
