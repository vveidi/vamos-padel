# 05: Undoing the last point

**What to build:** The player can undo a point awarded by mistake. Mis-taps are inevitable: the zones are large, the hand is wet, and the Double Tap gesture fires on an unrelated movement. Without an undo the only way out is to abandon the match.

An undo removes the last **rally** from the **journal**; the points, games, sets and **serving side** come back to exactly the state they were in. Several rallies in a row can be undone.

**Blocked by:** 04

**Status:** done

- [x] There is an undo gesture for the last point on the score screen
- [x] After an undo the state matches the state before the undone rally, serve included
- [x] Undo works across the boundary of a game, a set and a tiebreak
- [x] An undo after the match is over returns the match to an unfinished state
- [x] Several undos in a row walk the journal back step by step
- [x] An undo on an empty journal breaks nothing
- [x] The tests cover undo across the boundary of a game and a set, and undoing the end of the match

## Comments

Done. Six criteria are closed by tests, the seventh — the gesture — was checked by hand:
the agent had no way to fire it, see below.

Checking the criteria:

- **The state after an undo matches the state before the rally**: the main test runs a match
  of two sets through and, on every rally, compares the state before the record with the state
  after the undo — in full, serve and outcome included. The journal deliberately passes
  through deuce, a tiebreak and a set boundary, and the test checks that it did: otherwise the
  fixture would one day stop reaching the boundaries while the test stayed green and kept
  promising that it does. The first version of the fixture did not in fact reach the tiebreak.
- **The boundaries of a game, a set and a tiebreak**: three separate tests, each looking at
  the state on both sides of the boundary.
- **Undoing a finished match**: it returns `.inProgress`, and the match accepts rallies
  again — before the undo, `record` was not writing them.
- **Several undos in a row**: the test records twelve rallies, remembering the state before
  each, and rolls all of them back, checking every step.
- **An empty journal**: three undos in a row on a new match do not change it at all.
- **The tests**: 68 in the package, nine of them about undo.

Decisions taken along the way:

- **Undo does not check whether the match is over**, unlike `record`. It exists for exactly
  that: to bring back into play a match finished by a mistaken tap.
- **The gesture is on the outcome screen too.** The criterion says "on the score screen", but
  after the last rally the score screen gives way to the outcome, and the criterion about
  undoing a finished match would have been unreachable from the app. The gesture is the same
  on both screens.
- **The zones stopped being `Button`s.** A button fires on release, so a long press would have
  awarded a point on top of the undo. The zone now rests on `onTapGesture` plus
  `onLongPressGesture`, and everything the button gave VoiceOver (role, label, value, action)
  is put back by hand — plus a separate "Отменить последний розыгрыш" action.
- **The gesture chosen is a long press, half a second.** The spec (the "Score screen" section)
  leaves the exact gesture to the prototype, and rightly so: it has to be chosen with a sweaty
  hand. A long press was taken for how it differs from a mis-tap — a wet palm brushes the
  screen in passing, whereas half a second of holding is intent. **The choice is
  provisional.**

### The gesture was checked by hand

The agent could not fire the gesture: the simulator stopped handing out its window, synthetic
presses were not reaching the app, and there is no access to the Mac's screen — picking
coordinates blind did not work. All the agent checked was what gets drawn: the score screen
looks the same as before after dropping `Button`, and so does the outcome screen.

The rest was checked by the owner on a 46 mm simulator — all four steps passed:

1. A short tap on a half adds exactly one point.
2. Holding for half a second undoes the last point and does **not** add a point for the hold
   itself. That was the main question: `onTapGesture` and `onLongPressGesture` on one zone do
   not conflict.
3. Holding on the outcome screen brings a finished match back into play.
4. Holding on an empty journal does nothing.

The choice of the gesture itself stays provisional: the spec leaves it to the prototype, and
the prototype is about a sweaty hand on court, not about a simulator.

Groundwork for the future: UI tests (XCUITest) are worth setting up. They fire taps and holds
without a window or coordinates, and would close this gap for good — here and in ticket 04,
where taps fell over for the first time. Separate work, part of none of the current tickets.
