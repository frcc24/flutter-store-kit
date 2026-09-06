# flutter-store-kit — rules for agents

Read this before changing anything. Mini Sudoku (`app/`) is the sample app;
`app/lib/core/` holds only what every app needs, `app/lib/features/` holds the
game.

- No abstraction with a single implementation. No interface, repository or
  factory until a second implementation exists.
- No dependency without a concrete need stated in the commit message.
- Test before production code: every branch, parser, timer and money path gets
  a failing test first. Widgets get one smoke test each.
- User-facing strings live in `app/lib/l10n/*.arb`; `app_en.arb` is the
  template. Never hardcode copy in widgets.
- Never commit secrets or signing material: `key.properties`, `*.jks`,
  `google-services.json`, `GoogleService-Info.plist`.
- Before every commit, inside `app/`: `dart format .`, `flutter analyze`,
  `flutter test`. All three clean.
- One worktree per task; small commits in English (`type: summary`).
