---
name: growth-report
description: Produce the weekly growth report for this app from the numbers you can export without a backend — Play Console statistics, Firebase Analytics events (game_started, game_completed, hint_used, ad_rewarded, purchase_delivered), Crashlytics crash-free users — as a table of verdicts (ok/watch/act) with one action each, using the thresholds and the timezone rules below. Use every Monday, after a release, or when someone asks "how is the app doing".
---

# Growth report with verdicts

## When to use
Weekly, after every release, and before spending on ads. A report without a
verdict per number is a table; this one decides.

## Inputs
- Play Console → Statistics: installs, uninstalls, ratings (last 7 days and
  the 7 before). Timezone: **America/Los_Angeles** — Play's, not yours.
- Firebase → Analytics → Events, last 7 days and the 7 before: `first_open`,
  `game_started`, `game_completed`, `hint_used` (param `source`),
  `ad_rewarded`, `purchase_delivered`. Timezone: the Analytics project's.
- Firebase → Crashlytics: crash-free users, 7 days. UTC.
- Retention: Analytics → Retention, D1 for the last 4 weekly cohorts.
- `report-template.md` next to this file.

## Steps
1. Copy `report-template.md`, fill the "Numbers" block. Write the timezone
   line once at the top; never line a Play day up against an Analytics day
   without saying so.
2. Apply the rules, one verdict per row:
   - **Crash-free users** ≥ 99% → ok; 97–99% → watch (read the top crash);
     < 97% → act (hotfix or `min_supported_build` to retire the build).
   - **Install → first game** = users with `game_started` ÷ `first_open`
     users. ≥ 0.5 → ok; below → act: the app breaks before the board (check
     Crashlytics on that build) or the consent dialog blocks.
   - **Completion** = `game_completed` ÷ `game_started`. ≥ 0.3 → ok;
     0.15–0.3 → watch (Easy should complete in minutes; check hint use);
     < 0.15 → act (difficulty or a bug in the board).
   - **Paid hints per completed game** = `hint_used{paid}` ÷
     `game_completed`. No threshold: a trend to watch. A jump after a
     release means the puzzle got harder or the free hint broke.
   - **Ad reward yield** = `ad_rewarded` ÷ `hint_used{paid}`. Below 0.5 →
     watch: rewarded ads are not filling (Unity dashboard fill rate) or the
     S2S callback is failing (`wrangler tail`).
   - **Installs, 7d vs prior 7d**: drop > 40% → act (campaign paused,
     listing changed, or a store policy warning); rise > 100% with flat
     `game_started` → watch (low-quality traffic).
   - **Uninstalls ÷ installs** (7d) > 0.6 → watch; read the 1-star reviews.
   - **D1 retention vs the app's own 4-week average**: drop > 30% → act on
     the release that landed that week; no absolute target — a market
     benchmark is somebody else's game.
   - **New 1-star reviews** (7d) > 2 → act: read them; most name a device
     or a step that fails.
3. Write the action for every non-ok row in one sentence that names a file,
   a console page or a person.
4. Put "What to do first" at the top: the single act with the most users
   behind it.

## Verify
- Every row has a number, a source, a verdict and an action (or "Nothing.").
- Ratios use the same period and the same timezone in numerator and
  denominator.
- The report names the app version(s) the week ran on.

## Pitfalls
- `game_completed` fires for every difficulty; segment by the `difficulty`
  parameter before judging completion.
- Events count occurrences, not people: use "users with event" in Analytics
  for the funnel ratios.
- A Play day starts at 00:00 Los Angeles; an Analytics day at 00:00 of the
  project's timezone. Comparing them by date shifts hours silently.
- Numbers from a week with fewer than ~50 new users are noise; say so
  instead of judging.
