# 01: The engine knows the half

**What to build:** `MatchState` gains `servingHalf: ServingHalf?` beside
`servingSide`, computed by the same walk over the journal that computes the
score. Nothing on screen changes yet; ticket 02 draws it.

`ServingHalf` is `.right` or `.left` **as the server sees it**, facing the net.
`nil` means the golden point, where the receiving pair chooses the side and the
app is not told which — not "unset", but "not knowable". Its doc comment has to
say that the frame is the server's own, or the score screen's mirror (ticket 02)
will one day be read as a bug and straightened out.

The rules and the reasoning are in `spec.md`; `CONTEXT.md` has the domain terms.
Do not restate them here — build them.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `ServingHalf` exists in `PadelScoring`, public, with `.right` and `.left`, and a doc comment stating the frame is the server's own
- [ ] `MatchState.servingHalf: ServingHalf?` is public and computed, stored nowhere (ADR-0001)
- [ ] In classic scoring the half is the parity of the rallies played in the current game — right on the first, alternating after
- [ ] The alternation holds inside a tiebreak, where the serve passes on a different rhythm than the half
- [ ] With `goldenPoint: true`, the half is `nil` on a golden point, and only there — never in a tiebreak, which the golden point does not reach
- [ ] Without `goldenPoint`, deuce and advantage have an ordinary half and it is never `nil`
- [ ] In the match to N points the half is the parity of the rallies within the current service turn — right on the turn's first rally
- [ ] An undo returns the half to what it was, with no code of its own doing it
- [ ] The cases below are in `PadelScoringTests`, and the package suite is green

## Where the value comes from

Both walks already carry what is needed; nothing new has to be counted.

`ClassicReplay` has `points` — the current game's points, or the tiebreak's —
and `isTieBreak`. So in both cases the half is `points.total` even → right, odd
→ left, with one exception ahead of it: golden point, not a tiebreak, and
`points == SideCounts(us: 3, them: 3)`. `Points.pointsInGame` and its deuce
threshold already live in `Points`; take the number from there rather than
writing `3`, for the reason that file gives.

`PointsToReplay` has `points.total` and `serveChangesEvery` (already clamped to
at least 1). The rally's index within the service turn is
`points.total % serveChangesEvery`; even → right.

## The tests

A new `ServingHalfTests` suite, next to `ServingSideTests` and built the same
way: feed a ruleset and a sequence of won rallies, assert on `MatchState`.

1. **The first rally of a match comes from the right.** Both rulesets.
2. **The half alternates within a game**, and **returns to the right when the
   next game starts** — the case that fails if someone anchors on total rallies
   played instead of on the game.
3. **The tiebreak.** Walk it rally by rally: the serve changes after one and
   every two thereafter while the half flips every time. This is where the two
   rhythms are visibly different, and the only place a shared counter would go
   unnoticed.
4. **The golden point is `nil`** at 3:3 with `goldenPoint: true`, and the rally
   before it is not.
5. **Advantage scoring is never `nil`** — deuce comes from the right,
   advantage from the left, on and on.
6. **The service turn boundary with an odd X.** X = 3: rally 3 opens a new turn
   and comes from the right, which is where anchoring on total parity gives the
   wrong answer. With the default X = 4 the two agree, so an even X cannot
   catch this.
7. **X below one** behaves like X = 1, matching what `ServingSideTests` already
   pins down for the side.
8. **An undo restores the half**, asserted the way `UndoTests` asserts the rest
   of the state.

## Notes

**On `nil` rather than a third case.** A `.undecided` case would make every
reader handle a state that occurs on one rally in a game. Optionality is
already how `MatchState` says "there is nothing to show" — `games`, `sets` —
and the screen's habit carries over unchanged.

**On what does not change.** `MatchPayload`, the database, the match card: a
finished match is no better for knowing which half its 47th rally came from.
The half is a live aid and it dies with the match.
