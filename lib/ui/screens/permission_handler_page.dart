import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/permission_service.dart';
import 'package:youbike/ui/widgets/base/confirm_dialog.dart';

class PermissionHandlerPage extends StatefulWidget {
  const PermissionHandlerPage({super.key});

  @override
  State<PermissionHandlerPage> createState() => _PermissionHandlerPageState();
}

class _PermissionHandlerPageState extends State<PermissionHandlerPage>
    with WidgetsBindingObserver {
  final PermissionService _perm = PermissionService();

  bool _permissionGranted = false;
  bool _permissionSkipped = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
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
    final granted = await _perm.readLocationStatus();
    final skip = await _isSkipped();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _permissionSkipped = skip;
      _checked = true;
    });
  }

  Future<bool> _isSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PermissionPrefKeys.skipLocation) ?? false;
  }

  Future<void> _setSkipped(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PermissionPrefKeys.skipLocation, v);
  }

  Future<void> _requestPermission() async {
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

  void _showSkipWarningDialog() {
    final l10n = AppLocalizations.of(context);
    ConfirmDialog.show(
      context,
      title: l10n.skip_location_title,
      content: l10n.skip_location_desc,
      confirmLabel: l10n.skip_permission_confirm,
      cancelLabel: l10n.cancel,
      danger: true,
      onConfirm: _performSkip,
    );
  }

  Future<void> _performSkip() async {
    final config = Provider.of<AppConfigService>(context, listen: false);
    config.setUseLocation(false);
    await _setSkipped(true);
    if (mounted) setState(() => _permissionSkipped = true);
  }

  void _goNext() {
    if (mounted) context.go('/');
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
                      Icon(Icons.location_on_rounded,
                          size: 64, color: cs.primary),
                      const SizedBox(height: 24),
                      Text(
                        l10n.permission_location_title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.permission_location_desc,
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
                      l10n.setup_complete,
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