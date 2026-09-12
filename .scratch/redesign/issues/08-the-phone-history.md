# 08: The phone history

**What to build:** `HistoryView` and `MatchRow` become tiles cut from the
court. A win keeps the turf green, a loss goes to cold glass, a stopped match
holds a trace of the floodlight — the season readable by colour before a single
number.

**Blocked by:** 02, 03

**Status:** done

- [x] The screen is dark, full-bleed, with a floodlight from the top right —
      no `List`, no separators, no chevrons
- [x] The title "History" is drawn as content in `.display`, with the match
      count beside it in `.caption`
- [x] `MatchRow` becomes a `CourtTile`: score in `.tileScore`, ruleset beneath,
      day and duration at the trailing edge
- [x] The three outcomes take the three tints, and a win carries the yellow
      glow at its top trailing corner
- [x] Tapping a tile still opens the match card
- [x] The app pins `.dark` — a phone in light mode gets the same court
- [x] The three states of `History` — unknown, known, unreadable — are still
      three, and still cannot be shown for one another
- [x] The empty state and the unreadable state are restyled too, not left as
      system views
- [x] `MatchWording` is untouched; every string still comes from it
- [x] Previews in both languages for a full history, an empty one, and an
      unreadable one

## The "New match" button

The board draws a yellow `PillButton` with a ball on it at the bottom. **It is
left out.** It leads to phone-side match creation, which is not in this feature
— see the spec.

That leaves the bottom of the screen empty, and that is correct for now: the
history is the whole of the phone's part in v1 and it has nothing to float over
the tiles. Do not fill the space with something else.

## Scrolling, without a `List`

`List` is what gives the current screen its scrolling, its cell reuse and its
separators. Losing the separators is the point; losing the reuse is not. A
`ScrollView` + `LazyVStack` is the replacement, and it wants checking against a
real history — a season is a few hundred matches, and each tile now draws a
weave gradient and possibly a radial glow.

If it stutters, the fix is inside `CourtTile` (rasterize the weave, drop the
glow while scrolling), not a return to `List`.

## The empty and the unreadable states

Today both are `ContentUnavailableView`, which is a system view with a system
look. They need the court's language instead, and they must stay clearly
different from one another: the comment on `History` is explicit that "there are
no matches yet", "it is not yet known" and "they could not be read" look alike
from a distance and must never be shown for one another.

The empty state keeps its sentence — a match played on your watch shows up here
by itself — and the unreadable state keeps its retry, which is what `attempt`
exists for.

## What must not change

**The rules on the row.** `MatchRow`'s doc comment says why they are there and
not only in the card: "16 : 14" is a strange tennis result and an ordinary match
to 16 points, and only the line beneath says which. The tile keeps them.

**Our side's score first**, in the row and in the card alike.

**The abandoned mark.** An abandoned match is marked explicitly today. Its tint
carries some of that now, but a tint alone is a thing you have to have learned;
keep the mark as well and let the tint reinforce it.

## Notes

**On pinning `.dark`.** In `PadelApp`'s `WindowGroup`, and it is a real
decision rather than a shortcut — ADR-0006 records it. Check the launch screen
and the app icon's background against it too; a white flash into a night court
is the kind of thing only a device shows.

**On the count beside the title.** "28 matches" on the board. It declines in
Russian, so it is a catalog string with a count, not a number glued to a word —
the same mechanism `ScoreView`'s "%lld games" uses. There is a `PluralFormsTests`
suite that exists for exactly this; add to it.

## Comments

### Closing note

`night`, a light in the top trailing corner, a title drawn as content and a
`LazyVStack` of `CourtTile`s under it. The tile is the control from ticket 03
and takes the outcome whole, so the three tints are decided in one place and
this screen never picks a background — it picks the *ink* that background
needs, which is `courtInk(winner)` on a tile that is half a court and the
title's weight on the one that is neither. The same three-way answer the watch's
outcome screen gives.

**The title is not a `navigationTitle`.** A bar would be a shelf of system
furniture across the top of a court holding one word. The stack stays — a tile
still pushes its card, and the card still has its Back button — but the root
names nothing, so iOS draws no bar. The count lives beside the title and is
drawn only for a history that has something in it: "0 matches" over "No matches
yet" says it twice.

**One new key: `%lld matches` / `%lld матч|матча|матчей`.** Pinned across 1–40
in `PluralFormsTests`, which walks past both of Russian's late boundaries — 21
and 31 — because a season is the one number here that nothing caps. From one
rather than zero, since an empty history draws no count at all.

### Two things the boards do not have a setting for

The boards are drawn at one Dynamic Type setting out of twelve, and at the
largest two the tile's columns and the header both stop fitting. Both are
`ViewThatFits` now — measured rather than asked of the environment, because
what decides is whether a date and a ruleset fit on one line, and the same
setting gives a different answer in the two languages. The day drops under the
score inside a tile; the count drops under the title in the header. Without it
the header read "Истор…" over "6 матч…".

The abandoned mark needed the same treatment and did not get it from
`ViewThatFits` alone: "не доигран" wrapped *inside* its capsule and came out a
lozenge. It is `.lineLimit(1).fixedSize()` now, and the fitting decides which
line it stands on rather than how wide it is.

### The white flash was real

The ticket asked for the launch screen to be checked against the pinned dark,
and it did not survive the check. `INFOPLIST_KEY_UILaunchScreen_Generation`
writes `UILaunchScreen = {}`, which means `systemBackground` — and the launch
screen renders before any of our code, so `.preferredColorScheme(.dark)` never
reaches it. On a phone set to light it is **white**, full screen, for the third
of a second the app takes to open. Recorded off the simulator frame by frame,
which is the only way to see it.

There is no build setting for the sub-key, so the target has a real
`Info.plist` now — `padel/Resources/Info.plist`, carrying `UILaunchScreen` and
nothing else, with `GENERATE_INFOPLIST_FILE` still merging everything else on
top of it the way the watch target already does. Its path is written once in
`INFOPLIST_FILE` (both configurations) and once in the target's membership
exceptions, which is the arrangement `CLAUDE.md` warns has to stay in agreement.
`LaunchNight` in the asset catalog is `Color.night` written a second time — one
colour, no appearance variants, so the phone's own setting cannot change it.

The app icon needed nothing: the icon set is still empty.

### What the row lost

The hour the match started at. The row said "9 сент. 2026 г., 13:11 · 22 мин"
and now says the day over the duration, which is what the board draws and what
the ticket asks for. Two matches on one evening are told apart by their scores,
and the hour is on the card.

### How it was checked

Driven on an iPhone 17 in Russian against a store seeded with all six kinds of
match — a win, a defeat, two sets, a match to N points, and both ways a match is
left unfinished. The three tints read apart at a glance, the won tiles carry
their glow, and tapping a tile opens its card with a working Back button. The
runtime UI snapshot shows each tile as **one** button whose label is the whole
match — "у нас 3, у соперников 2, не доигран, Классический счёт · 1 сет, 9 сент.
2026 г., 22 мин" — so the combining survived the restyle.

Relaunched at `UICTContentSizeCategoryAccessibilityXXXL`: the header stacks, the
tiles stack, the mark keeps its own line, nothing truncates. Emptied the store
and looked at the empty state in English. Recorded the launch on a light-mode
phone before and after the `Info.plist`: white, then `night`.

`padelTests` passes, 14 cases. The watch app still builds — the catalog is a
member of both targets.
