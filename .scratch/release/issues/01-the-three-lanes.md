# 01: The three lanes, and the key they sign with

**What to build:** `fastlane/Fastfile` with `test`, `build` and `beta`, an
`Appfile` naming the app and the team, and the App Store Connect API key wired
in without any part of it entering the repo.

**Blocked by:** 02 — discovered, not planned: signing a Release archive needs
an *Apple Distribution* certificate, and the API key is what creates one.

**Status:** ready-for-agent

- [x] `fastlane test` runs the four packages' `swift test` and then
      `PadelTests` on an iOS simulator, and fails the lane when any of them
      fails
- [ ] `fastlane build` produces a signed `.ipa` from the `Padel` scheme and
      uploads nothing
- [ ] `fastlane beta` runs `test`, then `build`, then uploads to TestFlight for
      internal testers only
- [ ] The build number is `latest_testflight_build_number + 1`; nothing in
      `project.pbxproj` is written by any lane
- [ ] The API key is read from `ENV`, the `.p8` is outside the repo, and
      `fastlane/.env.default` is gitignored — `git status` is clean after a
      full `beta` run
- [x] `beta` refuses to run on a dirty working tree, and tags nothing
- [ ] The TestFlight changelog is the last commit's subject line, overridable
      with `fastlane beta notes:"…"`
- [x] No lane, file or comment uses the word `deliver`
- [x] ADR-0007 records Automatic signing and the absence of `match`
- [ ] `build` was run end to end and produced an `.ipa`; the upload half is
      ticket 03's to prove

## The simulator the tests run on

Resolved at run time — the newest available iPhone — rather than pinned to a
device name that Xcode will drop. A lane that breaks because a simulator was
renamed is a lane nobody trusts.

## What `build` is for

Signing, the embedded watch app and the export are the half that goes wrong,
and they can all be exercised without an upload behind them. When `beta` fails,
running `build` says which half failed. It is also the only thing in this
feature that can be run at all before the app icon exists.

## What must not change

**The archive is one archive.** The watch app is embedded — the iOS target has
an Embed Watch Content phase and the watch carries
`INFOPLIST_KEY_WKCompanionAppBundleIdentifier = com.vveidi.padel` — so there is
one `.ipa`, one upload and one App Store Connect record. A second lane for the
watch would be a second app.

**Nothing writes to `project.pbxproj`.** The build number is asked of App Store
Connect, and `MARKETING_VERSION` is a human's decision. A lane that commits to
the repo is a lane that has to be undone when the upload fails.

**`CLAUDE.md`'s build incantation is not moved into Ruby.** The debug
simulator build stays the documented shell one-liner. Wrapping it in a lane
would buy a second place to keep it in sync.

## Notes

**On the `.env.default`.** fastlane loads `fastlane/.env.default` by itself,
which is what makes the key id and the issuer id available without exporting
anything in a shell. It holds no secret — the `.p8` is the secret and it lives
at `~/.appstoreconnect/private_keys/` — but it is gitignored anyway, because a
file whose name says "env" and whose contents say "issuer" is a file somebody
will eventually put a key in.

**On the ADR.** One decision here clears all three bars: hard to reverse,
surprising to a future reader, and a real trade-off with a named alternative.
That is Automatic signing with no `match`, and the reason is that `match` needs
a private git repo and this project has no remote at all. The build-number
source does not earn one — it is two lines to change.

## Comments

**Not closed. Four of ten criteria are ticked, and the other six all wait on
the same missing thing: the App Store Connect API key, which is ticket 02's and
a human's.** The three lanes, the `Appfile` and ADR-0007 are written and in the
commit; what could not happen is a run that talks to App Store Connect.

What was built: `fastlane/Fastfile` with `test`, `build` and `beta`, an
`Appfile` naming `com.vveidi.padel` and team `FDT69Y2CLT`, `fastlane/.env*`
added to `.gitignore`, and `docs/adr/0007-automatic-signing-and-no-match.md`.

What was verified by running it:

- **`fastlane test` — green.** Four packages' `swift test`, then `PadelTests`
  on iPhone 17 (iOS 26.5), resolved at run time by `newest_iphone`: newest
  runtime, highest model number, plain model over Pro Max. 53s for the project
  half. It also failed correctly once — see the flake below.
- **`beta` refuses a dirty tree.** Run on the staged working tree, it stopped
  at `ensure_git_status_clean` before any other step. It tags nothing.
- **No `deliver`.** Grep over `fastlane/`, the ADR and `.gitignore`. The only
  hit is `PadelDelivery` in the list of packages to test, which is the repo's
  own meaning of the word and the one the spec wanted kept.
- **ADR-0007 exists**, and the Fastfile's "no key" error points at it by path.

What `build` could not do, and what stands behind it anyway. There is no
`~/.appstoreconnect/private_keys/`, no app record, and only an *Apple
Development* identity in the keychain — no *Apple Distribution* certificate,
which is exactly what the API key plus `-allowProvisioningUpdates` would
create. `fastlane build` therefore stops in one second at `connect_key` with
"Set ASC_KEY_ID and ASC_ISSUER_ID in fastlane/.env.default", which is the
intended failure and not a lane bug.

So the half the ticket calls "the half that goes wrong" was exercised by hand
instead, with the same `xcodebuild` the lane runs:

    xcodebuild -project Padel.xcodeproj -scheme Padel -configuration Release \
      -destination 'generic/platform=iOS' -archivePath … \
      CURRENT_PROJECT_VERSION=42 archive        → Archive Succeeded
    xcodebuild -exportArchive … (method: development)  → EXPORT SUCCEEDED

and the results say:

- **One archive, watch inside.** `Padel.app/Watch/Padel Watch App.app`, and in
  the `.ipa`, `Payload/Padel.app/Watch/Padel Watch App.app`. Both signed, each
  against its own profile.
- **The build number rides in as a build setting.** `CURRENT_PROJECT_VERSION=42`
  on the command line reached `CFBundleVersion = 42` in *both* Info.plists;
  `MARKETING_VERSION` stayed `1.0`, and `git status` on `project.pbxproj` stayed
  clean. That is the mechanism criterion 4 asks for — only the number's source
  (`latest_testflight_build_number + 1`) is unrun.

Two decisions taken without asking:

- **The build number is resolved inside `build`, not inside `beta`.** An
  `.ipa` carrying the project's stale `1` is not the artifact `beta` would
  upload, so running `build` on its own should exercise the same path. The
  price is that `build` needs the network and an app record, which is why it
  cannot be the thing that runs before ticket 02 either.
- **`disable_slide_to_type: false` on `run_tests`.** scan resolves a device of
  its own for that tweak and was editing iPhone 17 Pro's keyboard preferences
  while the tests ran on iPhone 17. Turning it off keeps the lane to one
  simulator.

**A pre-existing flake, surfaced by the lane.** The first `fastlane test` run
failed on `Packages/PadelDesign/Tests/PadelDesignTests/Controls/TileTests.swift:154`,
"A match still in progress is drawn as one stopped early" — it compares two
rendered rasters' mean luminance with `==`, and under the load of four test
runs back to back they came out `0.1585819026143783` vs `0.15857676928104492`.
Five further runs of that package alone were green. It is a float-equality
assertion on a render: two drawings of one paint are equal to within a step of
1/255, not equal. It was going to fail a `beta` at random, so it was fixed
here rather than left for another feature's ticket —
`Raster.patch(columns:rows:matches:)` now makes the comparison a tolerance, in
the harness next to `pixel(_:_:isCloseTo:)`, which treats color the same way
for the same reason.

**The review.** `code-review`'s two sub-agents both died on an API session
limit, so the two axes were run inline instead of in parallel sub-agents. The
one confirmed finding was duplicated code: the `app_store_connect_api_key(…)`
call appeared in both `build` and `beta`, and was extracted to
`connect_api_key`. Nothing else came back.

**When this is picked up again**, after ticket 02: `fastlane build` is the
whole remaining job. If it signs, criteria 2, 4 and 10 fall together, and 3, 5
and 7 fall to ticket 03's first `beta`.
