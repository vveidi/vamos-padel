# The icon is the ball on the court

The app icon is the app's own ball on the app's own court: the night court's blue full bleed, the ball in the middle, one floodlight from a corner. No net, no lines, no glass. Both targets ship the same artwork, and the phone's dark variant is that artwork again, because the app pins `.dark` and has no second appearance to answer.

What decided it is the smallest size the icon is ever drawn at — 29 points, a row in Settings. Everything larger flatters any candidate. Two were drawn and compared side by side at 1024, 180, 80 and 29, in `docs/design/AppIcon.html`, which keeps the one that lost.

## The court from a high corner lost

The rejected candidate was the whole court in three-quarter view from above one corner: the near glass catching the floodlight, the frame's posts, the net and the white lines a real court has. It had no ball, because the glass was its subject and a ball would have been a second one.

At 1024 it was the better picture, and it was the only one of the two that says *padel*. It lost at 29 points. There the lines, the net, the posts and both panes are gone, and what is left is a dark lozenge. Its ground is the night around the court, so the tile's own edge disappears into a dark Settings list and it does not read as an icon at all. It was enlarged to give it the fairest shot at that row, and it still failed there.

There was a second argument against it, and it was an argument, not the reason. A perspective court is a second drawing of the court `PadelDesign` already owns, and no test keeps the two in step: the day the court's blue is re-tuned or a theme lands, the icon is a hand-edited file nobody's build will catch. That is a cost paid forever, but it did not decide anything. A picture that held up at 29 points would have been worth it.

## What the winner costs

**It does not say padel.** A yellow ball on a blue court is every racket sport. The glass back wall is the one thing padel has that no other racket sport does, and the icon gave it up. In the App Store that difference is worth something, and the icon leaves it to the Store name, which ADR-0008 already makes say *Padel*.

**It can still drift, only less.** Its ball is `Ball`'s own path and its court is the court's own blue, so there is no second court to keep honest; only the weave departs from the app's, coarser so it survives 29 points. But it is a PNG exported from the study, which copies the palette's values rather than reading them, and no test compares the two. Re-tuning the court's blue means re-exporting the icon by hand, twice: the tinted variant is drawn for the system's grayscale and re-tint, not derived from the default.
