import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';

/// 權限類型：location 或 notification
enum PermissionType { location, notification }

class PermissionPageEntry {
  /// 建立定位權限頁
  const PermissionPageEntry.location() : type = PermissionType.location;

  /// 建立通知權限頁
  const PermissionPageEntry.notification()
      : type = PermissionType.notification;

  final PermissionType type;
}

class PermissionHandlerPage extends StatefulWidget {
  const PermissionHandlerPage({
    super.key,
    this.type = PermissionType.location,
  });

  final PermissionType type;

  @override
  State<PermissionHandlerPage> createState() => _PermissionHandlerPageState();
}

class _PermissionHandlerPageState extends State<PermissionHandlerPage>
    with WidgetsBindingObserver {
  /// 略過標記的 prefs key，依權限類型區分
  String get _skipKey => widget.type == PermissionType.location
      ? 'skip_location_permission'
      : 'skip_notification_permission';

  bool _permissionGranted = false;
  bool _permissionSkipped = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // Web 平台不支援通知權限，直接跳至首頁
    if (kIsWeb && widget.type == PermissionType.notification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await _readGranted();
    final skip = await _isSkipped();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _permissionSkipped = skip;
      _checked = true;
    });
  }

  /// 讀取目前權限狀態是否為已授權
  Future<bool> _readGranted() async {
    switch (widget.type) {
      case PermissionType.location:
        // 統一在 Web 走 Geolocator（與 MapViewModel 同源），避免
        // permission_handler_html (Permissions API) 與 navigator.geolocation
        // 在「使用者重設權限」場景的狀態分歧。
        if (kIsWeb) {
          try {
            final p = await Geolocator.checkPermission();
            return p == LocationPermission.always ||
                p == LocationPermission.whileInUse;
          } catch (_) {
            return false;
          }
        }
        final s = await Permission.location.status;
        return s.isGranted || s.isLimited;
      case PermissionType.notification:
        // Android 13+ 需 POST_NOTIFICATIONS；舊版與 iOS 用 FirebaseMessaging
        const platform = Permission.notification;
        final s = await platform.status;
        // permission_handler 在未支持 platform 權限的版本上會回 undetermined，
        // 仍接受 isGranted。若想使用 FCM 原生狀態可再呼叫。
        if (s.isGranted) return true;
        // iOS/舊 Android fallback：檢查 FCM authorizationStatus
        try {
          final fcmStatus =
              await FirebaseMessaging.instance.getNotificationSettings();
          return fcmStatus.authorizationStatus ==
              AuthorizationStatus.authorized;
        } catch (_) {
          return false;
        }
    }
  }

  Future<bool> _isSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipKey) ?? false;
  }

  Future<void> _setSkipped(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipKey, v);
  }

  Future<void> _requestPermission() async {
    switch (widget.type) {
      case PermissionType.location:
        await _requestLocation();
        break;
      case PermissionType.notification:
        await _requestNotification();
        break;
    }
  }

  Future<void> _requestLocation() async {
    // Web：走 Geolocator（與 MapViewModel 同源）。Geolocator.requestPermission()
    // 內部呼叫 navigator.geolocation.getCurrentPosition，會觸發瀏覽器原生詢問框。
    // Web 沒有「永久拒絕」語意 — deniedForever 在 Web 等於使用者剛拒絕，不該彈
    // permanentlyDenied dialog 引導去系統設定（Web 沒這個入口）。
    if (kIsWeb) {
      try {
        final p = await Geolocator.requestPermission();
        if (!mounted) return;
        if (p == LocationPermission.always ||
            p == LocationPermission.whileInUse) {
          setState(() => _permissionGranted = true);
        }
        // denied / deniedForever 都視為「使用者剛拒絕」，不彈 dialog，
        // 讓使用者留在本頁可再次按按鈕或選略過。
      } catch (_) {
        // Geolocator 在 Web 例外時不更新狀態
      }
      return;
    }

    final status = await Permission.location.status;

    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog();
      return;
    }

    final result = await Permission.location.request();

    if (result.isGranted || result.isLimited) {
      if (!mounted) return;
      setState(() => _permissionGranted = true);
    } else if (result.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog();
    }
  }

  Future<void> _requestNotification() async {
    // 1) 以 permission_handler 處理 Android 13+ POST_NOTIFICATIONS
    const platform = Permission.notification;
    final status = await platform.status;

    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog();
      return;
    }

    if (!status.isGranted) {
      // 一次性請求：不論結果為何不再二次請求，
      // 避免使用者按「拒絕」後又被 FCM requestPermission 再彈一次系統詢問框。
      final result = await platform.request();
      if (!mounted) return;
      if (result.isGranted) {
        setState(() => _permissionGranted = true);
      } else if (result.isPermanentlyDenied) {
        _showPermanentlyDeniedDialog();
      }
      // 使用者按拒絕（暫時性 deny）→ 結束本輪，不重複請求。
      return;
    }

    // 2) 已通過 Android permission，過渡給 FCM 處理 iOS 與舊版 Android
    try {
      final s = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: false,
        provisional: false,
      );
      final granted = s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional;
      if (!mounted) return;
      if (granted) {
        setState(() => _permissionGranted = true);
      }
      // iOS 的 denied 為「使用者剛剛拒絕」，非永久拒絕；
      // 永久拒絕需使用者已拒絕兩次後系統才提升權限層級，
      // 為了不誤彈永久拒絕對話框，這裡不再額外處理，使用者可在系統設定重設。
    } catch (_) {
      // 非 Firebase 環境（如 Web 或尚未初始化）忽略
    }
  }

  void _showPermanentlyDeniedDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.permission_denied_title),
        content: Text(l10n.permission_denied_content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            child: Text(l10n.open_settings),
          ),
        ],
      ),
    );
  }

  void _showSkipWarningDialog() {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_skipDialogTitle),
        content: Text(_skipDialogDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performSkip();
            },
            child: Text(
              l10n.skip_permission_confirm,
              style: TextStyle(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }

  String get _skipDialogTitle => widget.type == PermissionType.location
      ? AppLocalizations.of(context).skip_location_title
      : AppLocalizations.of(context).skip_notification_title;

  String get _skipDialogDesc => widget.type == PermissionType.location
      ? AppLocalizations.of(context).skip_location_desc
      : AppLocalizations.of(context).skip_notification_desc;

  Future<void> _performSkip() async {
    if (widget.type == PermissionType.location) {
      // 略過定位 → AppConfig 同步關閉定位服務（避免一邊略過又用定位的混淆）
      final config = Provider.of<AppConfigService>(context, listen: false);
      config.setUseLocation(false);
    } else {
      // 略過通知 → 同步關閉設定中的「通知服務」開關，
      // 確保「跳過」反映到 UI（否則 OS 通知仍可能彈，但 App 設定應與實際處理意圖一致）。
      final config = Provider.of<AppConfigService>(context, listen: false);
      config.setUseNotification(false);
    }
    await _setSkipped(true);
    if (mounted) setState(() => _permissionSkipped = true);
  }

  void _goNext() {
    // 定位與通知各自獨立：略過定位不代表略過通知，讓使用者自行決定通知。
    // Web 平台不支援通知權限，直接跳至首頁。
    if (widget.type == PermissionType.location && !kIsWeb) {
      if (mounted) context.go('/permission/notification');
    } else {
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final canProceed = _permissionGranted || _permissionSkipped;

    // 還在檢查中，顯示 loading
    if (!_checked) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final iconData = widget.type == PermissionType.location
        ? Icons.location_on_rounded
        : Icons.notifications_active_rounded;
    final title = widget.type == PermissionType.location
        ? l10n.permission_location_title
        : l10n.permission_notification_title;
    final desc = widget.type == PermissionType.location
        ? l10n.permission_location_desc
        : l10n.permission_notification_desc;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isLight ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, size: 64, color: cs.primary),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        desc,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      if (!_permissionGranted && !_permissionSkipped) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.shield_outlined),
                          label: Text(l10n.grant_permission),
                          onPressed: _requestPermission,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton(
                            onPressed: _showSkipWarningDialog,
                            child: Text(
                              l10n.skip_permission_label,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                      if (_permissionGranted)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Icon(Icons.check_circle,
                              color: Colors.green.shade500, size: 32),
                        ),
                      if (_permissionSkipped)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.skip_permission_label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canProceed ? _goNext : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      // Web 上不會走 notification 頁（splash 會直接放行），
                      // 因此 location 頁在 Web 就是最後一步，按鈕顯示「開始使用」。
                      // 原生端 location 頁仍顯示「繼續」，因還有 notification 頁。
                      (widget.type == PermissionType.location && !kIsWeb)
                          ? l10n.setup_continue
                          : l10n.setup_complete,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
