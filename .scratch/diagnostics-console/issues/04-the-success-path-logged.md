# 04: The success path logged

**What to build:** today only failures are written. Add `info` messages at the
points below and a `debug` message for every rally, worded like the messages
already there — short, lower case, saying what happened.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] **Both devices:** the app launched, the store opened and how many matches
      it holds; the app went to the background and came back
- [ ] **The match:** started — its ruleset, how it is scored (watch alone,
      phone alone, paired) and who serves; over or abandoned — the final score
      and how long it lasted; an unfinished match taken back on launch
- [ ] **Delivery:** the session activated; the other device reachable or not;
      a parcel sent and a parcel received, with its kind (`match`, `receipt`,
      `intent`, `update`) and the match's id; a delivery marked
- [ ] **The workout:** started, mirrored to the phone, ended, written to Health
- [ ] **Every rally:** `debug`, who won it and the score after; an undo too
- [ ] Driven on a simulator pair: a paired match played and ended, then read
      in both consoles (02, 03) — or, if they are not built yet, in
      Console.app — with every line above present

## Notes

A rally a minute is 100–200 lines a match; the console filters by level, and
the 14-day retention holds weeks of them.

## Comments
