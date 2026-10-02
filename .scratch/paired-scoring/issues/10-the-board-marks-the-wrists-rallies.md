# 10: The board marks the wrist's rallies

**What to verify:** the phone's scoreboard marks a rally the watch awarded
exactly as it marks one the phone did. This is what is left of `rally-mark` 03
once the phone can be handed a rally it did not record.

**Blocked by:** 05

**Status:** needs-triage

- [ ] **Every rally is marked, whatever awarded it.** A rally tapped into the
      wrist marks the board. The phone has no origin filter, and the one 05
      adds to the watch has no counterpart on the phone — ADR-0011 says why the
      two devices differ
- [ ] A rally the phone awards and a rally that arrives over the live link go
      through one path and look identical. Today that path is
      `ScoreboardView`'s `onChange` on the journal; whatever 05 changes about
      how the board gets its match must keep it the only one
- [ ] The board is driven on a simulator pair with the watch awarding the
      rallies: a rally to each side, a game taken, an undo from the wrist that
      marks nothing

## Notes

`rally-mark` 03 built the mark on the phone and drove it with the phone
awarding every rally, because under ADR-0009 there was no other origin. These
three criteria were its own and moved here; nothing on the phone needs writing
for them unless 05 moves where the board's journal comes from.
