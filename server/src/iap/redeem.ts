import { answeredAlready, requestHash, type CommitOutcome, type OperationKey } from '../db/transaction.js';
import { creditHints } from '../wallet/wallet_service.js';
import type { PurchaseVerifier } from './google_play_verifier.js';
import { hintProduct } from './products.js';

/// Turning a real-money purchase into hints. The server decides how many
/// (products.ts) and the same receipt credits once (the purchase token is the
/// idempotency key — never an id the client chose).
export type RedeemRefusal = 'unknown_product' | 'product_mismatch' | 'not_purchased' | 'verification_unavailable';

export class RedeemRefused extends Error {
  constructor(
    readonly refusal: RedeemRefusal,
    detail: string,
  ) {
    super(detail);
    this.name = 'RedeemRefused';
  }
}

/// 503 is the only retryable one, and the state the feature sits in until the
/// service account exists.
export function redeemRefusalStatus(refusal: RedeemRefusal): number {
  switch (refusal) {
    case 'unknown_product':
    case 'product_mismatch':
      return 400;
    case 'not_purchased':
      return 409;
    case 'verification_unavailable':
      return 503;
  }
}

export interface RedeemRequest {
  readonly productId: string;
  readonly purchaseToken: string;
  readonly verifier: PurchaseVerifier;
}

export interface Redeemed {
  readonly productId: string;
  readonly granted: number;
  readonly hints: number;
}

export async function redeemGooglePurchase(db: D1Database, uid: string, request: RedeemRequest): Promise<CommitOutcome<Redeemed>> {
  const product = hintProduct(request.productId);
  if (product === undefined) throw new RedeemRefused('unknown_product', `no product ${request.productId}`);

  // Hashed: the token is long and is a credential of sorts.
  const key: OperationKey = {
    operationId: `google:${await requestHash(request.purchaseToken)}`,
    uid,
    kind: 'iap_redeem',
    requestHash: await requestHash(JSON.stringify({ productId: request.productId })),
  };
  // Before the verifier: a retry of a purchase already credited must not
  // depend on Google being reachable a second time.
  const answered = await answeredAlready<{ hints: number }>(db, key);
  if (answered !== null) return withProduct(answered, product.id, product.hints);

  const verification = await request.verifier.verify(request.productId, request.purchaseToken);
  if (verification === null) throw new RedeemRefused('verification_unavailable', 'the receipt could not be checked');
  if (verification.productId !== request.productId) throw new RedeemRefused('product_mismatch', `the receipt is for ${verification.productId}`);
  if (verification.purchaseState !== 'purchased') throw new RedeemRefused('not_purchased', `the purchase is ${verification.purchaseState}`);

  return withProduct(await creditHints(db, uid, key, product.hints, 'google_play'), product.id, product.hints);
}

function withProduct(outcome: CommitOutcome<{ hints: number }>, productId: string, granted: number): CommitOutcome<Redeemed> {
  if (outcome.status === 'conflict') return outcome;
  return { status: outcome.status, response: { productId, granted, hints: outcome.response.hints } };
}
