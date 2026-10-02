# 09: The phone shows a match started on the wrist

**What to build:** when the watch starts a paired match, the phone's scorer
holds it but the phone's screen stays where it was — usually the new match
screen, whose "Start match" is then refused because a match is running. The
phone should put the match it holds on its scoreboard, whatever started it.

**Blocked by:** 05

**Status:** needs-triage

- [ ] A paired match started from the watch opens the scoreboard on the phone,
      from any tab
- [ ] The new match screen never offers a start the scorer will refuse
- [ ] Leaving the scoreboard of a paired match does what ticket 08 decides
      about the other device's match; today `leave()` calls `release()`
- [ ] Previews cover the phone receiving a match it did not start

## Notes

Found while driving ticket 05 on a simulator pair: the watch's start was
accepted, the history later listed the match, and the phone's screen never
moved.
