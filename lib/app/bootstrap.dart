import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/app_logger.dart';
import 'app.dart';

/// Single entry point used by `main.dart`. Keeping this separate from
/// `main()` makes it easy to add flavor-specific bootstrap later (e.g.
/// crash reporting init) without touching platform entry files.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();
  runApp(const ProviderScope(child: RemoteTvApp()));
}
