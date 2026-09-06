import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/crash/crash_reporter.dart';
import 'core/remote/remote_flags.dart';
import 'core/storage/local_store.dart';
import 'services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrashReporter.init();
  final store = LocalStore(await SharedPreferences.getInstance());
  final info = await PackageInfo.fromPlatform();
  // Bounded by its own timeout: the flags never hold the first frame hostage.
  final flags = await RemoteFlags.fetch();
  runApp(
    MiniSudokuApp(
      services: Services.production(
        store,
        flags: flags,
        buildNumber: int.tryParse(info.buildNumber) ?? 0,
        packageName: info.packageName,
      ),
    ),
  );
}
