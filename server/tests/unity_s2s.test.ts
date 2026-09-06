import { env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';

import { grantAdReward, hmacMd5Hex, unitySignatureBase, unitySignatureValid } from '../src/ads/unity_s2s.js';
import { readWallet } from '../src/wallet/wallet_service.js';
import { resetDb } from './support/setup.js';

describe('unity signature', () => {
  it('matches the RFC 2202 HMAC-MD5 test vector', async () => {
    // RFC 2202 test case 2: key "Jefe", data "what do ya want for nothing?"
    expect(await hmacMd5Hex('Jefe', 'what do ya want for nothing?')).toBe('750c783e6ab0b503eaa86e310a5db738');
  });

  it('signs every parameter but hmac, sorted, comma-separated', () => {
    const query = new URLSearchParams({ oid: 'offer-1', hmac: 'zzz', sid: 'u1', product: 'hint' });
    expect(unitySignatureBase(query)).toBe('oid=offer-1,product=hint,sid=u1');
  });

  it('accepts a query signed with the configured secret and refuses anything else', async () => {
    const query = new URLSearchParams({ sid: 'u1', oid: 'offer-1' });
    query.set('hmac', await hmacMd5Hex('test-unity-secret', unitySignatureBase(query)));
    expect(await unitySignatureValid(env, query)).toBe(true);

    const forged = new URLSearchParams(query);
    forged.set('sid', 'u2');
    expect(await unitySignatureValid(env, forged)).toBe(false);

    const unsigned = new URLSearchParams({ sid: 'u1', oid: 'offer-1' });
    expect(await unitySignatureValid(env, unsigned)).toBe(false);

    expect(await unitySignatureValid({ ...env, UNITY_ADS_S2S_SECRET: '' }, query)).toBe(false);
  });
});

describe('ad reward', () => {
  beforeEach(resetDb);

  it('pays one hint per offer id, and a retry is paid nothing more', async () => {
    expect(await grantAdReward(env.DB, 'u1', 'offer-1')).toEqual({ status: 'committed', response: { hints: 1 } });
    expect(await grantAdReward(env.DB, 'u1', 'offer-1')).toEqual({ status: 'replayed', response: { hints: 1 } });
    expect(await grantAdReward(env.DB, 'u1', 'offer-2')).toEqual({ status: 'committed', response: { hints: 2 } });
    expect(await readWallet(env.DB, 'u1')).toEqual({ hints: 2 });
  });
});
