import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/language_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/settings_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      // 1. 側邊設定面板 (還原 centralSettingsPanel)
      drawer: const SettingsPanel(),
      
      body: Stack(
        children: [
          // 2. 地圖層 (還原 map-wrapper)
          FlutterMap(
            options: MapOptions(
              initialCenter: appState.center,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) appState.setFollowingUser(false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.youbike.android',
              ),
              MarkerLayer(markers: appState.stationMarkers),
            ],
          ),

          // 3. 頂部刷新計時器 (還原 updateCountdown)
          Positioned(
            top: 50,
            right: 20,
            child: _buildCountdownButton(context, appState),
          ),

          // 4. 設定按鈕 (還原 settingsButton)
          Positioned(
            top: 50,
            left: 20,
            child: Builder(
              builder: (context) => FloatingActionButton.small(
                heroTag: 'settings',
                backgroundColor: AppColors.primary,
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.settings, color: Colors.white),
              ),
            ),
          ),

          // 5. 底部可拖拽搜尋面板 (還原 mainContent)
          _buildBottomSearchPanel(context, appState),

          // 6. 啟動遮罩 (還原 loadingOverlay)
          const LoadingOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => appState.updateUserLocation(),
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.my_location,
          color: appState.isFollowingUser ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildCountdownButton(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.autorenew, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            "${appState.countdown} ${LanguageService.getText('update_countdown', appState.currentLang)}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchPanel(BuildContext context, AppState appState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: appState.isDarkMode ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
            ],
          ),
          child: Column(
            children: [
              // 拖拽把手 (還原 dragHandle)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 搜尋框 (還原 searchContainer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: LanguageService.getText('search_placeholder', appState.currentLang),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    filled: true,
                    fillColor: appState.isDarkMode ? Colors.black26 : Colors.grey[100],
                  ),
                  onChanged: (val) => appState.searchStations(val),
                ),
              ),
              const SizedBox(height: 10),
              // 結果列表 (還原 results)
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: appState.searchResults.length,
                  itemBuilder: (context, index) {
                    final s = appState.searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.directions_bike, color: AppColors.primary),
                      title: Text(appState.currentLang == 'en' ? s.nameEn : s.nameTw),
                      subtitle: Text(appState.currentLang == 'en' ? s.addressEn : s.addressTw),
                      onTap: () => appState.focusStation(s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
