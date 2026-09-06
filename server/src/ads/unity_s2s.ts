import { requestHash, type CommitOutcome, type OperationKey } from '../db/transaction.js';
import { creditHints, type WalletSnapshot } from '../wallet/wallet_service.js';

/// Paying a player for a finished rewarded ad.
///
/// **Unity credits, the client never does.** "The video finished", said by the
/// device, is worth nothing: a modified build says it in a loop. The only
/// statement worth paying on is Unity's own server-to-server callback, signed
/// with a secret the device does not hold.
///
/// Not self-serve: Unity enables the callback per Game ID through a support
/// ticket and hands back the secret. Until it is set, this refuses everything.
/// Spec: https://docs.unity.com/en-us/ads-unity/4.19.0/sdk-integration/s2s-redeem-callbacks

/// The exact string Unity signed: every parameter but `hmac`, `key=value`,
/// sorted, comma-separated. Values are the decoded ones, so the callback URL
/// registered with Unity must use plain ASCII parameters.
export function unitySignatureBase(query: URLSearchParams): string {
  return [...query.entries()]
    .filter(([key]) => key !== 'hmac')
    .map(([key, value]) => `${key}=${value}`)
    .sort()
    .join(',');
}

async function md5(bytes: Uint8Array): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest('MD5', bytes as BufferSource));
}

/// HMAC-MD5 by hand: the spec says MD5 and WebCrypto's `importKey` only takes
/// the SHA family for HMAC. Workers exposes MD5 through `digest` as an
/// extension, so RFC 2104 is written out. The RFC 2202 vector in the test is
/// what fails loudly if a runtime ever drops it.
export async function hmacMd5Hex(secret: string, message: string): Promise<string> {
  const blockSize = 64;
  const encoder = new TextEncoder();
  let key = encoder.encode(secret);
  if (key.length > blockSize) key = await md5(key);
  const padded = new Uint8Array(blockSize);
  padded.set(key);
  const messageBytes = encoder.encode(message);
  const inner = new Uint8Array(blockSize + messageBytes.length);
  const outer = new Uint8Array(blockSize + 16);
  for (let index = 0; index < blockSize; index++) {
    inner[index] = padded[index]! ^ 0x36;
    outer[index] = padded[index]! ^ 0x5c;
  }
  inner.set(messageBytes, blockSize);
  outer.set(await md5(inner), blockSize);
  return [...(await md5(outer))].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

/// Constant-time comparison so a forged signature cannot be refined byte by
/// byte from the response time.
function secureEquals(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let index = 0; index < a.length; index++) diff |= a.charCodeAt(index) ^ b.charCodeAt(index);
  return diff === 0;
}

/// Comma-separated when Unity issues one secret per Game ID (Android, iOS).
export function unitySecrets(env: Env): string[] {
  return String(env.UNITY_ADS_S2S_SECRET ?? '')
    .split(',')
    .map((secret) => secret.trim())
    .filter((secret) => secret.length > 0);
}

/// False when no secret is configured — "not set up yet" and "forged" deserve
/// the same answer to the caller, which is nothing.
export async function unitySignatureValid(env: Env, query: URLSearchParams): Promise<boolean> {
  const signature = query.get('hmac');
  if (signature === null) return false;
  const base = unitySignatureBase(query);
  for (const secret of unitySecrets(env)) {
    if (secureEquals(signature.toLowerCase(), await hmacMd5Hex(secret, base))) return true;
  }
  return false;
}

/// One hint per finished view. [offerId] is Unity's transaction id and the
/// idempotency key: Unity retries a callback it did not get a 200 for.
export async function grantAdReward(db: D1Database, uid: string, offerId: string): Promise<CommitOutcome<WalletSnapshot>> {
  const key: OperationKey = {
    operationId: `unity:${offerId}`,
    uid,
    kind: 'ad_reward',
    requestHash: await requestHash(JSON.stringify({ offerId })),
  };
  return creditHints(db, uid, key, 1, 'unity_ads');
}
