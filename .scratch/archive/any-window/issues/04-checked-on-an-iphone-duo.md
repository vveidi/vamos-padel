# 04: Checked on an iPhone Duo

**What to build:** nothing yet — a pass over the app on an iPhone Duo, or its
simulator, once one is at hand.

**Blocked by:** 02, 03

**Status:** wontfix

- [ ] The scoreboard on the outer display in both poses, on the inner display,
      and in a Split View half: the halves are never narrow, and no control is
      under the hinge or the system's reserved regions
- [ ] New match, the history and the match card on the inner display and in a
      Split View half
- [ ] Opening and closing the device mid-match keeps the match, the score and
      the mirroring
- [ ] Anything that is wrong is a ticket of its own, not a fix folded in here

## Notes

**Waiting on the means, not on a decision.** The toolchain is Xcode 26.6 with the
iOS 26.5 SDK: no Duo simulator, and none of iOS 27's APIs for it. This ticket
becomes `ready-for-human` when there is a device, or `ready-for-agent` when
Xcode 27 is installed and its simulator has a Duo.

**The inner display is regular by regular in either pose**, and nearly square,
so the board's rule may put the net either way there. That is expected; a board
whose halves are wide enough is the criterion, not which arrangement wins.

## Comments

Closed `wontfix` by the owner on 2026-10-01: the app is not checked on an
iPhone Duo now. That check is for later, once there is a device or a simulator,
and it will be a ticket of its own then. Nothing here was built.
