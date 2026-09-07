---
name: store-release
description: Build, sign and upload an Android release of this app to the Play Console the kit way — key.properties and upload keystore, versionCode bump, flutter build appbundle, certificate check, internal testing track, and the 14-day closed test rule for new personal accounts. Use when the user wants to ship a build, bump the version, check signing, or roll back a release.
---

# Release to the Play Store

## When to use
Every time a build leaves the machine: internal test, closed test,
production, or a rollback.

## Inputs
- `android/key.properties` and the upload keystore it points at (never in
  git; see `docs/release.md` for creating them).
- The `versionCode` last uploaded to any track (read it in the Play Console,
  not in the repo).
- Release notes in en-US, pt-BR and es-419 (a line each is enough).

## Steps
1. Bump `version` in `app/pubspec.yaml`: `name+code`, and `code` must be
   higher than the last upload to any track. The kit's convention is to bump
   both on every store upload (`0.2.0+2` → `0.2.1+3`).
2. Add the entry to `CHANGELOG.md`.
3. In `app/`: `flutter analyze && flutter test && flutter build appbundle
   --release`. Without `key.properties` the build fails on purpose with
   `android/key.properties not found` — that is the kit refusing to ship a
   debug-signed bundle.
4. Check the signer (English locale forced; the JBR keytool crashes on
   localized messages):
   ```bash
   keytool -J-Duser.language=en -J-Duser.country=US -printcert \
     -jarfile app/build/app/outputs/bundle/release/app-release.aab
   ```
   The `Owner` must be your upload key, never `CN=Android Debug`.
5. Play Console → Testing → Internal testing → Create release → upload the
   `.aab`, paste the release notes, roll out.
6. Install from the internal track on a real phone and run
   `docs/device-test-checklist.md`.
7. Promote: Internal → Closed → Production. A **personal developer account
   created after November 2023 must run a closed test with at least 12
   testers opted in for 14 continuous days** before it can apply for
   production access. Plan the calendar around it.

## Verify
- The Play Console shows the new `versionCode` on the track.
- `git tag -a v<version>` on the commit that was built, so the build can be
  reproduced.

## Pitfalls
- Losing the upload keystore: keep it and its passwords in a password
  manager. Play App Signing lets you reset an upload key from the Console,
  but only with the account's support flow.
- `versionCode` is decided by the Console, not by the repo: two machines
  building from the same commit collide on upload.
- A tester who sideloaded a debug APK cannot update to the store build (the
  signatures differ); uninstall first.
- Rollback = promote the previous release on the track in the Console; no
  rebuild.
