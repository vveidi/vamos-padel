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

**Status:** ready-for-agent

- [ ] **The watch answers.** A new message travels from the watch to the
      phone: "I have ended match `<id>`". The watch sends it once it holds the
      ended match, and again for every resend of that match it receives
- [ ] **The board waits.** After End on a paired match, from either device, the
      board shows a loader until that answer arrives. It leaves for the history
      after that, and not before. The scorer releases the match on the answer,
      not on End
- [ ] **A lost send is resent.** While the phone waits it still holds the ended
      match, so a reconnect resends it, and the watch answers again
- [ ] **The watch's outcome is never skipped.** Once the watch has the ended
      match, it shows "Match unfinished", whatever happens to the link
      afterwards
- [ ] **A watch that never answers does not trap the board.** After about ten
      seconds without an answer the loader stays and a "Leave anyway" button
      appears under it. Leaving releases the match as today
- [ ] "Close" on a won paired match does not wait: the watch already holds
      that match and shows its outcome
- [ ] A solo match is unchanged: End leaves at once
- [ ] Covered in `MatchScorerTests`. Driven on a simulator pair with the link
      cut between the end and the release

## Notes

Found while building ticket 12. Its PR raised this, and the owner chose a
loader and waiting for the watch's answer.

Triage settled the three open questions:

- **The answer is new on the wire.** `Echo` travels only from the phone to the
  watch, and from the watch only `MatchIntent`s go out. The new message rides
  that watch-to-phone channel; its exact shape is the builder's call.
- **The wait is bounded by the player, not a timer.** Leaving silently would
  bring the bug back, and waiting forever traps the board when the watch is
  out of reach. So after ~10 s the player gets a way out.
- **"Close" does not wait.** The watch ignores a release once its match is over
  (`MatchView.followUpdates`), and a won match reached it with the winning
  rally.
