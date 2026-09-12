# 01: The three lanes, and the key they sign with

**What to build:** `fastlane/Fastfile` with `test`, `build` and `beta`, an
`Appfile` naming the app and the team, and the App Store Connect API key wired
in without any part of it entering the repo.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `fastlane test` runs the four packages' `swift test` and then
      `padelTests` on an iOS simulator, and fails the lane when any of them
      fails
- [ ] `fastlane build` produces a signed `.ipa` from the `padel` scheme and
      uploads nothing
- [ ] `fastlane beta` runs `test`, then `build`, then uploads to TestFlight for
      internal testers only
- [ ] The build number is `latest_testflight_build_number + 1`; nothing in
      `project.pbxproj` is written by any lane
- [ ] The API key is read from `ENV`, the `.p8` is outside the repo, and
      `fastlane/.env.default` is gitignored — `git status` is clean after a
      full `beta` run
- [ ] `beta` refuses to run on a dirty working tree, and tags nothing
- [ ] The TestFlight changelog is the last commit's subject line, overridable
      with `fastlane beta notes:"…"`
- [ ] No lane, file or comment uses the word `deliver`
- [ ] ADR-0007 records Automatic signing and the absence of `match`
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
