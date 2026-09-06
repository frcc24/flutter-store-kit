import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base URL of the Worker, given at build time:
/// `flutter run --dart-define=KIT_API_URL=https://mini-sudoku-api.<account>.workers.dev`
/// Empty means "no server": paid hints, ad rewards and the hint pack stay
/// hidden and the game keeps its one free hint per puzzle.
const kitApiUrl = String.fromEnvironment('KIT_API_URL');

sealed class SpendResult {
  const SpendResult();
}

final class SpendBalance extends SpendResult {
  const SpendBalance(this.hints);
  final int hints;
  @override
  bool operator ==(Object other) =>
      other is SpendBalance && other.hints == hints;
  @override
  int get hashCode => hints;
}

final class SpendNoHints extends SpendResult {
  const SpendNoHints();
}

final class SpendUnavailable extends SpendResult {
  const SpendUnavailable();
}

sealed class RedeemResult {
  const RedeemResult();
}

final class RedeemGranted extends RedeemResult {
  const RedeemGranted(this.hints);
  final int hints;
  @override
  bool operator ==(Object other) =>
      other is RedeemGranted && other.hints == hints;
  @override
  int get hashCode => hints;
}

final class RedeemRetryLater extends RedeemResult {
  const RedeemRetryLater();
}

final class RedeemRefusedResult extends RedeemResult {
  const RedeemRefusedResult(this.code);
  final String code;
  @override
  bool operator ==(Object other) =>
      other is RedeemRefusedResult && other.code == code;
  @override
  int get hashCode => code.hashCode;
}

/// The Worker's four routes. Never throws: no token, no network and a 5xx
/// all come back as the "unavailable" member of each result.
class KitApi {
  KitApi({
    required this.baseUrl,
    required this._tokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static KitApi? fromEnvironment(Future<String?> Function() tokenProvider) =>
      kitApiUrl.isEmpty
      ? null
      : KitApi(baseUrl: Uri.parse(kitApiUrl), tokenProvider: tokenProvider);

  final Uri baseUrl;
  final Future<String?> Function() _tokenProvider;
  final http.Client _client;
  final Duration timeout;

  Future<int?> wallet() async {
    final response = await _send('GET', '/v1/wallet');
    if (response == null || response.statusCode != 200) return null;
    return (_json(response)['hints'] as num?)?.toInt();
  }

  Future<SpendResult> spendHint(String operationId) async {
    final response = await _send(
      'POST',
      '/v1/hints/spend',
      body: {'operationId': operationId},
    );
    if (response == null) return const SpendUnavailable();
    final body = _json(response);
    if (response.statusCode == 200) {
      return SpendBalance((body['hints'] as num).toInt());
    }
    if (response.statusCode == 409 && body['code'] == 'no_hints') {
      return const SpendNoHints();
    }
    return const SpendUnavailable();
  }

  Future<RedeemResult> redeem({
    required String productId,
    required String purchaseToken,
  }) async {
    final response = await _send(
      'POST',
      '/v1/iap/google/redeem',
      body: {'productId': productId, 'purchaseToken': purchaseToken},
    );
    if (response == null || response.statusCode >= 500) {
      return const RedeemRetryLater();
    }
    final body = _json(response);
    if (response.statusCode == 200) {
      return RedeemGranted((body['hints'] as num).toInt());
    }
    return RedeemRefusedResult(
      body['code']?.toString() ?? 'http_${response.statusCode}',
    );
  }

  /// True when the server erased the account, or had nothing to erase.
  Future<bool> deleteAccount() async {
    final response = await _send('POST', '/v1/account/delete');
    return response != null && response.statusCode == 200;
  }

  Future<http.Response?> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final token = await _tokenProvider();
    if (token == null) return null;
    final request = http.Request(method, baseUrl.resolve(path))
      ..headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      // One timeout over the whole delivery, headers and body included.
      return await _deliver(request).timeout(timeout);
    } on TimeoutException {
      return null;
    } catch (error) {
      debugPrint('[KitApi] $method $path failed: $error');
      return null;
    }
  }

  Future<http.Response> _deliver(http.Request request) async =>
      http.Response.fromStream(await _client.send(request));

  static Map<String, Object?> _json(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map ? decoded.cast<String, Object?>() : const {};
    } catch (_) {
      return const {};
    }
  }
}
