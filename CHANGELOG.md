# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow the
`version` field in `app/pubspec.yaml`.

## [Unreleased]

### Changed

- `docs/publishing-checklist.md` opens with a six-line short version and splits
  into "once per app" and "every release", so the page you print is the summary
  and the detail sits under it.

## [0.3.1] - 2026-09-07

### Fixed

- The generator could ship a puzzle with two solutions. `_countSolutions`
  aborted at its node limit and returned the solutions found so far, so a
  search that ran out of budget with one solution was read as "unique" and the
  cell removal was kept. It now reports whether the search finished, and only a
  finished search with exactly one solution keeps a removal. `tool/check_unique.dart`
  proves it over 90 puzzles with an independent solver; before the fix, 13 of
  those 90 had two solutions.

- The review prompt no longer asks the player a question before the Play
  review card. The in-app review policy forbids any question before or while
  the card is shown, including "are you enjoying it?", and forbids a button
  that triggers the API. `ReviewPrompt` now exposes `willAsk` and `maybeAsk`;
  `review_dialog.dart` and its four strings are gone.

### Changed

- `version` bumped to `0.3.1+4`.

## [0.3.0] - 2026-09-06

### Added

- Seven Claude Code skills in `.claude/skills/` and a plugin manifest;
  `tool/check_skills.mjs` validates them in CI.
- `docs/publishing-checklist.md`, `docs/store-listing.md` (en-US, pt-BR,
  es-419), `docs/store-image-prompts.md`.
- Analytics events `game_started`, `hint_used`, `ad_rewarded`,
  `purchase_delivered`.

### Changed

- `version` bumped to `0.3.0+3`.

## [0.2.0] - 2026-09-06

### Added

- `server/`: Cloudflare Worker + D1 hint wallet — Firebase ID token auth,
  atomic idempotent ledger, Google Play receipt verification with
  acknowledgement, Unity S2S reward callback (HMAC-MD5), account deletion.
- Unity Ads: rewarded ad that pays one hint through the server, interstitial
  every second completed game, GDPR/CCPA consent dialog, iOS ATT.
- Purchases: `remove_ads` (restored by the store) and `hint_pack_5` (credited
  only after the Worker verified the receipt).
- Review prompt after the third completed game, then every fifth.
- Delete my data (server → Firebase user → device) and a bilingual deletion
  page next to the privacy policy.
- Remote flags: force update gate, ads and purchase kill switches.

### Changed

- `version` bumped to `0.2.0+2` in `app/pubspec.yaml`.

## [0.1.0] - 2026-09-06

### Added

- Mini Sudoku: 9x9 puzzles with a unique solution in three difficulties,
  mistakes, one free hint per game, elapsed time, resume of the saved game.
- Statistics (completed games, best time per difficulty), rules, language
  setting (system, English, Portuguese, Spanish).
- Privacy policy screen and hosted policy in `docs/privacy-policy.md`.
- Crashlytics and Analytics that never block the boot.
- Release signing from `android/key.properties`; fails loudly without it.
- CI: format, analyze, test, Android debug build, iOS no-codesign build.
