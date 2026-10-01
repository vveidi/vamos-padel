# 09: Stopping a match early

**What to build:** The player can stop a match without playing it out: the court time ran out, it started raining, somebody pulled their back. The hour of play is not lost by it — the match is saved alongside the rest, but marked as **abandoned**.

The mark exists for the sake of future statistics: without it a match dropped at 5:2 cannot be told apart from a loss, and that information is lost for good, because the journal knows no difference between "played it out" and "walked off".

**Blocked by:** 07

**Status:** done

- [x] The score screen offers a way to end a match early
- [x] Ending is confirmed, so that an accidental tap does not cut the match short
- [x] An abandoned match is saved together with its journal
- [x] The abandoned mark is saved and reads back
- [x] An abandoned match counts as neither a win nor a loss
- [x] The workout session ends correctly when the match is stopped early

## Comments

**What was built.**

The match outcome became a third value: `MatchOutcome.abandoned`. It has no winner, but it
does have `isOver`; everyone who used to ask "is the match over?" now looks at that property
(formerly `isFinished`) and answers the same way for a match played out and one stopped.

Being abandoned is the only thing about a match that has to be **stored**: it cannot be
derived from the rally journal, and the journal of a match stopped at 5:2 is no different from
the journal of a match about to resume. So `Match` gained an `isAbandoned` field and an
`abandon()` method, and the schema gained an `abandoned` column. The engine meanwhile stayed a
pure function of the ruleset and the journal: the mark is laid over the computed state
(`MatchState.abandoned`) rather than mixed into the score, so an abandoned match remembers the
score it was stopped at. ADR-0001 gained a consequence about that exception, and the glossary
a clarification in "Match state".

There is no room for a button on the score screen — there are exactly two tap zones and three
quantities there — so the controls moved to a neighbouring `TabView` page (`ScorePages.swift`),
the same place the system's workout puts them: the match runs inside one anyway, and a swipe
to a "Завершить" button is a gesture the player has already made on this watch. What opens is
always the score. The button raises a `confirmationDialog`: "Завершить матч? / Матч сохранится
недоигранным".

The outcome screen (`OutcomeView`) now takes a `Side?`: `nil` means an abandoned match. It
assigns no winner, shows "Матч не доигран" and the score, in which our side is marked with the
same green as our half of the score screen. There is no undo gesture on it — see below.

**How each criterion was checked.**

- *A way to end early* — the control page next to the score; captured in the simulator
  (Series 11 46mm).
- *The confirmation* — a `confirmationDialog` with a destructive "Завершить" and "Играть
  дальше"; captured in the same place.
- *The journal is saved* — after the stop all four rallies lie in `rally`, and the `abandoned`
  column is 1.
- *The mark is saved and reads back* — "A stopped match is saved abandoned and not offered for
  continuation" and "The abandoned mark survives a relaunch of the app": before the stop a new
  connection to the same database offers the match for continuation, afterwards it does not.
  The check catches both legs of the trip at once: had the mark not been written, or not been
  read, the match would land on court again. Plus "A database left at the previous schema
  version reads back after migrating": a match written before the column appeared reads back
  as still playable.
- *Neither a win nor a loss* — `MatchOutcome.abandoned.winner == nil` and "A match stopped
  early is marked abandoned".
- *The workout ends* — `MatchView` holds the workout by `outcome == .inProgress` rather than
  by the presence of a winner, so a stop closes it by the same transition as the last rally.
  Not covered by tests, by the spec's decision (a wrapper over `HKWorkoutSession`).

`swift test` in both packages: 75 and 21 tests, all green. Both targets build.

**Decisions the ticket did not ask for.**

- **Undo does not bring an abandoned match back into play** (`Match.undo()` does nothing on
  one, and there is no gesture on the outcome screen). Stopping is not a rally, undoing a
  point does not lift it, and a gesture that looks like it works while in fact only changing
  the score of an already stopped match is worse than none. An accidental tap is guarded
  against by the confirmation — which is what the ticket asked for.
- **A won match cannot be stopped**: it already has a winner, and declaring it abandoned would
  mean canceling the outcome.
- **A match stopped before its first rally** is abandoned with an empty journal. There is
  deliberately no special rule: that is the exact description of what happened, and the
  database already allows empty match rows anyway (an undo down to zero).
- **The API has as yet no way to read a finished match back**: `matchInProgress()` does not
  hand back an abandoned match by definition. Reading will appear together with whoever needs
  it — the hand-off to the phone and the history (tickets 10, 11); until then one test looks
  into the database with bare SQL, as the migration tests already do.

**What is left to check by hand** (the spec puts gestures among what tests do not cover): the
swipe to the control page with a sweaty hand — whether the tap zones intercept it and whether
it leads away from the score by accident. The page indicator dots sit at the bottom, centred
in our zone; if they start swallowing taps, the zone should be raised.

**A review along two axes (standards and spec).** Fixed:

- The store gained `match(id:)` — the second half of the contract. The spec demands of Seam 2
  a round trip "with the same journal, ruleset and abandoned mark", and `matchInProgress()`
  does not hand back an abandoned match by design, so the mark used to read back only
  indirectly, through a `nil`. Now the test compares the restored match with the saved one in
  full, across two rulesets, and the bare SQL is gone from the tests.
- `onEnd`/`endMatch()` were renamed to `onAbandon`/`abandon()`: the glossary had already
  chosen the word, and "end" additionally collided with `isOver` — which is true of a won
  match as well.
- Removed: a stale "(ticket 09)" reference in `ClassicScoringTests`, a duplicated paragraph of
  comment in `MatchView`, and an avoid-synonym "interrupted" in the amendment to ADR-0001.
- The case "stopped before the first rally" was written into ticket 11: such a match is saved
  honestly, but has no business in the history list.

Deliberately left as is:

- **The controls on a neighbouring page rather than on the score screen itself.** The spec
  keeps the score screen empty on purpose: "two tap zones filling the display", "exactly three
  quantities". A button on it would take either room from the digit or a tap from the zone. A
  swipe to the control page is what the player does in the system's workout, and the match
  runs inside one. The risk that the zones intercept the swipe, or that the indicator dots eat
  a tap, stays on the list to check by hand.
- **Undo does not bring an abandoned match back into play.** The ticket explicitly hands the
  guard against an accidental tap to the confirmation. A gesture that looks like it works
  while in fact changing the score of an already stopped match is worse than none.
- **The duration is counted to the last rally, not to the stop.** That is how the glossary
  defines it: "the time from the first rally to the last", and separately, not up to "now".
- **`OutcomeView` takes a `Side?` rather than a `MatchOutcome`.** The outcome screen exists
  only after the match, and `.inProgress` has to be unrepresentable on it. The wider type
  would have been more honest by name and worse by meaning.

**No migrations yet.** The `abandoned` column first arrived as a separate `v2` migration; by
the owner's decision it was folded back into `v1`. The app has no users, there is nothing to
migrate and nobody to migrate it for, and an extra schema version is code that will never run
on any device but the developer's. For now: the schema is edited directly in `v1`, and a
second version is not created before the first release. The rule is written down where it will
be seen — in `MatchDatabase`'s doc comment and in the test that lists the versions literally.
