import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:mini_sudoku/core/api/kit_api.dart';
import 'package:mini_sudoku/core/iap/iap_service.dart';
import 'package:mini_sudoku/core/iap/products.dart';
import 'package:mini_sudoku/core/storage/local_store.dart';
import 'package:mini_sudoku/features/shop/purchase_deliveries.dart';

import 'support/test_services.dart';

/// The store, with every method the app calls recorded.
class FakeStore implements InAppPurchase {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  final bought = <String>[];
  var restored = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> countryCode() async => 'BR';

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: [
      for (final id in identifiers)
        ProductDetails(
          id: id,
          title: id,
          description: id,
          price: r'R$ 4,90',
          rawPrice: 4.9,
          currencyCode: 'BRL',
        ),
    ],
    notFoundIDs: const [],
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought.add(purchaseParam.productDetails.id);
    return true;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    expect(
      autoConsume,
      isFalse,
      reason: 'a consumable is consumed only after the server credited it',
    );
    bought.add(purchaseParam.productDetails.id);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);

  @override
  Future<void> restorePurchases({String? applicationUserName}) async =>
      restored++;

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() =>
      throw UnsupportedError('no platform in tests');
}

PurchaseDetails purchased(
  String productId, {
  PurchaseStatus status = PurchaseStatus.purchased,
}) => PurchaseDetails(
  purchaseID: 'p-$productId',
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'server-token',
    source: 'test',
  ),
  transactionDate: '0',
  status: status,
)..pendingCompletePurchase = true;

KitApi apiAnswering(int status, Object body) => KitApi(
  baseUrl: Uri.parse('https://api.test'),
  tokenProvider: () async => 'tok',
  client: MockClient(
    (_) async => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<
    ({
      FakeStore store,
      LocalStore local,
      IapService iap,
      PurchaseDeliveries deliveries,
    })
  >
  setup({KitApi? api}) async {
    final local = await freshStore();
    final fake = FakeStore();
    late PurchaseDeliveries deliveries;
    final iap = IapService(
      store: fake,
      onPurchase: (purchase) => deliveries.deliver(purchase),
    );
    deliveries = PurchaseDeliveries(store: local, api: api, finish: iap.finish);
    await iap.init(kitProductIds);
    addTearDown(iap.dispose);
    return (store: fake, local: local, iap: iap, deliveries: deliveries);
  }

  test('init loads the products and buying goes to the store', () async {
    final (:store, :iap, local: _, deliveries: _) = await setup();
    expect(iap.available, isTrue);
    expect(iap.products.keys, containsAll([removeAdsId, hintPack5Id]));
    await iap.buyNonConsumable(removeAdsId);
    await iap.buyConsumable(hintPack5Id);
    expect(store.bought, [removeAdsId, hintPack5Id]);
    await iap.restore();
    expect(store.restored, 1);
  });

  test('remove_ads sets adFree and completes the purchase', () async {
    final (:store, :local, :iap, :deliveries) = await setup();
    await deliveries.deliver(purchased(removeAdsId));
    expect(local.loadStats().adFree, isTrue);
    expect(store.completed, [removeAdsId]);
    expect(iap.lastError, isNull);
  });

  test('hint_pack_5 is credited only when the server grants it', () async {
    final granted = await setup(
      api: apiAnswering(200, {
        'productId': hintPack5Id,
        'granted': 5,
        'hints': 5,
      }),
    );
    await granted.deliveries.deliver(purchased(hintPack5Id));
    expect(granted.local.loadStats().hintBalance, 5);
    expect(granted.store.completed, [hintPack5Id]);

    final later = await setup(
      api: apiAnswering(503, {'code': 'verification_unavailable'}),
    );
    await later.deliveries.deliver(purchased(hintPack5Id));
    expect(
      later.store.completed,
      isEmpty,
      reason: 'left pending so the store re-delivers it next start',
    );

    final noServer = await setup();
    await noServer.deliveries.deliver(purchased(hintPack5Id));
    expect(noServer.store.completed, isEmpty);
  });

  test('a cancelled purchase is closed and delivers nothing', () async {
    final (:store, :iap, local: _, deliveries: _) = await setup();
    store.controller.add([
      purchased(removeAdsId, status: PurchaseStatus.canceled),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(store.completed, [removeAdsId]);
    expect(iap.purchasePending, isFalse);
  });
}
