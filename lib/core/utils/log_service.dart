import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel { debug, info, warning, error }

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const _appLogKey = 'app_activity_log';
  List<Map<String, dynamic>> _appLogs = [];

  List<Map<String, dynamic>> get appLogs => _appLogs;

  Future<void> loadAppLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appLogKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _appLogs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      } catch (_) {
        _appLogs = [];
      }
    } else {
      _appLogs = [];
    }
  }

  Future<void> clearAppLogs() async {
    _appLogs = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appLogKey);
  }

  void _log(LogLevel level, String tag, String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String().split('.').first;
    final levelStr = _getLevelString(level);
    final formattedMessage = '[$timestamp] [$levelStr] [$tag]: $message';

    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        developer.log(formattedMessage, name: tag);
        // Android logcat 只接 Dart stdout；developer.log 不會印到 I/flutter。
        // Web Chrome DevTools console 也只接 print()。
        // 用 print() 鏡像到原生 console 讓 flutter run -d chrome 與 Android logcat 都看得到。
        if (kDebugMode) {
          // ignore: avoid_print
          print(formattedMessage);
        }
      case LogLevel.warning:
        developer.log(formattedMessage, name: tag, level: 900);
        if (kDebugMode) {
          // ignore: avoid_print
          print(formattedMessage);
        }
      case LogLevel.error:
        developer.log(formattedMessage, name: tag, level: 1000, error: error, stackTrace: stackTrace);
    }

    // 持久化至 app 日誌（僅 info 以上）
    if (level != LogLevel.debug) {
      final entry = {
        'timestamp': timestamp,
        'level': levelStr,
        'tag': tag,
        'message': message,
      };
      _appLogs.insert(0, entry);
      if (_appLogs.length > 100) _appLogs.removeLast();
      Future.microtask(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_appLogKey, jsonEncode(_appLogs));
      });
    }
  }

  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return 'DEBUG';
      case LogLevel.info: return 'INFO';
      case LogLevel.warning: return 'WARN';
      case LogLevel.error: return 'ERROR';
    }
  }

  void d(String tag, String message) => _log(LogLevel.debug, tag, message);
  void i(String tag, String message) => _log(LogLevel.info, tag, message);
  void w(String tag, String message) => _log(LogLevel.warning, tag, message);
  void e(String tag, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
}