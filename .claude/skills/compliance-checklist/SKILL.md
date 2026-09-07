---
name: compliance-checklist
description: Walk the Google Play compliance items that block a review — privacy policy and account-deletion URLs, the Data safety form answers for this app's SDKs (Unity Ads, Google Play Billing, Firebase Crashlytics/Analytics, anonymous account), ads and content-rating declarations, target audience, the 14-day closed test rule — and produce the filled answers. Use before a first upload, after adding an SDK, or when the Console shows a policy warning.
---

# Compliance that unblocks the review

## When to use
Before the first upload, whenever an SDK is added or removed, and whenever
the Play Console flags a policy issue.

## Inputs
- `docs/publishing-checklist.md` (this repo) — the one page to tick.
- The list of SDKs in `app/pubspec.yaml` (ads, billing, firebase_*).
- The two hosted pages: `docs/privacy-policy.md`, `docs/delete-account.md`.

## Steps
1. Diff the SDK list against the privacy policy: every SDK that receives
   device data must have a paragraph (Unity Ads, Google Play Billing, Firebase
   Crashlytics/Analytics/Auth). Update the policy and its effective date if
   they disagree; the in-app privacy screen (`privacyAds`, `privacyPurchases`,
   `privacyAccount` strings) must say the same thing.
2. Fill Data safety from the table in `docs/publishing-checklist.md`. When
   unsure whether a data type is "collected", answer yes: the form is judged
   against what the SDKs actually send, not against intent.
3. Declare ads = yes, in-app purchases = yes (both are visible in the app
   and the review checks).
4. Content rating: run the questionnaire as "Game → Puzzle"; the kit has no
   violence, gambling or user-generated content.
5. Account deletion: declare yes; paste the deletion URL. The page must
   work without the app installed.
6. Target audience 13+. Do not opt into the Families program unless you also
   remove personalized ads and the anonymous account.
7. If the developer account is personal and new: schedule the 14-day closed
   test with 12 testers before anything else; production access is refused
   until it completes.

## Verify
- Open both hosted URLs in a private browser window: 200, readable, no
  login.
- Policy → App content in the Console shows every section "Completed" with
  no warning icon.
- The Data safety preview on the listing lists Unity Ads sharing and the
  deletion option.

## Pitfalls
- A policy page on another host than the deletion page makes reviewers stop
  and ask; keep both in `docs/` of the same public repo.
- "Contains ads" left as no while Unity Ads is in the APK is an automated
  rejection.
- The anonymous account still counts as an account for the deletion policy.
- Reviewers read the pt-BR listing if the account is Brazilian; keep the
  translations as complete as the English.
