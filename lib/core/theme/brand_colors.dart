import 'package:flutter/material.dart';

/// 所有非 ColorScheme 的品牌色集中處。
/// 其他顏色一律使用 theme.colorScheme.*。
class BrandColors {
  BrandColors._();


  /// YouBike 橘 — 種子色、載入圓圈、進度條。
  static const Color orange = Color(0xFFFF9800);

  /// 淺橘 — 地圖按鈕背景，搭配黑字清晰可讀。
  static const Color lightOrange = Color(0xFFFFCC80);

  /// 站點標記與群集黃（Road-Sign 標準）。
  static const Color markerYellow = Color(0xFFFFD700);


  /// 導航圖示、GPS 脈衝點 — 永遠藍色。
  static const Color accentBlue = Colors.blue;

  /// 電動車圖示與電池百分比 — 永遠亮綠色。
  static const Color accentGreen = Color(0xFF4CAF50);

  // ── 語義輔助色（取代散落的 hard-code） ──

  /// 釘選車站星號（明確 amber 對比 onSurfaceVariant）。
  static const Color pinnedStars = Color(0xFFFFC107);

  /// 「成功 / 已完成 / 已同意」綠（取代散落 `Colors.green.shadeXXX`）。
  /// Material Green 500 與 accentGreen 同色，因此另提供視覺差異略淺的 600。
  static const Color success = Color(0xFF43A047);

  // 日誌頁等級色 — 採低飽和以免吸睛，色相與 severity 對應
  static const Color logError = Color(0xFFC62828);
  static const Color logWarn = Color(0xFFF57C00);
  static const Color logInfo = Color(0xFF1976D2);
}