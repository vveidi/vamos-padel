# 01: The design package, its tokens and its type ramp

**What to build:** A fourth local package, `Packages/PadelDesign`, holding the
colors, the radii and the type ramp the whole redesign is drawn from. No
screen changes in this ticket — it is the floor the other ten stand on.

**Blocked by:** None

**Status:** done

- [x] `Packages/PadelDesign` exists, `swift-tools-version: 6.0`, platforms
      `.iOS(.v18)`, `.watchOS(.v11)`, `.macOS(.v14)` — macOS for the same
      reason `PadelScoring` carries it, so the package builds and tests without
      a simulator
- [x] It depends on `PadelScoring` and on nothing else
- [x] Registered in `padel.xcodeproj` as an `XCLocalSwiftPackageReference` and
      linked into **both** app targets, the way the three existing packages are
- [x] Every color from the boards is a named token, and no screen in the repo
      is left holding a literal color after tickets 04–09
- [x] The type ramp exists with seven entries, each built with `relativeTo:`
      so Dynamic Type scales it
- [x] Radii are named for what they wrap, not for their size, and resolve per
      platform
- [x] Previews in the package show the palette and the ramp on both platforms
- [x] `swift test` passes in the package (even if it only has a smoke test —
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

## Comments

### Closing note

`Packages/PadelDesign` is in, registered, linked into both app targets, and
holds nothing but values: six source files, no view. Ticket 02 draws the first
shape.

    Sources/PadelDesign/
      Palette.swift      every color the boards spend, and the ink's weights
      CourtColors.swift  surface, ink, lines and weave, each per `Side`
      Lighting.swift     floodlight, night scrim, ball glow — as `Gradient`s
      Radii.swift        four radii on `CGFloat`, resolved per platform
      Typography.swift   `TypeRamp` and `.textStyle(_:)`
      Platform.swift     the one `#if os(watchOS)` the radii and the ramp share
      Previews.swift     three boards: the palette, the ramp, the radii

**How each criterion was verified.**

- *The package, the manifest, the platforms* — `swift-tools-version: 6.0`,
  `.iOS(.v18) .watchOS(.v11) .macOS(.v14)`, worded like its three neighbors.
- *Depends on `PadelScoring` and nothing else* — checked structurally, not by
  eye: `PackageIsolationTests` reads `Package.swift` and fails on a second
  `.package(`, and walks the sources against an allowlist of `SwiftUI`,
  `PadelScoring` and `CoreGraphics`. Lifted from `PadelScoring`'s suite of the
  same name, allowlist and argument included. The other direction needs no
  test: `PadelStorage` and `PadelDelivery` cannot import what their manifests
  do not declare.
- *Registered and linked into both targets* — `xcodebuild -list` now names a
  `PadelDesign` scheme, and after building both apps the derived data holds
  `PadelDesign.o` under **both** `Debug-watchsimulator` and
  `Debug-iphonesimulator`. Both targets build clean.
- *Every color from the boards is a named token* — the table's eight, plus the
  eleven the table did not list but the boards spend (below). Read strictly:
  the net's tape and post, the ball's seam, the shadow under both, and the two
  whites the court's lines are painted in are all board colors, and leaving
  them out would have meant 02 and 03 writing the literals this criterion
  exists to prevent. The second half of the criterion — "no screen is left
  holding a literal color" — is scoped by its own wording to *after* tickets
  04–09; nothing here touched a screen, so `MatchCard`'s `ourSideColor` and
  `ScoreView`'s `ourColor` are still there, and 04–09 remove them.
- *Seven ramp entries, each anchored* — `TypeRampTests`: seven cases, seven
  distinct `Font`s, `.score` the largest, `.score`/`.scoreAside` sharing both a
  design **and an anchor**. That an entry *has* an anchor is not asserted, and
  deliberately so — see "the anchor cannot be tested" below.
- *Radii named for what they wrap, per platform* — `.card .tile .button
  .segment`, watch values half the 2x boards', phone values as drawn.
- *Previews on both platforms* — three boards, four previews, verified by
  opening them, which is the only way a preview is ever verified. Both
  platforms come from the same four, since the sizes and the radii resolve per
  platform.
- *`swift test` passes* — 19 tests in 4 suites, clean. SwiftLint is clean on
  the package too, which took registering it in `.swiftlint.yml` — that file
  lints an explicit allowlist, and until the package was added to it the whole
  of `PadelDesign` was silently unlinted. It found two violations once it could
  see the code, both in `Previews.swift`, both fixed.

**Departures from the ticket as written.**

**The ramp is applied as `.textStyle(.score)`, not as a `Font`.** The ticket
asks for `Font.system(size:weight:design:)` "anchored with `relativeTo:`".
Those two do not compose: `Font.system(size:weight:design:)` takes no text
style, and the only `Font` factory that does is
`Font.custom(_:size:relativeTo:)`, which needs a face to name — which is
exactly what ticket 11 has not decided yet. So the anchor is applied where
SwiftUI actually offers it, `ScaledMetric(wrappedValue:relativeTo:)`, inside a
`ViewModifier`. `TypeRamp` still carries `size`, `weight`, `design` and
`relativeTo` as values, so ticket 11 changes this one file and no screen —
which was the point of building the ramp first.

It is `.textStyle(_:)` rather than an overload of `.font(_:)` because `Font`
already has a `body` and a `caption`: `.font(.body)` would have become
ambiguous at every call site in the app.

**`.tileScore` has a watch size.** The ticket's table gives it "—". A ramp with
a hole in it is a ramp that crashes or falls back silently, so it resolves to
15pt on the watch, sized between `.display` and `.control` the way the phone's
25 sits between its 31 and 16. No watch screen uses it today.

**Eleven tokens the palette table did not list.** All are on the boards, and
every one of them is named by ticket 02 or 03 in prose — so leaving them out
would have put the literal in the consuming ticket, which is precisely what
"do not scatter them" forbids:

| Token | Value | Where |
| --- | --- | --- |
| `ballWash` | `ball` at 0.14 | the fill behind a chosen segment or half |
| `knob` | `#0b2b26` | the knob of a `ball`-tinted `Toggle` (03 names it) |
| `ballSeam` | `#142812` at 0.4 | the ball's two seam arcs (02: "dark green at ~0.4") |
| `netTape` | `ink` at 0.82 | the net's tape (02: "tape, ink at 0.82") |
| `netPost` | `ink` at 0.9 | the post at each end (02: "post, ink at 0.9") |
| `shadow` | black at 0.5 | what lifts the net and the ball off the court |
| `lineTheirHalf` | `#b4ebde` | the paint their half's lines are drawn in |
| `lineOurHalf` | `#bef5e4` | the paint ours are drawn in |
| `floodlight` | `#fff8d6` | the warm white the floodlight gradient is made of |
| `courtWeave(on:)` | white at 0.028 / 0.032 | the court's diagonal texture |
| `InkWeight.strong` | 0.65 | the label of an unselected segment (03 names it) |

Two more weights joined the ticket's six for the net alone — `.tape` 0.82 and
`.post` 0.9 — so that `netTape` and `netPost` are the ink at a weight rather
than two more colors. The boards' 0.10 divider is **not** a ninth weight: it
reads as `.hairline` at 0.12, on the ticket's own argument that two hundredths
apart is one weight drawn twice.

`lineTheirHalf` and `lineOurHalf` were originally inline hexes inside
`courtLine(_:on:)` — named and moved into `Palette.swift` so that the file
which claims to hold every color actually does.

A third gradient joined the ticket's two: `Gradient.ballGlow`, the `ball`-at-
0.16 radial the history board draws in the corner of a won tile. Same argument
— it is on the boards, ticket 03 needs it, and defining it there would be
scattering it.

**What a screen may reach and what it may not.** The tokens only this package's
own primitives use — the net's two, the seam, the shadow, the two line
paints — are `internal`, not `public`. A screen has no business drawing a net,
and ticket 02, which does, lives in this package. The `ShapeStyle` mirror
covers the public tokens only, which is why `Previews.swift` reaches the
internal ones as `Color.netTape` rather than `.netTape`.

**The mirror is complete.** `courtSurface`, `courtInk`, `courtLine` and
`courtWeave` were public on `Color` but missing from the `ShapeStyle`
extension, so ticket 02's `.fill(.courtSurface(side))` would not have compiled
while `.fill(.ball)` did. Both spellings now exist for every public token.

**`.court` is gone.** There was a fifth radius, 26pt, for the court framed as a
panel. That frame is only on `PhoneNewMatch`, which `spec.md` puts out of scope
— *"reference for the visual language and nothing more"* — so it was a radius
for a screen this feature is not building. Four remain.

**`Gradient.floodlightStrengths` is gone** for the same reason in miniature: a
public `0.12...0.17` that its own doc comment admitted enforced nothing, and
that nothing read.

**`TypeRamp.font` is now `internal`.** It was public "for a preview or a
`Canvas`", and it is the ramp with the anchor stripped off: `.font(entry.font)`
compiles, looks right and silently never scales — a public door straight past
the thing the ramp exists for. The tests still need a value to compare entries
by, so it survives inside the package.

**The scaling test that could not be written.** The obvious way to prove the
ramp answers Dynamic Type is to render an entry at `.xSmall` and again at
`.accessibility5`. It was written, it failed on all seven entries, and the
reason is not the ramp: `swift test` runs on macOS, and macOS has no Dynamic
Type. Measured rather than assumed — on the Mac, SwiftUI's own `.font(.body)`
renders to the same height at both settings, and so does a bare `@ScaledMetric`
in a plain `View`. Running the package's tests on an iOS simulator instead
would need a checked-in scheme with a test action, which the package does not
have and which is not this ticket's to add.

**And the anchor cannot be tested either — the first attempt only looked like
it could.** What stood in the scaling test's place was
`everyEntryIsAnchored`, asserting
`Font.TextStyle.allCases.contains(entry.relativeTo)`. That assertion cannot
fail: `relativeTo` is a non-optional `Font.TextStyle`, so every possible value
satisfies it. It was cited twice — here and in `RenderingTests` — as the
structural half of the Dynamic Type story, and it verified nothing. Deleted,
and both citations rewritten to say plainly that the anchor is a type-level
guarantee rather than a tested one.

Chasing that turned up a real defect the review had not asked about.
`.scoreAside` was anchored to `.title2` while `.score` was anchored to
`.largeTitle` — and two text styles do not scale by the same factor, so at the
far end of the Dynamic Type range the games digit would have drifted off the
score's baseline. The ticket is explicit that the two "have to move together
when type scales". `.scoreAside` is now anchored to `.largeTitle` alongside
`.score`, and `theScoreAndItsAsideStayAPair` asserts the shared anchor — a
test with a mechanism behind it, replacing one without.

What is left as evidence: `#Preview("The ramp, largest type")` beside the
default one, so the difference is one glance on a real canvas.
`RenderingTests` records all of this where the next person will look for it.

**On `Color(hex:)` being internal.** A screen that can build a color from a hex
is a screen that can invent one, and this package is the argument that it
should not. The tests reach it through `@testable import`.

**On the one test that draws.** There was briefly a test that rendered the
three preview boards and asserted each produced a bitmap taller than zero. It
was dropped: it would have passed on an all-black image with every swatch
wrong, a broken preview is found by the person opening it a second later, and
it had cost the three boards their `private` — test scaffolding setting the
module's visibility is the tail wagging the dog.

What replaced it tests product code instead. `.textStyle(_:)` is the only
machinery in the package — a `ViewModifier` carrying a `DynamicProperty` — and
every screen in 04–09 will call it. `RenderingTests` renders `"40"` through all
seven entries and asserts the entry reaches the glyphs: heights rise with the
ramp, and `.score` renders taller than `.caption`. Checked by mutation rather
than assumed — with the modifier's body reduced to `content`, all seven render
at 16px and the test fails.

**One review finding left standing on purpose.** `RadiiBoard` was called scope
creep against criterion 7, which asks for previews of "the palette and the
ramp". Kept: the criterion reads as a floor rather than a ceiling, the radii
are one of the three things this ticket ships, and they resolve per platform —
which is exactly the kind of value that is wrong in a way nobody notices until
it is drawn. Deleting a working preview to satisfy a strict reading would have
made the package worse.

One breach was also left where it was found: `PadelDelivery/Package.swift`
says "neighbouring". It predates this ticket and is not in this diff.
