import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/config/app_environment.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';

/// 初始化流程專用的區域選擇頁面——風格模仿 PermissionHandlerPage
/// - 無 AppBar 返回鍵（避免使用者跳過）
/// - 使用下拉選單選擇地區
/// - 底部固定「繼續」按鈕，選擇後啟用
/// - 選擇後直接導向下一步（通知權限或首頁）
class OnboardingRegionSelectionScreen extends StatefulWidget {
  const OnboardingRegionSelectionScreen({super.key});

  @override
  State<OnboardingRegionSelectionScreen> createState() =>
      _OnboardingRegionSelectionScreenState();
}

class _OnboardingRegionSelectionScreenState
    extends State<OnboardingRegionSelectionScreen> {
  String? _selectedRegion;
  bool _isLoading = false;

  void _onRegionChanged(String? regionId) {
    if (regionId != null && regionId != _selectedRegion) {
      setState(() => _selectedRegion = regionId);
    }
  }

  Future<void> _continue() async {
    if (_selectedRegion == null || _isLoading) return;
    setState(() => _isLoading = true);
    final config = Provider.of<AppConfigService>(context, listen: false);
    config.setRegion(_selectedRegion!);
    if (!mounted) return;
    // Web 直接進首頁，非 Web 進通知權限頁
    if (AppEnvironment.isWeb) {
      context.go('/');
    } else {
      context.go('/permission/notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final entries = config.regions.entries.toList();

    // 取得目前已選擇的地區（若有）
    final currentRegion = config.hasSelectedRegion ? config.selectedRegion : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isLight ? Brightness.dark : Brightness.light,
      ),
      child: PopScope(
        canPop: false, // 防止使用者用返回鍵跳過區域選擇
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.public_rounded, size: 64, color: cs.primary),
                        const SizedBox(height: 24),
                        Text(
                          l10n.onboarding_region_title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.onboarding_region_message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // 下拉選單
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: cs.outlineVariant,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRegion ?? currentRegion,
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                                      color: cs.onSurfaceVariant, size: 24),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: cs.onSurface,
                                  ),
                                  hint: Text(
                                    l10n.select_region_hint,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  items: entries.map((entry) {
                                    final regionId = entry.key;
                                    final regionKey = entry.value['name'] as String;
                                    final label = _lookupLabel(regionKey, l10n);
                                    return DropdownMenuItem<String>(
                                      value: regionId,
                                      child: Text(label),
                                    );
                                  }).toList(),
                                  onChanged: _onRegionChanged,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 底部固定按鈕
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_selectedRegion != null || currentRegion != null) && !_isLoading
                          ? _continue
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              l10n.setup_complete,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _lookupLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'region_taipei':
        return l10n.region_taipei;
      case 'region_new_taipei':
        return l10n.region_new_taipei;
      case 'region_taoyuan':
        return l10n.region_taoyuan;
      case 'region_hsinchu_county':
        return l10n.region_hsinchu_county;
      case 'region_hsinchu_city':
        return l10n.region_hsinchu_city;
      case 'region_science_park':
        return l10n.region_science_park;
      case 'region_miaoli':
        return l10n.region_miaoli;
      case 'region_taichung':
        return l10n.region_taichung;
      case 'region_chiayi':
        return l10n.region_chiayi;
      case 'region_tainan':
        return l10n.region_tainan;
      case 'region_kaohsiung':
        return l10n.region_kaohsiung;
      case 'region_pingtung':
        return l10n.region_pingtung;
      case 'region_taitung':
        return l10n.region_taitung;
      default:
        return key;
    }
  }
}