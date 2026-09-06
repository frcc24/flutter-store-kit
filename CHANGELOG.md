# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow the
`version` field in `app/pubspec.yaml`.

## [Unreleased]

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
