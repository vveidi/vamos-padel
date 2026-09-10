# 08: The phone history

**What to build:** `HistoryView` and `MatchRow` become tiles cut from the
court. A win keeps the turf green, a loss goes to cold glass, a stopped match
holds a trace of the floodlight — the season readable by colour before a single
number.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] The screen is dark, full-bleed, with a floodlight from the top right —
      no `List`, no separators, no chevrons
- [ ] The title "History" is drawn as content in `.display`, with the match
      count beside it in `.caption`
- [ ] `MatchRow` becomes a `CourtTile`: score in `.tileScore`, ruleset beneath,
      day and duration at the trailing edge
- [ ] The three outcomes take the three tints, and a win carries the yellow
      glow at its top trailing corner
- [ ] Tapping a tile still opens the match card
- [ ] The app pins `.dark` — a phone in light mode gets the same court
- [ ] The three states of `History` — unknown, known, unreadable — are still
      three, and still cannot be shown for one another
- [ ] The empty state and the unreadable state are restyled too, not left as
      system views
- [ ] `MatchWording` is untouched; every string still comes from it
- [ ] Previews in both languages for a full history, an empty one, and an
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
