import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/providers/loading_view_model.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isVisible;
  const LoadingOverlay({super.key, required this.isVisible});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  static const Color brandOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadingVm = Provider.of<LoadingViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: brandOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: brandOrange.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bike_rounded, 
                        size: 64, 
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  "YouBike",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: loadingVm.loadingProgress / 100, 
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(brandOrange),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _buildNoticeText(context, loadingVm),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildNoticeText(BuildContext context, LoadingViewModel vm) {
    final l10n = AppLocalizations.of(context);
    final key = vm.currentNotice;
    final val = vm.statusValue;

    // 處理動態數值插值
    if (key == 'init_syncing_stations') {
      final count = val ?? 0;
      return "正在載入 $count 個站點..."; 
      // 注意：實際應使用 l10n.syncing_stations(count)
    }

    // 普通 Key 映射
    switch (key) {
      case 'init_starting': return l10n.init_starting;
      case 'init_requesting_permission': return "請求定位權限...";
      case 'init_verifying_permission': return "驗證權限狀態...";
      case 'init_locating': return l10n.init_locating;
      case 'init_map_engine': return "啟動地圖渲染引擎...";
      case 'init_map_tiles': return "配置區域地圖快取...";
      case 'init_syncing': return l10n.init_syncing;
      case 'init_clustering': return "初始化站點集群...";
      case 'init_updating': return l10n.init_updating;
      case 'init_success': return l10n.init_success;
      default: return key;
    }
  }
}
