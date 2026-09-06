import { answeredAlready, commitAtomic, requestHash, storageOperationId, type CommitOutcome, type OperationKey } from '../db/transaction.js';

/// The hint balance. Credits come from verified purchases and Unity's signed
/// callback; debits come from the app spending a paid hint. The client
/// mirrors the number this returns and never adds on its own.
export interface WalletSnapshot {
  readonly hints: number;
}

export class WalletRefused extends Error {
  constructor(
    readonly refusal: 'no_hints',
    detail: string,
  ) {
    super(detail);
    this.name = 'WalletRefused';
  }
}

interface WalletRow {
  readonly hints: number;
  readonly revision: number;
}

export async function ensureWallet(db: D1Database, uid: string): Promise<void> {
  const now = Math.floor(Date.now() / 1000);
  await db
    .prepare('INSERT OR IGNORE INTO wallets (firebase_uid, hints, revision, created_at, updated_at) VALUES (?, 0, 0, ?, ?)')
    .bind(uid, now, now)
    .run();
}

async function walletRow(db: D1Database, uid: string): Promise<WalletRow> {
  await ensureWallet(db, uid);
  const row = await db.prepare('SELECT hints, revision FROM wallets WHERE firebase_uid = ?').bind(uid).first<WalletRow>();
  if (row === null) throw new Error(`wallet ${uid} vanished between insert and select`);
  return row;
}

export async function readWallet(db: D1Database, uid: string): Promise<WalletSnapshot> {
  const row = await walletRow(db, uid);
  return { hints: row.hints };
}

async function move(db: D1Database, uid: string, key: OperationKey, delta: number, source: string): Promise<CommitOutcome<WalletSnapshot>> {
  const answered = await answeredAlready<WalletSnapshot>(db, key);
  if (answered !== null) return answered;

  const row = await walletRow(db, uid);
  if (row.hints + delta < 0) throw new WalletRefused('no_hints', `balance is ${row.hints}`);

  const now = Math.floor(Date.now() / 1000);
  return commitAtomic(
    db,
    key,
    [{ uid, expectedRevision: row.revision }],
    { hints: row.hints + delta },
    [
      db.prepare('UPDATE wallets SET hints = hints + ?, revision = revision + 1, updated_at = ? WHERE firebase_uid = ?').bind(delta, now, uid),
      db
        .prepare('INSERT INTO ledger (operation_id, firebase_uid, delta_hints, source, created_at) VALUES (?, ?, ?, ?, ?)')
        .bind(storageOperationId(key), uid, delta, source, now),
    ],
  );
}

/// [key] is chosen by the caller from something the client cannot forge: the
/// hash of a Play purchase token, Unity's offer id. Never a client-chosen id.
export function creditHints(db: D1Database, uid: string, key: OperationKey, delta: number, source: string): Promise<CommitOutcome<WalletSnapshot>> {
  if (delta <= 0) throw new Error('creditHints needs a positive delta');
  return move(db, uid, key, delta, source);
}

/// Here the client does choose the id (a spend is the client's own action)
/// and a retry with the same id answers the same balance.
export async function spendHint(db: D1Database, uid: string, operationId: string): Promise<CommitOutcome<WalletSnapshot>> {
  const key: OperationKey = { operationId, uid, kind: 'hint_spend', requestHash: await requestHash('{}') };
  return move(db, uid, key, -1, 'spend');
}
