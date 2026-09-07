# Service account for the Play Developer API

The Worker verifies receipts with the Android Publisher API. It authenticates
as a Google Cloud service account that the Play Console has been told to
trust. One-time setup, ten minutes.

1. Play Console → Setup → API access. Link the Google Cloud project (create
   one if the page offers it). Note the project name.
2. Google Cloud Console → IAM & Admin → Service accounts → Create service
   account. Name: `play-receipt-verifier`. No roles are needed at the Cloud
   level. Create.
3. Open the account → Keys → Add key → Create new key → JSON. A file
   downloads. It is a credential: never commit it, never paste it in chat.
4. Back in Play Console → Setup → API access → the service account now
   appears under "Service accounts" → Manage Play Console permissions →
   Invite user: check **View app information and download bulk reports**,
   **View financial data, orders, and cancellation survey responses** and
   **Manage orders and subscriptions**. Apply to this app only. Send invite.
5. Turn the JSON into one line and store it as a Worker secret:
   ```bash
   cd server
   node -e "process.stdout.write(JSON.stringify(require('/path/to/key.json')))" | npx wrangler secret put GOOGLE_PLAY_SERVICE_ACCOUNT
   ```
6. Delete the downloaded file. The Worker holds the only copy you need; a
   new key can always be issued.
7. Wait up to 24 hours before the first real verification; Google propagates
   the permission slowly the first time.

What the Worker does with it: signs a JWT with the key, trades it for an
OAuth token with scope `androidpublisher`, and calls
`purchases/products/{productId}/tokens/{token}` and `:acknowledge`
(`server/src/iap/google_play_verifier.ts`).
