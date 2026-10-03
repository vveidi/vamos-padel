# 01: The crown pages down from the score

**What to build:** the match opens on the score, the middle of `ScorePages`'
three vertical pages. Turning the Digital Crown down from there does nothing;
it only pages once it has been turned up first. A swipe pages both ways from
the start, so the paging works and the crown alone is out of step with it.

**Blocked by:** None

**Status:** ready-for-human

- [x] **Down first.** The crown turned down from a freshly opened score pages
      to tap mode, with no turn up before it
- [x] **Up still works.** The crown turned up from the score pages to the
      controls, and back down to the score
- [ ] **Swipes untouched.** A swipe still pages both ways
- [x] **The match still opens on the score**, with no visible jump from
      another page
- [x] Driven on a watch simulator: the crown turned down, up and down again
      from a fresh match

## Comments

**Closing note.** The fix is two changes together; neither alone did it. The
`NavigationStack` moved from around the `TabView` into the page that pushes
(tap mode on the match, settings on the start), and `ScorePages` builds on
`.controls` and moves to `.score` in `onAppear`. The start pages got the same
move although their crown worked: a stack always goes inside a `TabView`.

Verified by the owner on a simulator with the trackpad as the crown. An
XCUITest probe (`XCUIDevice.rotateDigitalCrown`) disagreed — it still saw the
first turn down eaten — but it was noisy across identical runs, so the owner's
check stands. Left for the owner: swipes both ways after the change, and that
the lists pushed from tap mode and the rules now land under the page
indicator rather than over it.
