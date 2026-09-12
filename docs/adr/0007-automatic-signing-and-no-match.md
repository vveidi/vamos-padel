# Automatic signing, and no `match`

The release lanes sign with Xcode's Automatic signing, driven by
`-allowProvisioningUpdates` and an App Store Connect API key. Certificates and
provisioning profiles are whatever the one Mac that builds this app happens to
hold, and nothing keeps a second copy of them.

`match` — fastlane's answer to the same problem — is not used.

## What `match` would need that this project does not have

`match` works by keeping the distribution certificate and the provisioning
profiles in a git repository, encrypted, so that every machine and every CI
runner checks out the same identity instead of each minting its own. That is
the right shape once there is more than one machine, and it is the only way to
stop a team from burning through Apple's certificate limit.

`git remote -v` is empty here. There is no repository to push the app to, let
alone a second private one to hold its keys, and creating one exists only to
serve a machine that does not exist either. The cost of `match` is paid on day
one — a repo, a passphrase, a bootstrapping step on every checkout — and the
thing it buys is not needed until day two.

Automatic signing is what one developer on one machine already has. Xcode
creates the distribution certificate and the profiles on first archive, the API
key is what authenticates that creation from a lane rather than from the
Accounts pane, and the whole of it is four xcodebuild flags in
`fastlane/Fastfile`.

## The key, and why it is not an Apple ID

`-allowProvisioningUpdates` needs an authenticated session. An Apple ID would
mean a `FASTLANE_SESSION` that expires about monthly and re-prompts for
two-factor each time it does; the App Store Connect API key does not expire and
is the only one of the two that would survive a move to CI.

The key id and the issuer id are not secrets on their own and live in
`fastlane/.env.default`, which fastlane loads by itself so that no lane depends
on remembering to export anything. The file is gitignored regardless, because a
file whose name says "env" is a file somebody will eventually put a key in. The
`.p8` is the secret, and it lives at `~/.appstoreconnect/private_keys/` — where
Apple's own tools look — and never comes near the repo.

gym does not pass a key through to xcodebuild, so the three
`-authenticationKey…` flags go in by hand alongside
`-allowProvisioningUpdates`, on the archive and on the export both.

## Consequences

- **The signing identity lives in one keychain and is backed up by nothing.**
  Accepted. Losing it costs a revoke and a re-archive, not a release; Apple
  will mint another.
- **A second machine starts from zero.** It will create its own certificate
  rather than share this one, which is fine until there are enough of them to
  hit Apple's limit. That is the day this decision gets reopened, and this file
  is where the alternative is already written down.
- **CI cannot run these lanes as they stand.** A runner has no keychain to
  create a certificate into and no way to keep one between jobs. The API key
  half carries over; the signing half is what `match` would have to be brought
  in for.
- **The archive is not reproducible off this Mac.** Two machines signing the
  same commit produce two differently-signed `.ipa`s. Nothing in this project
  depends on them being identical.
