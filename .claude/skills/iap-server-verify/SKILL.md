---
name: iap-server-verify
description: Set up, test and debug in-app purchases in this app — the remove_ads and hint_pack_5 products in the Play Console, the Google Play service account the Worker uses to verify receipts, the wrangler secrets, license testers, and the redeem flow (autoConsume off, consume only after the server credited). Use when a purchase does not deliver, redeem answers 503, or the user is wiring their own project.
---

# Purchases verified on the server

## When to use
Creating the products, granting the Worker its credential, testing a purchase
end to end, or reading why a purchase stayed pending.

## Inputs
- Play Console access to the app (products, license testers).
- Google Cloud project linked to the Play Console (Setup → API access).
- The deployed Worker (`server/README.md`) and `wrangler` logged in.

## Steps
1. Products: Play Console → Monetize → Products → In-app products → Create:
   `remove_ads` (one-time, price of your choice) and `hint_pack_5` (one-time;
   consumption is done by the app, not a Console setting). Activate both.
   The ids are constants in `app/lib/core/iap/products.dart` and
   `server/src/iap/products.ts` (`hint_pack_5` → 5 hints).
2. Service account: follow `play-console-setup.md` next to this file
   (Cloud IAM service account → JSON key → invite it in the Play Console with
   "View financial data" and "Manage orders and subscriptions").
3. Secret and package name:
   ```bash
   cd server
   npx wrangler secret put GOOGLE_PLAY_SERVICE_ACCOUNT   # paste the JSON key on one line
   ```
   `ANDROID_PACKAGE_NAME` in `wrangler.toml` must equal the `applicationId`.
4. License testers: Play Console → Setup → License testing → add the Google
   accounts that will test; they are not charged. Install the app from the
   internal testing track (purchases do not work on sideloaded builds).
5. Flow to keep in mind while debugging: `IapService.buyConsumable`
   (`autoConsume: false`) → the store delivers `purchased` →
   `PurchaseDeliveries.deliver` → `KitApi.redeem` → Worker
   `POST /v1/iap/google/redeem` verifies with Google, **acknowledges**, credits
   once per purchase token → the app consumes the purchase → the game screen
   reloads the balance. `remove_ads` never touches the server: the store
   restores it (`Restore purchases` in Settings).
6. Read the server side: `npx wrangler tail` while buying. `503
   verification_unavailable` means the secret is missing or the account lacks
   permission; `400 product_mismatch` means the ids disagree; `409
   not_purchased` means Google reports pending or cancelled.

## Verify
- A license tester buys `hint_pack_5`: the wallet shows 5, the purchase is
  consumed (buying again works), the Console order shows "acknowledged".
- Buying `remove_ads`: "Ads removed" in Settings, no interstitial after the
  next game, and it survives a reinstall through Restore purchases.
- `curl -X POST https://<worker>/v1/iap/google/redeem` with a made-up token
  and a real ID token answers 503 (the verifier refuses what it cannot check).

## Pitfalls
- An unacknowledged purchase is refunded by Google after three days; the
  Worker acknowledges before crediting, and returns null (503) if that call
  fails, so the player keeps a retryable purchase, never a free one.
- `completePurchase` on Android only acknowledges. A consumable must be
  consumed (`InAppPurchaseAndroidPlatformAddition.consumePurchase`, which
  `IapService.finish(consumable: true)` does) or the store answers "already
  owned" on the next buy.
- A purchase the server could not verify stays open on purpose; the store
  re-delivers it on the next app start and the redeem replays from the
  receipt even if Google is down.
- The service account permission takes up to 24 h to propagate the first
  time; a 401 from Google right after inviting it is normal.
