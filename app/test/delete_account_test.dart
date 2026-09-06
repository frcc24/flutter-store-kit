import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_sudoku/core/api/kit_api.dart';
import 'package:mini_sudoku/core/auth/anonymous_session.dart';
import 'package:mini_sudoku/features/settings/delete_account.dart';
import 'package:mini_sudoku/features/stats/player_stats.dart';

import 'support/test_services.dart';

class FakeSession extends AnonymousSession {
  int deleted = 0;
  @override
  Future<String?> uid() async => 'u1';
  @override
  Future<String?> idToken({bool forceRefresh = false}) async => 'tok';
  @override
  Future<void> deleteUser() async => deleted++;
}

KitApi apiAnswering(int status) => KitApi(
  baseUrl: Uri.parse('https://api.test'),
  tokenProvider: () async => 'tok',
  client: MockClient(
    (_) async => http.Response(
      jsonEncode({'deleted': true}),
      status,
      headers: {'content-type': 'application/json'},
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('without a server the local data is wiped', () async {
    final store = await freshStore();
    await store.saveStats(const PlayerStats(completedGames: 7));
    final services = await testServices(store: store);
    expect(await deleteEverything(services), DeleteOutcome.done);
    expect(store.loadStats().completedGames, 0);
  });

  test('server first, then the Firebase user, then local data', () async {
    final store = await freshStore();
    await store.saveStats(const PlayerStats(completedGames: 7));
    final session = FakeSession();
    final services = await testServices(
      store: store,
      api: apiAnswering(200),
      session: session,
    );
    expect(await deleteEverything(services), DeleteOutcome.done);
    expect(session.deleted, 1);
    expect(store.loadStats().completedGames, 0);
  });

  test('when the server cannot confirm, nothing is deleted', () async {
    final store = await freshStore();
    await store.saveStats(const PlayerStats(completedGames: 7));
    final session = FakeSession();
    final services = await testServices(
      store: store,
      api: apiAnswering(503),
      session: session,
    );
    expect(await deleteEverything(services), DeleteOutcome.unavailable);
    expect(session.deleted, 0);
    expect(store.loadStats().completedGames, 7);
  });
}
