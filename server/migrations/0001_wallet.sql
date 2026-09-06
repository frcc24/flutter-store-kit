-- The hint wallet, and the two tables that make every write to it atomic and
-- idempotent on D1, which has no interactive transaction: `batch()` rolls the
-- whole sequence back only when a statement FAILS, so
--   1. a duplicate must FAIL, not be skipped: `operations.operation_id` is the
--      primary key, and the idempotency insert is the first statement of every
--      batch;
--   2. a stale precondition must FAIL, not match zero rows: `operation_guards`
--      copies the wallet's revision inside the batch and a CHECK compares it
--      with the one the caller read.

CREATE TABLE wallets (
  firebase_uid TEXT PRIMARY KEY,
  hints INTEGER NOT NULL DEFAULT 0,
  revision INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK (hints >= 0)
);

CREATE TABLE operations (
  operation_id TEXT PRIMARY KEY,
  firebase_uid TEXT NOT NULL,
  kind TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_blob BLOB NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_operations_uid ON operations (firebase_uid, created_at);

CREATE TABLE operation_guards (
  operation_id TEXT NOT NULL REFERENCES operations (operation_id) ON DELETE CASCADE,
  firebase_uid TEXT NOT NULL,
  expected_revision INTEGER NOT NULL,
  observed_revision INTEGER NOT NULL,
  PRIMARY KEY (operation_id, firebase_uid),
  CHECK (expected_revision = observed_revision)
);

-- One row per hint movement. Referencing the guard means an entry cannot
-- exist without its precondition having held.
CREATE TABLE ledger (
  ledger_id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_id TEXT NOT NULL,
  firebase_uid TEXT NOT NULL,
  delta_hints INTEGER NOT NULL,
  source TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (operation_id, firebase_uid) REFERENCES operation_guards (operation_id, firebase_uid),
  UNIQUE (operation_id, firebase_uid)
);

CREATE INDEX idx_ledger_uid ON ledger (firebase_uid, created_at);
