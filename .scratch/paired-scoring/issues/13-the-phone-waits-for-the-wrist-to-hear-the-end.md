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

**Status:** done

- [x] **The watch answers.** A new message travels from the watch to the
      phone: "I have ended match `<id>`". The watch sends it once it holds the
      ended match, and again for every resend of that match it receives
- [x] **The board waits.** After End on a paired match, from either device, the
      board shows a loader until that answer arrives. It leaves for the history
      after that, and not before. The scorer releases the match on the answer,
      not on End
- [x] **A lost send is resent.** While the phone waits it still holds the ended
      match, so a reconnect resends it, and the watch answers again
- [x] **The watch's outcome is never skipped.** Once the watch has the ended
      match, it shows "Match unfinished", whatever happens to the link
      afterwards
- [x] **A watch that never answers does not trap the board.** After about ten
      seconds without an answer the loader stays and a "Leave anyway" button
      appears under it. Leaving releases the match as today
- [x] "Close" on a won paired match does not wait: the watch already holds
      that match and shows its outcome
- [x] A solo match is unchanged: End leaves at once
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

## Comments

**Closed.** The watch answers with `MatchIntent.heardEnd(of:)`, sent by
`MatchRemote` for every ended paired match it receives. `MatchScorer` lets go
of an abandoned match only on that answer. The board shows "Waiting for the
watch", then "Leave anyway" after ten seconds.

Covered in `MatchScorerTests`, `MatchRemoteTests` and `MatchPayloadTests`.
Driven on a simulator pair: solo End leaves at once; paired End from either
device with the link up shows "Match unfinished" on the watch and the history
on the phone; with the watch app killed before End the board waits, offers to
leave, and "Leave anyway" leaves; relaunching the watch instead resends the
end and the board leaves on the answer. Checked in Russian and at the largest
type.

Left open: the last criterion. A simulator cannot cut the link between the end
reaching the watch and its answer, so that drive moved to ticket 07, with
Close on a won match, which was ticked on the code alone. A phone relaunched
while it waits loses the wait: ticket 15.

The answer comes from the transport, not the screen: a relaunched watch, or one
scoring its own match, answers too, so the phone does not wait on a watch that
no longer shows the match.
