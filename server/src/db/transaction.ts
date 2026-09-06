/// Atomic, idempotent mutations on D1.
///
/// D1 offers no interactive transaction. `batch()` is the only atom: it runs
/// the statements in order and rolls the whole sequence back if one FAILS. Two
/// traps follow, and this module exists to close both.
///
/// Trap 1 — a duplicate that does not fail. Checking "did I already do this?"
/// in a separate round trip loses the race: two concurrent retries both read
/// "no" and both pay. So the idempotency insert is the FIRST statement of the
/// batch itself; the second attempt violates the primary key, aborts its own
/// batch, and is answered from the stored response.
///
/// Trap 2 — a precondition that matches zero rows. `UPDATE ... WHERE revision
/// = ?` matching nothing is a successful statement; the rest of the batch
/// would commit around it. `operation_guards` turns a stale revision into a
/// CHECK violation, which fails.
export interface OperationKey {
  readonly operationId: string;
  readonly uid: string;
  readonly kind: string;
  readonly requestHash: string;
}

export interface RevisionGuard {
  readonly uid: string;
  readonly expectedRevision: number;
}

export type ConflictCode = 'revision_conflict' | 'operation_id_reused';

export type CommitOutcome<T> =
  | { readonly status: 'committed'; readonly response: T }
  | { readonly status: 'replayed'; readonly response: T }
  | { readonly status: 'conflict'; readonly code: ConflictCode };

function isConstraintViolation(error: unknown): boolean {
  return String(error).toUpperCase().includes('CONSTRAINT');
}

/// `kind` is never client-supplied, so folding it into the stored id makes a
/// cross-kind collision structurally impossible. Every ledger row must be
/// built with this same function.
export function storageOperationId(key: Pick<OperationKey, 'operationId' | 'kind'>): string {
  return `${key.kind}:${key.operationId}`;
}

export async function commitAtomic<T>(
  db: D1Database,
  key: OperationKey,
  guards: readonly RevisionGuard[],
  response: T,
  mutations: readonly D1PreparedStatement[],
): Promise<CommitOutcome<T>> {
  const now = Math.floor(Date.now() / 1000);
  const encoded = new TextEncoder().encode(JSON.stringify(response));
  const storageId = storageOperationId(key);

  const statements: D1PreparedStatement[] = [
    db
      .prepare('INSERT INTO operations (operation_id, firebase_uid, kind, request_hash, response_blob, created_at) VALUES (?, ?, ?, ?, ?, ?)')
      .bind(storageId, key.uid, key.kind, key.requestHash, encoded, now),
    ...guards.map((guard) =>
      db
        .prepare(
          `INSERT INTO operation_guards (operation_id, firebase_uid, expected_revision, observed_revision)
           SELECT ?, ?, ?, revision FROM wallets WHERE firebase_uid = ?`,
        )
        .bind(storageId, guard.uid, guard.expectedRevision, guard.uid),
    ),
    ...mutations,
  ];

  try {
    await db.batch(statements);
    return { status: 'committed', response };
  } catch (error) {
    if (!isConstraintViolation(error)) throw error;
    // Which constraint fired is decided by reading the database, not by
    // parsing the message. The batch is atomic: if the operation row is there,
    // this attempt was a duplicate; if not, nothing was written.
    const stored = await replayOf<T>(db, key);
    if (stored === 'hash_mismatch') return { status: 'conflict', code: 'operation_id_reused' };
    if (stored !== null) return { status: 'replayed', response: stored };
    return { status: 'conflict', code: 'revision_conflict' };
  }
}

async function replayOf<T>(db: D1Database, key: OperationKey): Promise<T | 'hash_mismatch' | null> {
  const row = await db
    .prepare('SELECT request_hash, response_blob FROM operations WHERE operation_id = ? AND firebase_uid = ?')
    .bind(storageOperationId(key), key.uid)
    .first<{ request_hash: string; response_blob: ArrayBuffer | number[] }>();
  if (row === null) return null;
  if (row.request_hash !== key.requestHash) return 'hash_mismatch';
  const bytes = Array.isArray(row.response_blob) ? new Uint8Array(row.response_blob) : new Uint8Array(row.response_blob);
  return JSON.parse(new TextDecoder().decode(bytes)) as T;
}

/// Call this BEFORE judging any precondition: the retry of a purchase already
/// credited must be answered from its receipt, not refused because the
/// balance it created is now "wrong".
export async function answeredAlready<T>(db: D1Database, key: OperationKey): Promise<CommitOutcome<T> | null> {
  const stored = await replayOf<T>(db, key);
  if (stored === null) return null;
  if (stored === 'hash_mismatch') return { status: 'conflict', code: 'operation_id_reused' };
  return { status: 'replayed', response: stored };
}

/// SHA-256 hex of a canonical (sorted, whitespace-free) serialization.
export async function requestHash(canonicalPayload: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(canonicalPayload));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}
