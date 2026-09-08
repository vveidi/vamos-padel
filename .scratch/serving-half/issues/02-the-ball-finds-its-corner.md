# 02: The ball finds its corner

**What to build:** The dot at the leading edge of the serving zone becomes a
tennis ball in that zone's corner, and the corner says which half the serve
comes from.

The screen draws the court as it is seen from our end, so the two zones mirror
each other: our right half sits at screen right, the opponents' right half at
screen **left**, because they are facing us. A serve then reads as a diagonal
across the screen, which is what a serve is.

**Blocked by:** 01

**Status:** done

- [x] The indicator is `tennisball.fill`, white, at the size the dot had, in the serving side's zone only
- [x] It sits in an **inner** corner — our zone's top corners, the opponents' bottom corners
- [x] `.right` draws trailing in our zone and **leading** in the opponents', and the mirror is explained in a comment where it is written
- [x] A `nil` half puts the ball at the middle of the zone's inner edge, still naming the side and no longer naming the half
- [x] The sets digit stays at `.overlay(alignment: .trailing)`, vertically centered, untouched
- [x] A move fades: the old ball out, then the new one in — never both at once
- [x] VoiceOver says "serving from the right" or "serving from the left" in place of "serving", and plain "serving" when the half is `nil`
- [x] Both new strings are in the catalog in Russian as well as English, and pinned by a test in `padelTests` the way the plural forms are — the catalog is shared, so the phone's target reaches these watch keys
- [x] The mapping is a named pure function, `(Side, ServingHalf?) -> Alignment`, not `switch`es inline in `body`
- [x] The previews cover both halves in both zones and the golden point, in both languages
- [x] The screen is seen running, not only previewed

## The mapping

| Zone | `.right` | `.left` | `nil` |
| --- | --- | --- | --- |
| Ours (bottom) | `.topTrailing` | `.topLeading` | `.top` |
| Theirs (top) | `.bottomLeading` | `.bottomTrailing` | `.bottom` |

The two rows are not a copy-paste slip. `.right` is the server's own right, and
the opponents face us.

## The frame that looks like a bug

One enum case, two opposite alignments. This is what a future reader meets, and
it is worth seeing before it is written:

```
       we serve from our right          they serve from their right

     ╭─────────────────────────╮      ╭─────────────────────────╮
     │                   10:09 │      │                   10:09 │
     │                         │      │                         │
     │    30               1   │ THEM │    30               1   │ THEM
     │                         │      │    ●                    │ ← .right
     ├─────────────────────────┤      ├─────────────────────────┤
     │                     ●   │      │                         │
     │    40               2   │  US  │    40               2   │  US
     │      ↑ .right           │      │                         │
     ╰─────────────────────────╯      ╰─────────────────────────╯
```

Both balls are on the **right half of the court** for the pair serving. They
land on opposite sides of the picture because the two pairs face opposite ways:

```
          far end — the opponents, facing us
    ┌───────────────────┬───────────────────┐
    │  ● their RIGHT    │    their LEFT     │
    └───────────────────┴───────────────────┘
    ══════════════════ net ══════════════════
    ┌───────────────────┬───────────────────┐
    │      our LEFT     │    our RIGHT ●    │
    └───────────────────┴───────────────────┘
          near end — us, the watch on a wrist
```

A serve from our right lands in their right box — bottom right to top left, a
diagonal, which is what a serve is.

**The correction not to make.** It reads as a copy-paste slip, so somebody
flattens it:

```swift
case (_, .right): .trailing
case (_, .left):  .leading
```

Both balls then sit on the same side, and our serve to their box draws as a
straight line up the screen — a serve padel does not have. Nothing goes red;
there is no test that reaches `padel Watch App/`. The app is simply wrong about
the opponents' half from then on, in a way only somebody standing on a court
notices.

The likeliest moment is not a human review. It is an agent asked to tidy a
`switch`, or a later ticket adding a court diagram that normalizes the
alignment logic on its way past.

## Why the inner corners

Two system elements decided it. The watch clock cannot be hidden by a
third-party app and is drawn top right — where `ScoreView`'s `ignoresSafeArea`
puts the opponents' zone. The page dots of `ScorePages` sit at the bottom. The
inner corners are clear of both, they keep ~40pt from the sets digit, and they
put the two balls either side of the center divider, mirroring each other the
way the halves do.

The outer corners would have been truthful — the server stands at the back of
the court — but the vertical position carries no meaning here, and paying for
that truth with a collision against the clock is a bad trade. Say so in a
comment; the next reader will wonder.

## The fade

Sequential, roughly 0.15s out and 0.15s in, one animation for the corner-to-
corner move and for the jump between zones on a change of serve. A crossfade
would show a ball in both halves for a moment, and that is the one thing this
indicator must never say. There is no motion continuity to protect — a fade
already gave up the reading that the ball travelled.

The half flips on **every** rally, so this runs on every tap. If it turns out
to be noise on the wrist rather than on a simulator, the fallback is a shorter
fade, not a slide.

## VoiceOver

The value's last clause is `"serving"` today. It becomes `"serving from the
right"` or `"serving from the left"` — whole clauses, not a fragment appended to
the old one, for the reason the existing comment about Russian plurals gives.

On a golden point it falls back to plain `"serving"`: less, rather than
something false. Three keys in the catalog, two of them new.

## Notes

**On not marking the golden point louder.** The ball goes to the middle and
does nothing else — no larger ball, no different shape, no extra announcement.
Naming the deciding point is a feature of its own and would arrive here wearing
this one's clothes.

**On seeing it run.** `watch-scoring` ticket 04 records that synthetic taps in
the simulator stopped reaching the app, and that the serve was checked instead
with a build carrying a pre-set journal. That method is the ordinary one here:
a journal that stands at a golden point, and one mid-tiebreak, are worth more
than a tap anyway — they are hard to reach by tapping and they are exactly what
this ticket gets wrong if it gets anything wrong.

**On `tennisball.fill`.** watchOS 9.0, against a target of 11.0. No
`#available`, no fallback.

**On why the mirror has no test, and what stands in for one.** The mapping is
the shape a test wants — a pure function from two values to an alignment — and
there is nowhere to put the test: the project has two app targets and one test
bundle, `padelTests`, hosted by the phone, so nothing reaches Swift code in
`padel Watch App/`. Moving the mapping into `PadelScoring` to gain a test is
the one thing ticket 01 forbids: the mirror is the view's frame, not the
engine's.

So the function is written named and pure anyway — the day a watch test target
exists, `theOpponentsRightHalfDrawsOnTheLeft` is one file away instead of a
refactor away — and the previews carry the claim in the meantime. Name them for
the surprise, not for the state: "The opponents serve from their right (screen
left)" is read by the person about to straighten out what looks like a typo.

## Comments

**Closed.** `ScoreView` gained `servingHalf`, threaded from `MatchState`
through `MatchView` and `ScorePages` — three one-line edits, nothing on the way
computes anything. Everything else is in `ScoreView.swift`:

`serveAlignment(for:from:)` is the mapping, file-private and pure, exactly the
six cases the ticket's table names. Its doc comment carries the mirror, the
correction not to make (written out as the two-case `switch` somebody would
flatten it to), and why the corners are the inner ones — the reader who is
about to "fix" it is inside this file, and so is the argument.

`ServeIndicator` is the ball. It holds two pieces of state — `corner`, where it
is drawn, and `isVisible` — and only `isVisible` is ever animated: the opacity
falls to zero over 0.15s, the sleep lets it get there, and only then does
`corner` take the new value and the ball come back. A zone change is the same
sequence run by two zones, one fading out while the other has not started. A
rally scored mid-fade cancels the sleeping task, and the guard after it is
load-bearing: without it the cancelled task would put the ball back at the
corner it was leaving.

The corner carries `.animation(nil, value: corner)`, and that line is the whole
of the ball not travelling — see the correction below for what it costs to
leave out.

VoiceOver gets three whole clauses through `servingClause`, and the two new
catalog keys are pinned in `SharedCatalogTests` rather than in
`PluralFormsTests` — they take no number, and the suite they joined is the one
that exists to prove the phone's bundle carries the watch's words.

Two departures worth naming:

- The ball is `Image(systemName:).resizable().frame(width: 10, height: 10)`
  rather than a font size, so it is the dot's size exactly rather than a glyph
  that happens to be about it.
- The overlay lost its `alignment:` argument and aligns inside itself with
  `.frame(maxWidth:maxHeight:alignment:)`, because the corner has to change at
  runtime and an `.overlay(alignment:)` is fixed at the call site. The old
  comment's promise still holds and is restated: an overlay takes no room from
  the layout, so the digit does not move whatever the ball does.

**Verification.** `swift test` green in all three packages, `padelTests` green
on an iOS simulator — 9 cases, the new one among them — and the watch app
builds.

Seen running, twice, both with a pre-set journal, since taps still do not reach
the app (`watch-scoring` 04):

1. A rigged score screen played by a 3-second clock through a real `Match` from
   0:0, screenshotted 35 times. The ball walked our zone's top corners
   trailing → leading → trailing → leading with the alternating rallies, sat at
   the top middle for exactly the golden point at 40:40, and after the game
   changed hands moved to the opponents' zone and opened at its bottom
   **leading** corner — their right, at screen left, which is the whole claim
   of the ticket. Two of the 35 frames caught a fade in progress with no ball
   in either zone and none caught two, which is the sequence the fade promises.
2. The real path — store → `RootView` → `MatchView` → `ScorePages` — launched
   on a match written into the store three rallies into a tiebreak at 6:6. The
   ball stood at our zone's top leading corner: the half is `.left` after three
   rallies while the serve had already changed hands twice, the two rhythms
   ticket 01 separated, read off a screen.

Positions were measured off the screenshots rather than eyeballed — the ball's
centroid lands 12pt from both edges of its corner in every frame, mirrored to
the pixel between the zones — and two frames were looked at whole, the golden
point and the opponents' serve, to check the ball against the clock and the
page dots. It is clear of both.

**The ball was sliding, and now it does not.** Reported straight after the
above: the ball travelled across the zone while it faded. It did, and the
verification above had not been in a position to see it — screenshots taken
0.4s apart against a 0.15s fade land either side of the animation, never inside
it.

The cause was the first version's shape. It drew the ball inside `if let shown`
and moved the corner with the state, which meant the corner was an animatable
layout change on a view SwiftUI could still be holding: a reinsertion arriving
while the removal was in flight reconnected the same view, and it slid from the
old corner to the new one as it came back. The `?? .center` fallback made it
worse — a fading ball was also being told to go to the middle of the zone.

What replaced it keeps `corner` and `isVisible` apart and puts
`.animation(nil, value: corner)` on the frame, so a corner change is excluded
from every animation, including one already running around it. The ball can
now be somewhere or nowhere and has nowhere to travel to.

Verified by making the animation observable rather than by looking harder: a
build with the fade temporarily at 1.2s, played by the same clock-driven rig,
100 screenshots. Every frame's ball sits at x = 33.2 or x = 339.2 — the two
corners, to a fifth of a pixel — while its luminance climbs and falls through
eight or nine intermediate frames per fade, and eleven frames between the fades
hold no ball in either zone. The frames were clustered rather than averaged,
after an average had already lied once: a centroid drifting between two corners
is what a slide and a crossfade look like alike, and only the clusters say
which. This is also the check the first pass should have run.
