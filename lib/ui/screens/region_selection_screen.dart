import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/ui/widgets/radio_dot.dart';

class RegionSelectionScreen extends StatelessWidget {
  const RegionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final entries = config.regions.entries.toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.settings_region),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: List.generate(entries.length, (i) {
          final entry = entries[i];
          final regionId = entry.key;
          final regionKey = entry.value['name'] as String;
          final label = _lookupLabel(regionKey, l10n);
          final isSelected = config.selectedRegion == regionId;
          final isLast = i == entries.length - 1;

          return Column(
            children: [
              RadioDot(
                label: label,
                isSelected: isSelected,
                onTap: () => config.setRegion(regionId),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          );
        }),
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
