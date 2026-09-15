# 04: The scoreboard

**What to build:** the phone's landscape score screen — the court across the
long axis, a half per side, both of them tapped to award a rally, the largest
digits the screen allows, and the ball in the corner of the serving half.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] The net crosses the long axis: in landscape it stands vertical and the
      halves lie left and right. `NetLine` from `PadelDesign` turned, not
      redrawn
- [ ] Ours is on the left by default and theirs on the right, both drawn on the
      one surface with the net between them — `court-surface` 01 collapsed the
      two grounds into one and deleted the painted lines, so this draws the
      plain surface from the start. Which half is ours is said by position and
      by the net. The screen names no color of its own
- [ ] A tap on a half records a rally for that side, and the journal is in the
      store before the digits change
- [ ] The points are the largest thing on the screen, from the `.score` ramp
      entry, with the games beside them and the sets at the half's outer edge —
      the arrangement `ScoreView` argues for, rotated
- [ ] The ball sits in a corner of the serving half and the corner says which
      half of the court is served from, mirrored between the two sides so a
      serve reads as a diagonal. The golden point puts it mid-edge, saying who
      serves and no longer from where
- [ ] Mirroring the board swaps which side is drawn left, the ball's corners
      with it, and is remembered for the length of the match only
- [ ] A quiet strip along the top: the ruleset in words, the match duration, and
      the way out
- [ ] Controls along the bottom over a scrim: undo, mirror the board, end the
      match. "End" asks for confirmation, as the watch's control page does
- [ ] No control steals a tap from a half, and no half swallows a control
- [ ] The screen asks for landscape on the way in with `requestGeometryUpdate`
      and lets go on the way out
- [ ] The idle timer is disabled while the scoreboard is up and restored when it
      leaves
- [ ] Every mutation — record, undo, abandon — sits in one cluster of
      `private func`s that persist after changing, the way `MatchView` does on
      the watch. Nothing else in the file writes to the store
- [ ] VoiceOver: each half is a button labelled by what tapping it does, valued
      with the score it shows, with undo as a custom action — `ScoreView`'s
      pattern, and its reasons
- [ ] Previews: both rulesets, a tiebreak, a golden point, two sets, mirrored
      and not, both languages
- [ ] The strings are in `Shared/Localizable.xcstrings`, English as the source

## The corners

`ScoreView.serveAlignment(for:from:)` is the watch's version and its doc comment
is the longest argument in the app for why this is domain knowledge dressed as
layout. This screen needs the same function turned a quarter turn: the server's
right and left become the top and the bottom of their half, mirrored between the
halves so that our serve crosses to their box diagonally rather than running
straight along the board.

Write it as its own function with its own preview per case, the way the watch's
is, and name the previews for the surprise rather than for the state. The
correction not to make is the same one: collapsing the mirror so both balls sit
at the same edge draws a serve padel does not have, and nothing goes red for it.

## Notes

**Why ours is on the left.** The history writes every score with us first —
`SideCounts.written` is "4 : 6" and the column is scanned on that promise. A
board that puts us on the right would contradict the column it is read next to.
The mirror button is there for where the players are standing; the default is
there for where the numbers are written.

**Why the top strip and not the middle.** The games and sets stay in their own
half, next to the points they belong to. A shared row down the middle — which is
what the reference app does — turns two scores into one line that has to be
puzzled out, and takes the vertical the digits were the point of.

**On the digit's size.** The half is roughly 426×393pt; the ceiling is the eye,
not the glyph. Take the `.score` ramp entry and let `minimumScaleFactor` handle
"AD" and a three-digit count; do not hand-write a point size — the redesign
removed the last of those on purpose, and ADR-0006 says why the ramp is an
interface.

**Where the mutation cluster goes later.** `paired-scoring` 02 builds a
`MatchHost` and moves every write behind it, so that the watch's intents and the
board's own taps come through one door. Keeping the writes together here is the
only thing this ticket does to make that a move rather than a rewrite — it is
not a reason to build an abstraction now.
