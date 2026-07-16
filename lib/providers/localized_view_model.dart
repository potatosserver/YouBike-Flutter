import 'package:flutter/material.dart';
import 'package:youbike/core/l10n/app_localizations.dart';

/// [LocalizedViewModel] 提供一個標準化的 L10n 注入接口。
/// 繼承此類的 ViewModel 可以直接通過 [l10n] 屬性訪問翻譯字符串，
/// 而無需在業務邏輯中傳遞 [BuildContext]。
abstract class LocalizedViewModel extends ChangeNotifier {
  AppLocalizations? _l10n;

  /// 獲取當前的 L10n 實例。如果尚未注入，則返回 null。
  AppLocalizations? get l10n => _l10n;

  /// 由 UI 層在 build 時調用，將當前的 [AppLocalizations] 注入到 ViewModel 中。
  void setL10n(AppLocalizations l10n) {
    if (_l10n == l10n) return;
    _l10n = l10n;
    // 語言切換後，可能需要重新計算某些依賴翻譯的狀態
    onL10nChanged();
    notifyListeners();
  }

  /// 當 L10n 實例被更新（如用戶切換語言）時觸發。
  /// 子類可以覆寫此方法來更新依賴翻譯的內部狀態。
  void onL10nChanged() {}

  /// 安全地獲取翻譯字符串。如果 L10n 尚未就緒，則返回預設值或 Key。
  String translate(String Function(AppLocalizations) getter,
      {String fallback = ''}) {
    if (_l10n == null) return fallback;
    return getter(_l10n!);
  }
}
