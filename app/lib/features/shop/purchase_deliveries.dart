import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/api/kit_api.dart';
import '../../core/iap/products.dart';
import '../../core/storage/local_store.dart';

/// What each product does once the store says it was bought. The hint pack
/// is credited by the Worker, which verifies the receipt with Google; the app
/// only mirrors the balance the server returns.
class PurchaseDeliveries {
  PurchaseDeliveries({
    required this.store,
    required this.api,
    required this.finish,
  });

  final LocalStore store;
  final KitApi? api;
  final Future<void> Function(
    PurchaseDetails purchase, {
    required bool consumable,
  })
  finish;

  Future<void> deliver(PurchaseDetails purchase) async {
    switch (purchase.productID) {
      case removeAdsId:
        await store.saveStats(store.loadStats().copyWith(adFree: true));
        await finish(purchase, consumable: false);
      case hintPack5Id:
        final api = this.api;
        // No server: nothing can verify the receipt. Left open on purpose;
        // the store re-delivers it on the next start.
        if (api == null) return;
        switch (await api.redeem(
          productId: hintPack5Id,
          purchaseToken: purchase.verificationData.serverVerificationData,
        )) {
          case RedeemGranted(:final hints):
            await store.saveStats(
              store.loadStats().copyWith(hintBalance: hints),
            );
            await finish(purchase, consumable: true);
          case RedeemRetryLater():
            return;
          case RedeemRefusedResult(:final code):
            debugPrint('[IAP] redeem refused: $code');
            // Google says it is not a paid purchase, or the ids disagree:
            // nothing to deliver, and leaving it open would loop forever.
            if (code != 'not_purchased') {
              await finish(purchase, consumable: true);
            }
        }
      default:
        debugPrint('[IAP] unknown product ${purchase.productID}');
        await finish(purchase, consumable: false);
    }
  }
}
