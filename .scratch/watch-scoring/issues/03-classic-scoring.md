# 03: Classic scoring

**What to build:** The second **ruleset** — padel by the classic rules. The player picks it, and the app counts 15/30/40, works out the end of a game, a set and the match, and starts a tiebreak at 6:6. If the **golden point** is on, deuce is settled by a single decisive rally instead of playing on for a two-point lead.

The game score appears next to the points on the score screen, smaller than the points.

**Blocked by:** 02

**Status:** done

- [x] The points run 15 / 30 / 40 and a game is won at a two-point lead
- [x] With the golden point off, deuce runs on until a two-point lead
- [x] With the golden point on, deuce is settled by a single rally
- [x] A set is won at six games and a two-point lead
- [x] At 6:6 a tiebreak begins and is played by padel's rules
- [x] The match ends at the given number of sets won, one by default
- [x] The game score is shown on screen and does not get in the way of reading the points
- [x] The tests cover: the game, deuce in both modes, the end of a set, the tiebreak, the end of the match

## Comments

Done. Every criterion checked:

- **15/30/40 and a game at a two-point lead**: the ladder of points was checked by tapping
  in the simulator — 0, 15, 30, 40 — the fourth point closes the game and zeroes the points,
  and the game counter goes up to 1. The test walks the whole ladder and separately checks a
  game won against resistance.
- **Without the golden point, deuce runs to a two-point lead**: from 40:40 one point gives
  advantage, the reply brings back deuce, two in a row win the game. Checked both by test and
  on screen — with a temporary build using `goldenPoint: false`, because with the golden
  point on, advantage is unreachable.
- **With the golden point, deuce is settled by a single rally**: at 40:40 the next tap gave
  the game to the opponents (games 0:1). In the engine the rule reduces to "first to four":
  before deuce a fourth point already means a two-point lead.
- **A set at six games and a two-point lead**: the tests cover 6:0, 6:5 (the set is not won
  yet) and 7:5 (won).
- **A tiebreak at 6:6**: taken to 6:6 by tapping in the simulator — the points in a tiebreak
  are shown as numbers again rather than as "40". The tests cover winning by seven points,
  playing on at 6:6 inside the tiebreak, and the set becoming 7:6.
- **The end of the match by the number of sets**: by default the match ends on the very first
  set — on screen that reads as "Мы выиграли, 7:6". The test checks that a match to two sets
  outlives its first set.
- **The games on screen**: they stand next to the points on a shared baseline, 22pt against
  60pt. Checked on 42 mm — the narrowest screen — in the densest state: at 40:40 with games
  at 5:5 the digits neither shrink nor collide with each other or with the system clock.
- **The tests**: 48 in the package, `swift test` without a simulator, 0.002 seconds.

Decisions taken along the way:

- **The points became a `Points` type rather than a number.** 15/30/40 cannot be expressed as
  a number, and advantage even less so. The shape of the score is not presentation but part of
  the rules: in a tiebreak the very same rallies are called by numbers again. So the way
  points are named is kept together with the counters — naming a game's points with a number
  is impossible — and the screen only asks for a label. Ticket 02 stored `SideCounts`
  directly; its tests were updated.
- **`classic(sets:)` renamed to `setsToWin:`.** The old name did not answer the question the
  criterion asks: is `sets: 2` a match of two sets or to two wins? A match to two sets lasts
  two or three.
- **The match's final score is games, not points.** The rally that ends the match also ends a
  game, so by that moment the points are already zeroed and the outcome screen would show 0:0.
  A match longer than one set is remembered by sets, otherwise the last set's score would pass
  itself off as the score of the whole match.
- **The golden point does not extend to the tiebreak**: it is a rule of the game, and a
  tiebreak is not a game. Pinned down by a test of its own.
- **A set count below one** behaves like a single set — the same as N < 1 in ticket 02. The
  value comes from the start screen (ticket 06), and a match that can never be finished is not
  the way to report a senseless setting.
- **The default ruleset changed to classic.** There is nothing to choose between until ticket
  06, and classic scoring is what padel is by default. Until the start screen, the match to N
  points stays reachable only from the tests.

A note for the future: **the sets are not shown on screen** — the spec names exactly three
quantities (points, games, serve). With a single set that is enough, but as soon as ticket 06
allows two to be chosen, the games line will be left without saying which set it belongs to.
That is worth settling where the choice appears.

### Following /code-review

The review ran along two axes. The standards axis found no hard violations: the package
stayed clean, `MatchState`'s initialiser stayed internal, the glossary was not broken. The
rest was fixed.

- **The final score no longer guesses.** `finalScore` chose the level by the number of sets
  played, and an abandoned match to two sets (ticket 09) would have passed the current set's
  score off as the score of the whole match. Now the ruleset chooses the level:
  `setsToWin > 1` means sets, otherwise games. Pinned down by two tests on an unfinished
  match.
- **One rule instead of three spellings.** A game, a tiebreak and a set are all "reached the
  threshold and is two clear" with different thresholds; the predicate became shared, and each
  level kept only what it departs from the rule by.
- **The game's threshold lived in two places**: `>= 4` in the engine and `>= 3` in the points
  label. Both are now derived from the length of the ladder `["0", "15", "30", "40"]` — the
  rule is one, and "40" is no longer written out as a number in the code either.
- **The point size went back from 60 to 64.** Shrinking it for the games' sake was a marked
  trade-off the review did not find in the note — and, as it turned out, an unnecessary one:
  at 42 mm with games at 5:5, both "40" and "AD" fit, and neither shrinks.
  `minimumScaleFactor` went back onto the points themselves: on the container it let the games
  squeeze the main digit.
- **A match ended by a tiebreak** handed back its points as `.game(0:0)`, though there was no
  game. Harmless now, but it would have surfaced in ticket 12; it is `.count` now.
- **`ScoreZone.points`** was renamed to `pointsLabel`: the field holds a label ("AD"), not a
  number. **`Points.counts`** was closed down to internal — outside the package the score is
  read, not computed.
- A duplicate test about the games being zeroed was merged into the test about a won set.

Deliberately not fixed:

- **The `points` + `games` pair travelling through three calls** is the shape of `MatchState`,
  and by rights it should be passed whole. It cannot be: `MatchState`'s initialiser is
  internal on purpose (ADR-0001), so previews in the watch target cannot assemble such a
  state. The tuple here is the price of the very ban it exists for.
- **The ladder `["0", "15", "30", "40"]` repeated in the test** is not a duplicate: a test has
  to name what it expects itself, otherwise it checks the implementation against its own
  constant.
- **`Points`' cases are public**, so points can be assembled outside the package without a
  journal. There is nothing to close: an enum's cases cannot be given narrower access, and the
  score screen's previews construct them.
