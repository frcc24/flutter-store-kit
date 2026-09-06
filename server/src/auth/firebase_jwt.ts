import { createRemoteJWKSet, errors as joseErrors, jwtVerify, type JWTPayload, type JWTVerifyGetKey } from 'jose';

/// Google's published keys for Firebase ID tokens. `createRemoteJWKSet`
/// fetches and caches them and re-fetches on an unknown `kid`, which is what
/// makes key rotation a non-event here.
const FIREBASE_JWKS_URL = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

/// The verified identity behind a request. Nothing else is allowed to decide
/// who the caller is.
export interface VerifiedIdentity {
  readonly uid: string;
  readonly isAnonymous: boolean;
  readonly signInProvider: string;
  readonly expiresAtSeconds: number;
}

export class TokenRejected extends Error {
  constructor(readonly code: string) {
    super(code);
    this.name = 'TokenRejected';
  }
}

/// Verifies Firebase ID tokens. `jose` enforces signature, `alg`, `iss`,
/// `aud`, `exp`/`nbf`; the Firebase-specific rules are checked here.
///
/// Deliberately not hand-rolled: sixty lines of JWT parsing is sixty places to
/// get algorithm confusion or an unbound `kid` lookup wrong. Security code
/// takes the maintained library.
export class FirebaseJwtVerifier {
  private readonly jwks: JWTVerifyGetKey;
  private readonly issuer: string;

  constructor(
    private readonly projectId: string,
    keys?: JWTVerifyGetKey,
  ) {
    this.issuer = `https://securetoken.google.com/${projectId}`;
    this.jwks = keys ?? createRemoteJWKSet(new URL(FIREBASE_JWKS_URL));
  }

  async verifyRequest(request: Request): Promise<VerifiedIdentity> {
    const header = request.headers.get('authorization');
    if (header === null) throw new TokenRejected('missing_authorization');
    const [scheme, token] = header.split(' ');
    if (scheme?.toLowerCase() !== 'bearer' || token === undefined || token.length === 0) {
      throw new TokenRejected('malformed_authorization');
    }
    return this.verify(token);
  }

  async verify(token: string): Promise<VerifiedIdentity> {
    let payload: JWTPayload;
    try {
      ({ payload } = await jwtVerify(token, this.jwks, {
        issuer: this.issuer,
        audience: this.projectId,
        // Pinned: an unpinned algorithm list is how `alg: none` gets in.
        algorithms: ['RS256'],
        clockTolerance: '30s',
      }));
    } catch (error) {
      throw new TokenRejected(reasonFor(error));
    }

    const uid = payload.sub;
    if (typeof uid !== 'string' || uid.length === 0) throw new TokenRejected('missing_subject');
    const userId = payload['user_id'];
    if (typeof userId === 'string' && userId !== uid) throw new TokenRejected('subject_mismatch');

    const authTime = payload['auth_time'];
    if (typeof authTime === 'number' && authTime > Date.now() / 1000 + 30) {
      throw new TokenRejected('auth_time_in_future');
    }

    const firebase = payload['firebase'];
    const signInProvider =
      typeof firebase === 'object' && firebase !== null && 'sign_in_provider' in firebase
        ? String((firebase as { sign_in_provider: unknown }).sign_in_provider)
        : 'unknown';

    return {
      uid,
      isAnonymous: signInProvider === 'anonymous',
      signInProvider,
      expiresAtSeconds: typeof payload.exp === 'number' ? payload.exp : 0,
    };
  }
}

/// Maps a `jose` failure to a stable code. Never surfaces the library's
/// message: it can contain token fragments. `jwks_unavailable` means Google's
/// key endpoint could not be reached — a 503 to retry, never a 401.
function reasonFor(error: unknown): string {
  if (error instanceof joseErrors.JWKSTimeout) return 'jwks_unavailable';
  if (!(error instanceof joseErrors.JOSEError)) return 'jwks_unavailable';
  switch (error.code) {
    case 'ERR_JWT_EXPIRED':
      return 'expired';
    case 'ERR_JWT_CLAIM_VALIDATION_FAILED':
      return 'claim_rejected';
    case 'ERR_JWS_SIGNATURE_VERIFICATION_FAILED':
      return 'bad_signature';
    case 'ERR_JWKS_NO_MATCHING_KEY':
      return 'unknown_key';
    case 'ERR_JWS_INVALID':
    case 'ERR_JWT_INVALID':
      return 'malformed';
    default:
      return 'rejected';
  }
}

export function verifierFor(env: Env): FirebaseJwtVerifier {
  return new FirebaseJwtVerifier(env.FIREBASE_PROJECT_ID);
}
