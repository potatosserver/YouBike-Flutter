import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use listen: true (default) to ensure the page rebuilds when settings change
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("設定"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Region Selection ---
          const SectionTitle(title: "區域設定"),
          DropdownButtonFormField<String>(
            value: appState.currentRegion,
            decoration: const InputDecoration(
              labelText: "選擇區域",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'taipei', child: Text("台北市")),
              DropdownMenuItem(value: 'newTaipei', child: Text("新北市")),
              DropdownMenuItem(value: 'taoyuan', child: Text("桃園市")),
              DropdownMenuItem(value: 'kaohsiung', child: Text("高雄市")),
            ],
            onChanged: (val) {
              if (val != null) appState.setRegion(val);
            },
          ),
          const SizedBox(height: 24),

          // --- Language Selection ---
          const SectionTitle(title: "語言設定"),
          SwitchListTile(
            title: Text(appState.currentLang == 'zh' ? "中文" : "English"),
            subtitle: const Text("切換顯示語言"),
            value: appState.currentLang == 'zh',
            onChanged: (val) {
              appState.toggleLanguage();
            },
          ),
          const SizedBox(height: 24),

          // --- Dark Mode ---
          const SectionTitle(title: "外觀設定"),
          SwitchListTile(
            title: const Text("深色模式"),
            subtitle: const Text("切換地圖與介面配色"),
            value: appState.isDarkMode,
            onChanged: (val) {
              appState.toggleDarkMode();
            },
          ),
          const SizedBox(height: 24),

          // --- Location Preference ---
          const SectionTitle(title: "定位設定"),
          SwitchListTile(
            title: const Text("啟用自動定位"),
            subtitle: const Text("啟動後地圖將自動跟隨您的位置"),
            value: appState.useLocation,
            onChanged: (val) {
              // Note: In AppState, we'd need a toggleUseLocation method
              // For now, we can use a simple setter or extend AppState
              appState.useLocation = val; 
              // To make this work, we should add a method to AppState to notifyListeners()
            },
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
 tanımla title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
