# 04: The watch score screen

**What to build:** `ScoreView` becomes the court. Two halves in glass blue and
turf green, the net between them, the score in `.score`, and the ball in the
serving half's corner.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Each zone is a `CourtHalf` — its own tint, weave, service line and center
      line — instead of a flat `.white.opacity(0.1)` / `ourColor.opacity(0.35)`
- [ ] A `NetLine` sits between the zones, replacing the 2pt `VStack` spacing
- [ ] The points use `.score`, the games `.scoreAside` on a shared baseline,
      the sets `.scoreAside` at the trailing edge — no `.system(size:)` left
- [ ] The ball is `PadelDesign.Ball`, yellow, at the size the dot has today
- [ ] `serveAlignment(for:from:)` is **unchanged** — same six cases, same doc
      comment, still file-private in `padel Watch App/`
- [ ] The fade sequence in `ServeIndicator` is unchanged, including
      `.animation(nil, value: corner)`
- [ ] `ScoreView.ourColor` is deleted; nothing outside `PadelDesign` names a
      colour
- [ ] The page dots of `ScorePages` still sit over our bottom edge, and the
      inner corners are still clear of them and of the clock
- [ ] Every VoiceOver label, value and action is exactly what it is today
- [ ] All fourteen existing previews still build and still say what they said
- [ ] Seen running, not only previewed

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
