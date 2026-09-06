import { env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';

import type { PurchaseVerification, PurchaseVerifier } from '../src/iap/google_play_verifier.js';
import { redeemGooglePurchase, RedeemRefused } from '../src/iap/redeem.js';
import { readWallet } from '../src/wallet/wallet_service.js';
import { resetDb } from './support/setup.js';

function verifierSaying(answer: PurchaseVerification | null): PurchaseVerifier {
  return { verify: async () => answer };
}

describe('redeem a Google Play purchase', () => {
  beforeEach(resetDb);

  it('credits the product once per purchase token', async () => {
    const verifier = verifierSaying({ productId: 'hint_pack_5', purchaseState: 'purchased' });
    const first = await redeemGooglePurchase(env.DB, 'u1', { productId: 'hint_pack_5', purchaseToken: 'tok', verifier });
    expect(first).toEqual({ status: 'committed', response: { productId: 'hint_pack_5', granted: 5, hints: 5 } });

    const again = await redeemGooglePurchase(env.DB, 'u1', { productId: 'hint_pack_5', purchaseToken: 'tok', verifier });
    expect(again.status).toBe('replayed');
    expect(await readWallet(env.DB, 'u1')).toEqual({ hints: 5 });
  });

  it('refuses what it cannot verify, and credits nothing', async () => {
    await expect(redeemGooglePurchase(env.DB, 'u1', { productId: 'hint_pack_5', purchaseToken: 'tok', verifier: verifierSaying(null) })).rejects.toMatchObject({
      refusal: 'verification_unavailable',
    });
    expect(await readWallet(env.DB, 'u1')).toEqual({ hints: 0 });
  });

  it('refuses an unknown product, a mismatched receipt and an unpaid purchase', async () => {
    await expect(redeemGooglePurchase(env.DB, 'u1', { productId: 'gems_9000', purchaseToken: 'tok', verifier: verifierSaying(null) })).rejects.toMatchObject({
      refusal: 'unknown_product',
    });
    await expect(
      redeemGooglePurchase(env.DB, 'u1', { productId: 'hint_pack_5', purchaseToken: 'tok', verifier: verifierSaying({ productId: 'other', purchaseState: 'purchased' }) }),
    ).rejects.toMatchObject({ refusal: 'product_mismatch' });
    await expect(
      redeemGooglePurchase(env.DB, 'u1', { productId: 'hint_pack_5', purchaseToken: 'tok', verifier: verifierSaying({ productId: 'hint_pack_5', purchaseState: 'pending' }) }),
    ).rejects.toBeInstanceOf(RedeemRefused);
    expect(await readWallet(env.DB, 'u1')).toEqual({ hints: 0 });
  });

  it('answers a retry from the receipt even when the verifier is down', async () => {
    const good = verifierSaying({ productId: 'hint_pack_5', purchaseState: 'purchased' });
    await redeemGooglePurchase(env.DB, 'u1', { productId: 'hint_pack_5', purchaseToken: 'tok', verifier: good });
    const retry = await redeemGooglePurchase(env.DB, 'u1', { productId: 'hint_pack_5', purchaseToken: 'tok', verifier: verifierSaying(null) });
    expect(retry).toEqual({ status: 'replayed', response: { productId: 'hint_pack_5', granted: 5, hints: 5 } });
  });
});
