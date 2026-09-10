# 03: The controls: segment, stepper, card, pill, tile

**What to build:** The five floating controls the boards repeat, in
`PadelDesign`. None of them is a system control restyled — the brief is "no
navigation bar, no list rows, no chevron-and-separator".

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `SegmentedChoice` — two options, the selected one ringed in `ball`
- [ ] `StepperRow` — a label, a value, − and + , and the **Digital Crown** on
      watchOS
- [ ] `SettingsCard` — the translucent rounded group with hairline dividers
- [ ] `PillButton` — the `ball`-yellow primary, and a quiet translucent variant
- [ ] `CourtTile` — the history tile cut from the court
- [ ] Every one of them works at the largest Dynamic Type setting without
      clipping, and the previews prove it
- [ ] Every one of them is a real button to VoiceOver — label, value, traits —
      and not a tapped rectangle
- [ ] Previews in both languages, because these are where the words live

## `SegmentedChoice`

Two side-by-side capsules. Selected: background `ball` at 0.14, a 2pt inset
ring in `ball`, label in `ball` at `.control` semibold. Unselected: `ink` at
0.10, label `ink` at 0.65, medium weight.

Two options only. "Classic" against "To N points" is the whole of its job, and
a general n-way segmented control is a thing to build when a third ruleset
exists.

## `StepperRow`

The row from the boards: label at the leading edge, then − , the value in
`.display`, + at the trailing edge, the circular buttons in `ink` at 0.12.

**The crown is the hard part and the reason this control exists.** Today
`RulesetView` uses `Picker`s, which the crown spins. The board's ± would replace
that with taps, and `target` runs **5...40** — 35 taps to cross it. So:

- The row is `.focusable()`, and the focused row binds
  `.digitalCrownRotation` to its value across its range
- ± moves one step; the crown scrubs
- Focus is visible — the focused row is the one the crown will move, and a
  player who cannot see which row that is will move the wrong number

The range comes in from the call site (`1...3`, `1...6`, `5...40`), and the
control clamps to it. It does not know what a set is.

**If the crown proves fiddly on a wrist** — not in a simulator — the fallback
is a `Picker` for `target` alone and a visible seam in the rules screen. Say so
in a comment if you take it, because a rules screen with one row unlike the
others looks like an oversight and is not.

## `SettingsCard`

A rounded translucent group — `ink` at 0.08, radius `.card` — holding rows with
a 1pt `ink`-at-0.10 divider between them and none at the ends. It is what
replaces `List`'s section. Rows are handed in; the card owns only the shape,
the padding and the dividers.

## `PillButton`

Two variants:

- **Primary** — `ball` background, `onBall` label in `.control`, optionally a
  `Ball` beside the label ("New match" on the history board carries one, in
  reverse: a dark ball on the yellow). Height 64 on phone, ~32 on watch.
- **Quiet** — `ink` at 0.12 with a hairline border, `ink` label. This is what
  "Undo" and "End" are drawn as on the phone score board; on the watch it is
  what the outcome screen's buttons become.

## `CourtTile`

The history row, cut from the court rather than ruled as a table row: radius
`.tile`, the weave over a tint, content handed in.

Three tints, and this is the control's whole argument — *you can read the
season by colour before reading a single number*:

| Outcome | Tint |
| --- | --- |
| Won | `ourHalf` — the turf green |
| Lost | `theirHalf` — cold glass |
| Abandoned | `night`, lifted, holding a trace of the floodlight |

A win also carries a soft `ball`-yellow radial glow at its top trailing corner
(the board draws it at 74×74, `ball` at 0.16 to clear).

The tile takes an **outcome**, and here the seam is worth being careful about:
`PadelScoring` has `Outcome`, and this is the same three-way distinction the
domain already draws — won, lost, abandoned. Take the domain's type rather than
inventing a `TileStyle`, for the reason `Side` is taken in ticket 01.

## Notes

**On accessibility.** These replace `List` rows, `Picker`s and `Toggle`s, all
of which came with VoiceOver for free. Every affordance the system gave has to
be put back by hand — `ScoreView`'s zone has the pattern, and the comment above
it ("The zone stopped being a button, so everything a button gave VoiceOver is
put back by hand") is the standard to meet.

**On Dynamic Type.** The boards are drawn at one size, and the rules screen at
the largest type is where this app has historically run out of width —
`StartView` carries a two-line comment about it and `RulesetView`'s preview
docs name "Serve after (X)" against "Подача через (X)" as the widest pair in
the app. Preview both languages at the largest setting before calling any of
these done.

**On what stays a system control.** Nothing here. The `Toggle` on the boards is
drawn as a `ball`-yellow track with a dark knob, which is a `Toggle` with a
`.tint(.ball)` — take that one for free rather than rebuilding it, but check
the knob colour against the board (`#0b2b26`, not black).
