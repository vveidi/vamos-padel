# 02: The icon

**What to build:** a study holding two candidate icons, a stop for the owner to
pick one, and the winner shipped to both targets.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `docs/design/AppIcon.html` is a **study**, not a board: it holds both
      candidates *and* keeps the loser, for the reason `docs/design/README.md`
      gives — a decision with its rejected options thrown away is an assertion
- [ ] Both candidates are shown at **1024, 180, 80 and 29pt** on one page, with
      the current icon beside them. The 29pt row is the one the decision is made
      at; everything else is flattery
- [ ] **Candidate A — the ball on the court.** The court's `#17406F` full-bleed
      with the weave, the app's own ball centered at roughly 46% of the icon, its
      two seam arcs in `ballSeam`, one floodlight from a corner. No net, no lines
- [ ] **Candidate B — the court from a high corner.** The whole court in
      three-quarter perspective: the near **glass wall** catching the floodlight,
      the frame's posts, the net, and the white lines a real court has and the app
      no longer draws. **No ball** — the glass is what makes it padel rather than
      tennis, and a ball on top of it is a second subject competing at 29pt
- [ ] Both render through headless Chrome at 1024×1024 and are looked at as PNGs,
      not only in a browser
- [ ] **Stop here and ask the owner which.** The choice is not the agent's; do not
      proceed to the export on a guess
- [ ] The winner ships as `icon-1024.png` to `Padel/Resources/Assets.xcassets/AppIcon.appiconset`
      and `Padel Watch App/Resources/Assets.xcassets/AppIcon.appiconset`
- [ ] The phone's **dark** variant is identical to the default — the app pins
      `.dark` and there is no second design — and that sameness is deliberate,
      not an oversight
- [ ] The phone's **tinted** variant is drawn for the job: the system grayscales
      and re-tints it, so a blue field with a yellow ball collapses to two grays
      unless the artwork carries its own value separation. Check it by actually
      desaturating the file
- [ ] `Contents.json` is unchanged in shape — same three entries on the phone,
      one on the watch
- [ ] Both apps build and the icon is **seen on a simulator home screen**, not
      only in the asset catalog. The watch's circular crop is checked there too

## Notes

**What the two candidates are actually arguing about.** A is the app's own
material — the same court, the same ball, the same light — and reads at any size.
B is the only one of the two that says *padel* rather than *racket sport*: the
glass back wall is the difference, and nothing else in the app draws it. B is
also two sources of truth, since the court exists as a top-down primitive and a
perspective court is a second drawing of the same thing that no code will keep
honest. That is a real cost and it is why the study exists rather than a
preference being asserted.

**Why HTML and not SwiftUI.** Drawing them as SwiftUI previews would be truer to
the app's primitives — for A. For B there is no primitive to be true to, and the
work would be a perspective-court renderer built to be thrown away. The study is
the cheaper honest comparison, and `RallyMark.html` is the precedent.

**The pipeline, since none exists in the repo.** The four icon PNGs in git have
no generator behind them. Headless Chrome screenshots the artboard at
1024×1024 and `sips` does any resizing; both are already on this machine. Neither
`rsvg-convert` nor ImageMagick is installed, so do not reach for them.

**The 29pt row is not a formality.** Both candidates will look good at 1024. One
of them is a perspective drawing of a court with a net and white lines in it, and
the question the study answers is whether that survives being 29 points across in
a Settings list.
