import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/station_format_helper.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/services/app_config_service.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;
  final VoidCallback onNavigate;
  final VoidCallback onShowElectric;

  static const _fmt = StationFormatHelper();

  const StationCard({
    super.key,
    required this.station,
    required this.onTap,
    required this.onNavigate,
    required this.onShowElectric,
  });

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final lang = config.currentLang;
    final isPinned = config.pinnedStationIds.contains(station.id);
    final hasElectric = (station.availableElectricBikes ?? 0) > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _fmt.name(station, lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.accentBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(children: [
                  if (hasElectric)
                    GestureDetector(
                      onTap: onShowElectric,
                      child: const Icon(Icons.electric_bolt,
                          color: BrandColors.accentGreen, size: 22),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => config.togglePinStation(station.id),
                    child: Icon(
                      isPinned ? Icons.star : Icons.star_border,
                      color: isPinned ? Colors.amber : cs.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onNavigate,
                    child: const Icon(Icons.navigation,
                        color: BrandColors.accentBlue, size: 22),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.distance} ${_fmt.distance(station.distance, l10n)}',
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.address} ${_fmt.address(station, lang)}',
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.availableBikes} ${_fmt.bikes(station.availableBikes, l10n)}',
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.availableElectricBikes} ${_fmt.bikes(station.availableElectricBikes, l10n)}',
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.emptySpaces} ${_fmt.bikes(station.emptySpaces, l10n)}',
              style: TextStyle(fontSize: 15, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
