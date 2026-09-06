import { applyD1Migrations, env } from 'cloudflare:test';
import { beforeAll } from 'vitest';

/// Applies the shipped migrations once per run and gives every test file a
/// way to start from empty tables.
beforeAll(async () => {
  await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
});

export async function resetDb(): Promise<void> {
  // Children before parents: the ledger references the guards, which
  // reference the operations.
  await env.DB.batch([
    env.DB.prepare('DELETE FROM ledger'),
    env.DB.prepare('DELETE FROM operation_guards'),
    env.DB.prepare('DELETE FROM operations'),
    env.DB.prepare('DELETE FROM wallets'),
  ]);
}
