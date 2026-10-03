# 15: The wait for the wrist survives a relaunch

**What to build:** after ticket 13 the phone holds an ended paired match until
the watch says it has it. That wait lives in memory only. `MatchScorer`
restores through `matchInProgress(scored:)`, which never returns an abandoned
match, so a phone relaunched while it waits comes back holding nothing. On the
next reconnect it sends "no match", and a watch that missed the end drops to its
start screen instead of showing "Match unfinished". That is ticket 13's bug,
reached through a relaunch.

**Blocked by:** 13

**Status:** needs-triage

- [ ] A paired match ended and not yet heard by the watch is held again after
      the phone relaunches, and its board comes back waiting
- [ ] The watch's answer after the relaunch releases it as before
- [ ] An ended match the watch already heard is not held again
- [ ] Covered in `MatchScorerTests`

## Notes

Found by the review of ticket 13.

Open question for triage: the store has no record of whether the watch heard
an end. Either it gains one (a schema change, which is still allowed before the
first release), or the phone holds every paired match ended in the last few
minutes and lets the watch's answer, or "Leave anyway", decide.
