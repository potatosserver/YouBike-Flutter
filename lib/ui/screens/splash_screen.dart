import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    // 非首次：檢查定位權限是否已處理（授權或略過）
    final skipLoc = prefs.getBool(PermissionPrefKeys.skipLocation) ?? false;

    final locGranted = await _perm.readLocationStatus();
    if (!mounted) return;
    if (!locGranted && !skipLoc) {
      context.go('/permission');
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}