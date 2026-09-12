# 13: The app icon

**What to build:** The icon for both apps, in the redesign's language. Both
`AppIcon.appiconset`s are empty today — `Contents.json` and nothing else.

**Blocked by:** 02

**Status:** done

- [x] The iOS icon set has a 1024×1024 mark and the app builds with it
- [x] The watch icon set has its own, drawn for a circle rather than cropped
      from the square one
- [x] The mark is the court's vocabulary and nothing new: `night`, the two
      halves, the net, the ball, and one accent
- [x] It survives being 60pt on a home screen and 24pt in Settings — checked at
      those sizes, not at 1024
- [x] Nothing in it is text

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

## Comments

**Closed.** The owner picked the third answer — the court with the ball waiting
on the net, which is what `canvas-court/Main.dc.html` draws before a match
starts. The two icon sets already held a mark, but it was a placeholder in a
generic court green with none of the palette in it; that is what was replaced.

It was not drawn by hand. A throwaway SwiftPM executable imported
`PadelDesign` and rendered `Court()`, `Floodlight` and `Ball` through
`ImageRenderer`, so the mark is the same court every screen draws rather than a
second court traced in an image editor. The four PNGs are the deliverable; the
renderer is not in the repo, by the owner's call — the day the palette moves,
the icons are redrawn the same way.

**On the sizes.** The court's thicknesses are absolute points, so the mark was
composed in a 128pt square and rendered at 8x. That is what makes the boards'
3pt tape a net you can see at 60pt instead of a hairline. Checked at 180, 120,
60 and 24pt under the mask each platform actually wears.

**On the watch.** The court runs full bleed there too. Taking it off the edges
so the posts and the outline's corners clear the circle leaves `night` showing
as a ring inside the crop, and a ring reads as a border around the icon rather
than as ground under it. Full bleed costs the outline's four corners and puts
the posts on the tangent, where they survive as nubs, and that is the cheaper
loss. The floodlight comes up from 0.17 to 0.20, since the crop takes the
corner it enters from; the ball comes down from 0.34 to 0.32.

**On the two iOS variants.** Dark is the same court taken 34% toward `night`
with the light down, and tinted is 50% with the light out — both under the
ball, not over it, so the one accent is the one thing that does not go down
with the lights. Tinted is drained to luminance in Core Graphics rather than
with `.grayscale(1)`: `ImageRenderer` drops effects it cannot resolve, and an
icon that quietly kept its colors is a bug nobody sees until App Store Connect
has the build.

This unblocks `.scratch/release/` ticket 03.
