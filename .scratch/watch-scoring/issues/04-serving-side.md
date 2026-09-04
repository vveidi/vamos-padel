# 04: The serving side

**What to build:** The app stops being silent about the serve. The score screen shows which **side** is serving, and the serve passes by itself: in **classic scoring** after every game, in **the match to N points** every X rallies.

This ends the one argument that comes up on court regularly. Until this ticket it is assumed that we serve first; choosing the first server will be added by ticket 06.

The side is tracked, not the particular player: **the sides are anonymous**, and the app has no way of knowing the order within a pair.

**Blocked by:** 03

**Status:** done

- [x] The serving-side indicator is visible on the score screen
- [x] In classic scoring the serve passes to the other side after every game
- [x] In the match to N points the serve passes every X rallies, X = 4 by default
- [x] The serving side is computed from the journal, the ruleset and the first server rather than stored separately
- [x] The tests cover the change of serve in both rulesets and the boundary value X = 1

## Comments

Done. Every criterion checked:

- **The indicator is visible on the score screen**: a dot at the edge of the serving side's
  zone. Checked in the simulator: before the first rally it is in our zone, and in a match
  with one game played it is in the opponents'.
- **In classic scoring the serve passes after every game**: the test walks a game rally by
  rally (inside a game the serve stays put) and three games in a row, and separately checks
  that a set boundary does not throw the serve off — `games` is zeroed along with the set, but
  the counter of changes is not.
- **In the match to N points the serve passes every X rallies**: the test checks all nine
  positions across two periods, with the rallies won in a mixed order — what affects the serve
  is their number, not the winner.
- **The serve is computed, not stored**: `MatchState.servingSide` is assembled by the same
  fold as the score. Storing it separately would have obliged undo (ticket 05) to roll it back
  by hand.
- **The tests**: 59 in the package, nine of them about the serve, `swift test` without a
  simulator. The boundary X = 1 is covered, and so is X < 1.

Decisions taken along the way:

- **The serve also passes inside a tiebreak.** The ticket and the spec say "after every
  game", and that is true on game boundaries, but inside a tiebreak padel's rule is different:
  the first rally is served by whoever's turn it is, after that it changes every two. Read
  literally, the indicator would lie for all thirteen rallies of the tiebreak — exactly where
  it is looked at most — so the rotation was implemented. This is a departure from the letter
  of the ticket in favour of its purpose; pinned down by a test of its own.
- **The first serve is a property of the match, not of the ruleset.** The rules are remembered
  until the next match (ticket 06), whereas who serves first is decided anew every time. Ours
  by default, as the ticket says.
- **X is clamped from below**, as N and the set count were before it: at zero the serve would
  not "simply never change" — it would crash the app on a division by zero.
- **The side is computed from the parity of the changes**, not by stepping through them one by
  one: the question "who serves on the hundredth rally" should cost as much as "who serves on
  the first".
- **The dot sits at the edge of the zone, not on the line with the score.** On the line it
  would push the digit off centre on every change of serve, and the eye would have to find the
  score again. The room for it is always taken; only the visibility changes.

A note on verification: **taps in the simulator did not work this time.** The simulator
stopped handing out its window through Accessibility, and synthetic presses were not reaching
the app, even though the system was delivering the events. So the change of serve was checked
not by tapping but with a build carrying a pre-set journal: the screen received its state from
the real engine rather than from substituted values. The change logic itself is covered by
tests. If the simulator does not recover, the following tickets should adopt this method as
the ordinary one rather than the emergency one.
