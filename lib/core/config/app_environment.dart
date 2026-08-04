/// 應用程式編譯期環境設定。
///
/// 由 `--dart-define=UPDATE_CHANNEL=<value>` 注入，常見值：
/// - `github`      : Android GitHub 發布版（預設）。
/// - `google_play` : Android Google Play 發布版。
/// - `web`         : Web 瀏覽器版。
/// - `test`        : 測試 / 特殊情境。
///
/// 注意：[AppEnvironment] 的所有 getter 都是在 build 期決定的常數，
/// 不要把它當作 runtime 平台偵測（`kIsWeb`）的替代品——除非語意上
/// 「Web build 應該走 Web 行為」是用 channel 標記的，否則兩者並不等價。
///
/// 例如：把 GitHub 版 APK 裝在 ChromeOS（kIsWeb=false）上時，
/// [isWeb] 仍是 `false`，但若 build 是用 `--dart-define=UPDATE_CHANNEL=web`
/// 編出，則 [isWeb] = `true`。
class AppEnvironment {
  /// 原始 channel 字串（已用 [String.fromEnvironment] 解析）。
  /// 大小寫不敏感；呼叫端可用 [channel] getter 取標準化小寫。
  static const String _rawChannel = String.fromEnvironment(
    'UPDATE_CHANNEL',
    defaultValue: 'github',
  );

  /// 標準化為小寫的 channel 值，供比較用。
  static String get channel => _rawChannel.toLowerCase();

  // ── 語意化查詢 ──────────────────────────────────────────────
  // 提供這些 getter 是為了避免每處都寫 `channel == 'xxx'`，
  // 同時讓 `kIsWeb` 的語意從「平台偵測」變成「build 目標」。

  /// 是否為 Web 發行版（`--dart-define=UPDATE_CHANNEL=web`）。
  static bool get isWeb => channel == 'web';

  /// 是否為 Google Play 發行版。
  static bool get isGooglePlay => channel == 'google_play';

  /// 是否為 GitHub Releases 發行版（含預設）。
  static bool get isGithub => channel == 'github';

  /// 是否為測試 / 特殊情境版本（`--dart-define=UPDATE_CHANNEL=test`）。
  static bool get isTest => channel == 'test';

  /// 是否為 Android 任一發行版（GitHub 或 Google Play）。
  /// 等同 `!isWeb`，但語意更明確。
  static bool get isAndroid => isGithub || isGooglePlay || isTest;

  // ── 顯示用 ────────────────────────────────────────────────

  /// 給「關於」頁面或 Firestore 上報用的可讀 channel 名稱。
  static String get displayChannel {
    switch (channel) {
      case 'github':
        return 'GitHub';
      case 'google_play':
        return 'Google Play';
      case 'web':
        return 'Web';
      case 'test':
        return 'Test';
      default:
        return _rawChannel;
    }
  }
}
