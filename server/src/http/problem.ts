/// RFC 9457 problem responses. The client localizes `code`; `detail` is
/// diagnostic and never displayed. No body carries a token or a receipt.
export type ProblemCode =
  | 'auth_required'
  | 'auth_invalid'
  | 'not_found'
  | 'method_not_allowed'
  | 'invalid_request'
  | 'revision_conflict'
  | 'operation_id_reused'
  | 'no_hints'
  | 'unknown_product'
  | 'product_mismatch'
  | 'not_purchased'
  | 'verification_unavailable'
  | 'internal_retryable';

interface ProblemInit {
  readonly status: number;
  readonly code: ProblemCode;
  readonly detail?: string;
  readonly retryAfterSeconds?: number;
}

export function problem({ status, code, detail, retryAfterSeconds }: ProblemInit): Response {
  const headers = new Headers({ 'content-type': 'application/problem+json' });
  if (retryAfterSeconds !== undefined) headers.set('retry-after', String(retryAfterSeconds));
  return new Response(
    JSON.stringify({ type: `https://flutter-store-kit.invalid/problems/${code}`, title: code, status, code, ...(detail === undefined ? {} : { detail }) }),
    { status, headers },
  );
}

export const authRequired = (): Response => problem({ status: 401, code: 'auth_required' });
export const authInvalid = (detail: string): Response => problem({ status: 401, code: 'auth_invalid', detail });
export const notFound = (): Response => problem({ status: 404, code: 'not_found' });
export const methodNotAllowed = (): Response => problem({ status: 405, code: 'method_not_allowed' });
export const invalidRequest = (detail: string): Response => problem({ status: 400, code: 'invalid_request', detail });
export const internalRetryable = (): Response => problem({ status: 503, code: 'internal_retryable', retryAfterSeconds: 5 });

export function json(body: unknown, init?: ResponseInit): Response {
  const headers = new Headers(init?.headers);
  headers.set('content-type', 'application/json');
  return new Response(JSON.stringify(body), { ...init, headers });
}
