import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/bike_station_mixer.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/data/services/app_config_service.dart';

/// 多源(YouBike / Moovo)混合清單用的統一卡片 widget。
///
/// 跟既有 `StationCard` 平行存在;後者照舊給「只在側欄顯示 YouBike」
/// 流程用,本 widget 專為跨源混排設計。
///
/// 視覺:
/// - 共用 layout (名稱 / 距離 / 地址 / 車數 / 電輔數 / 空位)
/// - YouBike: 維持原本 surfaceLow 底色 + accentBlue 名稱。
/// - Moovo: 淡綠底(#b9d302 0.12 alpha)區分來源,其他樣式一致。
class BikeStationCard extends StatelessWidget {
  final BikeStationItem item;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  const BikeStationCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onNavigate,
  });

  bool get _isMoovo => item.source == StationSource.moovo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final config = Provider.of<AppConfigService>(context);
    final isPinned = config.pinnedStationIds.contains(item.id);

    final baseSurface = cs.surfaceContainerLow;
    final moovoSurface = Color.alphaBlend(
      BrandColors.markerMoovoGreen.withValues(alpha: 0.12),
      baseSurface,
    );
    final bgColor = _isMoovo ? moovoSurface : baseSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
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
                    item.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isMoovo
                          ? BrandColors.markerMoovoGreen
                          : BrandColors.accentBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(children: [
                  if (_isMoovo)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BrandColors.markerMoovoGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Moovo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => config.togglePinStation(item.id),
                    child: Icon(
                      isPinned ? Icons.star : Icons.star_border,
                      color: isPinned
                          ? BrandColors.pinnedStars
                          : cs.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onNavigate,
                    child: const Icon(
                      Icons.navigation,
                      color: BrandColors.accentBlue,
                      size: 22,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            // 距離跨 km 轉換 (跟 YouBike `StationFormatHelper.distance()` 同規則):
            // < 1000m → 公尺 + 「公尺」單位; ≥ 1000m → km + 「公里」單位 (一位小數)。
            _infoRow(l10n.distance, _formatDistance(item.distance, l10n), cs),
            // Moovo: 只留「距離」和「可借車輛數」,隱藏電輔 / 空位。
            // YouBike: 沿用舊 layout — 保留全部欄位,避免破壞既有 YouBike 使用者。
            if (_isMoovo) ...[
              const SizedBox(height: 4),
              _infoRow(l10n.rentableBikes, '${item.bikeCount ?? '—'}', cs),
            ] else ...[
              const SizedBox(height: 4),
              _infoRow(l10n.availableBikes, '${item.bikeCount ?? '—'}', cs),
              const SizedBox(height: 4),
              _infoRow(l10n.availableElectricBikes, '${item.eBikeCount ?? '—'}', cs),
              if (item.emptySpaces != null) ...[
                const SizedBox(height: 4),
                _infoRow(l10n.emptySpaces, '${item.emptySpaces}', cs),
              ],
            ],
          ],
        ),
        ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme cs) {
    return Text(
      '$label $value',
      style: TextStyle(fontSize: 15, color: cs.onSurface),
    );
  }

  /// 公尺跨 km 換算 — 跟 YouBike `StationFormatHelper.distance` 用同一規則。
  static String _formatDistance(double meters, AppLocalizations l10n) {
    return meters < 1000
        ? '${meters.toStringAsFixed(0)}${l10n.dist_m}'
        : '${(meters / 1000).toStringAsFixed(1)}${l10n.dist_km}';
  }
}
