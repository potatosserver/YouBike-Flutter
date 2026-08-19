import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/config/app_environment.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/ui/widgets/radio_dot.dart';

/// 初始化流程專用的區域選擇頁面（獨立於設定頁的 RegionSelectionScreen）。
/// - 無 AppBar 返回鍵（避免使用者跳過）
/// - 選擇後直接導向下一步（通知權限或首頁）
/// - 標題與文案針對初次使用場景調整
class OnboardingRegionSelectionScreen extends StatefulWidget {
  const OnboardingRegionSelectionScreen({super.key});

  @override
  State<OnboardingRegionSelectionScreen> createState() =>
      _OnboardingRegionSelectionScreenState();
}

class _OnboardingRegionSelectionScreenState
    extends State<OnboardingRegionSelectionScreen> {
  String? _selectedRegion;

  void _onRegionTap(String regionId) {
    final config = Provider.of<AppConfigService>(context, listen: false);
    config.setRegion(regionId);
    setState(() => _selectedRegion = regionId);
    // 選擇後導向下一步：通知權限頁或首頁
    if (mounted) {
      if (!AppEnvironment.isWeb) {
        context.go('/permission/notification');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final entries = config.regions.entries.toList();

    return PopScope(
      canPop: false, // 防止使用者用返回鍵跳過區域選擇
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboarding_region_title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboarding_region_message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: List.generate(entries.length, (i) {
                      final entry = entries[i];
                      final regionId = entry.key;
                      final regionKey = entry.value['name'] as String;
                      final label = _lookupLabel(regionKey, l10n);
                      final isSelected =
                          config.selectedRegion == regionId || _selectedRegion == regionId;
                      final isLast = i == entries.length - 1;

                      return Column(
                        children: [
                          RadioDot(
                            label: label,
                            isSelected: isSelected,
                            onTap: () => _onRegionTap(regionId),
                          ),
                          if (!isLast) const SizedBox(height: 24),
                        ],
                      );
                    }),
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