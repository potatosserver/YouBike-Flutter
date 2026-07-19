import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/providers/loading_view_model.dart';
import 'package:youbike/ui/widgets/map_view.dart';
import 'package:youbike/providers/station_view_model.dart';
import 'package:youbike/core/services/gps_requester.dart';
import 'package:youbike/ui/widgets/map_mask_overlay.dart';
import 'package:youbike/ui/widgets/loading_overlay.dart';
import 'package:youbike/ui/widgets/search_panel.dart';
import 'package:youbike/ui/widgets/home_update_button.dart';
import 'package:youbike/data/services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  double? _panelHeight;
  bool _isMapReady = false;

  MapViewModel get _mapVm => Provider.of<MapViewModel>(context, listen: false);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<StationViewModel>(context, listen: false)
            .mapTrigger
            .attach(_mapController);
      }
    });

    // 回報裝置活躍到 Firestore（非同步，失敗不影響使用）
    Future.microtask(() => FirebaseService.instance.reportAppActive());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;

          final double aspectRatio = availableWidth / availableHeight;
          final bool isWide = aspectRatio > 0.8;

          final double sidebarWidth =
              isWide ? (availableWidth * 0.3).clamp(300.0, 400.0) : 0.0;
          const double horizontalMargin = 20.0;
          const double gap = 20.0;

          return Stack(
            children: [
              if (isWide)
                Positioned(
                  left: horizontalMargin + sidebarWidth + gap,
                  top: horizontalMargin,
                  right: horizontalMargin,
                  bottom: horizontalMargin,
                  child: MapView(
                    mapController: _mapController,
                    isMapReady: _isMapReady,
                    onReady: (ready) => setState(() => _isMapReady = ready),
                    onMoveToStation: (pos, zoom) =>
                        _mapController.move(pos, zoom),
                  ),
                )
              else
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: availableHeight -
                      (_panelHeight ?? availableHeight * 0.35),
                  child: MapView(
                    mapController: _mapController,
                    isMapReady: _isMapReady,
                    onReady: (ready) => setState(() => _isMapReady = ready),
                    onMoveToStation: (pos, zoom) =>
                        _mapController.move(pos, zoom),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: MapMaskOverlay(
                    maskColor: cs.surface,
                    panelHeight: _panelHeight ?? availableHeight * 0.35,
                    isWide: isWide,
                    leftOffset:
                        isWide ? horizontalMargin + sidebarWidth + gap : null,
                  ),
                ),
              ),
              if (isWide)
                Positioned(
                    top: horizontalMargin,
                    bottom: horizontalMargin,
                    left: horizontalMargin,
                    width: sidebarWidth,
                    child: SearchPanel(
                      isWide: true,
                      mapController: _mapController,
                      onHeightChanged: (h) => setState(() => _panelHeight = h),
                    ))
              else
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: _panelHeight ?? availableHeight * 0.35,
                  child: SearchPanel(
                    isWide: false,
                    panelHeight: _panelHeight,
                    mapController: _mapController,
                    onHeightChanged: (h) => setState(() => _panelHeight = h),
                  ),
                ),
              if (!isWide)
                Positioned(
                  bottom: (_panelHeight ?? availableHeight * 0.35) - 40,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      double newHeight =
                          (_panelHeight ?? availableHeight * 0.35) -
                              details.delta.dy;
                      newHeight = newHeight.clamp(
                          availableHeight * 0.2, availableHeight * 0.8);
                      setState(() => _panelHeight = newHeight);
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ...[
                Positioned(
                  top: isWide ? (horizontalMargin + 16.0) : 40,
                  right: isWide ? (horizontalMargin + 16.0) : 15,
                  child: GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Center(
                          child: Icon(Icons.settings,
                              size: 22, color: cs.onSurface)),
                    ),
                  ),
                ),
                Positioned(
                  right: isWide ? (horizontalMargin + 16.0) : 20,
                  bottom: isWide
                      ? (horizontalMargin + 16.0)
                      : (_panelHeight ?? availableHeight * 0.35) + 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.my_location,
                          size: 22, color: cs.onSurface),
                      onPressed: () async {
                        const gps = GpsRequester();
                        final stationVm = Provider.of<StationViewModel>(context,
                            listen: false);
                        final pos = await gps.requestOrFallback(_mapVm);
                        if (!mounted) return;
                        stationVm.refreshCards(moveTo: pos);
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: isWide ? (horizontalMargin + 16.0) : 30,
                  left: isWide ? (horizontalMargin + sidebarWidth + gap) : 0,
                  right: isWide ? (horizontalMargin + 16.0) : 0,
                  child: const Center(child: HomeUpdateButton()),
                ),
              ],
              Positioned.fill(
                child: Selector<LoadingViewModel, bool>(
                  selector: (_, state) => state.isLoading,
                  builder: (context, isLoading, child) {
                    return isLoading
                        ? const LoadingOverlay(isVisible: true)
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
