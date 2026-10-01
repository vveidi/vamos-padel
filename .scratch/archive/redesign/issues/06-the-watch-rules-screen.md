# 06: The watch rules screen

**What to build:** `RulesetView` loses its `List` and its `Picker`s: a
`ChoiceRow` for the ruleset, a `ChoiceRow` for each number, a toggle for the
golden point, and a sentence at the bottom saying what the match will be.

**Blocked by:** 03

**Status:** done

- [x] The screen is dark, full-bleed, with a floodlight from the top left — no
      `List`
- [x] `.toolbar(.hidden, for: .navigationBar)`; "Rules" is drawn as content at
      the top left, clear of the clock
- [x] A `ChoiceRow` chooses between Classic and To N points — **not** a
      `SegmentedChoice`, which is unavailable on watchOS
- [x] The numbers are `ChoiceRow`s over their ranges, and **the crown scrolls
      the page each one opens**, which is where 5...40 is crossed
- [x] The golden point is a `Toggle` tinted `ball`, knob `#0b2b26`
- [x] The bottom sentence describes the chosen ruleset in words
- [x] The choice still leaves the screen on change, not on a "Done" button
- [x] `Numbers` — which remembers the other ruleset's values — is untouched
- [x] The bounds stay where they are: `1...3`, `1...6`, `5...40`
- [x] Previews in both languages, both rulesets, at the largest type

## The crown

Today every number is a `Picker` and the crown spins it; `target` is
**5...40**, and a ± button alone would make crossing that range 35 taps. The
crown keeps that range, but it now scrolls the page a `ChoiceRow` opens rather
than spinning a value in place. Nothing has to be focused first.

Verify on a device, or at least in the simulator with the crown: open "Points
(N)", check the page arrives already scrolled to the current value rather than
at 5, turn the crown across the list, tap one, and check it comes straight back
without a "Done".

**This replaces the design ticket 03 shipped**, where the stepper bound the
crown to a focused row. The boards draw a segmented control and ± on the watch
and both were judged wrong for a 198pt screen; see the spec's "The watch picks
on a page; the phone picks in place".

## The sentence at the bottom

New, and taken from the references: `Padel Score Tracker` says the rule
settings back as one sentence about the match rather than leaving four numbers
to be assembled by the reader. The board draws it as
*"Best of 3 sets. A set is 6 games, a tiebreak at 6–6. Deuce is one point."*

It is **generated from the ruleset**, not four hardcoded strings — the numbers
in it move with the steppers. Two rulesets, and the golden point changes the
last clause ("Deuce is one point" against "Deuce is played out"). That is four
sentences in the catalog at minimum; work out the smallest set that stays
grammatical in Russian, where the count governs the noun. The catalog declines
nouns for us already (`StartView`'s `parameters(of:)` note) — use the same
mechanism rather than assembling words.

This is the one part of this ticket that is new copy rather than a restyle. If
it turns into its own argument, split it out: the screen is shippable without
it, and a half-translated sentence is worse than none.

## What must not change

**Leaving on change.** The comment is explicit: nothing on this screen needs
confirming, and an extra tap is exactly what hiding the screen behind a push
was for. `.onChange(of: numbers.ruleset, initial: false)` stays.

**`Numbers`.** It holds both rulesets' values so that glancing at the
neighbouring ruleset and coming back does not cost the sets already dialled in,
and it fills the unoccupied half from `Ruleset`'s own defaults rather than from
numbers written out again. Restyle the controls above it; leave it alone.

**The bounds and their reasons.** `1...3` because five played sets is
professional padel and the score screen sizes one digit; `5...40` because a
match shorter than five points ends before the serve changes hands; `1...6`
because groups play 2 or 4 and 1 makes sense. All three comments stay.

## Notes

**On the label column.** `RulesetView`'s previews record that "Serve after (X)"
against "Подача через (X)" is the widest pair in the app, and the stepper row
gives the label less room than a `List` row did — the ± buttons and the value
take a fixed width out of 198pt. Check Russian at the largest type first, not
last; this is where the screen breaks if it breaks.

## Comments

### Closing note

The screen is `night` with the rules board's own light on it, a "Rules" title
at the top left where the bar used to be, one `SettingsCard`, and the sentence
under it. The card holds the ruleset's row first and then the two rows that
ruleset owns: what the choice switches is the rows beneath it, and a row that
changes its neighbours belongs among them rather than floating above the card.
`Numbers`, the three ranges and their three comments are untouched, and the
choice still leaves on `.onChange` rather than on a "Done".

**The label column never ran out of width**, because the value is not beside
the label any more — `ChoiceRow` stands it underneath, and each of the two gets
the row's full width. At `.accessibility5` in Russian "Очков до победы" holds
one line and "Смена подачи через" takes two; nothing is clipped and nothing is
scaled down. The ticket's warning was written for the stepper row, which is now
the phone's.

### The sentence, and what it cost the catalog

Three new keys, not four, and two borrowed:

- **`First to %lld sets. A set is 6 games, a tiebreak at 6:6.`** — one key with
  the whole classic clause inside it, so that Russian can decline *сет* and
  English can restate the line rather than count it. One set is a different
  sentence in both languages ("A single set of 6 games…", "Один сет: 6
  геймов…"), which is what the `one` category is for. Six games and the
  tiebreak sit inside this clause because they are `ClassicReplay`'s numbers
  and not the player's.
- **`Deuce is one point.` / `Deuce is played out to a two-point lead.`** — the
  clause the switch turns over.
- **The match to N points borrows the phone's two clauses** — `Scoring to %lld
  points` and `Serve changes every %lld rallies`, joined with a full stop. They
  are already pinned across both their ranges, and here they say exactly what
  they say on the phone. `MatchWording`'s rule is about the two targets sharing
  a key where they say *different* things; this is the case that comment calls
  the one where a single key is right, so the sentence for that ruleset needed
  no new words at all.

The board's "Best of 3 sets" was not taken. The app counts sets *to win*
everywhere else — "Classic scoring · 2 sets" on the phone, "2 sets" under the
ruleset's name on the watch — and a sentence that alone counted sets played
would be the one line in the app doing arithmetic on the number above it.

New forms are pinned like every other: `First to N sets` walks 1…3 in both
languages in `PluralFormsTests`, and the two deuce clauses are written out in
`SharedCatalogTests`.

### The knob needed a control after all

The criterion names `#0b2b26`, and `.tint(.ball)` does not reach the knob —
which is what ticket 05 found and wrote down as ticket 03's business. So
`PadelDesign` gained **`BallSwitch`**, a `ToggleStyle`: the binding, the label
and the tap stay SwiftUI's, and the drawing is the boards' — `ball` track, deep
teal knob, the board's 52×31 halved. It is a style and not a control so that
VoiceOver keeps the system's switch whole, through
`.accessibilityRepresentation`; the simulator's runtime snapshot reports the
golden point as `switch|Golden point|1` and flips it to `0` on a tap.

Two things came with it, deliberately:

- **The Health row on the settings page wears it too.** Two switches one scroll
  apart, one of them the system's white knob and the other the boards', is a
  seam that reads as a bug. `ControlPreviews`' board takes it as well.
- **The row's own height moved into the style.** `ControlMetrics` is the
  package's and not a screen's, and both apps were asking for
  `stackedRowHeight` by hand so a switch would stand as tall as the rows beside
  it. The style asks for it now, and `StartPages`' `.frame(minHeight:)` went.

### How each criterion was checked

`swift test` green in `PadelDesign` (the new "The ball switch" suite included),
`PadelTests` green on the iPhone 17 Pro — 13 cases, the two new ones among
them. `swiftformat --lint` and `swiftlint` clean on everything touched; the
switch's tests are their own file because the suite took `ControlsTests` past
400 lines.

Run on the 46mm Series 11 in both languages, reached the way a player reaches
it — court page, scroll down, tap the rules row:

- No bar, "Rules" at the top left, the clock clear of it.
- Classic → By points switched the two rows under it and the sentence with
  them; coming back to Classic still had the sets that were dialled in.
- "Очков до победы" opened **centred on 16**, not at 5, and 21 was one short
  scroll away. Tapping it came straight back — no "Done" — and the sentence
  read "Счёт до 21 очка. Смена подачи через 4 розыгрыша.", which is the
  genitive the catalog is pinned on.
- Both deuce clauses, both languages, off the switch.
- The largest of the twelve Dynamic Type settings, pinned temporarily in the
  app because the watch simulator has no `content_size`: both rulesets hold in
  Russian.

**Not verified: the edge-swipe back, and the crown itself.** The rules screen's
only way back is now the stack's gesture, and the simulator's synthetic swipes
arrive as taps — the proof that it is the tool and not the screen is that the
same gesture does nothing on the pushed choice page either, which carries a
visible Back button. The crown scrolling those pages is watchOS scrolling a
`ScrollView`; that the page *opens* on the chosen value was checked, the turn
itself wants a wrist.

### The screen was a trap, and the rules moved onto the page below

The unverified thing above was the broken thing. The owner tried it the same
day: **there is no way off a pushed watchOS screen whose navigation bar is
hidden.** The edge swipe does not answer for the Back button — hide the bar on
a pushed screen and the player is stuck on it. That is not a thing to work
around; it is a thing to stop doing.

So, on the owner's call, **the rules are not a screen any more**. They are a
section of the settings page they used to be pushed from — `RulesetSettings`,
the same card, the same four `ChoiceRow`s, the same sentence, now sitting under
that page's "Settings" title with the Health switch below it. `RulesetView` is
gone, and with it the chevron row that opened it and the two wording helpers
that filled it in (`name(of:)`, `parameters(of:)` — ticket 05's, and there is
nothing left for them to label).

What this does to the criteria ticked above:

- **The second one no longer applies.** There is no rules screen to hide a bar
  on and no "Rules" title to draw; the page keeps its own. Everything the
  criterion was protecting — no bar, no chevron-and-separator, the title clear
  of the clock — is true of the page the rules are on.
- **The rest stand exactly as they were.** The card, the rows, the crown
  scrolling the list each row opens, the switch and its knob, the sentence,
  leaving on change, `Numbers`, the three bounds, and previews in both
  languages at the largest type.

Two things came with the move:

- **The settings page scrolls.** It is a title, a card of four rows, a sentence
  and a switch — taller than every watch. The `TabView`'s vertical paging and
  the page's own `ScrollView` nest without fighting: a swipe (or the crown)
  scrolls to the foot, and a swipe past the top turns back to the court.
- **What is pushed keeps its bar.** The value lists a `ChoiceRow` opens are the
  only pushed screens left in the app, and they draw watchOS's own title and
  Back chevron. `ChoiceRow`'s doc already said why; it is now load-bearing.

Checked on the 46mm in both languages: page down from the court, set every
value, open a list and come back with Back, scroll to the Health switch, and
swipe back up to the court. At `.accessibility5` in Russian the page grows to
about two screens and the switch is still reachable at the foot.

**One string went stale rather than wrong.** `SharedCatalogTests` pinned "Point
scoring" as a sentence only the watch says — it was the name on the row that
pushed the screen. That test now pins "Serve changes every", which is a label
on the page and is still said. The keys the move orphaned — "Rules", "Classic
scoring", "Point scoring", "%lld points" — are left in the catalog with their
Russian: the phone's new-match screen is a ticket away and will want most of
them, and `PluralFormsTests` is the reason the last one is worth keeping
whatever says it.

### The chevron is back, on the rows that open something

The owner's call, and the row's own doc had argued the other way: the value lit
in `ball` was to be the whole affordance, a chevron being the system's
furniture back again. On a wrist that argument turns out to be about the wrong
thing. The lit value says what the row *is*. It does not say the row **opens**,
and a row that pushes a screen has to say so before it is tapped.

So `PadelDesign` gained ``Chevron`` — the glyph the settings card's rules row
used to carry, well and all, now a control of its own — and ``ChoiceRow`` draws
one at its trailing edge. Only those rows: a switch changes in place and wears
none. `ChoiceRow`'s "No chevron" paragraph is rewritten rather than deleted, so
the next reader gets the argument and the reason it lost.

Checked in both languages: at the default setting every label still holds one
line beside the mark, and at `.accessibility5` in Russian "Смена подачи через"
takes its second line and the chevron stays where it is — it is furniture and
does not grow with the type, the same rule the switch follows. A raster test in
`ControlsTests` fails if the mark stops being drawn.

### The two navigation faults, and what they were

The owner's console, on every push:

```
[SaltUICore:NavigationBar] Transition completion could not be called; the
navigation controller is likely in a bad state!
[SaltUICore:NavigationBar] Transitioning bar did not exist during transition,
but top stack item was valid at completion; creating a new model
```

Reproduced on the simulator, then bisected with the log open. The cause is
`.toolbar(.hidden, for: .navigationBar)` on the `NavigationStack`'s root —
ticket 05's line, and this ticket's second criterion. Hide the bar and the
stack has no bar to push *from*: watchOS notices at the end of the transition
and builds a new model to recover. Declaring `.toolbar(.visible)` on the pushed
page does not help — it is the *from* bar that is missing.

**The fix is to stop hiding it.** Neither page has a `navigationTitle`, and
that is all it takes: watchOS reserves nothing for a bar with nothing in it.
The court page and the settings page screenshot pixel-for-pixel identical with
the line and without it — the court still runs to the glass — and the faults go
to zero across four pushes and a pop. The line is gone from `StartPages` with a
comment in its place saying why its absence is deliberate.

That is very likely the same bad state the missing way back was made of, which
would make one modifier the cause of all three complaints. It is not proof: the
edge swipe still cannot be driven from a Mac, so whether it now returns from a
pushed page is a thing to try on a wrist.
