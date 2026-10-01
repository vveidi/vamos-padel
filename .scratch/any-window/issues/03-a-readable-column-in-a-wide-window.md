# 03: A readable column in a wide window

**What to build:** New match, the history and the match card keep their content
to one column of readable width in a wide window, centred, instead of
stretching it across the screen.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] One named constant for the column's width, in `PadelDesign/Tokens/`, used
      by all three screens. Start near 600 pt and settle it on a device
- [ ] In a window wider than the constant the content is that wide and centred;
      the ground — the night, the floodlight — still fills the window
- [ ] In a window narrower than the constant nothing changes from today
- [ ] New match's pinned "Start match" and the history's bottom bar follow the
      column, not the window
- [ ] Previews of each screen in a wide window, in both languages
- [ ] The closing note says what the constant is and where the number came from

## Notes

**The column was asked for once before**, in `phone-scoring/05` ("the list
works in landscape: the column is capped at a readable width and centred"),
which closed `wontfix` for its other criteria. This is that criterion, for all
three screens.

**SwiftUI has no readable-width guide of its own.** UIKit's
`readableContentGuide` is not reachable from a SwiftUI layout, which is why the
width is a constant here rather than the system's.
