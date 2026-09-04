# 12: The match card

**What to build:** Opening a match from the list, the owner sees not only how it ended but how it came about: the course of the score is reconstructed from the **rally journal** by the same engine that counted the match on the watch.

This is what the journal is stored for instead of the final score (ADR-0001), and what the engine lives in a shared package for: the same logic yields the same result on both devices.

**Blocked by:** 11, 03

**Status:** done

- [x] The card shows the course of the score through the match, not only the result
- [x] The course is reconstructed by the engine from the journal rather than stored separately
- [x] For classic scoring the progression through games and sets is visible
- [x] For the match to N points it is visible how the points were accumulated
- [x] The card of an abandoned match shows clearly that it was not played out
- [x] A match restored on the phone shows the same score as it had on the watch

## Comments

**Done.** The card is a scoreboard: the outcome and the final score at the top, and
underneath the score as it stood after every step the match moved by.

- **The course, not only the result**: under "Ход матча" stands a two-row strip — "Мы"
  above "Соперники" — with a column per step and the score after it. The step just taken
  is the filled cell, so who took what is read off without reading a number, and the
  numbers say how close it was. Checked in the simulator on five seeded matches, in both
  appearances and at `accessibility-medium`.
- **Reconstructed by the engine**: `MatchCourse(ruleset:journal:)` in `PadelScoring`,
  reached from the card as `match.course`. Nothing about the course is stored, and the
  card computes nothing — it draws what the engine hands it.
- **Classic scoring**: a section per set, headed "Сет N" with the set's games on the
  right; inside it the games, and beneath them the tiebreak's points where the set went
  to one — "7 : 6" says a tiebreak happened and nothing about how it went. In a match of
  one set the header is "Ход матча" instead: the number and the score would both be the
  match's own, already in large type above.
- **The match to N points**: the same strip, a column per rally.
- **An abandoned match**: "Матч не доигран" stands where "Мы выиграли" would, and the
  last section carries "Гейм не доигран · 40 : 0" — where inside a game the match was
  left. A game carried no further than 40:30 wins nobody anything and is therefore no
  step of the course, but it is exactly where play stopped, and without it the card would
  end on the last game that did finish, as if the match had been stopped on a clean
  boundary.
- **The same score as on the watch**: the engine is one, the phone links the same
  package, and what travels is the ruleset and the journal — everything the score is
  computed from. A test pins the course to the state's `finalScore` across five rulesets
  and four journals, so the card and the watch's outcome screen cannot arrive at
  different numbers. What was not run is the pair itself: a match played on a watch and
  opened on a phone needs both devices (see below).

## What was decided along the way

**One walk over the journal, two readers.** The course could have been folded a second
time next to `MatchState`'s fold, and would have agreed with it — until the first edit to
either. Instead the fold moved into `ClassicReplay` and `PointsToReplay`, and `MatchState`
became a projection of the same walk the course is read off. A course that disagreed with
the score would be worse than no course at all, and this is the only way to make the
disagreement impossible rather than unlikely. `MatchState.swift` kept its value and lost
its engine; the 76 tests that were passing before the move still pass unchanged.

**The course is made of what was played out.** A game abandoned at 40:30 is not a step: a
step is somebody taking something, and inventing one for an unfinished game would put a
game into the course that nobody won. The set the match stands in — empty until its first
game — is dropped for the same reason. Where the match was actually left is said by the
state's points, in as many words, on the one card where it matters.

**The strip is the running score, not the winner of each step.** A row of "мы / они /
мы" answers "was it close" only after the reader adds it up. Thirteen columns — six games
each and a tiebreak, the longest set there is — fit the width without scrolling; a match
to twenty-one points does not and scrolls, which beats cutting it short at the point
everyone reads first.

**The abandoned capsule is not repeated on the card.** The row needs it because a score
in a column of results must not pass for a win at a glance. On the card the outcome is
already spelled out in a whole sentence, in the place a win is announced, and the capsule
beside it was the same sentence twice.

**The phone's words for a match now live in one place.** `MatchWording.swift` holds the
ruleset's name and the dates, which the row and the card have to say identically. This is
the third copy ticket 11 said should force the seam — and it forced it exactly as far as
the phone: the watch's start screen names a ruleset about to be chosen and keeps the
numbers out of it, which is a different sentence, not the same one copied.

**"Смена подачи через X розыгрышей" is on the card and not in the row.** So is the golden
point. They decide how the match was played, not how the number in front of the reader is
to be read — the split ticket 11 asked for.

## What is not verified

**A match played on the watch and opened on the phone.** That needs the pair run together,
which this setup does not do. What is checked underneath it: the course is a pure function
of the ruleset and the journal (a test), those two are exactly what delivery carries
(`PadelDelivery`'s tests), and they survive the store round trip (`PadelStorage`'s). The
card asks the same engine the watch asks.

**The horizontal scroll of a long strip** was seen to be needed — a match to 16 points
runs off the edge — but not dragged: the simulator's UI is driven here by clicking, not
by gestures.
