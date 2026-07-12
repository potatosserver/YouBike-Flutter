

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/app_state.dart';
import '../widgets/map_view.dart';
import '../widgets/search_panel.dart';
import '../widgets/home_update_button.dart';

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
          return Stack(
            children: [
              Positioned(
                top: isWide ? 12 : 0,
                left: isWide ? 392 : 0,
                right: isWide ? 12 : 0,
                bottom: isWide ? 12 : (_panelHeight ?? size.height * 0.35) + 12,
                child: MapView(
                  mapController: _mapController,
                  isMapReady: _isMapReady,
                  onReady: (ready) => setState(() => _isMapReady = ready),
                  onMoveToStation: (pos, zoom) => _mapController.move(pos, zoom),
                ),
              ),
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
              if (isWide)
                Positioned(top: 12, bottom: 12, left: 12, width: 368, 
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
              Positioned(
                bottom: 30, left: isWide ? 390 : 0, right: 0,
                child: const Center(child: HomeUpdateButton()),
              ),
            ],
          );
        },
      ),
    );
  }
}
