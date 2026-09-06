import { createLocalJWKSet, exportJWK, SignJWT, type JWTPayload } from 'jose';

import { FirebaseJwtVerifier } from '../../src/auth/firebase_jwt.js';

/// A throwaway RSA key and a verifier that trusts only it. Tokens signed here
/// look exactly like Firebase's (issuer, audience, sub = user_id, auth_time)
/// so the verifier's real rules run against real signatures, offline.
export async function localAuth(projectId = 'test-project') {
  const { privateKey, publicKey } = (await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  )) as CryptoKeyPair;
  const jwk = { ...(await exportJWK(publicKey)), kid: 'local-1', alg: 'RS256', use: 'sig' };
  const verifier = new FirebaseJwtVerifier(projectId, createLocalJWKSet({ keys: [jwk] }));

  async function tokenFor(uid: string, overrides: JWTPayload & { audience?: string; issuer?: string } = {}): Promise<string> {
    const { audience, issuer, ...claims } = overrides;
    const now = Math.floor(Date.now() / 1000);
    const jwt = new SignJWT({ user_id: uid, auth_time: now - 5, firebase: { sign_in_provider: 'anonymous' }, ...claims })
      .setProtectedHeader({ alg: 'RS256', kid: 'local-1' })
      .setIssuer(issuer ?? `https://securetoken.google.com/${projectId}`)
      .setAudience(audience ?? projectId)
      .setSubject(uid)
      .setIssuedAt(now - 5);
    // The setters win over the payload, so an `exp` override must skip the
    // default expiry or the "expired token" case silently tests a valid one.
    return (claims.exp === undefined ? jwt.setExpirationTime(now + 3600) : jwt).sign(privateKey);
  }

  return { verifier, tokenFor };
}
