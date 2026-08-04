import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/ui/screens/home_screen.dart';
import 'package:youbike/ui/widgets/loading_overlay.dart';
import 'package:youbike/providers/loading_view_model.dart';
import 'package:youbike/providers/bike_station_view_model.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/core/config/app_environment.dart';
import 'package:youbike/core/services/gps_requester.dart';
import 'package:youbike/core/services/update_checker_service.dart';
import 'package:youbike/core/utils/log_service.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _initializeApp();
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    final loadingVm = Provider.of<LoadingViewModel>(context, listen: false);
    final stationVm = Provider.of<BikeStationViewModel>(context, listen: false);
    final mapVm = Provider.of<MapViewModel>(context, listen: false);

    loadingVm.setLoading(true);
    loadingVm.updateStatus('init_starting', progress: 5);

    try {
      loadingVm.updateStatus('init_requesting_permission', progress: 12);
      await Future.delayed(const Duration(milliseconds: 500));

      loadingVm.updateStatus('init_locating', progress: 24);
      const gps = GpsRequester();
      await gps.requestOrFallback(mapVm);

      loadingVm.updateStatus('init_map_engine', progress: 38);
      await Future.delayed(const Duration(milliseconds: 400));

      loadingVm.updateStatus('init_map_tiles', progress: 52);
      await Future.delayed(const Duration(milliseconds: 400));

      loadingVm.updateStatus('init_syncing', progress: 68);
      // 由 AppWrapper 統一執行 boot — 確保 LoadingOverlay 與 bootDone 同步。
      await stationVm.boot();

      loadingVm.updateStatus('init_clustering', progress: 86);

      loadingVm.updateStatus('init_updating', progress: 96);
      await Future.delayed(const Duration(milliseconds: 300));

      // Only use updateChannel for runtime update behavior.
      // FLAVOR is not involved in this app initialization flow.
      if (AppEnvironment.isGooglePlay) {
        await _checkGooglePlayUpdate();
      }
    } catch (e) {
      LogService().e('APP_INIT', 'Initial data fetch failed', error: e);
    } finally {
      loadingVm.setFinished();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _checkGooglePlayUpdate() async {
    try {
      final updateInfo =
          await UpdateCheckerService().checkForGooglePlayUpdate();
      if (updateInfo != null) {
        await UpdateCheckerService().startGooglePlayUpdate(updateInfo);
      }
    } catch (e, st) {
      LogService().e('UPDATE', 'Google Play update check failed',
          error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        LoadingOverlay(isVisible: _isInitializing),
      ],
    );
  }
}
