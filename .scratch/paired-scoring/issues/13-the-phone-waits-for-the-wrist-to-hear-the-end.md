# 13: The phone waits for the wrist to hear the end

**What to build:** when a paired match ends, the phone lets go of it straight
away: it publishes the ended match, then releases it, and both go out to the
watch as fire-and-forget sends. If the ended match is lost on the way and only
the release arrives, the watch never sees the match end. It drops to its start
screen instead of showing "Match unfinished". Before ticket 12 the phone held
the ended match, and a reconnect resent it. Now nothing does.

The phone should wait until the watch has the ended match before it lets go.
Until then the board shows that it is waiting.

**Blocked by:** 12

**Status:** needs-triage

- [ ] **The board waits.** After End on a paired match, from either device, the
      board shows a loader until the watch says it has the ended match. It
      leaves for the history after that, and not before
- [ ] **The watch's outcome is never skipped.** Once the watch has the ended
      match, it shows "Match unfinished", whatever happens to the link
      afterwards
- [ ] **A watch that never answers does not trap the board.** What the board
      does then is the owner's call (see Notes)
- [ ] A solo match is unchanged: End leaves at once
- [ ] Covered in `MatchScorerTests`. Driven on a simulator pair with the link
      cut between the end and the release

## Notes

Found while building ticket 12. Its PR raised this, and the owner chose a
loader and waiting for the watch's answer.

Open questions for triage:

- What counts as the watch's answer: an echo the scorer already sends, or a
  new acknowledgement on the wire?
- How long the board waits, and what it does when the watch stays silent or
  unreachable: leave anyway, offer to leave, or keep waiting.
- Whether a won paired match closed through "Close" waits too. The watch
  already shows its outcome, but it would see the same release.
