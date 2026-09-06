import { deleteAccount } from './account/delete.js';
import { grantAdReward, unitySignatureValid } from './ads/unity_s2s.js';
import { FirebaseJwtVerifier, TokenRejected, verifierFor, type VerifiedIdentity } from './auth/firebase_jwt.js';
import type { CommitOutcome } from './db/transaction.js';
import { authInvalid, authRequired, internalRetryable, invalidRequest, json, problem } from './http/problem.js';
import { Router, type RouteContext } from './http/router.js';
import { googlePlayVerifier, type PurchaseVerifier } from './iap/google_play_verifier.js';
import { redeemGooglePurchase, RedeemRefused, redeemRefusalStatus } from './iap/redeem.js';
import { readWallet, spendHint, WalletRefused } from './wallet/wallet_service.js';

/// What the router needs from the outside world, injected so the tests can
/// sign tokens with a local key and answer receipts without Google.
export interface Deps {
  readonly verifier: (env: Env) => FirebaseJwtVerifier;
  readonly purchaseVerifier: (env: Env) => PurchaseVerifier;
}

// ponytail: no rate limiter. The HMAC and the ID token close the fraud paths;
// volume abuse gets the Card Kingdoms `rate_limiter.ts` when it is measured.

export function createRouter(deps: Deps): Router {
  return (
    new Router()
      .get('/v1/health', () => json({ ok: true }))
      .get('/v1/wallet', (context) => authenticated(context, deps, async (identity) => json(await readWallet(context.env.DB, identity.uid))))
      .post('/v1/hints/spend', (context) =>
        authenticated(context, deps, async (identity) => {
          const body = (await context.request.json().catch(() => null)) as { operationId?: string } | null;
          if (body === null || typeof body.operationId !== 'string' || body.operationId.length === 0 || body.operationId.length > 128) {
            return invalidRequest('operationId (1-128 chars) is required');
          }
          try {
            return outcomeResponse(await spendHint(context.env.DB, identity.uid, body.operationId));
          } catch (error) {
            if (error instanceof WalletRefused) return problem({ status: 409, code: error.refusal, detail: error.message });
            throw error;
          }
        }),
      )
      .post('/v1/iap/google/redeem', (context) =>
        authenticated(context, deps, async (identity) => {
          const body = (await context.request.json().catch(() => null)) as { productId?: string; purchaseToken?: string } | null;
          if (body === null || typeof body.productId !== 'string' || typeof body.purchaseToken !== 'string') {
            return invalidRequest('productId and purchaseToken are required');
          }
          try {
            return outcomeResponse(
              await redeemGooglePurchase(context.env.DB, identity.uid, {
                productId: body.productId,
                purchaseToken: body.purchaseToken,
                verifier: deps.purchaseVerifier(context.env),
              }),
            );
          } catch (error) {
            if (error instanceof RedeemRefused) return problem({ status: redeemRefusalStatus(error.refusal), code: error.refusal, detail: error.message });
            throw error;
          }
        }),
      )
      // Unity's server-to-server callback. Unauthenticated by necessity (Unity
      // holds no Firebase token) and authenticated in substance by the HMAC.
      // `sid` is the uid the app handed the SDK as serverId. Unity wants the
      // single character `1` back on success; a replay answers `1` too, because
      // the repeat that actually happens is Unity retrying a payment that landed.
      .get('/v1/ads/unity/reward', async (context) => {
        const query = context.url.searchParams;
        if (!(await unitySignatureValid(context.env, query))) return new Response('invalid signature', { status: 403 });
        const uid = query.get('sid') ?? '';
        const offerId = query.get('oid') ?? '';
        if (uid.length === 0 || offerId.length === 0) return new Response('missing sid or oid', { status: 400 });
        const outcome = await grantAdReward(context.env.DB, uid, offerId);
        if (outcome.status === 'conflict') return new Response(outcome.code, { status: 409 });
        return new Response('1', { status: 200, headers: { 'content-type': 'text/plain' } });
      })
      .post('/v1/account/delete', (context) => authenticated(context, deps, async (identity) => json(await deleteAccount(context.env.DB, identity.uid))))
  );
}

async function authenticated(context: RouteContext, deps: Deps, handler: (identity: VerifiedIdentity) => Promise<Response>): Promise<Response> {
  let identity: VerifiedIdentity;
  try {
    identity = await deps.verifier(context.env).verifyRequest(context.request);
  } catch (error) {
    if (error instanceof TokenRejected) {
      if (error.code === 'missing_authorization') return authRequired();
      // Google's key endpoint unreachable is our problem, not the caller's.
      if (error.code === 'jwks_unavailable') return internalRetryable();
      return authInvalid(error.code);
    }
    throw error;
  }
  return handler(identity);
}

function outcomeResponse<T>(outcome: CommitOutcome<T>): Response {
  if (outcome.status === 'conflict') return problem({ status: 409, code: outcome.code });
  return json(outcome.response);
}

const app = createRouter({ verifier: verifierFor, purchaseVerifier: googlePlayVerifier });

export default {
  fetch: (request: Request, env: Env, ctx: ExecutionContext): Promise<Response> => app.handle(request, env, ctx),
};
