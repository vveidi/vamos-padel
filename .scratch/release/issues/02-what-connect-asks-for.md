# 02: What App Store Connect asks for before it will take a build

**What to build:** The settings and the records that have to exist on the other
end, and that no lane can supply — the export-compliance answer in the project,
and the app record in App Store Connect.

**Blocked by:** None

**Status:** ready-for-human

- [ ] `ITSAppUsesNonExemptEncryption = NO` is set on the iOS target, in both
      configurations, and reaches the built `Info.plist`
- [ ] An app record for `com.vveidi.padel` exists in App Store Connect, with
      the bundle id registered and the watch app's bundle id alongside it
- [ ] The App Store Connect API key exists, with the App Manager role, and its
      `.p8` is saved at `~/.appstoreconnect/private_keys/`
- [ ] An internal tester group exists with at least one tester in it

## Why the encryption key is worth one line

Without `ITSAppUsesNonExemptEncryption`, every single upload stops in App Store
Connect on the export-compliance question and waits for somebody to click
through it. The app talks to no network and encrypts nothing — the store is a
local SQLite file and the only thing that crosses a wire is a match parcel over
WatchConnectivity — so the answer is `NO` and it never changes.

It is a build setting rather than a lane, which is why it is here and not in
ticket 01: a lane that patched an `Info.plist` on the way past would be a lane
that has to be read before the plist can be believed.

## Why the rest is `ready-for-human`

None of it is code. An API key is generated in App Store Connect by somebody
signed in as Account Holder, the app record is created by hand, and a tester
group is a list of people. An agent can say exactly what is needed and can
check afterwards that it is there, which is what the criteria above are, but it
cannot click the buttons.

The `.p8` is downloadable exactly once. Saving it anywhere other than
`~/.appstoreconnect/private_keys/` means generating a new key later.

## Notes

**On the two bundle ids.** `com.vveidi.padel` and
`com.vveidi.padel.watchkitapp` both have to be registered, but only the phone
app gets an App Store Connect record — the watch app is embedded in it, not
sold beside it.

**On roles.** The API key needs App Manager to upload builds. Developer is not
enough, and the error it gives when it is not enough does not say so.
