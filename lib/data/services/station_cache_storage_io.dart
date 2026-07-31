import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/services/station_cache_storage.dart';

/// Native (Android/iOS) 實作 — 用 `path_provider` 拿 App 私有目錄，
/// 以原生 `dart:io` File I/O 讀寫。
class FileStationCacheStorage implements IStationCacheStorage {
  Future<File> _resolve(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$key');
  }

  @override
  Future<String?> read(String key) async {
    try {
      final f = await _resolve(key);
      if (!await f.exists()) return null;
      return await f.readAsString();
    } catch (e) {
      LogService().w('CacheStorage', 'file read $key failed: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final f = await _resolve(key);
      await f.writeAsString(value);
    } catch (e) {
      LogService().w('CacheStorage', 'file write $key failed: $e');
    }
  }
}

/// Conditional import 入口 — native 平台使用本檔 factory。
IStationCacheStorage createStorage() => FileStationCacheStorage();
