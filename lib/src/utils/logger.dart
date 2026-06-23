import 'dart:developer' as developer;

/// Logger utility for Artemis SDK
///
/// Provides structured logging with different levels.
/// Log level is controlled by SDK configuration.
class ArtemisLogger {
  static String _logLevel = 'info';
  static bool _enabled = false;
  static bool _printToConsole = false;

  /// Configure logger
  ///
  /// [enabled] turns logging on/off entirely.
  /// [logLevel] controls the minimum severity that is logged.
  /// [printToConsole] toggles `print()` output to the console for every
  /// emitted log, independently of [logLevel].
  static void configure({
    required bool enabled,
    required String logLevel,
    bool printToConsole = false,
  }) {
    _enabled = enabled;
    _logLevel = logLevel.toLowerCase();
    _printToConsole = printToConsole;
  }

  /// Log debug message
  static void debug(String message, [Object? data]) {
    if (_enabled && _shouldLog('debug')) {
      _log('DEBUG', message, data);
    }
  }

  /// Log info message
  static void info(String message, [Object? data]) {
    if (_enabled && _shouldLog('info')) {
      _log('INFO', message, data);
    }
  }

  /// Log warning message
  static void warning(String message, [Object? data]) {
    if (_enabled && _shouldLog('warning')) {
      _log('WARNING', message, data);
    }
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enabled && _shouldLog('error')) {
      _log('ERROR', message, error);
      if (stackTrace != null) {
        developer.log(
          stackTrace.toString(),
          name: 'ARTEMIS_SDK',
          level: 1000,
        );
      }
    }
  }

  /// Check if current log level allows logging
  static bool _shouldLog(String level) {
    const levels = ['debug', 'info', 'warning', 'error'];
    final currentLevelIndex = levels.indexOf(_logLevel);
    final requestedLevelIndex = levels.indexOf(level);

    if (currentLevelIndex == -1) return true;
    if (requestedLevelIndex == -1) return false;

    return requestedLevelIndex >= currentLevelIndex;
  }

  /// Internal log method
  static void _log(String level, String message, [Object? data]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level: $message';

    developer.log(
      logMessage,
      name: 'ARTEMIS_SDK',
      error: data,
    );

    // Also print to console when the print flag is enabled
    if (_printToConsole) {
      // ignore: avoid_print
      print('🔷 ARTEMIS_SDK $logMessage');
      if (data != null) {
        // ignore: avoid_print
        print('   Data: $data');
      }
    }
  }
}
