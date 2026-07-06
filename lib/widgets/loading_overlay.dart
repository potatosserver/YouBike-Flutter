import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDarkMode = appState.isDarkMode;

    return Material(
      // 網頁版 #loadingOverlay: background-color: rgba(255, 255, 255, 1)
      color: isDarkMode ? const Color(0xFF1C1B1F) : Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 網頁版 #loadingText: font-size: 1.5em, color: #007BFF, text-align: center
            Text(
              "${appState.currentLang.startsWith('en') ? 'Loading' : '載入中'}：${appState.loadingProgress}%",
              style: const TextStyle(
                fontSize: 24, // 約 1.5em
                fontWeight: FontWeight.w500,
                color: Color(0xFF007BFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10), // margin-top: 10px
            // 網頁版 #noticeBox: background: #fff, padding: 10px, border: 1px solid #ccc, border-radius: 5px
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2C2B30) : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isDarkMode ? Colors.white24 : const Color(0xFFCCCCCC),
                  width: 1,
                ),
              ),
              child: Text(
                appState.loadingNotice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
