import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:youbike/core/config/app_environment.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/providers/loading_view_model.dart';
import 'package:youbike/ui/widgets/map_view.dart';
import 'package:youbike/providers/bike_station_view_model.dart';
import 'package:youbike/core/services/gps_requester.dart';
import 'package:youbike/ui/widgets/map_mask_overlay.dart';
import 'package:youbike/ui/widgets/loading_overlay.dart';
import 'package:youbike/ui/widgets/search_panel.dart';
import 'package:youbike/ui/widgets/home_update_button.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/firebase_service.dart';
import 'package:youbike/core/services/map_animated_move.dart';
import 'package:latlong2/latlong.dart' show Distance, LengthUnit;
import 'package:youbike/ui/widgets/github_update_alert_dialog.dart';
import 'package:youbike/core/services/update_checker_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/safe_map_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // SafeMapController drops non-finite moveRaw inputs at the boundary,
  // so NaN never reaches the camera state during flutter_map fling /
  // pinch animations. See safe_map_controller.dart for the rationale.
  final MapController _mapController = SafeMapController();
  double? _panelHeight;
  bool _isMapReady = false;
  AnimatedMapController? _animatedMap;

  MapViewModel get _mapVm => Provider.of<MapViewModel>(context, listen: false);

  @override
  void initState() {
    super.initState();
    // boot 統一口徑只在 AppWrapper 呼叫；這裡只負責把 mapController 接上。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bikeVm = Provider.of<BikeStationViewModel>(context, listen: false);
      bikeVm.mapTrigger.attach(_mapController);
      _animatedMap ??=
          AnimatedMapController(mapController: _mapController, vsync: this);
      // 若已經 boot 完成 (極慢網路, postFrame 才到)，補觸發 filter
      if (bikeVm.bootDone) {
        bikeVm.setQuery(bikeVm.activeQuery);
        _checkStartupUpdate();
      }
    });

    // 回報裝置活躍到 Firestore
    final config = Provider.of<AppConfigService>(context, listen: false);
    Future.microtask(() => FirestoreDeviceStatsService.instance
        .reportAppActive(config));
  }

  // 為了處理 bootDone 在 postFrameCallback 之後才變為 true 的情況，
  // 我們需要監聽 bikeVm.bootDone 的變化。
  // 但最簡單的做法是在 build 中檢查一次，並記錄已檢查過。
  bool _hasCheckedStartupUpdate = false;

  Future<void> _checkStartupUpdate() async {
    // Web build 不檢查更新（沒有原生 in-app update 流程，也不跳轉到 GitHub）。
    if (AppEnvironment.isWeb) {
      return;
    }

    final service = UpdateCheckerService();
    final config = Provider.of<AppConfigService>(context, listen: false);
    final versionOnly = config.appVersion.split('+').first;
    final l10n = AppLocalizations.of(context);

    try {
      // Fluttertoast plugin 在 Web 平台未實作，呼叫會拋 PlatformException。
      if (!AppEnvironment.isWeb) {
        Fluttertoast.showToast(msg: l10n.checking_for_updates);
      }
      final result = await service.checkForUpdate(currentVersion: versionOnly);
      if (!AppEnvironment.isWeb) Fluttertoast.cancel();
      if (!mounted) return;

      // Google Play 版的更新走 Play Store in-app update，
      // service 層已分流；這裡再守衛一次，避免任何 fallback 路徑誤觸 GitHub 提示。
      if (AppEnvironment.isGooglePlay) {
        return;
      }

      if (result.isLatest) {
        if (!AppEnvironment.isWeb) {
          Fluttertoast.showToast(msg: l10n.latest_version_installed);
        }
      } else {
        final latestRelease = await service.getLatestGithubRelease();
        if (latestRelease != null && mounted) {
          await GithubUpdateAlertDialog.show(context, latestRelease);
        }
      }
    } catch (e) {
      debugPrint('Startup update check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Consumer<BikeStationViewModel>(
      builder: (context, bikeVm, _) {
        if (!bikeVm.bootDone) {
          return Scaffold(
            backgroundColor: cs.surface,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!_hasCheckedStartupUpdate) {
          _hasCheckedStartupUpdate = true;
          Future.microtask(() => _checkStartupUpdate());
        }

        return Scaffold(
      backgroundColor: cs.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;

          // Use actual screen size (not viewInsets-affected constraints)
          // to determine layout type. Keyboard should not trigger layout switch.
          final screenSize = MediaQuery.of(context).size;
          final double screenAspectRatio = screenSize.width / screenSize.height;
          final bool isWide = screenAspectRatio > 0.8;

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
                    onMoveToStation: (pos, zoom) {
                      if (_animatedMap != null) {
                        _animatedMap!.animateTo(pos, zoom);
                      } else {
                        // Direct fallback when _animatedMap isn't built yet
                        // (postFrame not yet fired). Guard against NaN at
                        // this site so we don't bypass every other layer.
                        if (pos.latitude.isFinite &&
                            pos.longitude.isFinite &&
                            zoom.isFinite) {
                          _mapController.move(pos, zoom);
                        }
                      }
                    },
                    animatedMap: _animatedMap,
                    onFirstReady: () =>
                        Provider.of<BikeStationViewModel>(context, listen: false)
                            .mapTrigger
                            .setReady(),
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
                    onMoveToStation: (pos, zoom) {
                      if (_animatedMap != null) {
                        _animatedMap!.animateTo(pos, zoom);
                      } else {
                        // Direct fallback when _animatedMap isn't built yet
                        // (postFrame not yet fired). Guard against NaN at
                        // this site so we don't bypass every other layer.
                        if (pos.latitude.isFinite &&
                            pos.longitude.isFinite &&
                            zoom.isFinite) {
                          _mapController.move(pos, zoom);
                        }
                      }
                    },
                    animatedMap: _animatedMap,
                    onFirstReady: () =>
                        Provider.of<BikeStationViewModel>(context, listen: false)
                            .mapTrigger
                            .setReady(),
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
                        final bikeVm = Provider.of<BikeStationViewModel>(context,
                            listen: false);
                        // 上次的定位位置（可能為 null，例如首次進入或權限剛被拒）。
                        // 若有，馬上把地圖滑過去 — 給使用者即時視覺回饋，不必等 GPS。
                        final cached = _mapVm.lastKnownLocation;
                        if (cached != null && _animatedMap != null) {
                          _animatedMap!.animateTo(cached, 18.0);
                        }
                        // 等 GPS 拿到新位置後再 fire 一次。
                        // 使用 request() 而非 requestOrFallback() — 失敗回傳 null，
                        // 此時不要硬把地圖移走（避免覆蓋 cached 的位置）。
                        final pos = await gps.request(_mapVm);
                        if (!mounted) return;
                        if (pos != null && _animatedMap != null) {
                          // 若新位置與上次相差 < 50m，視為同一點，不觸發第二次動畫
                          // （否則會打斷剛剛那段動畫造成畫面抖動）。
                          final movedFar = cached == null ||
                              const Distance()
                                      .as(LengthUnit.Meter, cached, pos) >
                                  50;
                          if (movedFar) {
                            _animatedMap!.animateTo(pos, 18.0);
                          }
                        }
                        // 刷新即時車輛數據；camera 移動由上面手動控制，不傳 moveTo。
                        bikeVm.refresh();
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
   },
   ); // Consumer
  }
}
