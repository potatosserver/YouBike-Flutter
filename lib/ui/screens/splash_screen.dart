import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/permission_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _firstLaunchKey = 'is_first_launch';

  final PermissionService _perm = PermissionService();

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirst) {
      await prefs.setBool(_firstLaunchKey, false);
      if (mounted) context.go('/welcome');
      return;
    }

    // 非首次：依序檢查定位、通知權限是否已處理（授權或略過）
    final skipLoc = prefs.getBool(PermissionPrefKeys.skipLocation) ?? false;
    final skipNotif =
        prefs.getBool(PermissionPrefKeys.skipNotification) ?? false;
    final notifHandled = prefs.getBool('notification_handled') ?? false;

    final locGranted = await _perm.readLocationStatus();
    if (!mounted) return;
    if (!locGranted && !skipLoc) {
      context.go('/permission');
      return;
    }

    // 已處理定位權限（授權或略過），但尚未選擇區域 → 導向區域選擇
    final config = Provider.of<AppConfigService>(context, listen: false);
    if (!config.hasSelectedRegion) {
      context.go('/region-selection');
      return;
    }

    // 通知權限：不以 OS 狀態為準（Android 12 以下會自動 granted）。
    // 檢查 notification_handled（已授予過）或 skipNotification（略過過）。
    // Web 跳過通知頁。
    if (!_perm.isWeb && !notifHandled && !skipNotif) {
      context.go('/permission/notification');
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}