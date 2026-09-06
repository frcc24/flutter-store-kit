# Release builds and signing

## Android

`android/app/build.gradle.kts` reads `android/key.properties` (git-ignored)
and signs release builds with the upload keystore it points at. **Without that
file every Release task fails with an explicit message**; there is no fallback
to the debug key, because a debug-signed bundle is rejected by the Play
Console and, worse, a debug-signed APK sideloaded by a tester cannot be
updated by the store build later.

### One-time setup per machine

1. Create the upload keystore (any JDK `keytool`; Android Studio ships one in
   `jbr/bin`):

   ```bash
   keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
     -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill
   in the passwords. `storeFile` is relative to `android/app/`.
3. Check both files are ignored: `git check-ignore android/key.properties
   android/app/upload-keystore.jks` prints both paths.

### Build and verify

```bash
flutter build appbundle --release
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The certificate owner must be your upload key, never `CN=Android Debug`.

On a machine whose system language is not English, the JDK bundled with
Android Studio can abort `keytool -printcert` with
`MissingFormatArgumentException: Format specifier '%2$s'` (a bug in its
localized messages). Force English for that one call:

```bash
keytool -J-Duser.language=en -J-Duser.country=US -printcert \
  -jarfile build/app/outputs/bundle/release/app-release.aab
```

### Keep the key

Losing the upload keystore means losing the ability to update the app unless
Play App Signing is enabled (it is, by default, for apps created after 2021 —
keep it on: Google holds the app signing key and you can reset a lost upload
key from the Play Console). Back up the `.jks` and its passwords in a password
manager, outside the repository.

### Versioning

`version: 0.1.0+1` in `pubspec.yaml` is `versionName+versionCode`. The Play
Console rejects a bundle whose `versionCode` is not higher than the last one
uploaded to any track, so bump the number after the `+` on every upload.

### Rollback

The last bundles stay in the Play Console (App bundle explorer). To roll back,
promote the previous release on the track; no rebuild needed.

## iOS

CI compiles with `flutter build ios --release --no-codesign` as a compile
gate. Signing and upload to App Store Connect are manual in Xcode and are not
part of this kit.
