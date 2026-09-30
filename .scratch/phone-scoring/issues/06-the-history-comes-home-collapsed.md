# 06: The history comes home with its title collapsed

**What to build:** the fix for a blemish ticket 04 left behind — after a match,
the history's large title is collapsed until the list is pulled down.

**Blocked by:** None

**Status:** needs-triage

- [ ] Leaving the scoreboard lands on the history with its large title standing,
      the way a fresh launch draws it
- [ ] A list the reader had deliberately scrolled is not snapped back to the top
      by the fix

## What is already known

The scoreboard asks for landscape on the way in and gives it back on the way
out. The history is laid out in landscape behind the cover while that happens,
and comes back holding a scroll offset it took in landscape — far enough down
to keep the navigation bar's large title collapsed. Pulling the list down
restores it, and so does relaunching.

It is the scroll offset and not the navigation bar: a plain device rotation to
landscape and back, with no scoreboard involved, leaves the large title alone.

Three fixes were tried in 04 and none worked:

- `.navigationBarTitleDisplayMode(.large)` on the history;
- a pushed screen in place of the full-screen cover;
- `.defaultScrollAnchor(.top, for: .sizeChanges)` on the list.

## The trade this ticket has to settle

A `ScrollViewReader` that scrolls to the top when the cover dismisses does fix
it. It also snaps a list the reader had scrolled on purpose, which is why 04
did not land it. Either that cost is acceptable, or the scroll has to be
conditional on the list having been at the top when the board opened.

That choice is why this is `needs-triage` rather than `ready-for-agent`.
