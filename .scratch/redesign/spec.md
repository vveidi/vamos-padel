# The redesign: one court at dusk (v1)

Status: ready-for-agent

## Problem Statement

The app is a correct scorer wearing the system's clothes. Every screen is a
`List` inside a `NavigationStack`, every color is a `.white.opacity(0.1)`
written where it was needed, and the one decision anybody made on purpose —
`ScoreView.ourColor` — lives as a `static let` on a view because there was
nowhere else to put it. Nothing is wrong and nothing is ours.

Three directions were drawn against the same content and shown side by side
(commit 46ff6bd). **Court** won: the app lives on one court at dusk, seen from
above, glass blue for their half and turf green for ours, a warm floodlight
spilling in from one corner, and the ball as the only bright thing on screen.
The brief that came with it was "less like a system app, and give it a soul".

The design is drawn in `canvas-court/` — six artboards and the annotations
around them. This feature is the code that follows from it.

## What is in, and what is not

The canvas has six boards. Two of them — `PhoneNewMatch` and `PhoneScore` —
are screens **the app does not have**, and building them is a feature, not a
repaint: it decides where a match is created, what the store writes on the
phone, and what delivery means when the phone is no longer only a reader.
`CONTEXT.md` currently says "The phone serves as the shop window for the
history", and phone scoring is what would rewrite that sentence.

So those two boards are **reference for the visual language and nothing more**.
The "New match" button drawn on `PhoneHistory` is left out with them: it leads
to a screen that does not exist.

Two screens that do exist have **no board**: the watch's outcome screen
(`OutcomeView`) and the phone's match card (`MatchCard`). They are restyled by
extension from the boards' vocabulary — the same court, the same tiles, the
same ramp — and not by inventing a new structure for them.

In scope, then:

| Screen | Board |
| --- | --- |
| Watch · score (`ScoreView`, `ScorePages`) | `WatchScore.dc.html` |
| Watch · start (`StartView`) | `Main.dc.html` |
| Watch · rules (`RulesetView`) | `WatchRules.dc.html` |
| Watch · outcome (`OutcomeView`) | — by extension |
| Phone · history (`HistoryView`, `MatchRow`) | `PhoneHistory.dc.html` |
| Phone · match card (`MatchCard`) | — by extension |

Explicitly not in this feature: **phone scoring**, **light mode**, and the
**two custom fonts** — the last has a ticket of its own (11) so the discussion
happens against something written down rather than in passing.

## The design, in words

Four things carry it, and they are worth stating before any hex value:

- **The court.** Two halves, theirs on top and ours at the bottom — the same
  as on court, because they are across the net in front of us. Full-bleed to
  all four edges. `ScoreView` already argues its layout from "the same as on
  court"; the redesign makes the argument visible.
- **The net.** Drawn as it looks from directly above: a bright tape line with a
  post at each end, not a band of mesh. Every screen split into two halves
  carries it.
- **The ball.** The app's one character, and it means exactly one thing: *this
  is yours, or this is chosen*. It waits on the net before the match, sits in
  the serving half's corner during play, and rides the primary button. Same
  object every time.
- **One accent.** The ball's yellow is the only color in the app. Losses go
  cold and grey. There is no red anywhere and no second accent to argue with
  the first.

## Reading the boards

**The watch boards are 2x and their type is not.** `canvas.json` says the watch
boards are drawn at 2x (396×484 px = 198×242 pt), and the layout obeys that:
a 46px header is 23pt, a 58px segment is 29pt, a 64px settings row is 32pt —
all plausible watch numbers. The type does not obey it. A 14px row label would
be **7pt**, below anything watchOS has a text style for, and the 92px score
would be 46pt against the 64pt the screen uses today. Halve the type and it is
illegible; take it at face value and the score is twice the screen.

The boards were drawn at phone scale and the watch ones doubled afterwards. So:

> **Layout, proportion and hierarchy transfer from the boards. Type sizes do
> not.** Every size comes from the ramp (ticket 01) at watchOS's own scale, and
> the board decides only which ramp entry a thing gets.

The phone boards are 1x and their numbers are honest — 31pt titles, 128pt
score, 13–15pt supporting text — but they go through the ramp too, so that the
font ticket has one place to land.

## Solution

A fourth local package, **`PadelDesign`**, holding the tokens, the court
primitives and the controls the boards keep repeating. The six screens stay
where they are and compose it.

### The seam

**The package knows about a court, a net and a ball. It does not know about a
match.**

`ScoreView` keeps `serveAlignment(for:from:)` — which corner a serve belongs in
is domain knowledge dressed as layout, and its doc comment is the longest
argument in the app for exactly that reason. It asks the package for *a ball in
a corner* and no more. Likewise `MatchCard` keeps the course of the score;
`PadelDesign` gives it a tile to draw it on.

The test for anything proposed for the package: could a screen that has never
heard of a rally use it? A `NetLine` passes. A `ScoreZone` does not.

## Implementation Decisions

### A package rather than styling per target

Five of the six boards draw the net, four draw the two-half court, four draw
the ball. Left in the targets, that is the net written five times and drifting
from the first week — and the watch and the phone cannot share a file at all
without one, since they are separate Xcode targets.

The alternative considered was a tokens-only package with the shapes redrawn
per screen. It solves the color drift and none of the shape drift, which is the
drift that shows.

### `Side` comes from `PadelScoring`

`CourtHalf` needs to know whose half it is to choose glass blue or turf green.
It takes `PadelScoring.Side`, and `PadelDesign` depends on `PadelScoring` for
it.

The alternative — a local `CourtSide` enum, keeping the design package free of
the domain — was rejected on the glossary's own terms: `CONTEXT.md` defines
**Side** and lists what not to call it ("_Avoid_: team, pair, couple").
Inventing a second name for it one directory away is the exact drift that entry
exists to prevent. `PadelScoring` is a pure model package with no I/O, so the
dependency costs an import, and the layering stays one-directional: the design
knows the domain, the domain never hears about the design.

### The ramp exists now; the fonts arrive later

The boards are set in Unbounded (numbers, titles) and Golos Text (everything
else). Neither ships in this feature — ticket 11 is where that is decided.

What ships now is the **ramp**: `.score`, `.display`, `.control`, `.body`,
`.caption`, `.footnote`, each mapped to a system face today (SF Rounded for the
numbers and titles, SF for the rest) and each carrying a `relativeTo:` so
Dynamic Type keeps working. After this feature no call site writes
`.font(.system(size:weight:design:))` again — `ScoreView`'s hand-written
`size: 64` and `MatchCard`'s `size: 44` are gone.

That is what makes ticket 11 a small ticket instead of a second redesign: it
changes one file's mapping. Building the screens on `.title`/`.body` now and
adding the ramp with the fonts would mean rewriting every screen twice.

### Dark only, and said out loud

One court, one time of day. There is no light palette, because a court at noon
is a second design nobody has drawn — not because dark mode was easier. The
package exposes a single palette and the phone pins `.dark`; the watch is dark
already.

ADR-0006 records this so a future reader does not read it as an oversight.

### Always-On is created by this feature, so it belongs to it

Nothing in the repo handles Always-On today — there is no `isLuminanceReduced`
anywhere — and today that is fine, because the score screen is nearly black
already. A full-bleed saturated court with a floodlight gradient and a bright
yellow ball, held on a wrist for ninety minutes, is a different proposition:
burn-in, battery, and a screen the HIG asks to be dimmed.

Ticket 10 gives the court primitives a dimmed variant. It is one focused change
at the bottom of the stack rather than a clause in every screen ticket.

### The crown survives the rules screen

The board replaces three `Picker`s with a segmented choice and ± stepper rows.
That reads well and works for `setsToWin` (1...3) and `serveChangesEvery`
(1...6). It does not work for **`target` (5...40)**: 36 values behind a ±
button is 35 taps, where a `Picker` spins under the crown today.

So the stepper binds the Digital Crown on the focused row — ± for one step, the
crown for a jump. A redesign that removes the watch's one precise input is a
downgrade dressed as a repaint. If it proves fiddly on a wrist, the fallback is
a `Picker` for N alone and a visible seam in the rules screen, not a 35-tap
stepper.

## What the boards say that the app does not do

Three deltas, decided separately:

1. **"Recording to Health"** on the watch's start board — a lit dot and a line,
   stating before the match that the watch will record a workout. The app never
   says this. It comes along (ticket 05): the reference apps earned it, and the
   workout is exactly the thing a player wants confirmed *before* an hour and a
   half, not after.

2. **The page dots are missing** from `WatchScore.dc.html`. They stay. The
   score screen is page two of a `TabView` and the control page is the only way
   to end a match from the court; `serveAlignment`'s doc comment records that
   the inner corners were chosen *because* of those dots and the clock. Losing
   the dots to match a board would cost the ball its argument.

3. **An on-screen Undo button** on the phone score board. Falls away with phone
   scoring. The watch's undo stays a long press.

## The tickets

```
01  the design package, its tokens and its type ramp
02  the court, the net and the ball
03  the controls: segment, stepper, card, pill, tile
04  the watch score screen
05  the watch start screen
06  the watch rules screen
07  the watch outcome screen
08  the phone history
09  the phone match card
10  the court in Always-On
11  the two fonts                      (needs-triage — discuss first)
```

01 blocks everything. 02 and 03 block the screens. 04–09 are independent of one
another and can be picked up in any order — one per session, per `CLAUDE.md`.
