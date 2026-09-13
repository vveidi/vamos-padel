# 11: The live pair run-through

**What to verify:** the half of this feature no simulator can see. A real watch
on a real wrist, a real phone on a bench, and a list of things that either work
or sink the release.

**Blocked by:** 05, 06, 07, 08, 09, 10

**Status:** ready-for-human

- [ ] **The mirrored session lifts the phone.** Start a match on the watch, lock
      the phone, play ten rallies from the wrist, unlock: all ten are there
- [ ] **And keeps lifting it.** The same, but leave it locked for twenty minutes
      with rallies throughout. Watch for the app being jettisoned and relaunched
      — the journal must come back from the store, not from memory
- [ ] **`startWatchApp` raises the watch.** With the watch app closed, start a
      match on the phone: the watch comes up into the match
- [ ] **Force-quit is honoured.** Swipe the phone's app away mid-match; the
      watch reports the phone unreachable and refuses taps. Reopen the app: the
      match is where it was
- [ ] **Range.** Walk the phone out of Bluetooth range and back. Same behaviour,
      and no invented rallies on the way back in
- [ ] **Latency from the wrist.** Time a tap to the digit changing, with the
      phone asleep in a pocket and again with the scoreboard open. Write both
      numbers into the closing note — this is the number that decides whether
      ADR-0010's fallback channel is needed
- [ ] **Ninety minutes of scoreboard.** Battery drawn on both devices, and how
      warm the phone gets with the idle timer disabled
- [ ] **Always-On on the watch** still dims the court the way the redesign
      built it to, now that the score arrives from outside
- [ ] **Health.** The workout lands in Health with the switch on, and does not
      with it off; the match runs either way
- [ ] **Refusing Health authorization** leaves a match that works while the
      screen is on, and says so
- [ ] **Two pairs, one bench.** Read the board from where the players actually
      stand, mirror it, read it again. Digits legible at three metres
- [ ] Every number and every surprise goes into the closing note

## Notes

**This is the ticket that can send the feature back.** If the latency from a
sleeping phone is seconds rather than fractions, the answer is not to ship it
and hope: it is ADR-0010's fallback, or a re-examination of ADR-0009 itself.
Both are decisions for the owner, which is why this ticket is not
`ready-for-agent`.

**Run it before the App Store lane, not after.** `release/01` and `release/03`
are waiting on this feature; a run-through that finds something on the day of
the upload finds it too late.
