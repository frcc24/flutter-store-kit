import { SignJWT, importPKCS8 } from 'jose';

/// Checking a Google Play receipt.
///
/// **Null is the only safe answer to a question this cannot answer.** No
/// credential, Google unreachable, a token Google does not recognise, an
/// acknowledgement that did not land — all return null, and the route turns
/// that into a 503 the client may retry. This is the one component whose
/// optimism would mint currency, so it has none.
export interface PurchaseVerification {
  readonly productId: string;
  readonly purchaseState: 'purchased' | 'pending' | 'cancelled';
  readonly orderId?: string;
}

export interface PurchaseVerifier {
  verify(productId: string, purchaseToken: string): Promise<PurchaseVerification | null>;
}

interface ServiceAccount {
  readonly client_email: string;
  readonly private_key: string;
  readonly token_uri?: string;
}

const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';
const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const TOKEN_EARLY_EXPIRY_MS = 60_000;

export function purchaseVerificationConfigured(env: Env): boolean {
  return typeof env.GOOGLE_PLAY_SERVICE_ACCOUNT === 'string' && env.GOOGLE_PLAY_SERVICE_ACCOUNT.length > 0;
}

/// Refuses everything, because it cannot check anything. Not a stub that says
/// "purchased": an unconfigured deployment that granted hints would be giving
/// them away.
class UnconfiguredVerifier implements PurchaseVerifier {
  async verify(): Promise<PurchaseVerification | null> {
    return null;
  }
}

export class GooglePlayVerifier implements PurchaseVerifier {
  constructor(
    private readonly account: ServiceAccount,
    private readonly packageName: string,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  private token: { value: string; expiresAtUnixMs: number } | null = null;

  async verify(productId: string, purchaseToken: string): Promise<PurchaseVerification | null> {
    const token = await this.accessToken();
    if (token === null) return null;

    // Looked up UNDER the product: a token that belongs to another product is
    // not found here, so a cheap receipt cannot buy an expensive one.
    const url = `${API}/applications/${encodeURIComponent(this.packageName)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

    let response: Response;
    try {
      response = await this.fetchImpl(url, { headers: { authorization: `Bearer ${token}` } });
    } catch (error) {
      console.error('play_verify_unreachable', String(error).slice(0, 120));
      return null;
    }
    if (!response.ok) {
      // 404 is a token Google does not know for this product (forged or
      // mismatched); anything else is Google having a bad day. Both are null.
      console.warn('play_verify_refused', response.status);
      return null;
    }

    const purchase = (await response.json()) as { purchaseState?: number; acknowledgementState?: number; orderId?: string };
    const orderId = purchase.orderId === undefined ? {} : { orderId: purchase.orderId };
    // productPurchases.purchaseState: 0 purchased, 1 cancelled, 2 pending.
    const state = purchase.purchaseState;
    if (state === 1) return { productId, purchaseState: 'cancelled', ...orderId };
    if (state === 2) return { productId, purchaseState: 'pending', ...orderId };
    if (state !== 0) {
      console.error('play_verify_unknown_state', String(state));
      return null;
    }

    // Acknowledged before it is reported, and reported only if that worked.
    // Google refunds an unacknowledged purchase after three days; crediting
    // and failing to acknowledge means the player keeps both.
    if (purchase.acknowledgementState === 0 && !(await this.acknowledge(url, token))) return null;

    return { productId, purchaseState: 'purchased', ...orderId };
  }

  private async acknowledge(purchaseUrl: string, token: string): Promise<boolean> {
    try {
      const response = await this.fetchImpl(`${purchaseUrl}:acknowledge`, {
        method: 'POST',
        headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
        body: '{}',
      });
      if (response.ok) return true;
      console.error('play_acknowledge_failed', response.status);
      return false;
    } catch (error) {
      console.error('play_acknowledge_failed', String(error).slice(0, 120));
      return false;
    }
  }

  /// The service account signs a JWT asserting who it is and what it wants,
  /// and Google trades that for a bearer token. Cached on the instance.
  private async accessToken(): Promise<string | null> {
    const cached = this.token;
    if (cached !== null && Date.now() < cached.expiresAtUnixMs) return cached.value;

    const tokenUri = this.account.token_uri ?? DEFAULT_TOKEN_URI;
    try {
      const key = await importPKCS8(this.account.private_key, 'RS256');
      const assertion = await new SignJWT({ scope: SCOPE })
        .setProtectedHeader({ alg: 'RS256' })
        .setIssuer(this.account.client_email)
        .setAudience(tokenUri)
        .setIssuedAt()
        .setExpirationTime('1h')
        .sign(key);

      const response = await this.fetchImpl(tokenUri, {
        method: 'POST',
        headers: { 'content-type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
      });
      if (!response.ok) {
        // Only the status: the body can quote the assertion.
        console.error('play_token_refused', response.status);
        return null;
      }
      const granted = (await response.json()) as { access_token?: string; expires_in?: number };
      if (typeof granted.access_token !== 'string') return null;
      this.token = { value: granted.access_token, expiresAtUnixMs: Date.now() + (granted.expires_in ?? 3600) * 1000 - TOKEN_EARLY_EXPIRY_MS };
      return granted.access_token;
    } catch (error) {
      console.error('play_token_failed', String(error).slice(0, 120));
      return null;
    }
  }
}

export function googlePlayVerifier(env: Env): PurchaseVerifier {
  if (!purchaseVerificationConfigured(env)) return new UnconfiguredVerifier();
  let account: ServiceAccount;
  try {
    account = JSON.parse(env.GOOGLE_PLAY_SERVICE_ACCOUNT!) as ServiceAccount;
  } catch {
    console.error('play_service_account_unparseable');
    return new UnconfiguredVerifier();
  }
  if (typeof account.client_email !== 'string' || typeof account.private_key !== 'string') {
    console.error('play_service_account_incomplete');
    return new UnconfiguredVerifier();
  }
  return new GooglePlayVerifier(account, env.ANDROID_PACKAGE_NAME);
}
