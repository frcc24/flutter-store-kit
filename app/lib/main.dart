import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/crash/crash_reporter.dart';
import 'core/storage/local_store.dart';
import 'services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrashReporter.init();
  final store = LocalStore(await SharedPreferences.getInstance());
  runApp(MiniSudokuApp(services: Services.production(store)));
}
