import 'package:logging/logging.dart';

/// Thin wrapper around `package:logging` that enforces the project's tag
/// convention, e.g. `[TV][DISCOVERY][mDNS]`, `[TV][PAIRING][GoogleTV]`.
///
/// **Never log secrets.** Do not pass pairing PINs, tokens, keys, or
/// certificates to any method here - see docs/architecture/security.md.
class AppLogger {
  AppLogger(String name) : _logger = Logger(name);

  final Logger _logger;

  static void init({Level level = Level.INFO}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.loggerName}: ${record.message}');
    });
  }

  void fine(String message) => _logger.fine(message);
  void info(String message) => _logger.info(message);
  void warning(String message) => _logger.warning(message);
  void severe(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);
}
