# 03: A readable column in a wide window

**What to build:** New match, the history and the match card keep their content
to one column of readable width in a wide window, centred, instead of
stretching it across the screen.

**Blocked by:** None

**Status:** done

- [x] One named constant for the column's width, in `PadelDesign/Tokens/`, used
      by all three screens. Start near 600 pt and settle it on a device
- [x] In a window wider than the constant the content is that wide and centred;
      the ground — the night, the floodlight — still fills the window
- [x] In a window narrower than the constant nothing changes from today
- [x] New match's pinned "Start match" and the history's bottom bar follow the
      column, not the window
- [x] Previews of each screen in a wide window, in both languages
- [x] The closing note says what the constant is and where the number came from

## Notes

**The column was asked for once before**, in `phone-scoring/05` ("the list
works in landscape: the column is capped at a readable width and centred"),
which closed `wontfix` for its other criteria. This is that criterion, for all
three screens.

**SwiftUI has no readable-width guide of its own.** UIKit's
`readableContentGuide` is not reachable from a SwiftUI layout, which is why the
width is a constant here rather than the system's.

## Comments

**Shipped.** `CGFloat.readableColumn`, 600 pt, in
`PadelDesign/Tokens/Column.swift`. It is the content's width; each screen's own
inset sits outside it. New match, the history (its tiles and its notices), the
match card and the pinned "Start match" are capped at it and centred. The ground
and the scrim still fill the window. A window narrower than the column plus the
inset lays out as before.

**Where 600 came from.** The ticket's starting number, kept after looking at all
three screens on an iPhone 17 Pro Max held sideways (about 830 pt inside the
safe area), in both languages and at the largest type.

**The history's bottom bar** is the system tab bar, which belongs to the root,
not the history. On iOS 26 it is a narrow capsule centred in the window, so it
already sits inside the column. It is left alone.
