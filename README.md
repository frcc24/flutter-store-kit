# flutter-store-kit

A small Flutter game — **Mini Sudoku** — that ships with everything a store
listing needs, so you can replace the game and keep the rest:

- local persistence (`LocalStore`), statistics, resume of the saved game
- localization: English (template), Portuguese, Spanish via `gen-l10n`
- Crashlytics + Analytics that never block the boot
- privacy policy screen and a hosted policy (`docs/privacy-policy.md`)
- release signing that fails loudly without your keystore (`docs/release.md`)
- CI on GitHub Actions: format, analyze, test, Android debug build, iOS
  no-codesign build
- a device test checklist (`docs/device-test-checklist.md`)

Coming in the next tags: Unity rewarded ads, in-app purchases verified by a
Cloudflare Worker, review prompt, remote config, Claude Code skills.

Tested with **Flutter 3.44.2 / Dart 3.12.2**. MIT license.

## Run it

```bash
cd app
flutter pub get      # also generates lib/l10n/app_localizations*.dart
flutter run
```

## Make it yours

1. Rename: change `name` in `app/pubspec.yaml`, the `applicationId` in
   `app/android/app/build.gradle.kts` and the iOS bundle id in Xcode.
2. Replace `app/lib/features/sudoku/` with your feature. Keep `app/lib/core/`.
3. Edit the strings in `app/lib/l10n/*.arb`; `app_en.arb` is the template.
4. Run `flutterfire configure` to replace `app/lib/firebase_options.dart`.
   `google-services.json` stays out of git (see `.gitignore`).
5. Regenerate the icon: put your 1024×1024 PNG at `app/assets/icon/icon.png`
   and run `dart run flutter_launcher_icons` inside `app/`.
6. Follow `docs/release.md` to sign and upload.

## Tags

Each `cap-NN` tag is the repository as it stands at the end of that chapter
of the book *Zero to Store with AI* (PT: *Do Zero à Loja com IA*), which walks
through building, monetizing and shipping this app with Claude Code.

## Português

Este repositório acompanha o livro *Do Zero à Loja com IA*. Cada tag `cap-NN`
é o estado do código no fim do capítulo correspondente. As instruções acima
valem igual; o livro explica o porquê de cada decisão.
