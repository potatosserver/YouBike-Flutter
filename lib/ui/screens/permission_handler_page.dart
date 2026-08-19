import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike/core/config/app_environment.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/permission_service.dart';
import 'package:youbike/ui/widgets/base/confirm_dialog.dart';

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

  /// 通知權限「已處理」標記（授予或略過都算），
  /// 與 [_skipKey] 不同：後者代表「使用者點略過」，前者代表「已處理過」。
  /// 兩者分離是為了避免 Android 13 彈系統對話框後 resume 觸發
  /// _checkPermission → _readGranted=false + _isSkipped=true →
  /// UI 錯把授予後狀態顯示為「暫時略過」。
  static const String _notificationHandledKey = 'notification_handled';

  /// 通知權限：使用者是否點過「授予」按鈕（含 OS 拒絕但我們視為已互動過）。
  bool _notificationGranted = false;

  final PermissionService _perm = PermissionService();

  bool _permissionGranted = false;
  bool _permissionSkipped = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // Web build 不支援通知權限（permission_handler 不可用），直接跳至首頁。
    if (AppEnvironment.isWeb && widget.type == PermissionType.notification) {
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

    // 通知頁面：檢查是否已處理過（從 _notificationHandledKey 讀取）
    if (widget.type == PermissionType.notification) {
      final prefs = await SharedPreferences.getInstance();
      _notificationGranted = prefs.getBool(_notificationHandledKey) ?? false;
      if (_notificationGranted && mounted) {
        setState(() => _permissionGranted = true);
      }
    }
  }

  /// 讀取目前權限狀態是否為已授權 — 集中於 PermissionService
  /// （其內部已處理 Web 走 Geolocator、Native 走 permission_handler 的分流）。
  ///
  /// 通知權限特殊處理：Android 12 以下 OS 會自動回 granted，
  /// 但我們希望使用者明確操作過才視為已處理。
  Future<bool> _readGranted() async {
    switch (widget.type) {
      case PermissionType.location:
        return _perm.readLocationStatus();
      case PermissionType.notification:
        // 通知：不以 OS 狀態為準。若已處理過就回 true，
        // 否則回 false 讓 UI 顯示請求按鈕。
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_notificationHandledKey) ?? false;
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
        _perm.showPermanentlyDeniedDialog(context);
        return;
      case LocationRequestResult.denied:
      case LocationRequestResult.unavailable:
        return;
    }
  }

  Future<void> _requestNotification() async {
    final result = await _perm.requestOsNotificationOnce();
    if (!mounted) return;

    switch (result) {
      case NotificationRequestResult.granted:
        _notificationGranted = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationHandledKey, true);
        setState(() => _permissionGranted = true);
        return;
      case NotificationRequestResult.permanentlyDenied:
        _perm.showPermanentlyDeniedDialog(context);
        return;
      case NotificationRequestResult.denied:
        return;
      case NotificationRequestResult.unavailable:
        _notificationGranted = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationHandledKey, true);
        setState(() => _permissionGranted = true);
        return;
    }
  }

  void _showSkipWarningDialog() {
    final l10n = AppLocalizations.of(context);
    final skipTitle = widget.type == PermissionType.location
        ? l10n.skip_location_title
        : l10n.skip_notification_title;
    final skipDesc = widget.type == PermissionType.location
        ? l10n.skip_location_desc
        : l10n.skip_notification_desc;
    ConfirmDialog.show(
      context,
      title: skipTitle,
      content: skipDesc,
      confirmLabel: l10n.skip_permission_confirm,
      cancelLabel: l10n.cancel,
      danger: true,
      onConfirm: _performSkip,
    );
  }

  Future<void> _performSkip() async {
    if (widget.type == PermissionType.location) {
      final config = Provider.of<AppConfigService>(context, listen: false);
      config.setUseLocation(false);
      // 略過定位權限且尚未選擇區域 → 導向區域選擇頁
      if (!config.hasSelectedRegion && mounted) {
        context.go('/region-selection');
        return;
      }
    } else {
      final config = Provider.of<AppConfigService>(context, listen: false);
      config.setUseNotification(false);
    }
    await _setSkipped(true);
    if (mounted) setState(() => _permissionSkipped = true);
  }

  void _goNext() {
    // 定位與通知各自獨立：略過定位不代表略過通知，讓使用者自行決定通知。
    // Web build 沒有通知頁要走，所以定位完成後直接回首頁。
    if (widget.type == PermissionType.location && !AppEnvironment.isWeb) {
      final config = Provider.of<AppConfigService>(context, listen: false);
      // 首次完成定位權限且尚未選擇區域 → 導向區域選擇頁
      if (!config.hasSelectedRegion) {
        if (mounted) context.go('/region-selection');
        return;
      }
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
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Icon(Icons.check_circle,
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
                      // Web build 沒有通知頁可走，定位完成後按鈕文案顯示「完成」。
                      (widget.type == PermissionType.location &&
                              !AppEnvironment.isWeb)
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