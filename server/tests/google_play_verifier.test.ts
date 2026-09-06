import { describe, expect, it, vi } from 'vitest';

import { GooglePlayVerifier } from '../src/iap/google_play_verifier.js';

/// A throwaway RSA key: the class signs a real JWT assertion, so the OAuth
/// step is exercised with a real key or not at all.
async function testAccount() {
  const { privateKey } = (await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  )) as CryptoKeyPair;
  const pkcs8 = (await crypto.subtle.exportKey('pkcs8', privateKey)) as ArrayBuffer;
  const body = btoa(String.fromCharCode(...new Uint8Array(pkcs8)))
    .replace(/(.{64})/g, '$1\n')
    .trim();
  return {
    client_email: 'play-verifier@test.iam.gserviceaccount.com',
    private_key: `-----BEGIN PRIVATE KEY-----\n${body}\n-----END PRIVATE KEY-----\n`,
    token_uri: 'https://oauth2.test/token',
  };
}

function ok(body: unknown) {
  return new Response(JSON.stringify(body), { status: 200, headers: { 'content-type': 'application/json' } });
}

/// A Google that grants a token and then answers `purchase` for the lookup.
function stubGoogle(purchase: unknown, { acknowledge = 200, purchaseStatus = 200 } = {}) {
  return vi.fn(async (input: RequestInfo | URL) => {
    const url = String(input);
    if (url === 'https://oauth2.test/token') return ok({ access_token: 'granted', expires_in: 3600 });
    if (url.endsWith(':acknowledge')) return new Response('{}', { status: acknowledge });
    if (purchaseStatus !== 200) return new Response('{}', { status: purchaseStatus });
    return ok(purchase);
  }) as unknown as typeof fetch;
}

function calls(fetchImpl: typeof fetch): string[] {
  return (fetchImpl as unknown as { mock: { calls: unknown[][] } }).mock.calls.map((call) => String(call[0]));
}

const PACKAGE = 'br.com.frcc24.mini_sudoku';

describe('google play verifier', () => {
  it('reports a purchase, and acknowledges it first', async () => {
    const fetchImpl = stubGoogle({ purchaseState: 0, acknowledgementState: 0, orderId: 'GPA.1' });
    const verifier = new GooglePlayVerifier(await testAccount(), PACKAGE, fetchImpl);
    expect(await verifier.verify('hint_pack_5', 'token-1')).toEqual({ productId: 'hint_pack_5', purchaseState: 'purchased', orderId: 'GPA.1' });
    expect(calls(fetchImpl).some((url) => url.endsWith(':acknowledge'))).toBe(true);
    expect(calls(fetchImpl).some((url) => url.includes(`/applications/${PACKAGE}/purchases/products/hint_pack_5/tokens/token-1`))).toBe(true);
  });

  it('refuses to report a purchase it could not acknowledge', async () => {
    const verifier = new GooglePlayVerifier(await testAccount(), PACKAGE, stubGoogle({ purchaseState: 0, acknowledgementState: 0 }, { acknowledge: 500 }));
    expect(await verifier.verify('hint_pack_5', 'token-1')).toBeNull();
  });

  it('does not acknowledge twice', async () => {
    const fetchImpl = stubGoogle({ purchaseState: 0, acknowledgementState: 1 });
    const verifier = new GooglePlayVerifier(await testAccount(), PACKAGE, fetchImpl);
    expect((await verifier.verify('hint_pack_5', 'token-1'))?.purchaseState).toBe('purchased');
    expect(calls(fetchImpl).some((url) => url.endsWith(':acknowledge'))).toBe(false);
  });

  it('reports cancelled and pending as what they are', async () => {
    expect((await new GooglePlayVerifier(await testAccount(), PACKAGE, stubGoogle({ purchaseState: 1 })).verify('hint_pack_5', 't'))?.purchaseState).toBe('cancelled');
    expect((await new GooglePlayVerifier(await testAccount(), PACKAGE, stubGoogle({ purchaseState: 2 })).verify('hint_pack_5', 't'))?.purchaseState).toBe('pending');
  });

  it('answers null when Google does not know the token or is down', async () => {
    expect(await new GooglePlayVerifier(await testAccount(), PACKAGE, stubGoogle({}, { purchaseStatus: 404 })).verify('hint_pack_5', 't')).toBeNull();
    expect(await new GooglePlayVerifier(await testAccount(), PACKAGE, stubGoogle({}, { purchaseStatus: 503 })).verify('hint_pack_5', 't')).toBeNull();
  });
});
