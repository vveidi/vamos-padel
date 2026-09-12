# 13: The app icon

**What to build:** The icon for both apps, in the redesign's language. Both
`AppIcon.appiconset`s are empty today — `Contents.json` and nothing else.

**Blocked by:** 02

**Status:** needs-triage

- [ ] The iOS icon set has a 1024×1024 mark and the app builds with it
- [ ] The watch icon set has its own, drawn for a circle rather than cropped
      from the square one
- [ ] The mark is the court's vocabulary and nothing new: `night`, the two
      halves, the net, the ball, and one accent
- [ ] It survives being 60pt on a home screen and 24pt in Settings — checked at
      those sizes, not at 1024
- [ ] Nothing in it is text

## Why this is triage and not ready-for-agent

Because drawing is a decision and the spec does not make it. The vocabulary is
settled — `spec.md` gives the court, the net, the ball and the one accent, and
ADR-0006 says there is one palette and no light variant — but which of them the
icon *is* has never been discussed, and there are at least three defensible
answers:

- **The ball alone**, on `night`. The app's one character, and the only thing
  that already means something at 24pt. Also the answer every tennis app gives.
- **The court seen from above**, the two halves and the tape. Unmistakably this
  app and nobody else's; possibly mush below 40pt.
- **The net and the ball on it**, which is what `Main.dc.html` draws before a
  match starts — the app's own opening image, already designed.

The third is the one I would argue for, and the argument is that it is the only
one of the three that the boards already drew. But an icon is the one thing in
the app that a person sees before they have read a single word of it, and it
should not be picked by an agent between two other tickets.

## What blocks what

`.scratch/release/` ticket 03 — the first TestFlight upload — cannot pass until
this exists. App Store Connect rejects a build with no icon during processing,
after the lane has already reported success.

## Notes

**On the watch icon.** watchOS wears it in a circle. A square mark with a
corner-heavy composition loses the corner, and the floodlight on these boards
comes in from exactly there.

**On there being no board for it.** As with tickets 07 and 09: draw by
extension, and treat a need for something the boards do not give as a sign to
look again rather than to invent.
