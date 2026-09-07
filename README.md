# flutter-store-kit

![CI](https://github.com/frcc24/flutter-store-kit/actions/workflows/ci.yaml/badge.svg)

A small Flutter game — **Mini Sudoku** — that ships with everything a store
listing needs, so you can replace the game and keep the rest:

- local persistence (`LocalStore`), statistics, resume of the saved game
- localization: English (template), Portuguese, Spanish via `gen-l10n`
- Crashlytics + Analytics that never block the boot
- Unity Ads: rewarded ad → hint, interstitial every second game, consent
  dialog, iOS ATT; empty game ids = no ads
- purchases: remove ads (store-restored) and a hint pack the server verifies
- `server/`: a Cloudflare Worker + D1 wallet (free plan) — receipt
  verification, Unity S2S callback, idempotent ledger, account deletion
- review prompt, delete-my-data flow, bilingual deletion page
- remote flags: force update, ads/purchases kill switches
- privacy policy screen and a hosted policy (`docs/privacy-policy.md`)
- release signing that fails loudly without your keystore (`docs/release.md`)
- CI on GitHub Actions: format, analyze, test, Android debug build, iOS
  no-codesign build, Worker typecheck and tests
- a device test checklist (`docs/device-test-checklist.md`)

Every online piece degrades to "unavailable" when it is not configured, so a
fresh clone builds, runs and passes its tests with no Firebase project, no
Worker and no Unity account.

The publishing checklist is `docs/publishing-checklist.md`.

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
5. Ads: put your Unity Game IDs in `app/lib/core/ads/ads_config.dart`.
6. Server: follow `server/README.md`, then build the app with
   `--dart-define=KIT_API_URL=https://<your worker>.workers.dev`. Create the
   products `remove_ads` and `hint_pack_5` in the Play Console.
7. Remote Config (optional): create `min_supported_build` (number),
   `ads_enabled` and `iap_enabled` (booleans) in the Firebase console; the
   app runs with "all on, nothing forced" until then.
8. Regenerate the icon: put your 1024×1024 PNG at `app/assets/icon/icon.png`
   and run `dart run flutter_launcher_icons` inside `app/`.
9. Follow `docs/release.md` to sign and upload.

## Claude Code skills

Open this repository in Claude Code and the skills in `.claude/skills/` are
picked up automatically (or run `claude --plugin-dir .` from anywhere):

| Skill | What it walks you through |
|---|---|
| `flutter-l10n` | adding copy in EN/PT/ES the kit way |
| `store-release` | signing, versionCode, upload, the 14-day closed test |
| `unity-ads` | Game IDs, consent, test mode, the S2S callback and its proof |
| `iap-server-verify` | Play products, service account, secrets, the redeem flow |
| `compliance-checklist` | policy URLs, Data safety answers, declarations |
| `store-listing-aso` | listing texts within limits, assets, experiments |
| `growth-report` | weekly numbers with a verdict and an action each |

`node tool/check_skills.mjs` validates them; CI runs it.

## Tags

Each `cap-NN` tag is the repository as it stands at the end of that chapter
of the book *Zero to Store with AI* (PT: *Do Zero à Loja com IA*), which walks
through building, monetizing and shipping this app with Claude Code.

## Português

Este repositório acompanha o livro *Do Zero à Loja com IA*. Cada tag `cap-NN`
é o estado do código no fim do capítulo correspondente. As instruções acima
valem igual; o livro explica o porquê de cada decisão.
