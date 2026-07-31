/// 跨平台快取儲存層介面。
///
/// - native (Android/iOS): 底層用 `dart:io` File + `path_provider`
/// - web (Chrome): 底層用瀏覽器 `window.localStorage`
///
/// 介面保持最簡：字串 in / 字串 out，避免把序列化邏輯耦合到 storage。
/// 所有例外 / 不存在都由實作吃掉、回傳 null，與舊 service 行為一致。
abstract class IStationCacheStorage {
  /// 讀取 [key] 對應的內容；不存在或失敗回 null。
  Future<String?> read(String key);

  /// 寫入 [key] / [value]；Quota 滿或失敗時靜默（仍記 log）。
  Future<void> write(String key, String value);
}
