import { env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';

import { requestHash, type OperationKey } from '../src/db/transaction.js';
import { creditHints, readWallet, spendHint, WalletRefused } from '../src/wallet/wallet_service.js';
import { resetDb } from './support/setup.js';

async function key(operationId: string, uid: string, kind = 'test'): Promise<OperationKey> {
  return { operationId, uid, kind, requestHash: await requestHash('{}') };
}

describe('wallet', () => {
  beforeEach(resetDb);

  it('reads zero for a player it has never seen', async () => {
    expect(await readWallet(env.DB, 'new')).toEqual({ hints: 0 });
  });

  it('credits and reports the new balance', async () => {
    const outcome = await creditHints(env.DB, 'u1', await key('c1', 'u1'), 5, 'test');
    expect(outcome).toEqual({ status: 'committed', response: { hints: 5 } });
    expect(await readWallet(env.DB, 'u1')).toEqual({ hints: 5 });
    const rows = await env.DB.prepare('SELECT delta_hints, source FROM ledger WHERE firebase_uid = ?').bind('u1').all<{ delta_hints: number; source: string }>();
    expect(rows.results).toEqual([{ delta_hints: 5, source: 'test' }]);
  });

  it('credits the same operation once', async () => {
    const k = await key('c1', 'u1');
    await creditHints(env.DB, 'u1', k, 5, 'test');
    expect(await creditHints(env.DB, 'u1', k, 5, 'test')).toEqual({ status: 'replayed', response: { hints: 5 } });
    expect(await readWallet(env.DB, 'u1')).toEqual({ hints: 5 });
  });

  it('spends one hint per operation and replays a retry', async () => {
    await creditHints(env.DB, 'u1', await key('c1', 'u1'), 2, 'test');
    expect(await spendHint(env.DB, 'u1', 's1')).toEqual({ status: 'committed', response: { hints: 1 } });
    expect(await spendHint(env.DB, 'u1', 's1')).toEqual({ status: 'replayed', response: { hints: 1 } });
    expect(await spendHint(env.DB, 'u1', 's2')).toEqual({ status: 'committed', response: { hints: 0 } });
  });

  it('refuses to spend below zero', async () => {
    await expect(spendHint(env.DB, 'u1', 's1')).rejects.toBeInstanceOf(WalletRefused);
    expect(await readWallet(env.DB, 'u1')).toEqual({ hints: 0 });
  });
});
