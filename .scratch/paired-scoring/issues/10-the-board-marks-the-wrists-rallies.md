# 10: The board marks the wrist's rallies

**What to verify:** the phone's scoreboard marks a rally the watch awarded
exactly as it marks one the phone did. This is what is left of `rally-mark` 03
once the phone can be handed a rally it did not record.

**Blocked by:** 05

**Status:** done

- [x] **Every rally is marked, whatever awarded it.** A rally tapped into the
      wrist marks the board. The phone has no origin filter, and the one 05
      adds to the watch has no counterpart on the phone — ADR-0011 says why the
      two devices differ
- [x] A rally the phone awards and a rally that arrives over the live link go
      through one path and look identical. Today that path is
      `ScoreboardView`'s `onChange` on the journal; whatever 05 changes about
      how the board gets its match must keep it the only one
- [x] The board is driven on a simulator pair with the watch awarding the
      rallies: a rally to each side, a game taken, an undo from the wrist that
      marks nothing

## Notes

`rally-mark` 03 built the mark on the phone and drove it with the phone
awarding every rally, because under ADR-0009 there was no other origin. These
three criteria were its own and moved here; nothing on the phone needs writing
for them unless 05 moves where the board's journal comes from.

## Comments

**Triage.** 05 and 09 kept the one path. Every match change, from the phone's
own tap or from the wrist's intent, reaches the board through
`MatchScorer.updates()` into `ScoreboardView.follow()`, and the mark is drawn
only by the `onChange` on the journal, which ignores a journal that shrank. No
code is expected: the first two criteria are read off the code and checked;
the third is the simulator drive, and a mark that fails it is a bug fixed here.

**Closed.** No code changed: the drive found nothing to fix. The first two
criteria are read off the code. The phone's own tap and the wrist's intent
both end in `MatchScorer.publish`, `ScoreboardView.follow()` takes either, and
the `onChange` on the journal has no origin to filter on. The third was driven
on a paired iPhone 17 Pro and Series 11 simulator, the watch awarding every
rally while the phone's screen was recorded. A rally to us, one to the
opponents and a game each lit their half. A long-press undo on the wrist took
the board back and lit nothing.
