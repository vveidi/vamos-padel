# 10: The court in Always-On

**What to build:** A dimmed variant of the court primitives, so the score
screen can be held on a wrist for ninety minutes without burning the display or
the battery.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] `CourtHalf`, `Floodlight`, `Ball` and `NetLine` read
      `@Environment(\.isLuminanceReduced)` and dim themselves
- [ ] In dimmed mode the floodlight is gone, the weave is gone, and the two
      half tints fall most of the way to `night`
- [ ] The score stays legible — it is the one thing the raised-wrist glance is
      for
- [ ] The ball stays, dimmed: which side serves is worth as much at a glance as
      the score
- [ ] The transition in and out is not jarring — the system fades it, so
      nothing here should animate on top of that
- [ ] Verified on a device or in the simulator's Always-On state, not by
      reasoning about it

## Why this is a ticket and not a clause in ticket 04

Nothing in this repo handles Always-On today — `grep` for `isLuminanceReduced`
returns nothing — and until now that has been fine. The score screen is nearly
black already: two flat tints at 10% and 35%, white numerals, a 10pt dot.

The redesign changes that. A full-bleed saturated court with a warm gradient
over it and a bright yellow ball, on an OLED that will hold the same frame for
an hour and a half of a match, is a different proposition — and the watch is
running a workout the whole time, which is precisely what keeps the screen on
and the app frontmost (`CONTEXT.md`, **Workout**).

Putting it here rather than in ticket 04 keeps it one change at the bottom of
the stack instead of a clause in six screen tickets. The dimming belongs to the
primitives; the screens should need no `if` at all.

## What dimmed mode should look like

The design brief is "one court at dusk". Dimmed is the same court **after the
floodlights go off**: the geometry survives, the light does not.

| Element | Lit | Dimmed |
| --- | --- | --- |
| Half tints | `#0e3d4c` / `#12564f` | most of the way to `night`, enough to keep the halves apart |
| Weave | 3% white | gone |
| Floodlight | warm radial | gone |
| Court lines | 0.2–0.36 | dimmer, but still there — they are the geometry |
| Net | ink 0.82 | dimmer |
| Score | full ink | full ink, unchanged |
| Ball | `ball` yellow | dimmer yellow, still yellow |

The rule: **the things that carry information stay, the things that carry
atmosphere go.** A glance in Always-On is for the score and the serve.

## Notes

**On which screens this reaches.** In practice only the score screen — that is
the one the workout keeps up and returns to on a raised wrist. But the dimming
lives in the primitives, so the start and rules screens get it free if they are
ever on screen when the wrist drops, and no screen needs to know.

**On the other screens' brightness.** Nothing else in the app is held up for
ninety minutes, so this ticket does not need to visit them.

**On verifying.** The simulator can be put into Always-On, and it is worth a
screenshot in both states side by side. What a preview cannot tell you is
whether the halves are still distinguishable when dimmed — two nearly-black
tints that differ by 4% on a calibrated display can be one colour on a watch in
the sun.
