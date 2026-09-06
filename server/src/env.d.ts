/// The Worker's bindings. Declared by hand, in the shape `wrangler types`
/// would generate (a `Cloudflare.Env` namespace interface plus a global
/// `Env` alias), so the Worker, the tests and the `cloudflare:test` harness —
/// whose `env` is typed `Cloudflare.Env` — all see one shape. A missing
/// secret is a typed `undefined`, never a runtime surprise.
declare namespace Cloudflare {
  interface Env {
    readonly DB: D1Database;
    readonly FIREBASE_PROJECT_ID: string;
    readonly ANDROID_PACKAGE_NAME: string;
    /// Whole JSON key of the Play Developer API service account (chapter 8).
    readonly GOOGLE_PLAY_SERVICE_ACCOUNT?: string;
    /// Comma-separated when Unity issues one per Game ID.
    readonly UNITY_ADS_S2S_SECRET?: string;
  }
}

// eslint-disable-next-line @typescript-eslint/no-empty-object-type
interface Env extends Cloudflare.Env {}
