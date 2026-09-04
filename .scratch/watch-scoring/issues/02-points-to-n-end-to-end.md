# 02: The match to N points from end to end

**What to build:** The first working counter. The player opens the app on the watch and sees a screen split into two equal halves. A tap on a half awards a point to that side, and the score on the screen grows. As soon as a side is first to reach N points, the match ends and the outcome is shown.

The simplest **ruleset** — no games, no sets, no deuce, no serve. After this ticket the app can already be used for a real game.

The geometry of the zones: two equal halves. Refining the geometry is deferred to the prototype and does not block this ticket.

**Blocked by:** 01

**Status:** done

- [x] A tap on a half of the screen adds a rally to the **journal** and raises that **side**'s score
- [x] The current points are shown in large type and read at a glance
- [x] The match ends as soon as a side reaches N points; further taps do not change the score
- [x] The match outcome is shown once it is over
- [x] N is set when the match is created, with a default of 16
- [x] The match state is computed from the journal and the ruleset rather than stored beside them
- [x] The same journal read twice yields the same state
- [x] The engine's tests cover the match to N, the end of the match, and the boundary value N = 1

## Comments

Done. Every criterion checked:

- **A tap on a half adds a rally**: `ScoreView` is two zones filling the display, each
  calling `Match.record(rallyWonBy:)`, that is, appending a rally to the journal; the score
  is recomputed from the journal. Checked with real taps in the simulator: three taps on the
  upper zone and two on the lower gave 3:2.
- **The points in large type**: 64pt, one digit per half. Checked in the simulator on 46 mm
  and 42 mm; at 15:14 the digits neither shrink nor collide with the system clock.
- **The match ends at N points, and further taps do not change the score**: the engine stops
  the fold at the rally that gave the Nth point, and `Match.record` writes nothing in a
  finished match — so that undo (ticket 05) does not run into extra presses. Checked by
  tapping: the match was taken to 16:3, after which eight taps across both zones changed
  nothing.
- **The outcome once it is over**: `OutcomeView` — who won and the final score. The score is
  printed winner-first, otherwise it reads backwards relative to the score screen, where the
  opponents are on top.
- **N defaults to 16**: `Ruleset.defaultPointsTo`. Choosing N will arrive with the start
  screen (ticket 06).
- **The state is computed, not stored**: `MatchState` is assembled from the ruleset and the
  journal on every read; it cannot be assembled from outside behind the journal's back — the
  memberwise initializer is internal.
- **The same journal yields the same state**: the test compares the states of the original
  journal and of a journal rebuilt from the same sequence.
- **The engine's tests**: 27 tests, `swift test` without a simulator.

Decisions taken along the way:

- **The geometry of the zones**: the opponents on top, us at the bottom — as on court, with
  the opponents across the net in front of us. Our half is recognized by color rather than
  by a label: a label would take room from the digit.
- **`Ruleset.classic` crashes the engine** with a pointer to ticket 03. The alternative —
  counting a classic match as a match to infinity — would have lied silently about the rules.
- **An N below one** is not forbidden by the type, so the engine behaves as it does at
  N = 1: whoever takes the first rally wins. A sensible bound will be set by the start screen
  (ticket 06).
- **A second match means relaunching the app.** A "New match" button was written and removed:
  the way back to a new match is the start screen (ticket 06).
- **"Match state" was added to the glossary** — the ticket's central term, which was missing
  from `CONTEXT.md`.
