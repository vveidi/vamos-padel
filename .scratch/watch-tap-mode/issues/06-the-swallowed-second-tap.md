# 06: The swallowed second tap

**What to decide:** whether multi-tap may silently drop a tap. Found while
building 03, on a watchOS 26.5 simulator: when a second tap goes down inside the
350 ms double-tap window but lifts after it, the double fails, the first tap is
dispatched as our point, and the second tap awards nothing to anyone. No point,
no haptic.

**Blocked by:** 03

**Status:** needs-triage

## What was measured

Two taps on the same spot, each held about 135 ms, by second touch-down after
the first release:

| second down | what fired                         |
| ----------- | ---------------------------------- |
| 80–200 ms   | the double alone — their point     |
| 315 ms      | the single for the first; second lost |
| 420 ms      | two singles — two of our points    |

So the lost band is roughly the window minus the length of a tap: a second tap
started in the last ~100 ms of the window.

## What to decide

- [ ] Felt on a wrist: does the band exist on hardware, and does a player land
      in it in practice — say, two of our points scored quickly
- [ ] Either accept it, as 03 accepts the two-quick-taps hazard, and record why;
      or replace the framework's double with a recognizer of our own that
      counts a late second tap as a second single

## Notes

The silence is what separates it from the known hazard. A misattributed point
buzzes the wrong way and the long press fixes it; a lost point buzzes nothing
for the second tap, which a player not looking may never notice.
