/// The one binding that exists only under test: the migration files
/// vitest.config.ts reads and hands to applyD1Migrations().
declare namespace Cloudflare {
  interface Env {
    readonly TEST_MIGRATIONS: import('cloudflare:test').D1Migration[];
  }
}
