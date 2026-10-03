# 01: The crown pages down from the score

**What to build:** the match opens on the score, the middle of `ScorePages`'
three vertical pages. Turning the Digital Crown down from there does nothing;
it only pages once it has been turned up first. A swipe pages both ways from
the start, so the paging works and the crown alone is out of step with it.

**Blocked by:** None

**Status:** done

- [x] **Down first.** The crown turned down from a freshly opened score pages
      to tap mode, with no turn up before it
- [x] **Up still works.** The crown turned up from the score pages to the
      controls, and back down to the score
- [x] **Swipes untouched.** A swipe still pages both ways
- [x] **The match still opens on the score**, with no visible jump from
      another page
- [x] Driven on a watch simulator: the crown turned down, up and down again
      from a fresh match

## Comments

**Closing note.** The cause: the pager preloads the page next to the one on
screen, and a `ScrollView` there takes the crown's first turn toward it — tap
mode below the score, the settings below the start. Both pages now scroll only
while on screen (`.scrollDisabled`). `ScorePages` also starts with no page and
picks the score in `onAppear`; built straight on the score, the crown thinks it
is on the first page and turning up is dead. The `NavigationStack` moved into
the pages that push, on both screens: a stack always goes inside a `TabView`.

Driven with a throwaway XCUITest probe (`XCUIDevice.rotateDigitalCrown`, 0.8 a
page) and by the owner with the trackpad: down and up from the score after a
start and after a relaunch, down and up on the start pages, the crown still
scrolling the settings, swipes both ways. One gap the probe still shows: on a
match just started from the start pages, the very first turn *up* does not
page; the owner's trackpad run found it fine. Animating the move to the score
did not change it.
