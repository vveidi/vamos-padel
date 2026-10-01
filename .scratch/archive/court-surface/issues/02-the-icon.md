# 02: The icon

**What to build:** a study holding two candidate icons, a stop for the owner to
pick one, and the winner shipped to both targets.

**Blocked by:** None

**Status:** done

- [x] `docs/design/AppIcon.html` is a **study**, not a board: it holds both
      candidates *and* keeps the loser, for the reason `docs/design/README.md`
      gives — a decision with its rejected options thrown away is an assertion
- [x] Both candidates are shown at **1024, 180, 80 and 29pt** on one page, with
      the current icon beside them. The 29pt row is the one the decision is made
      at; everything else is flattery
- [x] **Candidate A — the ball on the court.** The court's `#17406F` full-bleed
      with the weave, the app's own ball centered at roughly 46% of the icon, its
      two seam arcs in `ballSeam`, one floodlight from a corner. No net, no lines
- [x] **Candidate B — the court from a high corner.** The whole court in
      three-quarter perspective: the near **glass wall** catching the floodlight,
      the frame's posts, the net, and the white lines a real court has and the app
      no longer draws. **No ball** — the glass is what makes it padel rather than
      tennis, and a ball on top of it is a second subject competing at 29pt
- [x] Both render through headless Chrome at 1024×1024 and are looked at as PNGs,
      not only in a browser
- [x] **Stop here and ask the owner which.** The choice is not the agent's; do not
      proceed to the export on a guess
- [x] The winner ships as `icon-1024.png` to `Padel/Resources/Assets.xcassets/AppIcon.appiconset`
      and `Padel Watch App/Resources/Assets.xcassets/AppIcon.appiconset`
- [x] The phone's **dark** variant is identical to the default — the app pins
      `.dark` and there is no second design — and that sameness is deliberate,
      not an oversight
- [x] The phone's **tinted** variant is drawn for the job: the system grayscales
      and re-tints it, so a blue field with a yellow ball collapses to two grays
      unless the artwork carries its own value separation. Check it by actually
      desaturating the file
- [x] `Contents.json` is unchanged in shape — same three entries on the phone,
      one on the watch
- [x] Both apps build and the icon is **seen on a simulator home screen**, not
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

## Comments

Built and closed. All eleven criteria met, one of them only after `code-review`
caught the study falsifying itself.

**The study.** `docs/design/AppIcon.html` holds both candidates at 1024, 180, 80
and 29pt with the superseded icon beside them at all four. Both are vector, so
every row is the artwork the export writes rather than a resampled copy, and
`?export=a|b|a-tinted` strips the page to one 1024 tile for headless Chrome. B
is kept drawn under a verdict saying why it lost, per `docs/design/README.md`.

**The candidates.** A is `court` full bleed with the weave, one floodlight from
the top-trailing corner, and `Ball`'s own 24-unit box at 46% of the icon with its
two seam curves at `ballSeam` — the disc itself lands at 42%, because the felt is
r11 of 24. B is the whole court from a high corner on an axonometric projection,
with the near glass, six posts, the net and the white lines, and no ball.

**The owner picked A at the 29pt row.** B is the better drawing at 1024 and the
only one of the two that says *padel*, and it lost anyway: at 29 points the
lines, the net, the posts and both panes are gone, and its `night` ground makes
the tile's own edge vanish in a dark Settings list. It was enlarged to 1.2 of its
projected size to give it the fairest shot at that row and still failed there.

**What shipped.** `icon-1024.png` to both catalogs. The phone's dark variant is
byte-identical to the default — md5 `89ef8bb4…` across all three files — because
the app pins `.dark` and there is no second appearance to answer. The tinted
variant is drawn rather than desaturated: ground at 0.150 against the default's
0.238, ball at 0.941, a separation of 0.791 against 0.654, maximum saturation
0.000. Both `Contents.json` are untouched.

**Driven.** Both schemes build clean and `PadelTests` passes 14/14 on this
session's own simulators. The icon was seen on the iOS home screen and in the
watch app grid, where the circular crop takes nothing that matters because the
ball is centred.

**What `code-review` found, and what each finding got.**

1. **The study rendered candidate A in its own "Current" column** — the three
   `<img>` tags pointed into the asset catalog, at the file this same change
   overwrote. Every comparison row showed A twice, the decisive one included, and
   the note describing two-tone halves and painted lines was false of what it
   drew. Fixed: the superseded icon is committed as `docs/design/icon-superseded.png`
   and the study points there. This is the one finding that would have shipped a
   broken artifact, and it is the argument for the rule it breaks — a study that
   points at a live file stops being a study the moment that file wins.
2. **The tinted numbers were single-pixel samples asserted as measurements.**
   The page claimed 0.14 / 0.94 / 0.80 "measured off the exported PNGs"; a second
   probe at a different pixel read 0.169 and 0.772, because the weave and the
   floodlight move a point sample by about 0.03. Re-measured as regional means
   with the regions and the luma formula named on the page.
3. **The current icon was missing from the 1024 rows.** Added.
4. **Comments over CLAUDE.md's four-line ceiling, and comments restating the
   markup.** The page banner, the tinted-symbol comment and the seam comment were
   trimmed; `// Clipped to the felt` over `clip-path="url(#felt)"` went; the
   `border-radius` comment now says where 22.37% comes from instead of naming the
   property. The 46% comment was corrected — it stated the box as the ball.
5. **`clipPath id="felt"` was defined inside candidate A and used by the tinted
   symbol.** Moved to the shared `defs`. Re-exported afterwards and the shipped
   PNG is byte-identical, so the refactor moved no pixels.
6. **Dead CSS** — four unused custom properties and a `.verdict .pending` rule
   left behind by the verdict being written. Deleted.

**Left for the owner to arbitrate.**

1. **The ball geometry is drawn twice**, once in `#cand-a` and once in
   `#cand-a-tinted`, along with three near-identical floodlight gradients and
   three hand-written size rows. One `<symbol>` taking its fills from CSS custom
   properties would collapse all three duplications. It was left alone because it
   is a judgment call the ticket did not ask for, and because the file is a study
   that will be read more often than edited — but the ball now changes in two
   places, which is exactly the maintenance argument B lost on.
2. **This decision has no ADR.** `RallyMark.html` is cited by ADR-0011;
   `AppIcon.html` is cited by nothing, and `.scratch/` is emptied when a feature
   closes. The README entry was reworded so it does not point at a ticket that
   will be deleted, but the durable record does not exist. Per
   `docs/agents/domain.md` writing one is not this ticket's to do unasked.
