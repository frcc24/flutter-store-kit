# mini-sudoku-api

The hint wallet behind Mini Sudoku: a Cloudflare Worker (free plan) with a D1
database. It exists because two things must never be decided by the phone —
whether a Google Play receipt is real, and whether a rewarded ad was really
watched.

| Route | Auth | What it does |
|---|---|---|
| `GET /v1/health` | none | liveness |
| `GET /v1/wallet` | Firebase ID token | `{hints}` |
| `POST /v1/hints/spend` `{operationId}` | Firebase ID token | spends one hint, idempotent per `operationId`; 409 `no_hints` |
| `POST /v1/iap/google/redeem` `{productId, purchaseToken}` | Firebase ID token | verifies the receipt with the Play Developer API, acknowledges it, credits once per token |
| `GET /v1/ads/unity/reward?sid&oid&hmac` | Unity HMAC-MD5 | credits one hint per Unity offer id; answers `1` |
| `POST /v1/account/delete` | Firebase ID token | erases the player's rows; repeatable |

Every write is one atomic D1 `batch()` with an idempotency record and a
revision guard (`src/db/transaction.ts`). A retry answers the stored response;
a stale precondition writes nothing.

## Run the tests (no account needed)

```bash
npm ci
npm test        # vitest inside workerd, real D1 via Miniflare
npm run check   # tsc
```

If `npm ci` prints `npm warn allow-scripts workerd@...`, the runtime binary
was not downloaded: run `npm approve-scripts workerd esbuild && npm rebuild`.
The `allowScripts` block in `package.json` records the approved versions.

## Run locally

```bash
cp .dev.vars.example .dev.vars   # optional; secrets stay empty until you have them
npm run db:migrate:local
npm run dev                      # http://127.0.0.1:8787
```

## Deploy (once per project)

1. `npx wrangler login`
2. `npx wrangler d1 create mini-sudoku` → paste the `database_id` into `wrangler.toml`.
3. Set `FIREBASE_PROJECT_ID` and `ANDROID_PACKAGE_NAME` in `wrangler.toml`.
4. `npm run db:migrate:prod`
5. `npm run deploy` → note the `https://mini-sudoku-api.<account>.workers.dev` URL; the
   app receives it as `--dart-define=KIT_API_URL=<url>`.
6. Secrets, when you have them:
   - `npx wrangler secret put GOOGLE_PLAY_SERVICE_ACCOUNT` — the whole JSON key of a
     service account with the "View financial data / Manage orders" permission in
     the Play Console (chapter 8 of the book walks through it). Until it is set,
     every redeem answers 503 and nothing is credited.
   - `npx wrangler secret put UNITY_ADS_S2S_SECRET` — Unity enables the S2S
     callback per Game ID through a support ticket and hands back the secret.
     Register the callback URL as `https://<worker>/v1/ads/unity/reward`.

## What it deliberately does not do

- Rate limiting (measure abuse first; the Card Kingdoms server has a D1 fixed
  window limiter to copy).
- Verifying the "remove ads" purchase: it is restored by the store on the
  device and a fraud there costs one phone's ad revenue.
- Serving the account-deletion page: it lives next to the privacy policy at
  `docs/delete-account.md`, on the same host, as the Play Console expects.
