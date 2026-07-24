import 'package:flutter/material.dart';
import 'package:youbike/core/theme/brand_colors.dart';

/// 通用「單車站點地圖圖釘」 — 圓型底 + 白邊 + 中央 PNG 腳踏車 icon。
///
/// 來源不同只需換 `color` 與 `active`：
/// - YouBike: `color: BrandColors.markerYellow`, `active: false`
/// - Moovo:   `color: BrandColors.markerMoovoGreen`, `active: false`
///   (active 狀態，未來點擊 / 選中時，外框由 `Colors.white` 改為亮藍)
class BikePinMarker extends StatelessWidget {
  final Color color;
  final bool active;
  const BikePinMarker({
    super.key,
    this.color = BrandColors.markerYellow,
    this.active = false,
  });

  /// 給 YouBike 使用的便利 constructor — 維持既有風格名稱。
  const BikePinMarker.youbike({super.key})
      : color = BrandColors.markerYellow,
        active = false;

  /// 給 Moovo 使用的便利 constructor — 綠色。
  const BikePinMarker.moovo({super.key})
      : color = BrandColors.markerMoovoGreen,
        active = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.blue : Colors.white,
              width: active ? 2.0 : 4.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/icons/bike_icon.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.directions_bike,
              size: 22,
              color: Colors.black87,
            );
          },
        ),
      ],
    );
  }
}

/// 既有 YouBike 風格入口 — 繼續 alias 對應「道路標誌風」。
/// 對外用 `RoadSignMarker()` 的程式碼不需修改。
class RoadSignMarker extends StatelessWidget {
  const RoadSignMarker({super.key});
  @override
  Widget build(BuildContext context) => const BikePinMarker.youbike();
}

/// (保留) Moovo 風格入口 — 給舊呼叫端使用；新程式碼直接寫 `BikePinMarker.moovo()`。
class MoovoPinMarker extends StatelessWidget {
  const MoovoPinMarker({super.key});
  @override
  Widget build(BuildContext context) => const BikePinMarker.moovo();
}

class ClusterMarker extends StatelessWidget {
  final int count;

  /// 自訂底色。預設為 YouBike 黃。Moovo 來源會用綠色。
  final Color color;
  const ClusterMarker({
    super.key,
    required this.count,
    this.color = BrandColors.markerYellow,
  });

  @override
  Widget build(BuildContext context) {
    final digits = count.toString().length;
    // 字型隨數字位數縮減，全部塞進固定容器（不擴大容器尺寸）。
    // 1-2 位: 18px / 3 位: 14px / 4 位+: 11px
    final double fontSize;
    if (digits <= 2) {
      fontSize = 18.0;
    } else if (digits == 3) {
      fontSize = 14.0;
    } else {
      fontSize = 11.0;
    }

    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white,
          width: 4.0,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count.toString(),
            maxLines: 1,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}
