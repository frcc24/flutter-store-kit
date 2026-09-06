import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:mini_sudoku/core/ads/ads_config.dart';
import 'package:mini_sudoku/core/ads/ads_service.dart';
import 'package:mini_sudoku/core/api/kit_api.dart';
import 'package:mini_sudoku/core/auth/anonymous_session.dart';
import 'package:mini_sudoku/core/iap/iap_service.dart';
import 'package:mini_sudoku/core/storage/local_store.dart';
import 'package:mini_sudoku/features/settings/settings_controller.dart';
import 'package:mini_sudoku/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalStore> freshStore([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalStore(await SharedPreferences.getInstance());
}

/// A store that is not there, which is what a test target has.
class NoStore implements InAppPurchase {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<String> countryCode() => throw UnsupportedError('no store');

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      throw UnsupportedError('no store');

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      throw UnsupportedError('no store');

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) => throw UnsupportedError('no store');

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      throw UnsupportedError('no store');

  @override
  Future<void> restorePurchases({String? applicationUserName}) =>
      throw UnsupportedError('no store');

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() =>
      throw UnsupportedError('no store');
}

/// Real store and settings; no Firebase, no server, no ads and no shop
/// unless given.
Future<Services> testServices({
  LocalStore? store,
  KitApi? api,
  AnonymousSession? session,
  AdsService? ads,
  IapService? iap,
}) async {
  final s = store ?? await freshStore();
  return Services(
    store: s,
    settings: SettingsController(s),
    session: session ?? AnonymousSession(),
    api: api,
    ads: ads ?? AdsService(config: const AdsConfig()),
    iap: iap ?? IapService(store: NoStore(), onPurchase: (_) async {}),
  );
}
