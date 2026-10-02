# 11: The phone's scorer survives a relaunch

**What to build:** `MatchScorer` lives in memory and starts empty. A phone app
jettisoned or crashed mid-match, then relaunched, broadcasts that there is no
match: the watch closes the unfinished match it was the remote of, and the
history keeps it "in progress" with no way to go on with it.

**Blocked by:** 05

**Status:** needs-triage

- [ ] A paired match the phone held when its app went away is held again when
      the app comes back, and the watch rejoins it where it was
- [ ] What happens to a solo phone match left in the store unfinished is
      decided here, not inherited by accident

## Notes

Found while triaging ticket 09. Ticket 07 already checks this on a real pair —
"the journal must come back from the store, not from memory", and a force-quit
app reopened to find the match where it was — and would fail both today.

Open questions for triage: which stored match counts as the one the phone held,
when the store cannot tell a match the phone scored from an unfinished one it
received; and whether ADR-0009 or ADR-0017 needs a word on it.
