import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_state.dart';

class RegionSelectionScreen extends StatelessWidget {
  const RegionSelectionScreen({super.key});

  String _getRegionName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'region_taipei': return l10n.region_taipei;
      case 'region_new_taipei': return l10n.region_new_taipei;
      case 'region_taoyuan': return l10n.region_taoyuan;
      case 'region_hsinchu_county': return l10n.region_hsinchu_county;
      case 'region_hsinchu_city': return l10n.region_hsinchu_city;
      case 'region_science_park': return l10n.region_science_park;
      case 'region_miaoli': return l10n.region_miaoli;
      case 'region_taichung': return l10n.region_taichung;
      case 'region_chiayi': return l10n.region_chiayi;
      case 'region_tainan': return l10n.region_tainan;
      case 'region_kaohsiung': return l10n.region_kaohsiung;
      case 'region_pingtung': return l10n.region_pingtung;
      case 'region_taitung': return l10n.region_taitung;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_region),
        backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
        foregroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: appState.regions.entries.map((entry) {
          final String regionId = entry.key;
          final String regionKey = entry.value['name'] as String;
          
          // Map region key to the actual AppLocalizations getter
          final String regionName = _getRegionName(l10n, regionKey);
          final bool isSelected = appState.selectedRegion == regionId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: InkWell(
              onTap: () {
                appState.setRegion(regionId);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isSelected 
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ) 
                        : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(regionName, style: TextStyle(
                    fontSize: 18, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
