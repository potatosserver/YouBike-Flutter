
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _panelHeight = MediaQuery.of(context).size.height * 0.35;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.of(context).size;
          final isWide = size.width >= 600;
          final appState = Provider.of<AppState>(context);

          return Stack(
            children: [
              // 1. Base Map Layer
              if (isWide)
                Positioned(
                  left: 408, top: 20, 
                  width: size.width - 428, height: size.height - 40,
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
                  height: size.height - (_panelHeight ?? size.height * 0.35),
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
                    panelHeight: _panelHeight ?? size.height * 0.35,
                    isWide: isWide,
                    leftOffset: isWide ? 408.0 : null,
                  ),
                ),
              ),
              
              // 3. Floating Panels
              if (isWide)
                Positioned(top: 20, bottom: 20, left: 20, width: 368, 
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
                  height: _panelHeight ?? size.height * 0.35,
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
                  bottom: (_panelHeight ?? size.height * 0.35) - 40, 
                  left: 0, 
                  right: 0, 
                  height: 140,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      double newHeight = (_panelHeight ?? size.height * 0.35) - details.delta.dy;
                      newHeight = newHeight.clamp(size.height * 0.2, size.height * 0.8);
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
                bottom: isWide ? 20 : (_panelHeight ?? size.height * 0.35) + 20, 
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF4A4A4A) : const Color(0xFFFDCACB),
                    borderRadius: BorderRadius.circular(12), 
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.my_location, size: 22, color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : Colors.black87),
                    onPressed: () {
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
              if (appState.isLoading)
                const LoadingOverlay(),
            ],
          );
        },
      ),
    );
  }
}
