# 10: The court in Always-On

**What to build:** A dimmed variant of the court primitives, so the score
screen can be held on a wrist for ninety minutes without burning the display or
the battery.

**Blocked by:** 04

**Status:** ready-for-human

- [x] `CourtHalf`, `Floodlight`, `Ball` and `NetLine` read
      `@Environment(\.isLuminanceReduced)` and dim themselves
- [x] In dimmed mode the floodlight is gone, the weave is gone, and the two
      half tints fall most of the way to `night`
- [x] The score stays legible — it is the one thing the raised-wrist glance is
      for
- [x] The ball stays, dimmed: which side serves is worth as much at a glance as
      the score
- [x] The transition in and out is not jarring — the system fades it, so
      nothing here should animate on top of that
- [ ] Verified on a device or in the simulator's Always-On state, not by
      reasoning about it

## Why this is a ticket and not a clause in ticket 04

Nothing in this repo handles Always-On today — `grep` for `isLuminanceReduced`
returns nothing — and until now that has been fine. The score screen is nearly
black already: two flat tints at 10% and 35%, white numerals, a 10pt dot.

The redesign changes that. A full-bleed saturated court with a warm gradient
over it and a bright yellow ball, on an OLED that will hold the same frame for
an hour and a half of a match, is a different proposition — and the watch is
running a workout the whole time, which is precisely what keeps the screen on
and the app frontmost (`CONTEXT.md`, **Workout**).

Putting it here rather than in ticket 04 keeps it one change at the bottom of
the stack instead of a clause in six screen tickets. The dimming belongs to the
primitives; the screens should need no `if` at all.

## What dimmed mode should look like

The design brief is "one court at dusk". Dimmed is the same court **after the
floodlights go off**: the geometry survives, the light does not.

| Element | Lit | Dimmed |
| --- | --- | --- |
| Half tints | `#0e3d4c` / `#12564f` | most of the way to `night`, enough to keep the halves apart |
| Weave | 3% white | gone |
| Floodlight | warm radial | gone |
| Court lines | 0.2–0.36 | dimmer, but still there — they are the geometry |
| Net | ink 0.82 | dimmer |
| Score | full ink | full ink, unchanged |
| Ball | `ball` yellow | dimmer yellow, still yellow |

The rule: **the things that carry information stay, the things that carry
atmosphere go.** A glance in Always-On is for the score and the serve.

## Notes

**On which screens this reaches.** In practice only the score screen — that is
the one the workout keeps up and returns to on a raised wrist. But the dimming
lives in the primitives, so the start and rules screens get it free if they are
ever on screen when the wrist drops, and no screen needs to know.

**On the other screens' brightness.** Nothing else in the app is held up for
ninety minutes, so this ticket does not need to visit them.

**On verifying.** The simulator can be put into Always-On, and it is worth a
screenshot in both states side by side. What a preview cannot tell you is
whether the halves are still distinguishable when dimmed — two nearly-black
tints that differ by 4% on a calibrated display can be one colour on a watch in
the sun.

## Comments

**Five of six criteria are ticked. The sixth cannot be met on this machine:
there is no Always-On state to put a watchOS simulator into.** Everything else
was verified by rendering the court at watch size and looking at it.

What was built. `CourtDimming` in `Tokens/CourtColors.swift` holds three
fractions, and the four primitives read `@Environment(\.isLuminanceReduced)`
and ask the token file for the dimmed color. No screen has an `if` in it, and
the lit path is byte-identical — the watch score screen screenshots the same
before and after.

Two mechanisms rather than one, because the court is two kinds of thing. A
**surface** is opaque and goes darker, mixed toward `night` with
`Color.mix(with:by:)`. **Paint** on a surface — a line, the weave, the tape —
already carries a weight, so it goes thinner with `opacity`. Mixing paint would
move its alpha along with its hue and leave both wrong.

| Element | Dimmed |
| --- | --- |
| Half tints | 0.55 of the way to `night` |
| Weave | `.clear` |
| Floodlight | `.opacity(0)` |
| Court lines | half their weight |
| Net tape and posts | half their weight |
| Score | untouched |
| Ball felt | 0.15 of the way to `night`; the shadow goes |

### Why criterion 6 is not ticked

The watchOS simulator has no Always-On state. There is no item for it in the
Simulator's Features, Debug or Device menus; `simctl ui` offers only
appearance, contrast and content size; `simctl io enumerate` reports one
framebuffer, not the second display an Always-On watch has; and `Device > Lock`
leaves the screen exactly as it was. There is no paired watch here either — the
first build that could reach one is `.scratch/release/`'s ticket 03.

Forcing the value from inside the app does not work either. `.environment(\.isLuminanceReduced, true)`
was tried at the watch app's root and again directly on `ScoreView`'s `VStack`,
rebuilt and reinstalled both times: the court came up fully lit. watchOS seeds
that value below where a user modifier can reach. Both probes were reverted.

So the dimmed state was judged from `ImageRenderer` renders of the primitives
at 416×496 — the real views at the real size, with the environment set the one
place it does take, which is the renderer. That is not a wrist and is not
claimed to be one. The open question is still the ticket's own: whether two
tints 0.032 apart in luminance are two halves in sunlight.

### The two numbers the pictures changed

Both were set by eye, wrong, and corrected by looking at the render.

**The halves at 0.72 were one black rectangle.** Measured 0.021 of luminance
apart. At 0.55 they measure 0.032 and read as glass and turf. The test now
fails below 0.028, so walking the fall back up fails here rather than on a
wrist.

**The ball at 0.42 had nearly gone.** It is at 0.15, where it still reads as
yellow. See the open judgment call below.

There was a third number that the pictures *appeared* to change and did not.
The net looked full-strength white in the first renders, which argued for
dimming it further than the lines. It was the dump harness: `ImageRenderer`
without `isOpaque` wrote translucent whites out as opaque. With that fixed the
net dims exactly as the token says, and the separate fraction it had grown was
deleted. The net takes the lines' half.

### What the review raised

`code-review` ran both axes. Fixed here:

- `netPost(dimmed:)` had no doc comment and `netTape`'s summary claimed the
  posts as well. Both corrected.
- `CourtDimming` was `public` although nothing outside the package reads it —
  against `Palette.swift`'s own rule that what only the primitives use is
  `internal`. Now internal.
- `Ball` mixed its own felt, which is the one thing `CourtColors.swift` says it
  owns. Moved to `Color.ballFelt(_:dimmed:)`, and `Ball.Finish.felt` deleted.
- `Ball` dimmed **both** finishes, so the cut-out ball inside `PillButton`
  would have gone dark while the button's full-strength `ball` ground did not —
  half a control dimming, on a screen this ticket has no business visiting.
  Scoped to `.onCourt`.
- Two stale DocC links to signatures that had gained `dimmed:`.
- Three doc comments carrying the design argument rather than the caller
  contract, and three inline comments restating their own line.
- Two untested rows of the table: the score's ink, which is the row that asks
  for nothing to happen and so would break silently, and the *faintest* line —
  the outline at 0.20, not the service line at 0.34, is the one at risk. Both
  now have tests. The outline survives.

One test was also passing for the wrong reason: it sampled the net's shadow
rather than its tape and would have passed on an invisible net. It now asks for
a margin.

### Left for the owner to arbitrate

**The ball's 0.15 may be too bright for the thing this ticket is about.**
`#DDF35C` dimmed lands at `#BCD253` — green still at 82% of full, the most
saturated pixels in a frame held for ninety minutes. The area is 10pt, so this
is burn-in rather than battery. It sits between two of this ticket's own lines:
"the ball stays, dimmed" against "a bright yellow ball … on an OLED that will
hold the same frame for an hour and a half". It was 0.42 and invisible; 0.15 is
the other end of one afternoon's eyeballing, not a settled number.

**The boolean seam.** The standards review argues the `dimmed:` flag threaded
through seven token functions is the wrong shape — the variant is already in
the environment, so it could be resolved once into a `CourtPalette` value or a
modifier instead. It is a fair point and it is a redesign of the package's
color API, which this ticket did not ask for; criterion 1 asks for exactly the
four views reading the environment. Left as built.

**The two shadows go when dimmed** — the net's and the ball's. Not a row in
the table. It follows from "the things that carry atmosphere go" but nobody
asked for it.

**`surface = 0.55` reads as "just over half", not the table's "most of the way
to `night`".** The table's next clause — "enough to keep the halves apart" — is
what moved it, and the two clauses cannot both be had.
