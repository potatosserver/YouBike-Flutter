
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/app_state.dart';
import '../widgets/map_view.dart';
import '../widgets/search_panel.dart';
import '../widgets/home_update_button.dart';
import '../widgets/map_mask_overlay.dart';
import '../widgets/loading_overlay.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  double? _panelHeight; 
  bool _isMapReady = false;

  AppState get _appState => Provider.of<AppState>(context, listen: false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;
          
          final double aspectRatio = availableWidth / availableHeight;
          final bool isWide = aspectRatio > 0.8;

          // 動態計算側邊欄寬度：佔寬度 30%，限制在 300~400px 之間
          final double sidebarWidth = isWide 
              ? (availableWidth * 0.3).clamp(300.0, 400.0) 
              : 0.0;
          const double horizontalMargin = 20.0;
          const double gap = 20.0;

          return Stack(
            children: [
              // 1. Base Map Layer
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
                    onMoveToStation: (pos, zoom) => _mapController.move(pos, zoom),
                  ),
                )
              else
                Positioned(
                  top: 0, left: 0, right: 0, 
                  height: availableHeight - (_panelHeight ?? availableHeight * 0.35),
                  child: MapView(
                    mapController: _mapController,
                    isMapReady: _isMapReady,
                    onReady: (ready) => setState(() => _isMapReady = ready),
                    onMoveToStation: (pos, zoom) => _mapController.move(pos, zoom),
                  ),
                ),
              
              // 2. Framed Mask Overlay (Wrapped in IgnorePointer for touch passthrough)
              Positioned.fill(
                child: IgnorePointer(
                  child: MapMaskOverlay(
                    maskColor: theme.brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
                    panelHeight: _panelHeight ?? availableHeight * 0.35,
                    isWide: isWide,
                    leftOffset: isWide ? horizontalMargin + sidebarWidth + gap : null,
                  ),
                ),
              ),
              
              // 3. Floating Panels
              if (isWide)
                Positioned(top: horizontalMargin, bottom: horizontalMargin, left: horizontalMargin, width: sidebarWidth, 
                  child: SearchPanel(
                    isWide: true, 
                    mapController: _mapController, 
                    onHeightChanged: (h) => setState(() => _panelHeight = h),
                  )
                )
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
              
              // 4. TOP-LEVEL Drag Touch Layer (Only for Narrow mode)
              if (!isWide)
                Positioned(
                  bottom: (_panelHeight ?? availableHeight * 0.35) - 40, 
                  left: 0, 
                  right: 0, 
                  height: 140,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      double newHeight = (_panelHeight ?? availableHeight * 0.35) - details.delta.dy;
                      newHeight = newHeight.clamp(availableHeight * 0.2, availableHeight * 0.8);
                      setState(() => _panelHeight = newHeight);
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              
              // 5. UI Buttons (Topmost)
              Positioned(
                top: 40, right: 15,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Center(child: Icon(Icons.settings, size: 22, color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : Colors.black87)),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: isWide ? 20 : (_panelHeight ?? availableHeight * 0.35) + 20, 
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF4A4A4A) : const Color(0xFFFDCACB),
                    borderRadius: BorderRadius.circular(12), 
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.my_location, size: 22, color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : Colors.black87),
                    onPressed: () async {
                      await _appState.requestAndCenterLocation();
                      LatLng snapPos = _appState.lastKnownLocation ?? _appState.getEffectiveLocation();
                      _mapController.move(snapPos, 18.0);
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 30, left: isWide ? 390 : 0, right: 0,
                child: const Center(child: HomeUpdateButton()),
              ),
              
              // 6. 頂層載入遮罩 (遮住所有內容直到初始化完成)
              Positioned.fill(
                child: Selector<AppState, bool>(
                  selector: (_, state) => state.isLoading,
                  builder: (context, isLoading, child) {
                    return isLoading ? const LoadingOverlay() : const SizedBox.shrink();
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
