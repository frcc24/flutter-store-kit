---
name: store-listing-aso
description: Write or improve the Google Play listing for this app — title, short and full descriptions within the character limits, localized to en-US, pt-BR and es-419, icon/feature graphic/screenshot specs and prompts, release notes, and what actually moves ranking (title words, ratings, retention). Use when preparing the listing, translating it, running a store listing experiment, or when installs are flat.
---

# Store listing and ASO

## When to use
Before the first upload, on every rewrite of the listing, and when the
install-to-page-view rate in the Console stalls.

## Inputs
- `docs/store-listing.md` — the current copy in three languages.
- `docs/store-image-prompts.md` — art direction and asset specs.
- Play Console → Statistics → Store performance (page views, installs).

## Steps
1. Title (≤ 30): the app name plus the one word people search. For a sudoku
   app "Sudoku" must be in the title; "Mini Sudoku" already carries it.
2. Short description (≤ 80): one sentence with the second and third search
   words (puzzle, hint, offline) and the promise. No emoji, no exclamation.
3. Full description (≤ 4000): first 2 lines are visible without "read more"
   — say what it is and what it lacks (no account, no lives). Then bullet
   features, then what you do not do. Keep the open-source link; it is a
   trust signal reviewers and users read.
4. Localize, do not translate literally: pt-BR and es-419 each rewritten by
   someone (or a model) told the tone is calm and plain. Same structure,
   same limits.
5. Assets from `docs/store-image-prompts.md`: icon, feature graphic, 4–8
   screenshots with one caption each. Same style block in every prompt.
6. Release notes: one line per language, what changed for the player.
7. After launch: Play Console → Store listing experiments. Test one thing
   (icon, or first screenshot, or short description), 7 days, 50/50. Ship
   the winner and test the next.

## Verify
- Paste each text into the Console: the counter must stay below the limit
  with no red warning.
- Preview the listing on a phone: the first two lines of the full
  description make sense on their own.
- All three languages are "Translated" in Manage translations, none marked
  "Machine translated" by you.

## Pitfalls
- Play has no keyword field: stuffing the description with words hurts
  readability and the review can flag it.
- Claims the app cannot back ("#1", "best", "free forever") are policy
  violations, not marketing.
- Feature graphic text under the center: Google's play button covers it.
- Screenshots must show the app as it is; mockups with features that are
  not in the build are a rejection reason.
