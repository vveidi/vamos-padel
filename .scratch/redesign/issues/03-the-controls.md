# 03: The controls: segment, stepper, card, pill, tile

**What to build:** The five floating controls the boards repeat, in
`PadelDesign`. None of them is a system control restyled — the brief is "no
navigation bar, no list rows, no chevron-and-separator".

**Blocked by:** 01

**Status:** done

- [x] `SegmentedChoice` — two options, the selected one ringed in `ball`
- [x] `StepperRow` — a label, a value, − and + , and the **Digital Crown** on
      watchOS
- [x] `SettingsCard` — the translucent rounded group with hairline dividers
- [x] `PillButton` — the `ball`-yellow primary, and a quiet translucent variant
- [x] `CourtTile` — the history tile cut from the court
- [x] Every one of them works at the largest Dynamic Type setting without
      clipping, and the previews prove it
- [x] Every one of them is a real button to VoiceOver — label, value, traits —
      and not a tapped rectangle
- [x] Previews in both languages, because these are where the words live

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

## Comments

**Done.** Five controls, one table of sizes, seven previews and 14 new tests.
Not one of them is a system control restyled: each of the four interactive ones
is built out of real `Button`s over the package's own shapes, and the `Toggle`
the ticket hands over for free is documented in `SettingsCard` rather than
wrapped — a wrapper would be this package having an opinion about a control it
was told not to have one about.

- **The files.** `SegmentedChoice`, `StepperRow`, `SettingsCard`, `PillButton`
  and `CourtTile` in `Packages/PadelDesign/Sources/PadelDesign/`, with
  `ControlMetrics` beside them holding every number off the boards and
  `ControlPreviews` holding the boards themselves. `ControlMetrics` is to the
  controls what `CourtMetrics` is to the court, and it says out loud why the
  two tables differ: the court is stretched across two screens and is drawn in
  fractions, a button is nearly the same size on a wrist as in a hand and is
  drawn in points.

- **How each criterion was verified.** `swift test` — 54 tests in 13 suites,
  the 14 new ones in `ControlsTests`. The ring lands on the chosen segment and
  moves with it; a divider appears between two rows and never at an end
  (measured by height, because a hairline of ink at 0.12 over a panel at 0.08
  is an exact difference in a number and a very small one in a picture); the
  primary pill is the ball's yellow and the quiet one is not; the three
  outcomes draw three grounds, only the win is lit, and a match still in
  progress draws as one stopped early. Both apps build — watchOS on Series 11
  (42mm), iOS on iPhone 17 — which is what compiles the crown at all.

- **On Dynamic Type, and what is actually proven.** Every height is a floor and
  never a measurement, and both the choice and the stepper row reflow through
  `ViewThatFits` when the width runs out. What the tests check is that reflow,
  fired by a narrow frame rather than by a type setting: macOS has no Dynamic
  Type — `RenderingTests` measured that rather than assuming it — so a test
  that turned the type up here would be asserting the Mac's behavior and
  calling it the control's. The same branch fires either way. The four
  `.accessibility5` previews are the rest of the evidence, and they are the
  half a human has to look at.

- **On VoiceOver, and one deliberate reading of the criterion.** The segments
  and the pills are real `Button`s, so the trait arrives without being asked
  for, and the chosen segment carries `.isSelected` the way the system's do.
  **The stepper row is adjustable rather than a pair of buttons** — one element
  carrying the label, the value and `.isAdjustable`, which is what `Stepper`
  itself reports on both platforms. Two buttons would have needed the words
  "increase" and "decrease", and this package owns no words to give them. The
  card is a container and has nothing to be a button about. The tile takes an
  optional `action`: given one it is a real `Button`, given none it is the
  surface inside a `NavigationLink` that is already the button.

- **A ninth ink weight: `.control` at 0.82.** The boards spend 0.82 on the
  wrist and 0.85 in the hand on a settings row's label and on the bar of the
  ± , and the only existing name for that number was `.tape` — the net's. A row
  label drawn in the net's weight is a call site that reads wrong, and the
  alternative, `.strong` at 0.65, is visibly dimmer than every board. So it is
  the third deliberate collapse, next to `hairline`/`surface`, and named for
  the same role `TypeRamp.control` is named for. `PaletteTests`' descent was
  updated to expect two collapsed pairs instead of one.

- **The tile's tints follow this ticket and not `PhoneHistory.dc.html`.** The
  board draws a loss as ink at 0.07 and a stopped match as `ball` at 0.08; the
  ticket's table says `theirHalf` and `night`, and the ticket wins. The board's
  version puts the accent on the one outcome that is neither a win nor a loss,
  which is the opposite of what the accent means (ADR-0006). The glow is the
  board's exactly — 74×74, `ball` at 0.16, hung off the corner so only its
  inner quarter falls on the tile.

- **The domain type is `MatchOutcome`, and it has a fourth case.** The ticket
  says "`PadelScoring` has `Outcome`"; what it has is `MatchOutcome`, and
  besides won, lost and abandoned it carries `inProgress`. A match still going
  is drawn as one stopped early — it has no result either, which is exactly
  what that tint says — and the two are told apart by the words the caller puts
  on the tile. Taking the domain's type rather than inventing a `TileStyle` is
  the decision the ticket asked for; `PackageIsolationTests` already named
  `MatchOutcome` as ticket 03's reason for importing `PadelScoring`.

- **The watch's ± are 15pt circles wearing a 26pt hit area.** The board's
  circle halved is 15pt, which is a target nobody hits on a moving wrist. The
  circle stays the board's size and the hit area grows under it, inside the
  button's own label — a frame put around a `Button` moves it without widening
  what it answers to. `ControlMetrics.stepperSpacing` takes the overhang back
  out of the spacing, so the drawn gap is still the board's.

- **`Package.swift`: the Mac moved from v14 to v15.** `SettingsCard` puts a
  divider between two rows it was handed and not at the ends, which needs
  `Group(subviews:)`. That shipped alongside iOS 18 and watchOS 11 — both
  already required — under the Mac's own version number. Nothing ships on the
  Mac; it is where this package's tests and index live.

- **Not done, and deliberately: the crown on a wrist.** `StepperRow` binds the
  Digital Crown on the focused row across the range it was handed, and draws
  the focus so the player can see which row the crown is holding. Whether that
  is fiddly in play is the ticket's own "not in a simulator", and it is not a
  question a Mac can answer. The fallback the ticket names — a `Picker` for
  `target` alone — was **not** taken, and nothing was written into the code
  about it: it is a decision for the first time this is worn, and ticket 06 is
  where the rules screen finds out.
