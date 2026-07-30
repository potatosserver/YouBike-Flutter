import 'package:flutter/material.dart';
import 'package:youbike/core/theme/brand_colors.dart';

/// 通用「單車站點地圖圖釘」 — 圓型底 + 白邊 + 中央 PNG 腳踏車 icon，含狀態標記。
///
/// 來源不同只需換 `color` 與 `active`：
/// - YouBike: `color: BrandColors.markerYellow`, `active: false`
/// - Moovo:   `color: BrandColors.markerMoovoGreen`, `active: false`
///   (active 狀態，未來點擊 / 選中時，外框由 `Colors.white` 改為亮藍)
///
/// 狀態標記（僅 YouBike 使用，置於圖釘外圍）：
/// - [hasElectric]: 右上角綠色圓點
/// - [isFull]: 外圈改為紅色（車位滿載）
/// - [noBikes]: 外圈改為橘色（無車可借）
/// - [isSuspended]: 灰色半透明覆蓋層（暫停營運）
class BikePinMarker extends StatelessWidget {
  final Color color;
  final bool active;

  /// 有電輔車 — 右上角綠色圓點。
  final bool hasElectric;

  /// 車位滿載 — 外圈紅色。
  final bool isFull;

  /// 無車可借 — 外圈橘色。
  final bool noBikes;

  /// 暫停營運 — 灰色覆蓋。
  final bool isSuspended;

  const BikePinMarker({
    super.key,
    this.color = BrandColors.markerYellow,
    this.active = false,
    this.hasElectric = false,
    this.isFull = false,
    this.noBikes = false,
    this.isSuspended = false,
  });

  /// 給 YouBike 使用的便利 constructor — 維持既有風格名稱。
  const BikePinMarker.youbike({
    super.key,
    this.hasElectric = false,
    this.isFull = false,
    this.noBikes = false,
    this.isSuspended = false,
  })  : color = BrandColors.markerYellow,
        active = false;

  /// 給 Moovo 使用的便利 constructor — 綠色。
  const BikePinMarker.moovo({super.key})
      : color = BrandColors.markerMoovoGreen,
        active = false,
        hasElectric = false,
        isFull = false,
        noBikes = false,
        isSuspended = false;

  @override
  Widget build(BuildContext context) {
    // 決定外圈顏色：full(紅) > noBikes(橘) > 預設白
    final ringColor = isFull
        ? BrandColors.markerFullRing
        : noBikes
            ? BrandColors.markerNoBikeRing
            : Colors.white;

    const size = 40.0; // 容器大小

    final content = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.blue : ringColor,
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
        // 右上角 — 有電輔車的綠色圓點
        if (hasElectric)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: BrandColors.markerElectricDot,
                shape: BoxShape.circle,
              ),
            ),
          ),
        // 暫停營運 — 灰色半透明覆蓋
        if (isSuspended)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: BrandColors.markerSuspendedOverlay,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );

    return SizedBox(width: size, height: size, child: content);
  }
}

/// 既有 YouBike 風格入口 — 繼續 alias 對應「道路標誌風」。
/// 不帶任何狀態標記，對外用 `RoadSignMarker()` 的程式碼不需修改。
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