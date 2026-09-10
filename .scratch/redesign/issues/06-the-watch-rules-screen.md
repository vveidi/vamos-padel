# 06: The watch rules screen

**What to build:** `RulesetView` loses its `List` and its `Picker`s: a
`ChoiceRow` for the ruleset, a `ChoiceRow` for each number, a toggle for the
golden point, and a sentence at the bottom saying what the match will be.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] The screen is dark, full-bleed, with a floodlight from the top left — no
      `List`
- [ ] `.toolbar(.hidden, for: .navigationBar)`; "Rules" is drawn as content at
      the top left, clear of the clock
- [ ] A `ChoiceRow` chooses between Classic and To N points — **not** a
      `SegmentedChoice`, which is unavailable on watchOS
- [ ] The numbers are `ChoiceRow`s over their ranges, and **the crown scrolls
      the page each one opens**, which is where 5...40 is crossed
- [ ] The golden point is a `Toggle` tinted `ball`, knob `#0b2b26`
- [ ] The bottom sentence describes the chosen ruleset in words
- [ ] The choice still leaves the screen on change, not on a "Done" button
- [ ] `Numbers` — which remembers the other ruleset's values — is untouched
- [ ] The bounds stay where they are: `1...3`, `1...6`, `5...40`
- [ ] Previews in both languages, both rulesets, at the largest type

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
