# 04: ADR-0011 stops contradicting the court

**What to build:** the two places where ADR-0011 still describes the two-colour
court corrected, and the one remaining doc that still asserts it in the present
tense.

**Blocked by:** None

**Status:** done

- [x] ADR-0011's consequence **"Strength belongs to the surface, not to the
      mark"** no longer calls the mark's strength "a per-side constant settled by
      eye". There is one surface, so there is one number — `.scratch/rally-mark/spec.md`
      already says so and the ADR still does not
- [x] The same paragraph no longer says `courtSurface`, `courtLine`, `courtInk`
      and `courtWeave` "are all per-side answers in that one file already".
      `courtLine` is deleted and the other three lost their `Side` (ADR-0012).
      The argument it was making — that a theme threaded through those functions
      threads the mark's number with them — survives the correction and should
      not be dropped with it
- [x] ADR-0011's consequence **"The mark and the identity of a half are now made
      of the same material"** no longer says which half is ours "is said today by
      turf green against glass blue". It is said by position and the net
      (ADR-0012)
- [x] That consequence's *conclusion* is re-decided rather than reworded. It
      argued that themes would degrade a hue difference into a value difference,
      and that the mark brightens the surface carrying that identity. With one
      surface the premise is gone — say whether the consequence is now settled,
      or what is left of it
- [x] **How the correction is made is decided and stated**: edited in place, or
      left standing with a superseding note pointing at ADR-0012. ADR-0012
      already records the court with no painted lines, so 0011 needs to stop
      contradicting it, not to re-argue it
- [x] `docs/design/canvas.json`'s board description no longer asserts "Deep glass
      blue for their half, turf green for ours" as present tense. It is the seed
      text the canvas renders, so it is read as a description of what the app is
- [x] `grep -rn "turf green\|glass blue" docs/ Packages "Padel Watch App" Padel`
      turns up nothing stating the two-colour rule as current. Two files keep it
      legitimately and must not be "fixed": `docs/design/RallyMark.html`, where
      the rejected candidates are the point and an annotation already says the
      court no longer ships, and `.scratch/rally-mark/spec.md`, which already
      states it in the past tense

## Notes

**This was found and flagged rather than fixed, deliberately.** `court-surface`
01 recorded it in its closing note: `docs/agents/domain.md` says that output
contradicting an ADR is surfaced explicitly rather than silently overridden, so
the ticket that broke 0011 correctly refused to rewrite it. That leaves the
correction owed, which is this.

**Why it cannot wait for the feature to close.** `.scratch/` is emptied when a
feature closes, and the note recording the conflict is in
`.scratch/court-surface/issues/01-the-one-surface.md`. The ADR would keep the
wrong sentence and lose the only record that anyone noticed.

**What is already correct, so that the fix does not go looking for work.**
`court-surface` 01 corrected `.scratch/rally-mark/spec.md` and
`issues/01-the-mark.md`, and wrote the annotation into `docs/design/RallyMark.html`
saying the night court it fires against is no longer what ships and that
candidate B — the painted lines flaring — is unbuildable rather than merely
rejected. What it left, because an ADR is not a ticket's to rewrite, is ADR-0011
itself.

**The risk in this ticket is over-correction.** ADR-0011 is a record of a
decision made at a time, and most of it is still true: the mark is the surface
brightened, the tint beat four other candidates, an undo is not marked, Always-On
never arises. Only the sentences resting on there being two surfaces are wrong.
An ADR rewritten past its actual error stops being a record.

## Comments

Built as one commit. Nothing left open.

**How the correction was made.** Edited in place, not left standing under a
superseding note, and the `## Consequences` preamble says so: ADR-0012 supersedes
nothing ADR-0011 decided — the tint still wins and still fires where it fired —
only the facts about the court that some of its consequences rested on. A
superseding note would have retired a whole record to correct three sentences.

**What the identity consequence was re-decided to.** Settled, not deferred.
ADR-0012 removed the premise rather than answering it: identity is carried by
position and the net, which no theme reaches, so brightening a half cannot dilute
what says the half is ours. What survives is the strength consequence alone — the
mark is still made of the surface, so a theme still names its strength. The
heading changed with the conclusion, because the old one ("made of the same
material") is now the opposite of the finding.

**Three places in ADR-0011, not two.** The ticket named two. The third is **"The
two tiers are carried by duration"**, which said a tier carried by strength would
make every theme "tune four numbers instead of two". That arithmetic counts
per-side strengths — two surfaces times base and peak. With one surface it is two
against one, so it was wrong for exactly the reason the other two were.

**ADR-0012 was edited too, and the ticket did not ask for it.** Its last
consequence read "ADR-0011's closing warning is sharper than it reads there" and
then repeated the dead premise — "a surface whose color is the only thing saying
whose surface it is" — which contradicts 0012's own body two sections up. It was
already wrong before this ticket; once 0011 declares the warning settled, leaving
it would have put the two ADRs in conflict instead of ending the one this ticket
exists to end. It is named here and in the PR rather than folded in quietly.

**A dangling citation went with it.** ADR-0011 credited `ScoreView` for the
argument that a label would take room from the digit. That comment went with
`court-surface` 01; the argument now lives in ADR-0012 and in
`docs/design/README.md`. The corrected sentence cites neither symbol.

**For the owner: the board this ticket edited is now owed deletion.**
`phone-scoring` 04 merged as #2 while this was in flight, so the phone score
screen has shipped — and `CLAUDE.md` says a board is deleted once its screen
ships, with `docs/design/README.md` already calling this the one board left,
"waiting on `phone-scoring`". Criterion 6 asked for the brief corrected, so it
was corrected; deleting `canvas.json`, `PhoneScore.dc.html` and the README's
paragraph about them is a larger call and is not this ticket's. It needs a ticket
under `phone-scoring` if the feature is done, and the brief is right meanwhile.
