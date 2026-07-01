import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("系統偵錯資訊"),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDebugSection("基礎狀態", [
              _buildDebugItem("目前區域", appState.currentRegion),
              _buildDebugItem("目前語言", appState.currentLang),
              _buildDebugItem("深色模式", appState.isDarkMode.toString()),
              _buildDebugItem("追蹤模式", appState.isFollowingUser.toString()),
              _buildDebugItem("加載中", appState.isLoading.toString()),
            ]),
            const Divider(),
            _buildDebugSection("數據量", [
              _buildDebugItem("總站牌數", appState.searchResults.length.toString()), // 這裡應顯示所有站牌
              _buildDebugItem("地圖 Marker 數", appState.stationMarkers.length.toString()),
              _buildDebugItem("倒數計時", appState.countdown.toString()),
            ]),
            const Divider(),
            _buildDebugSection("座標資訊", [
              _buildDebugItem("中心點", appState.center.toString()),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 簡單的複製到剪貼簿邏輯 (可選)
              },
              child: const Text("複製所有資訊"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        ...items,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace', color: Colors.blue)),
        ],
      ),
    );
  }
}
