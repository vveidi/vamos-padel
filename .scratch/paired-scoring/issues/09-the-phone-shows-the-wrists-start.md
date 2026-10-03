# 09: The phone shows a match started on the wrist

**What to build:** when the watch starts a paired match, the phone's scorer
holds it but the phone's screen stays where it was — usually the new match
screen, whose "Start match" is then refused because a match is running. The
phone should put the match it holds on its scoreboard, whatever started it.

**Blocked by:** 05

**Status:** done

- [x] **The scoreboard is up for as long as the scorer holds a match**, whoever
      started it. A paired match started on the watch opens it from any tab, and
      a phone that was in the background shows it when the app is next opened
- [x] The new match screen cannot be reached while a match is held, so it never
      offers a start the scorer will refuse for that reason. The other refusals
      it logs today — Health refused, the watch not answering — are ticket 08's
- [x] **A paired match that is not over has no way back on the board.** It is
      left through "End" and its confirmation only. Once it is over — by the
      rules, or ended on either device — the way back returns and leads to the
      history. A solo match's board is unchanged
- [x] A paired match ended on the watch leaves its outcome on the board, as one
      ended on the phone does
- [x] Previews cover the phone receiving a match it did not start, and the board
      of a paired match running (no way back) and over (the way back)

## Notes

Found while driving ticket 05 on a simulator pair: the watch's start was
accepted, the history later listed the match, and the phone's screen never
moved.

Today `RootView` shows the board from its own `running`, which only the new
match screen sets, and the way back calls `leave()`, which calls `release()`:
in a paired match that would tell the watch there is no match in mid-play.

This makes the phone the watch's mirror image. The watch already takes up the
phone's paired match on its own, and keeps an ended match up until the player
leaves it.

A phone whose app is relaunched mid-match comes back with an empty scorer.
That is ticket 11, not this one.

## Comments

Shipped. `RootView` follows `scorer.updates()` and puts up the board for
whatever match the scorer holds, so a watch-started match opens it from
either tab and from the background. A paired board shows no way back
until the match is over; "End" on a paired match keeps the outcome up.
A solo board is unchanged. `MatchScorer.release` now takes the match id
and lets go of nothing else, so a late tap on an old board cannot drop a
match the watch has just started. Driven on a paired simulator in both
languages and at the largest type. Open for the owner: End and Undo
stay on the board of a match that is over, as they do for a solo one.
