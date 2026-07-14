import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';
import 'package:youbike_android/data/services/app_config_service.dart';

class RegionSelectionScreen extends StatelessWidget {
  const RegionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
      appBar: AppBar(
        title: Text(l10n.settings_region),
        backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
        foregroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: config.regions.entries.map((entry) {
          final String regionId = entry.key;
          final String regionKey = entry.value['name'] as String;
          
          // Correct way to get translation for regions from AppLocalizations
          String regionName;
          switch (regionKey) {
            case 'region_taipei': regionName = l10n.region_taipei; break;
            case 'region_new_taipei': regionName = l10n.region_new_taipei; break;
            case 'region_taoyuan': regionName = l10n.region_taoyuan; break;
            case 'region_hsinchu_county': regionName = l10n.region_hsinchu_county; break;
            case 'region_hsinchu_city': regionName = l10n.region_hsinchu_city; break;
            case 'region_science_park': regionName = l10n.region_science_park; break;
            case 'region_miaoli': regionName = l10n.region_miaoli; break;
            case 'region_taichung': regionName = l10n.region_taichung; break;
            case 'region_chiayi': regionName = l10n.region_chiayi; break;
            case 'region_tainan': regionName = l10n.region_tainan; break;
            case 'region_kaohsiung': regionName = l10n.region_kaohsiung; break;
            case 'region_pingtung': regionName = l10n.region_pingtung; break;
            case 'region_taitung': regionName = l10n.region_taitung; break;
            default: regionName = regionKey;
          }
          final bool isSelected = config.selectedRegion == regionId;


          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: InkWell(
              onTap: () {
                config.setRegion(regionId);
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
