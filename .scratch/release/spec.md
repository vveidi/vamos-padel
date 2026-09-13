# Release: the build leaves the machine (v1)

Status: ready-for-agent

## Problem Statement

The app has never left this Mac. There is no remote, no CI, no App Store
Connect record that anything has been uploaded to, and no way to put a build on
a wrist that is not plugged in over here. Every screen of the redesign has been
checked in a simulator, which is the last place a padel match is ever played.

What is missing is not a decision about how to ship — it is the twenty minutes
of signing, archiving and uploading that nobody wants to do by hand twice.
fastlane is the thing that does it twice.

## What is in, and what is not

**In: TestFlight.** An archive that signs, an upload that lands, and a build
number that does not have to be remembered.

**Not in: the App Store.** No `fastlane/metadata/` tree, no screenshots for two
device families, no description in two languages, no privacy questionnaire, no
age rating, and no release notes. "What's New in This Version" does not exist
for a 1.0 — App Store Connect only shows it on updates — so writing one now
would be writing into a field Apple will not display. When there is a 1.1 there
will be a ticket.

**Not in: CI.** `git remote -v` is empty. There is nothing to push to and
nothing to run on, and a pipeline built for a runner that does not exist is a
pipeline nobody has ever seen work.

## One archive, not two

The watch app is embedded in the phone app —
`INFOPLIST_KEY_WKCompanionAppBundleIdentifier = com.vveidi.padel`, plus an
Embed Watch Content phase on the iOS target. So this is one archive, one
upload, and one App Store Connect record, and the watch comes along inside it.

## Solution

Three lanes in `fastlane/Fastfile`:

| Lane | What it does |
| --- | --- |
| `test` | the four `swift test` packages, then `PadelTests` on an iOS simulator |
| `build` | Release archive → a signed `.ipa`, and stops |
| `beta` | `test`, then `build`, then upload to TestFlight for internal testers |

`build` exists so that the half that actually goes wrong — signing, the
embedded watch app, the export — can be run without an upload behind it. When
`beta` fails you already know which half failed.

## Implementation Decisions

### The word `deliver` is taken

fastlane's App Store upload action is called `deliver`, and `CONTEXT.md`
already defines **Match delivery** as *the journey of a finished match from the
watch to the phone*. There is a whole package named `PadelDelivery` on that
meaning. A lane called `deliver` in this repo would mean the opposite of what
the directory next to it means, so the upload lane is `beta` and the word does
not appear.

### An App Store Connect API key, not an Apple ID

An Apple ID needs a `FASTLANE_SESSION` that expires about monthly and
re-prompts for two-factor every time. The API key does not expire, and it is
the only one of the two that would survive a move to CI. The `.p8` lives at
`~/.appstoreconnect/private_keys/` — where Apple's own tools look — and never
comes near the repo. The key id and the issuer id are not secrets on their own
and sit in a gitignored `fastlane/.env.default`, which fastlane loads by
itself, so no lane depends on remembering to export anything.

### Automatic signing, and no `match`

`match` keeps certificates and profiles in a private git repo. There is no
remote here to hold one. Automatic signing with `-allowProvisioningUpdates` and
an API key is what one machine with one developer actually needs, and ADR-0007
records it so that the day there is a second machine the decision is found
rather than rediscovered.

### The build number comes from TestFlight, not from the repo

`latest_testflight_build_number + 1`. Nothing is written back: `agvtool` would
need `VERSIONING_SYSTEM = apple-generic` added and would commit
`project.pbxproj` on every upload, and `CURRENT_PROJECT_VERSION` is written
six times in that file between the targets. Asking App Store Connect what it
already has is the one source that cannot drift from what is actually up there.

`MARKETING_VERSION` stays something set by hand, when a human decides the
version changed.

### brew's fastlane, no `Gemfile`

fastlane is installed through Homebrew and stays that way. The cost is that an
unrelated `brew upgrade` can move the release tooling, so the Fastfile sticks
to long-stable actions and pins nothing clever.

### "What to Test" is the last commit's subject

`beta` refuses to run on a dirty tree, so the commit *is* the build. The
subject lines in this repo are already sentences — "Read the match down the
page instead of across a table" is a better note than anything that would be
typed twice. `fastlane beta notes:"…"` overrides it. English only: it is a note
to the only person who will read it, and ADR-0005's two languages are about
what a player reads.

## The blocker this feature did not own, and no longer has

**Both `AppIcon.appiconset`s used to be empty**, and App Store Connect rejects
a build with no icon during processing. The redesign drew the icon and both
catalogs now carry it, so ticket 03 waits on nothing outside this feature.

What it does wait on is `phone-scoring`: that feature moves the match onto the
phone and removes delivery, which is what ticket 03's last criterion is written
against.

## The tickets

```
01  the three lanes, and the key they sign with
02  what App Store Connect asks for before it will take a build
03  the first upload                        (and on phone-scoring landing)
```
