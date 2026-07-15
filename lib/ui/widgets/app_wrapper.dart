import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/ui/screens/home_screen.dart';
import 'package:youbike_android/ui/widgets/loading_overlay.dart';
import 'package:youbike_android/providers/loading_view_model.dart';
import 'package:youbike_android/providers/station_view_model.dart';
import 'package:youbike_android/providers/map_view_model.dart';
import 'package:youbike_android/core/utils/log_service.dart';

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
    final stationVm = Provider.of<StationViewModel>(context, listen: false);
    final mapVm = Provider.of<MapViewModel>(context, listen: false);

    loadingVm.setLoading(true);
    loadingVm.updateStatus('init_starting', progress: 5);

    try {
      // --- 階段 1: 定位與權限 ---
      loadingVm.updateStatus('init_requesting_permission', progress: 12);
      await Future.delayed(const Duration(milliseconds: 500));

      loadingVm.updateStatus('init_locating', progress: 24);
      await mapVm.requestAndCenterLocation();

      // --- 階段 2: 地圖引擎準備 ---
      loadingVm.updateStatus('init_map_engine', progress: 38);
      await Future.delayed(const Duration(milliseconds: 400));

      loadingVm.updateStatus('init_map_tiles', progress: 52);
      await Future.delayed(const Duration(milliseconds: 400));

      // --- 階段 3: 數據同步 (掛鉤真實數據) ---
      loadingVm.updateStatus('init_syncing', progress: 68);
      await stationVm.fetchBaseData(loadingVm); // 傳入 loadingVm 以回報數量

      loadingVm.updateStatus('init_clustering', progress: 86);
      await stationVm.refreshCards();

      loadingVm.updateStatus('init_updating', progress: 96);
      await Future.delayed(const Duration(milliseconds: 300));
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 底層：主畫面預先渲染
        const HomeScreen(),

        // 頂層：共用真實載入層
        LoadingOverlay(isVisible: _isInitializing),
      ],
    );
  }
}
