import { env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';

import { answeredAlready, commitAtomic, requestHash, storageOperationId, type OperationKey } from '../src/db/transaction.js';
import { resetDb } from './support/setup.js';

async function seedWallet(uid: string, hints: number, revision: number) {
  await env.DB.prepare('INSERT INTO wallets (firebase_uid, hints, revision, created_at, updated_at) VALUES (?, ?, ?, 0, 0)')
    .bind(uid, hints, revision)
    .run();
}

function creditStatements(uid: string, key: OperationKey, delta: number) {
  return [
    env.DB.prepare('UPDATE wallets SET hints = hints + ?, revision = revision + 1, updated_at = 1 WHERE firebase_uid = ?').bind(delta, uid),
    env.DB.prepare('INSERT INTO ledger (operation_id, firebase_uid, delta_hints, source, created_at) VALUES (?, ?, ?, ?, 1)').bind(
      storageOperationId(key),
      uid,
      delta,
      'test',
    ),
  ];
}

describe('commitAtomic', () => {
  beforeEach(resetDb);

  it('commits the mutations with the idempotency record and the guard', async () => {
    await seedWallet('u1', 0, 0);
    const key: OperationKey = { operationId: 'op-1', uid: 'u1', kind: 'test', requestHash: await requestHash('{}') };

    const outcome = await commitAtomic(env.DB, key, [{ uid: 'u1', expectedRevision: 0 }], { hints: 5 }, creditStatements('u1', key, 5));

    expect(outcome).toEqual({ status: 'committed', response: { hints: 5 } });
    const wallet = await env.DB.prepare('SELECT hints, revision FROM wallets WHERE firebase_uid = ?').bind('u1').first<{ hints: number; revision: number }>();
    expect(wallet).toEqual({ hints: 5, revision: 1 });
  });

  it('replays the stored response instead of paying twice', async () => {
    await seedWallet('u1', 0, 0);
    const key: OperationKey = { operationId: 'op-1', uid: 'u1', kind: 'test', requestHash: await requestHash('{}') };
    await commitAtomic(env.DB, key, [{ uid: 'u1', expectedRevision: 0 }], { hints: 5 }, creditStatements('u1', key, 5));

    const again = await commitAtomic(env.DB, key, [{ uid: 'u1', expectedRevision: 1 }], { hints: 999 }, creditStatements('u1', key, 5));

    expect(again).toEqual({ status: 'replayed', response: { hints: 5 } });
    const wallet = await env.DB.prepare('SELECT hints FROM wallets WHERE firebase_uid = ?').bind('u1').first<{ hints: number }>();
    expect(wallet?.hints).toBe(5);
    expect(await answeredAlready(env.DB, key)).toEqual({ status: 'replayed', response: { hints: 5 } });
  });

  it('rejects the same id with a different request', async () => {
    await seedWallet('u1', 0, 0);
    const key: OperationKey = { operationId: 'op-1', uid: 'u1', kind: 'test', requestHash: await requestHash('{"a":1}') };
    await commitAtomic(env.DB, key, [{ uid: 'u1', expectedRevision: 0 }], { hints: 5 }, creditStatements('u1', key, 5));

    const other = { ...key, requestHash: await requestHash('{"a":2}') };
    expect(await commitAtomic(env.DB, other, [{ uid: 'u1', expectedRevision: 1 }], { hints: 5 }, creditStatements('u1', other, 5))).toEqual({
      status: 'conflict',
      code: 'operation_id_reused',
    });
  });

  it('writes nothing when the revision moved', async () => {
    await seedWallet('u1', 0, 3);
    const key: OperationKey = { operationId: 'op-2', uid: 'u1', kind: 'test', requestHash: await requestHash('{}') };

    const outcome = await commitAtomic(env.DB, key, [{ uid: 'u1', expectedRevision: 2 }], { hints: 5 }, creditStatements('u1', key, 5));

    expect(outcome).toEqual({ status: 'conflict', code: 'revision_conflict' });
    const wallet = await env.DB.prepare('SELECT hints FROM wallets WHERE firebase_uid = ?').bind('u1').first<{ hints: number }>();
    expect(wallet?.hints).toBe(0);
    const ops = await env.DB.prepare('SELECT COUNT(*) AS n FROM operations').first<{ n: number }>();
    expect(ops?.n).toBe(0);
  });

  it('writes nothing when the wallet does not exist', async () => {
    const key: OperationKey = { operationId: 'op-3', uid: 'ghost', kind: 'test', requestHash: await requestHash('{}') };
    const outcome = await commitAtomic(env.DB, key, [{ uid: 'ghost', expectedRevision: 0 }], { hints: 1 }, creditStatements('ghost', key, 1));
    expect(outcome).toEqual({ status: 'conflict', code: 'revision_conflict' });
  });
});
