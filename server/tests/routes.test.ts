import { env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';

import { hmacMd5Hex, unitySignatureBase } from '../src/ads/unity_s2s.js';
import type { PurchaseVerification } from '../src/iap/google_play_verifier.js';
import { createRouter } from '../src/index.js';
import { localAuth } from './support/local_auth.js';
import { resetDb } from './support/setup.js';

const ctx = { waitUntil() {}, passThroughOnException() {} } as unknown as ExecutionContext;

async function app(verifierAnswer: PurchaseVerification | null = null) {
  const auth = await localAuth('test-project');
  const router = createRouter({ verifier: () => auth.verifier, purchaseVerifier: () => ({ verify: async () => verifierAnswer }) });
  const call = (path: string, init: RequestInit = {}) => router.handle(new Request(`https://api.test${path}`, init), env, ctx);
  const bearer = async (uid: string) => ({ authorization: `Bearer ${await auth.tokenFor(uid)}` });
  return { call, bearer };
}

describe('routes', () => {
  beforeEach(resetDb);

  it('refuses the wallet without a token and serves it with one', async () => {
    const { call, bearer } = await app();
    expect((await call('/v1/wallet')).status).toBe(401);
    const response = await call('/v1/wallet', { headers: await bearer('u1') });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ hints: 0 });
  });

  it('answers 404 and 405 apart', async () => {
    const { call, bearer } = await app();
    expect((await call('/v1/nothing')).status).toBe(404);
    expect((await call('/v1/wallet', { method: 'POST', headers: await bearer('u1') })).status).toBe(405);
  });

  it('spends a hint only when there is one', async () => {
    const { call, bearer } = await app();
    const headers = { ...(await bearer('u1')), 'content-type': 'application/json' };
    const refused = await call('/v1/hints/spend', { method: 'POST', headers, body: JSON.stringify({ operationId: 'op-1' }) });
    expect(refused.status).toBe(409);
    expect(((await refused.json()) as { code: string }).code).toBe('no_hints');
    expect((await call('/v1/hints/spend', { method: 'POST', headers, body: '{}' })).status).toBe(400);
  });

  it('pays the Unity callback only with a valid signature', async () => {
    const { call, bearer } = await app();
    const query = new URLSearchParams({ sid: 'u1', oid: 'offer-1' });
    expect((await call(`/v1/ads/unity/reward?${query}`)).status).toBe(403);

    query.set('hmac', await hmacMd5Hex('test-unity-secret', unitySignatureBase(query)));
    const paid = await call(`/v1/ads/unity/reward?${query}`);
    expect(paid.status).toBe(200);
    expect(await paid.text()).toBe('1');

    const wallet = await call('/v1/wallet', { headers: await bearer('u1') });
    expect(await wallet.json()).toEqual({ hints: 1 });

    const spend = await call('/v1/hints/spend', {
      method: 'POST',
      headers: { ...(await bearer('u1')), 'content-type': 'application/json' },
      body: JSON.stringify({ operationId: 'op-1' }),
    });
    expect(await spend.json()).toEqual({ hints: 0 });
  });

  it('redeems a purchase the verifier confirms and refuses what it cannot check', async () => {
    const confirmed = await app({ productId: 'hint_pack_5', purchaseState: 'purchased' });
    const headers = { ...(await confirmed.bearer('u1')), 'content-type': 'application/json' };
    const body = JSON.stringify({ productId: 'hint_pack_5', purchaseToken: 'tok' });
    const granted = await confirmed.call('/v1/iap/google/redeem', { method: 'POST', headers, body });
    expect(granted.status).toBe(200);
    expect(await granted.json()).toEqual({ productId: 'hint_pack_5', granted: 5, hints: 5 });

    const unavailable = await app(null);
    const refused = await unavailable.call('/v1/iap/google/redeem', {
      method: 'POST',
      headers: { ...(await unavailable.bearer('u2')), 'content-type': 'application/json' },
      body,
    });
    expect(refused.status).toBe(503);
  });

  it('deletes the account and answers a repeat as already gone', async () => {
    const { call, bearer } = await app();
    await call('/v1/wallet', { headers: await bearer('u1') });
    const first = await call('/v1/account/delete', { method: 'POST', headers: await bearer('u1') });
    expect(await first.json()).toEqual({ deleted: true });
    const second = await call('/v1/account/delete', { method: 'POST', headers: await bearer('u1') });
    expect(await second.json()).toEqual({ deleted: false });
    const rows = await env.DB.prepare('SELECT COUNT(*) AS n FROM wallets').first<{ n: number }>();
    expect(rows?.n).toBe(0);
  });
});
