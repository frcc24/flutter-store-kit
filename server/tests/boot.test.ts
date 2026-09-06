import { env, SELF } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';

describe('worker boots', () => {
  it('answers the health check', async () => {
    const response = await SELF.fetch('https://example.com/v1/health');
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ ok: true });
  });

  it('has the wallet schema', async () => {
    const tables = await env.DB.prepare("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name").all<{ name: string }>();
    const names = tables.results.map((row) => row.name);
    for (const expected of ['wallets', 'operations', 'operation_guards', 'ledger']) {
      expect(names).toContain(expected);
    }
  });
});
