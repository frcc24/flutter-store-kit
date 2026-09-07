# Publishing checklist — Google Play

One page. Every line is something the review, the policy or a real upload
has refused once. Tick it before **every** production release; the first
time, tick it before the internal test too.

## Account and app record (once)

- [ ] Developer account verified (identity, and the phone/e-mail checks).
- [ ] **Personal account created after November 2023:** a closed test with
      at least 12 testers opted in for 14 continuous days must finish before
      applying for production access. Start it on day one.
- [ ] App created with the final package name (`applicationId` in
      `app/android/app/build.gradle.kts`); it cannot change later.
- [ ] Play App Signing enabled (default). Upload keystore backed up in two
      places with its passwords (`docs/release.md`).

## Policy pages

- [ ] Privacy policy URL on the listing: public, reachable without login,
      same host as the deletion page. The kit's is
      `https://github.com/<you>/flutter-store-kit/blob/main/docs/privacy-policy.md`
      (and the app links it from the privacy screen — keep the two the same).
- [ ] Account deletion URL (Policy → App content → Data deletion): the kit's
      `docs/delete-account.md`. It must explain deletion **without installing
      the app**; ours directs to e-mail with a prefilled subject.
- [ ] Both pages describe the app that exists: Unity Ads, Google Play
      purchases, anonymous Firebase account, Crashlytics, Analytics. Update
      the effective date when any SDK changes.

## App content declarations (Policy → App content)

- [ ] **Data safety**: Collected — Device or other IDs (advertising id, for
      ads, by Unity), Purchase history (by Google Play, to credit purchases),
      App interactions (Analytics), Crash logs and Diagnostics (Crashlytics),
      Other identifiers (the anonymous account id, to keep the hint balance).
      Shared — device id with Unity Ads (advertising). Data is encrypted in
      transit; users can request deletion (in-app and by e-mail). Not used
      for tracking across apps by us.
- [ ] **Ads**: Yes, the app contains ads.
- [ ] **Content rating** questionnaire: puzzle game, no violence, contains
      ads and in-app purchases.
- [ ] **Target audience**: 13+ (the policy says the app is not directed to
      children; do not tick "children" or the Families policy applies).
- [ ] **Government apps / News / COVID / Financial features**: No.
- [ ] **Account deletion**: Yes, the app lets users create an account
      (anonymous counts) and provides in-app and web deletion.

## Build

- [ ] `version` bumped in `app/pubspec.yaml`; `versionCode` higher than any
      track's last upload.
- [ ] `flutter analyze`, `flutter test`, `server: npm test` green.
- [ ] `flutter build appbundle --release` signed with the upload key
      (`keytool -J-Duser.language=en -printcert -jarfile …` shows your CN).
- [ ] Target API level meets the current requirement (Google raises it every
      August; `flutter.targetSdkVersion` follows the Flutter version — keep
      Flutter updated).
- [ ] `docs/device-test-checklist.md` run on a physical phone with the
      **store** build (internal track), not a sideloaded APK.
- [ ] Firebase: `flutterfire configure` done for the release package name;
      the Play App Signing certificate's SHA-1 registered in the Firebase
      project (the release build's Google services differ from the debug
      one).

## Listing

- [ ] `docs/store-listing.md` pasted: en-US default, pt-BR and es-419
      translations; title ≤ 30, short description ≤ 80, full ≤ 4000 chars.
- [ ] Icon 512×512 PNG, feature graphic 1024×500, at least 4 phone
      screenshots (see `docs/store-image-prompts.md`).
- [ ] Contact e-mail on the listing is one you read; deletion requests
      arrive there.
- [ ] Release notes in the three languages.

## After upload

- [ ] Internal test → closed test (14 days if required) → production with a
      staged rollout (10% → 50% → 100%), watching crash-free users and the
      one-star reviews between steps.
- [ ] Remote Config keys exist (`min_supported_build`, `ads_enabled`,
      `iap_enabled`) so a bad build can be retired without a new release.
- [ ] Rollback = promote the previous release on the track.
