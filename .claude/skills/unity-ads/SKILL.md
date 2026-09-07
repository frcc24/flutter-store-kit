---
name: unity-ads
description: Set up and debug Unity Ads in this app — Game IDs and placements in app/lib/core/ads/ads_config.dart, the consent dialog before init, test mode in debug builds, iOS ATT, the rewarded ad that pays a hint through the Worker, and the server-to-server callback secret. Use when ads do not show, a reward does not arrive, or the user is wiring their own Unity project.
---

# Unity Ads: rewarded hint and interstitial

## When to use
Wiring a new Unity project, an ad that never loads, a reward that never
credits, or the consent switch behaving oddly.

## Inputs
- Unity dashboard (dashboard.unity3d.com) → Monetization → your project:
  Game IDs for Android and iOS; placement ids (the defaults are
  `Rewarded_Android`, `Interstitial_Android`, `Rewarded_iOS`,
  `Interstitial_iOS`).
- For the reward: the deployed Worker URL and the S2S secret Unity issues.

## Steps
1. Put the ids in `app/lib/core/ads/ads_config.dart`:
   `const kitAds = AdsConfig(androidGameId: '1234567', iosGameId: '1234568');`
   Empty ids mean "no ads", which is how the kit ships.
2. Consent: `HomeScreen._bootServices` asks once with
   `showAdsConsentDialog` and stores the answer (`LocalStore.saveAdsConsent`);
   `AdsService.init(consent:)` sets GDPR and CCPA consent **before**
   `UnityAds.init`. Settings has the switch. Do not move init before the
   dialog.
3. Test mode is `kDebugMode`: debug builds show Unity's test ads, release
   builds show real ones. Never click real ads on your own device — Unity
   bans the account.
4. iOS: `NSUserTrackingUsageDescription` and `SKAdNetworkItems`
   (`4dzt52r2t5.skadnetwork`) are already in `ios/Runner/Info.plist`;
   `AdsService.init` requests ATT first.
5. Rewarded flow: `showHintOffer` → `AdsService.showRewarded(serverId: uid)`
   → Unity calls `GET https://<worker>/v1/ads/unity/reward?sid=<uid>&oid=…&hmac=…`
   → the Worker credits one hint → the app polls `GET /v1/wallet` four times
   (800 ms apart) and applies the hint. The app never adds the hint itself.
6. S2S callback: open a ticket with Unity support asking to enable the
   "server-to-server redeem callback" for each Game ID, with the callback
   URL above. They answer with a secret per Game ID. Then:
   ```bash
   cd server && npx wrangler secret put UNITY_ADS_S2S_SECRET   # comma-separate two secrets
   ```
7. Prove the callback without an ad. Sign a query with the secret and call
   the Worker (HMAC-MD5 over `key=value` pairs sorted, comma-separated,
   without `hmac`):
   ```bash
   SECRET='the-secret'; BASE='oid=test-1,sid=<a real uid>'
   HMAC=$(node -e "console.log(require('crypto').createHmac('md5',process.argv[1]).update(process.argv[2]).digest('hex'))" "$SECRET" "$BASE")
   curl "https://<worker>/v1/ads/unity/reward?oid=test-1&sid=<uid>&hmac=$HMAC"   # prints 1
   ```
   Then `GET /v1/wallet` with that user's token shows `hints: 1`. A second
   call with the same `oid` prints `1` again and credits nothing (replay).

## Verify
- `flutter run` on a phone: the consent dialog appears once; "Out of hints"
  offers "Watch an ad"; a test ad plays; the hint appears within seconds.
- `npx wrangler tail` while the ad finishes shows the `/v1/ads/unity/reward`
  request answering 200.

## Pitfalls
- Without the secret the Worker answers 403 to everything, including real
  callbacks; the player sees "on its way" forever. Set the secret before
  shipping ads.
- `serverId` must be the uid the Worker authenticates; Unity echoes it as
  `sid`. A build that passes anything else pays the wrong wallet or none.
- Test ads do fire the S2S callback in Unity's test mode only if the
  placement is configured for it; when in doubt, use the signed curl above.
- Interstitial and review prompt never share a game: `GameScreen._afterGame`
  decides, and the order there is deliberate.
