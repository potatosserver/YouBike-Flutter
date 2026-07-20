import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/permission_service.dart';

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
  /// 略過標記的 prefs key，依權限類型區分。集中於 [PermissionPrefKeys]。
  String get _skipKey => widget.type == PermissionType.location
      ? PermissionPrefKeys.skipLocation
      : PermissionPrefKeys.skipNotification;

  /// 統一權限讀取與請求入口（亦集中 kIsWeb 短路）。
  final PermissionService _perm = PermissionService();

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

  /// 讀取目前權限狀態是否為已授權 — 集中於 PermissionService
  /// （其內部已處理 Web 走 Geolocator、Native 走 permission_handler 的分流）。
  Future<bool> _readGranted() async {
    switch (widget.type) {
      case PermissionType.location:
        return _perm.readLocationStatus();
      case PermissionType.notification:
        return _perm.readSystemNotificationStatus();
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
    // Web / Native 分流集中於 PermissionService 內部 — 此處只需處理 granted 分支。
    final result = await _perm.requestLocationOnce();
    if (!mounted) return;
    switch (result) {
      case LocationRequestResult.granted:
        setState(() => _permissionGranted = true);
        return;
      case LocationRequestResult.permanentlyDenied:
        // Web 不會回此值（Web 沒有「永久拒絕」語意）
        _perm.showPermanentlyDeniedDialog(context);
        return;
      case LocationRequestResult.denied:
      case LocationRequestResult.unavailable:
        // 暫時性拒絕 / 環境不支援 → 結束本輪，使用者可再按或選略過。
        return;
    }
  }

  Future<void> _requestNotification() async {
    // 集中於 PermissionService：
    // 1) Android 13+ 走 permission_handler 的 POST_NOTIFICATIONS
    // 2) Web 自動視為 granted（由 service 內 isWeb 短路）
    final result = await _perm.requestOsNotificationOnce();
    if (!mounted) return;

    switch (result) {
      case NotificationRequestResult.granted:
        setState(() => _permissionGranted = true);
        return;
      case NotificationRequestResult.permanentlyDenied:
        _perm.showPermanentlyDeniedDialog(context);
        return;
      case NotificationRequestResult.denied:
        // 使用者按「拒絕」（暫時性 deny）→ 結束本輪，不重複請求。
        return;
      case NotificationRequestResult.unavailable:
        // 環境不支援時直接視為通過（與 readSystemNotificationStatus 對齊 Web=true 策略）
        setState(() => _permissionGranted = true);
        return;
    }
  }

  void _showSkipWarningDialog() {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final skipTitle = widget.type == PermissionType.location
        ? l10n.skip_location_title
        : l10n.skip_notification_title;
    final skipDesc = widget.type == PermissionType.location
        ? l10n.skip_location_desc
        : l10n.skip_notification_desc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(skipTitle),
        content: Text(skipDesc),
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
                        // ignore: prefer_const_constructors
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: const Icon(Icons.check_circle,
                              color: BrandColors.success, size: 32),
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
