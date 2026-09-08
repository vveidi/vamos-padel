# 02: The ball finds its corner

**What to build:** The dot at the leading edge of the serving zone becomes a
tennis ball in that zone's corner, and the corner says which half the serve
comes from.

The screen draws the court as it is seen from our end, so the two zones mirror
each other: our right half sits at screen right, the opponents' right half at
screen **left**, because they are facing us. A serve then reads as a diagonal
across the screen, which is what a serve is.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The indicator is `tennisball.fill`, white, at the size the dot had, in the serving side's zone only
- [ ] It sits in an **inner** corner — our zone's top corners, the opponents' bottom corners
- [ ] `.right` draws trailing in our zone and **leading** in the opponents', and the mirror is explained in a comment where it is written
- [ ] A `nil` half puts the ball at the middle of the zone's inner edge, still naming the side and no longer naming the half
- [ ] The sets digit stays at `.overlay(alignment: .trailing)`, vertically centered, untouched
- [ ] A move fades: the old ball out, then the new one in — never both at once
- [ ] VoiceOver says "serving from the right" or "serving from the left" in place of "serving", and plain "serving" when the half is `nil`
- [ ] Both new strings are in the catalog in Russian as well as English, and pinned by a test in `padelTests` the way the plural forms are — the catalog is shared, so the phone's target reaches these watch keys
- [ ] The mapping is a named pure function, `(Side, ServingHalf?) -> Alignment`, not `switch`es inline in `body`
- [ ] The previews cover both halves in both zones and the golden point, in both languages
- [ ] The screen is seen running, not only previewed

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
