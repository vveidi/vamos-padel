# 12: The board of a match that is over

**What to build:** once a match is over — won by the rules, or ended on either
device — the phone's board still offers Undo and End. End on a match already
over changes nothing, and its alert says "The match will be saved as
unfinished", which is false for a match that was won. Undo reopens it.

**Blocked by:** 09

**Status:** needs-triage

- [ ] What the board's controls offer on a match that is over is decided and
      built, solo and paired alike
- [ ] No alert on the board says anything untrue about a match that is over
- [ ] Previews cover the board of a won match and of an ended one

## Notes

Found while building ticket 09, which brought the way back to a paired board
only once its match is over. The solo board has behaved this way since it
shipped.

Open questions for triage: whether Undo stays, so a rally wrongly scored as
the last one can be taken back; and whether End goes, or turns into the way
back.
