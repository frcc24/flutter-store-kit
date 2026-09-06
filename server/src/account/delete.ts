/// Erases everything the Worker holds about one player. Idempotent by
/// construction: a second call finds nothing and still succeeds — a retry
/// after a lost response must not tell the player their deletion failed.
///
/// The app deletes its Firebase user AFTER this returns: the ID token is what
/// authenticated the call, and a user deleted first leaves data behind with
/// nothing left that can authorise removing it.
export async function deleteAccount(db: D1Database, uid: string): Promise<{ deleted: boolean }> {
  const existing = await db.prepare('SELECT 1 AS present FROM wallets WHERE firebase_uid = ?').bind(uid).first<{ present: number }>();
  await db.batch([
    db.prepare('DELETE FROM ledger WHERE firebase_uid = ?').bind(uid),
    db.prepare('DELETE FROM operation_guards WHERE firebase_uid = ?').bind(uid),
    db.prepare('DELETE FROM operations WHERE firebase_uid = ?').bind(uid),
    db.prepare('DELETE FROM wallets WHERE firebase_uid = ?').bind(uid),
  ]);
  return { deleted: existing !== null };
}
