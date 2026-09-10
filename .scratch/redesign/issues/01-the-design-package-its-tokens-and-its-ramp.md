# 01: The design package, its tokens and its type ramp

**What to build:** A fourth local package, `Packages/PadelDesign`, holding the
colors, the radii and the type ramp the whole redesign is drawn from. No
screen changes in this ticket — it is the floor the other ten stand on.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `Packages/PadelDesign` exists, `swift-tools-version: 6.0`, platforms
      `.iOS(.v18)`, `.watchOS(.v11)`, `.macOS(.v14)` — macOS for the same
      reason `PadelScoring` carries it, so the package builds and tests without
      a simulator
- [ ] It depends on `PadelScoring` and on nothing else
- [ ] Registered in `padel.xcodeproj` as an `XCLocalSwiftPackageReference` and
      linked into **both** app targets, the way the three existing packages are
- [ ] Every color from the boards is a named token, and no screen in the repo
      is left holding a literal color after tickets 04–09
- [ ] The type ramp exists with seven entries, each built with `relativeTo:`
      so Dynamic Type scales it
- [ ] Radii are named for what they wrap, not for their size, and resolve per
      platform
- [ ] Previews in the package show the palette and the ramp on both platforms
- [ ] `swift test` passes in the package (even if it only has a smoke test —
      the target has to build under SwiftPM, which is what gives the LSP an
      index for it)

## The palette

Read off `canvas-court/`. Hex where the board gives hex, alpha-over-ink where
it gives `rgba(238, 247, 245, α)` — that is the same ink at a different weight,
and it should be one token with an opacity, not eight tokens.

| Token | Value | Where |
| --- | --- | --- |
| `night` | `#04181f` | the app's ground, outside the court |
| `theirHalf` | `#0e3d4c` | glass blue, the top half |
| `ourHalf` | `#12564f` | turf green, the bottom half |
| `ball` | `#ddf35c` | the one accent |
| `onBall` | `#16260a` | a label on ball yellow |
| `ink` | `#eef7f5` | text and lines on `night` |
| `inkTheirHalf` | `#dcefe9` | text inside their half |
| `inkOurHalf` | `#f4fffb` | text inside our half |

Weights of `ink`, as named opacities rather than numbers at call sites:
`.primary` 1.0, `.secondary` 0.55, `.tertiary` 0.4, `.hairline` 0.12,
`.surface` 0.12, `.surfaceQuiet` 0.08.

Court lines are their own, and they differ per half — `rgba(180, 235, 222, …)`
in theirs, `rgba(190, 245, 228, …)` in ours, at 0.34/0.28/0.20 and
0.36/0.30/0.22 for the service line, the center line and the outline. They
belong to the court primitive (ticket 02), so define them here and let 02 use
them; do not scatter them.

Two gradients, both tokens rather than shapes:

- **Floodlight** — `radial-gradient` of `rgba(255, 248, 214, 0.12…0.17)` to
  clear, from one corner. Warm white, and it is *light*, not a hue: it must
  never read as a second accent.
- **Night scrim** — `night` from clear to 0.82 to 0.95, the fade the floating
  controls sit on so the court can run under them.

## The ramp

Seven entries. The sizes below are the starting point, not the specification —
see the spec's "Reading the boards": the watch boards' type is drawn at phone
scale and cannot be halved with the layout.

| Entry | Watch | Phone | Face today | Face later (ticket 11) |
| --- | --- | --- | --- | --- |
| `.score` | 46 | 128 | SF Rounded semibold | Unbounded 600 |
| `.scoreAside` | 14 | 38 | SF Rounded medium | Unbounded 500 |
| `.display` | 17 | 31 | SF Rounded semibold | Unbounded 600 |
| `.tileScore` | — | 25 | SF Rounded semibold | Unbounded 600 |
| `.control` | 15 | 16 | SF semibold | Golos 600 |
| `.body` | 14 | 15 | SF regular | Golos 400 |
| `.caption` | 13 | 13 | SF regular | Golos 400 |

Every entry is `Font.system(size:weight:design:)` **anchored with
`relativeTo:`** — `.score` relative to `.largeTitle`, `.body` relative to
`.body`, and so on — so the sizes above are what the ramp gives at the default
Dynamic Type setting and not a freeze.

`.score` and `.scoreAside` are one pair on purpose: the games digit beside the
points shares a baseline with it (`ScoreView` already does this) and the two
have to move together when type scales.

## Why the ramp before the fonts

Ticket 11 decides whether Unbounded and Golos Text ship. Whatever it decides,
it should be able to change **one file** — the ramp's mapping — and no screen.
That is only true if the screens never name a face. Hence: after tickets 04–09,
`grep -rn "\.system(size:" padel "padel Watch App"` returns nothing, and
`ScoreView`'s `size: 64` and `MatchCard`'s `size: 44` are gone.

## Notes

**On the package name.** `PadelDesign`, not `PadelCourt`. The court is what it
draws; the design system is what it is, and next to `PadelScoring` and
`PadelStorage` a `PadelCourt` would read as a domain package about courts.

**On depending on `PadelScoring`.** For `Side`, and for nothing else — see the
spec. The dependency runs one way and must stay that way: nothing in
`PadelScoring`, `PadelStorage` or `PadelDelivery` may ever import
`PadelDesign`.

**On tests.** There is not much here to assert — a color is a color. The test
target exists so the package builds under `swift test` and carries an index,
which per `CLAUDE.md` is what makes `hover` and `goToDefinition` work inside
it. A smoke test that the ramp returns distinct fonts is enough.
