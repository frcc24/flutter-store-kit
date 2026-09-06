import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_sudoku/core/api/kit_api.dart';

void main() {
  final requests = <http.BaseRequest>[];

  KitApi api(
    Future<http.Response> Function(http.Request request) answer, {
    String? token = 'tok',
  }) {
    requests.clear();
    return KitApi(
      baseUrl: Uri.parse('https://api.test'),
      tokenProvider: () async => token,
      client: MockClient((request) {
        requests.add(request);
        return answer(request);
      }),
    );
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  test('wallet sends the bearer token and reads hints', () async {
    final hints = await api((_) async => json({'hints': 3})).wallet();
    expect(hints, 3);
    expect(requests.single.headers['authorization'], 'Bearer tok');
    expect(requests.single.url.path, '/v1/wallet');
  });

  test('without a token nothing is sent', () async {
    expect(
      await api((_) async => json({'hints': 3}), token: null).wallet(),
      isNull,
    );
    expect(requests, isEmpty);
  });

  test('spend maps balance, no_hints and failures', () async {
    expect(
      await api((_) async => json({'hints': 1})).spendHint('op'),
      const SpendBalance(1),
    );
    expect(
      await api((_) async => json({'code': 'no_hints'}, 409)).spendHint('op'),
      const SpendNoHints(),
    );
    expect(
      await api(
        (_) async => throw http.ClientException('offline'),
      ).spendHint('op'),
      const SpendUnavailable(),
    );
    expect(
      await api(
        (_) async => json({'code': 'internal_retryable'}, 503),
      ).spendHint('op'),
      const SpendUnavailable(),
    );
    expect(jsonDecode((requests.single as http.Request).body), {
      'operationId': 'op',
    });
  });

  test('redeem maps granted, retry later and refusals', () async {
    expect(
      await api(
        (_) async =>
            json({'productId': 'hint_pack_5', 'granted': 5, 'hints': 5}),
      ).redeem(productId: 'hint_pack_5', purchaseToken: 't'),
      const RedeemGranted(5),
    );
    expect(
      await api(
        (_) async => json({'code': 'verification_unavailable'}, 503),
      ).redeem(productId: 'hint_pack_5', purchaseToken: 't'),
      const RedeemRetryLater(),
    );
    expect(
      await api(
        (_) async => throw http.ClientException('offline'),
      ).redeem(productId: 'hint_pack_5', purchaseToken: 't'),
      const RedeemRetryLater(),
    );
    expect(
      await api(
        (_) async => json({'code': 'product_mismatch'}, 400),
      ).redeem(productId: 'hint_pack_5', purchaseToken: 't'),
      const RedeemRefusedResult('product_mismatch'),
    );
  });

  test('deleteAccount is true only on 200', () async {
    expect(
      await api((_) async => json({'deleted': true})).deleteAccount(),
      isTrue,
    );
    expect(await api((_) async => json({}, 503)).deleteAccount(), isFalse);
  });

  test('fromEnvironment is null when KIT_API_URL is empty', () {
    expect(KitApi.fromEnvironment(() async => null), isNull);
  });
}
