import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../crash/crash_reporter.dart';

/// Thin wrapper over in_app_purchase. The only file that imports the plugin.
/// Every purchased or restored item goes to [onPurchase]; whoever delivers
/// calls [finish] afterwards — never before, so a purchase the server could
/// not credit stays open and the store hands it back on the next start.
class IapService extends ChangeNotifier {
  IapService({InAppPurchase? store, required this.onPurchase})
    : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final Future<void> Function(PurchaseDetails purchase) onPurchase;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool available = false;
  final Map<String, ProductDetails> products = {};
  bool purchasePending = false;
  String? lastError;

  Future<void> init(Set<String> productIds) async {
    try {
      available = await _store.isAvailable();
    } catch (error) {
      // A target with no store plugin answers by throwing: no shelf, not a bug.
      debugPrint('[IAP] no store on this build: $error');
      available = false;
    }
    if (!available) {
      notifyListeners();
      return;
    }
    await _sub?.cancel();
    _sub = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) {
        lastError = '$error';
        CrashReporter.recordError(
          error,
          StackTrace.current,
          reason: 'IAP.purchaseStream',
        );
        notifyListeners();
      },
    );
    try {
      final response = await _store.queryProductDetails(productIds);
      products
        ..clear()
        ..addEntries(
          response.productDetails.map(
            (product) => MapEntry(product.id, product),
          ),
        );
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[IAP] the store does not know: ${response.notFoundIDs}');
      }
    } catch (error, stack) {
      CrashReporter.recordError(
        error,
        stack,
        reason: 'IAP.queryProductDetails',
      );
    }
    notifyListeners();
  }

  Future<void> buyNonConsumable(String productId) =>
      _buy(productId, consumable: false);

  Future<void> buyConsumable(String productId) =>
      _buy(productId, consumable: true);

  Future<void> _buy(String productId, {required bool consumable}) async {
    final product = products[productId];
    if (product == null) return;
    lastError = null;
    final param = PurchaseParam(productDetails: product);
    try {
      if (consumable) {
        // Consumed by finish() after the server credited it, never before.
        await _store.buyConsumable(purchaseParam: param, autoConsume: false);
      } else {
        await _store.buyNonConsumable(purchaseParam: param);
      }
    } catch (error, stack) {
      lastError = '$error';
      CrashReporter.recordError(error, stack, reason: 'IAP.buy');
      notifyListeners();
    }
  }

  Future<void> restore() async {
    try {
      await _store.restorePurchases();
    } catch (error, stack) {
      CrashReporter.recordError(error, stack, reason: 'IAP.restore');
    }
  }

  /// Closes a purchase with the store. A consumable on Android must be
  /// consumed, or the player can never buy it again; everything else is
  /// acknowledged with completePurchase.
  Future<void> finish(
    PurchaseDetails purchase, {
    required bool consumable,
  }) async {
    try {
      if (consumable && defaultTargetPlatform == TargetPlatform.android) {
        await _store
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
            .consumePurchase(purchase);
      } else if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    } catch (error, stack) {
      CrashReporter.recordError(error, stack, reason: 'IAP.finish');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchasePending = true;
        case PurchaseStatus.error:
          purchasePending = false;
          lastError = purchase.error?.message;
          await finish(purchase, consumable: false);
        case PurchaseStatus.canceled:
          purchasePending = false;
          await finish(purchase, consumable: false);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          purchasePending = false;
          await onPurchase(purchase);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
