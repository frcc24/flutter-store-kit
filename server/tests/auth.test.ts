import { describe, expect, it } from 'vitest';

import { TokenRejected } from '../src/auth/firebase_jwt.js';
import { localAuth } from './support/local_auth.js';

function withBearer(token: string | null): Request {
  return new Request('https://example.com/v1/wallet', token === null ? {} : { headers: { authorization: `Bearer ${token}` } });
}

async function rejection(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof TokenRejected) return error.code;
    throw error;
  }
  throw new Error('expected a rejection');
}

describe('firebase id tokens', () => {
  it('accepts a token signed by a trusted key', async () => {
    const { verifier, tokenFor } = await localAuth();
    const identity = await verifier.verifyRequest(withBearer(await tokenFor('u1')));
    expect(identity.uid).toBe('u1');
    expect(identity.isAnonymous).toBe(true);
  });

  it('rejects a missing or malformed header without touching the network', async () => {
    const { verifier } = await localAuth();
    expect(await rejection(verifier.verifyRequest(withBearer(null)))).toBe('missing_authorization');
    expect(await rejection(verifier.verifyRequest(new Request('https://example.com', { headers: { authorization: 'Basic abc' } })))).toBe(
      'malformed_authorization',
    );
    expect(await rejection(verifier.verify('not-a-jwt'))).toBe('malformed');
  });

  it('rejects the wrong audience, a foreign subject and an expired token', async () => {
    const { verifier, tokenFor } = await localAuth();
    expect(await rejection(verifier.verify(await tokenFor('u1', { audience: 'other-project' })))).toBe('claim_rejected');
    expect(await rejection(verifier.verify(await tokenFor('u1', { user_id: 'u2' })))).toBe('subject_mismatch');
    expect(await rejection(verifier.verify(await tokenFor('u1', { exp: Math.floor(Date.now() / 1000) - 120 })))).toBe('expired');
  });

  it('rejects a token signed by another key', async () => {
    const { verifier } = await localAuth();
    const other = await localAuth();
    expect(await rejection(verifier.verify(await other.tokenFor('u1')))).toBe('bad_signature');
  });
});
