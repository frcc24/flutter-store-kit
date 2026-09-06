import '../../services.dart';

enum DeleteOutcome { done, unavailable }

/// Erases the player: Worker rows first (the ID token is what authorises
/// that call), then the Firebase user, then everything on the device. If the
/// server cannot confirm, nothing at all is deleted — a half-deleted account
/// is data left behind with nothing that can reach it any more.
Future<DeleteOutcome> deleteEverything(Services services) async {
  final api = services.api;
  if (api != null && await services.session.uid() != null) {
    if (!await api.deleteAccount()) return DeleteOutcome.unavailable;
  }
  await services.session.deleteUser();
  await services.store.clearAll();
  return DeleteOutcome.done;
}
