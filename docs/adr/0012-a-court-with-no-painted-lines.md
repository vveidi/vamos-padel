# A court with no painted lines

`CourtHalf` draws a surface and a weave. It paints no service line, no centre
line and no outline, and a half carries no identity of its own.

## The lines were removed because the half is not a court to scale

A real padel half is 10m by 10m — square. The half drawn here is a letterbox,
198pt wide and about 120pt deep on a watch. Every line placed at its correct
*fraction* of the half therefore landed in the right fraction of the wrong
shape: the service boxes came out as letterboxes, and the line a player looks
for was nowhere near where they look.

The outline was worse than misplaced. It was a tennis import: a padel court's
edge is glass and mesh, and a painted sideline inside the half draws a boundary
that does not exist.

Neither re-placing the lines nor thinning them fixes either problem, because
the shape is the problem. The half cannot be made into a court to scale without
giving up the letterbox the screens are, so a service line written back would be
the same mistake a second time.

## One surface, and position says whose it is

Both halves take the one blue. Which half is ours is said by **position** —
theirs above the net, ours below, the same as when you stand on court — and by
the net between them, never by a second hue and never by a label. That is why
nothing in `CourtColors.swift` takes a `Side`, and why `CourtHalf` is one view
rather than two.

## Consequences

- **The weave is the only texture left on the surface**, and it stays at the
  weight it had rather than being asked to do the lines' work.
- **`CourtMetrics` holds thicknesses and no proportions.** The one proportion it
  used to hold was the service line's, and it was deleted along with the shape
  it was measured in.
- **ADR-0011's closing warning is sharper than it reads there.** The rally mark
  brightens a surface whose color is the only thing saying whose surface it is,
  and with the lines gone there is nothing else on the half to carry that.
