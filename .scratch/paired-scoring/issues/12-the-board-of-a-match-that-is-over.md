# 12: The board of a match that is over

**What to build:** once a match is over — won by the rules, or ended on either
device — the phone's board still offers Undo and End. End on a match already
over changes nothing, and its alert says "The match will be saved as
unfinished", which is false for a match that was won. Undo reopens it.

End becomes the board's one way off, on any match, and the chevron goes. A
match ended on either device leaves no board behind it, so the one match the
board shows over is a won one.

**Blocked by:** 09

**Status:** ready-for-agent

- [ ] **No chevron.** The board's way back ("Back to your matches") is removed,
      solo and paired alike
- [ ] **End always takes the board away.** On a match in play it asks as it
      does today, ends the match and leaves for the history — a paired match
      too, which today stays on the board after End
- [ ] **End on a won match asks too, truthfully.** Its alert says nothing
      about the match being saved as unfinished; it asks whether to leave a
      match that is saved as it was won, and leaves on yes
- [ ] **A match ended on the watch takes the board away.** End on the wrist
      takes the phone's board to the history as End on the phone does. The
      watch's own outcome screen is unchanged
- [ ] **Undo is always there.** On a won match it takes back the winning rally
      and the match plays on, solo and paired; on the wrist a reopened paired
      match goes back to its score screen
- [ ] Previews cover the board of a won match, solo and paired, and the End
      alert on it
- [ ] Driven on a simulator pair: a paired match won, undone from the phone and
      won again; ended from the phone; ended from the wrist. A solo match won,
      then left through End

## Notes

Found while building ticket 09, which brought the way back to a paired board
only once its match is over. The solo board has behaved this way since it
shipped.

This undoes 09's "a match ended on the watch leaves its outcome on the board".
`CONTEXT.md`'s Scoreboard entry still reads true: the phone no longer holds a
match once it is ended.

An ended match is never on the board, so Undo never meets one, and the engine
keeps refusing to undo an abandonment.

The alert stays the system's `.alert`, which takes no tap outside it and lets
nothing behind it be pressed. The comment over it says why it is not a
`confirmationDialog`.

Undoing a won paired match reopens it after the watch has closed its workout;
the watch starts a second one, as a solo match undone from its outcome does.
The phone keeps its screen lit until that session arrives.

## Comments

**Triage.** The owner's calls: the chevron goes; End is the way off and always
asks; Undo stays on every board; a match ended on the wrist takes the phone's
board with it.
