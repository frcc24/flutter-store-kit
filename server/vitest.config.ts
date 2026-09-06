import path from 'node:path';

import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-pool-workers';
import { defineConfig } from 'vitest/config';

/// Tests run inside workerd, not Node: D1, Request/Response and WebCrypto are
/// the real ones (Miniflare provides them locally, no account involved). The
/// migration files that ship are the schema the tests run against.
export default defineConfig({
  test: {
    setupFiles: ['./tests/support/setup.ts'],
    // Every file shares one D1 database; run them one at a time.
    fileParallelism: false,
  },
  plugins: [
    cloudflareTest(async () => ({
      wrangler: { configPath: './wrangler.toml' },
      miniflare: {
        bindings: {
          TEST_MIGRATIONS: await readD1Migrations(path.join(import.meta.dirname, 'migrations')),
          FIREBASE_PROJECT_ID: 'test-project',
          ANDROID_PACKAGE_NAME: 'br.com.frcc24.mini_sudoku',
          // Obviously fake; nothing signed with it is accepted anywhere else.
          UNITY_ADS_S2S_SECRET: 'test-unity-secret',
        },
      },
    })),
  ],
});
