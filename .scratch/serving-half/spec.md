# The serving half (v1)

Status: ready-for-agent

## Problem Statement

The score screen says which side serves and stops there. On court that settles
half of the argument: the serving pair still has to work out which of the two
service courts the ball goes from, and after an undo, a long rally or a dispute
nobody is sure any more. The rule is mechanical — the half changes with every
rally — which is exactly the sort of bookkeeping the app took the score over
for.

`watch-scoring` ticket 04 put a dot at the leading edge of the serving side's
zone. The dot has a horizontal position and spends it on nothing.

## The rules being modeled

- The server stands behind the service line, in one half of the court, right or
  left of the center line. **The first rally of a game is served from the
  right, and the half alternates on every rally after it.**
- The serve has to land diagonally, in the receiver's matching box. So the
  target follows from the half by rule and is worth nothing on screen.
- **In a tiebreak the alternation does not break.** The serve changes hands
  after one rally and every two thereafter, but the half still flips every
  single rally. One rule covers a game and a tiebreak alike: the parity of the
  rallies played in it.
- **On a golden point the receiving pair chooses** which side to receive on. No
  computation can be right, and `Ruleset.defaultClassic` has `goldenPoint:
  true`, so this is not a corner — it is most games.

Not modeled, and deliberately:

- **Which of the two partners serves.** It rotates across games and needs
  player identity; the sides are anonymous in v1.
- **Receivers keeping their sides for a whole set.** Same reason.
- **Ends changing after odd games.** The frame is the server's own right and
  left, facing the net, which is the same court half at either end. Tracking
  ends would buy nothing.

## Solution

`MatchState` gains `servingHalf: ServingHalf?` beside `servingSide`, computed by
the same walk over the journal. `nil` is the golden point: the half is not
merely unset, it is not knowable.

The score screen's dot becomes `tennisball.fill` and moves into the corners of
the serving side's zone — leading or trailing according to the half, and always
on the zone's **inner** edge, the one against the center divider. The sets digit
stays exactly where it is.

## Implementation Decisions

### The engine owns the half, the view owns the mirror

`ServingHalf` is `.right` or `.left` **as the server sees it**, facing the net.
That is the only frame in which the value is stable, and it is the frame the
rules are written in.

The screen draws the court as it is seen from our end, so the two zones mirror
each other: our right half is at screen right, and the opponents' right half is
at screen **left**, because they are facing us. A serve therefore reads as a
diagonal across the screen, which is what a serve is. `ScoreView` already
argues its layout from "the same as on court" and this is the same argument.

The mirror is the view's business and must not leak into `ServingHalf`. Its doc
comment has to say so, or the top zone will one day get "fixed".

### The golden point has no half

Three ways were weighed:

- **Guess the right half.** Wrong about half the time, on the one rally of the
  game everybody is watching.
- **Ask the player to tap.** A new gesture on the score screen, on the sweatiest
  rally there is, competing with the two tap zones that award points.
- **Say nothing.** The ball moves to the middle of the zone's inner edge — it
  still says *who* serves, which the player needs, and stops saying *from
  where*, which we do not know.

The third is chosen. The app's one duty here is not to lie, and a ball that
goes to the middle exactly at 3:3 doubles as a golden-point marker at no cost.

It is not marked any louder than that — no larger ball, no different shape.
Announcing the deciding point is a feature of its own, with its own VoiceOver,
and it would arrive wearing this one's clothes.

### A service turn stands in for a game in the match to N points

Padel anchors the half on a game, and that ruleset has none. The half is
anchored on the **service turn** instead: the first rally after the serve
changes hands comes from the right, and it alternates after that. With the
default X = 4 this is the same as the parity of all rallies played; with an odd
X the two part company, and the service turn is the one somebody would recite
out loud.

### Computed, never stored

For the reason `servingSide` is (ADR-0001, and `watch-scoring` ticket 04): a
half kept beside the journal would have to be rolled back by hand on undo, and
one day would not be.

### The ball moves to the corners, the sets digit stays

The dot lived at `.overlay(alignment: .leading)`; the sets digit lives at
`.overlay(alignment: .trailing)`, both vertically centered. A ball that can sit
trailing collides with the digit in a match of more than one set.

The ball moves to the corners instead, and to the **inner** ones — our zone's
top corners, the opponents' bottom corners — so the two flank the center
divider and mirror each other the way the halves do. Two system elements
decided this: the watch clock cannot be hidden by a third-party app and is
drawn top right, where `ignoresSafeArea` puts the opponents' zone; and the page
dots of `ScorePages` sit at the bottom. The inner corners are clear of both.

The vertical position carries no meaning. The outer corners would have been
truthful — the server does stand at the back of the court — and paying for that
truth with a collision against the clock is a bad trade.

### The ball fades, it does not fly

The half flips on every rally, so this element now moves constantly. The old
ball fades out and the new one fades in **after** it, never at the same time: a
crossfade would put a ball in both halves for a moment, and that is the one
thing the indicator must never say. There is no motion continuity to protect —
a fade already gave up the reading that the ball travelled.

### `tennisball.fill`, white

Available from watchOS 9.0 against a target of 11.0, so no `#available` and no
fallback. White at the size the dot had, for contrast against both backgrounds —
`ourColor` at 0.35 and white at 0.1 — and because a fifth color on a screen
that has three would be spent on the smallest thing on it. If the seam turns
out to be invisible on a 41mm watch, the answer is a larger ball, not a
brighter one.

## Testing Decisions

The rule lives in `PadelScoring` and is tested there, through `MatchState`, the
way `ServingSideTests` already tests the side: feed a ruleset and a sequence of
won rallies, assert on the observable state. `swift test`, no simulator.

The cases that earn a test are the ones where the half is not simply "every
other rally": the first rally of a new game, the tiebreak (where the serve and
the half move on different rhythms), the golden point, and the service turn
boundary in the match to N points with an odd X.

The mirror gets no unit test, and not because it does not deserve one. The
mapping is a pure function from a side and a half to an alignment, which is
exactly what a test wants; there is nowhere to run it. The project has two app
targets and one test bundle — `padelTests`, hosted by the phone — so nothing
reaches Swift code in `padel Watch App/`. Moving the mapping into
`PadelScoring` to make it testable is the leak this spec forbids two sections
above.

It is written as a named pure function regardless, so that a watch test target
would make the test a new file rather than a refactor. Until then the previews
carry it, named for the surprise: "The opponents serve from their right (screen
left)".

The two new VoiceOver strings are the exception and are tested. The catalog is
shared between the targets — localization ticket 05 proved that on purpose —
so `padelTests` resolves the watch's keys in both languages the way it already
pins the plural forms.

## Out of Scope

- **First and second serve, faults.** The journal records rallies, not serves.
- **Which partner serves, and receivers keeping their sides.** Needs player
  identity; the sides are anonymous in v1.
- **The phone.** Nothing about a finished match is better for knowing which
  half its 47th rally came from. `MatchPayload` and the match card do not
  change.
- **A louder golden point.** Its own ticket if it is wanted.
- **An ADR.** The mirrored frame is the most surprising decision here and the
  likeliest to be "corrected" by a future reader — but an ADR is the wrong
  shape for that risk. The person who breaks it is already inside
  `ScoreView.swift`, reading `case (.them, .right): .bottomLeading` as a typo;
  they are not going to open `docs/adr/` first. A decision met mid-edit is
  guarded at the site or not at all. The five ADRs this repo has all constrain
  code across it and are cited by name from other files; one about which corner
  a glyph sits in would be the first that nothing ever cites, and it would
  lower the bar for the next one.

  A different framing would clear it: **the score screen is drawn from our end
  of the court** — the general rule the mirror is one consequence of, which
  would also govern a court diagram, serve placement, a positional heat map.
  Worth filing if anything positional follows v1, at which point the mirror
  becomes a consequence bullet rather than the subject. Open question, not a
  decision.

## Further Notes

`CONTEXT.md` gained its **Serving half** entry with this spec, before any code.
The entry is the place the golden-point exception is stated in domain terms;
the ticket should not restate the rules, only build them.
