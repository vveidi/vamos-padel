# 07: The live pair run-through

**What to verify:** the half of this feature no simulator can see. A real watch
on a real wrist, a real phone on a bench, and a list of things that either work
or sink the release.

**Blocked by:** 04, 05, 08

**Status:** ready-for-human

- [ ] **The mirrored session lifts the phone.** Start a paired match on the
      watch, lock the phone, play ten rallies from the wrist, unlock: all ten
      are there
- [ ] **And keeps lifting it.** The same, but leave it locked for twenty minutes
      with rallies throughout. Watch for the app being jettisoned and relaunched
      — the journal must come back from the store, not from memory
- [ ] **`startWatchApp` raises the watch.** With the watch app closed, start a
      paired match on the phone: the watch comes up into the match
- [ ] **Force-quit is honoured.** Swipe the phone's app away mid-match; the
      watch reports the phone unreachable and refuses taps. Reopen the app: the
      match is where it was
- [ ] **Range.** Walk the phone out of Bluetooth range and back. Same behaviour,
      and no invented rallies on the way back in
- [ ] **The watch lost.** Take the watch off mid-match and close its app: the
      scoreboard says so and goes on scoring; reopen it and the watch rejoins
      where the phone is
- [ ] **Latency from the wrist.** Time a tap to the digit changing, with the
      phone asleep in a pocket and again with the scoreboard open. Write both
      numbers into the closing note — this is the number that decides whether
      the fallback channel ADR-0010 names is needed
- [ ] **A refused tap** looks different from a taken one on the wrist
- [ ] **The setting.** With it off on both devices, each scores alone exactly as
      before, and a watch-scored match is still delivered. With it on, a start
      on either device pairs; with the other device away or busy, the start
      screen says so and offers to score alone
- [ ] **Ninety minutes of scoreboard.** Battery drawn on both devices, and how
      warm the phone gets with the idle timer disabled
- [ ] **Always-On on the watch** still dims the court the way the redesign
      built it to, now that the score arrives from outside
- [ ] **Health.** The workout of a paired match lands in Health with the switch
      on, and does not with it off; the match runs either way
- [ ] **Refusing Health authorization** on the phone leaves the phone's switch
      off and says why
- [ ] **Two pairs, one bench.** Read the board from where the players actually
      stand, mirror it, read it again. Digits legible at three metres
- [ ] Every number and every surprise goes into the closing note

## Notes

**This is the ticket that can send the feature back.** If the latency from a
sleeping phone is seconds rather than fractions, the answer is not to ship it
and hope: it is the fallback channel, or a re-examination of pairing itself.
Both are decisions for the owner.

**The first upload waits on this.** `release/03` lists it as a blocker: the
paired match ships in the first release or not at all, and a run-through that
finds something on the day of the upload finds it too late.
