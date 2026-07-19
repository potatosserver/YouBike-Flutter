// 🚧 Firebase 設定檔
//
// 請依照以下步驟產生正式設定：
//
// 1. 在 Firebase Console (https://console.firebase.google.com) 建立專案
// 2. 新增 Android App，套件名稱為「com.potatosserver.youbike」
// 3. 下載 google-services.json 放到 android/app/ 目錄下
// 4. 執行下列指令產生此檔案：
//
//    dart pub global activate flutterfire_cli
//    flutterfire configure --project=你的Firebase專案ID
//
// 5. 啟用 Firestore 資料庫（建立一個名為 device_stats 的 collection）
// 6. 啟用 Cloud Messaging (FCM) 以使用推播功能
//
// 如果只是想測試，也可以直接將 google-services.json 放入
// android/app/ 目錄，Firebase.initializeApp() 會自動讀取。

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Firebase 專案組態
///
/// 由 `flutterfire configure` 自動產生。
/// 目前為佔位設定 — 請依照上方註解完成 Firebase 設定。
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  // ⚠️ 以下為範例佔位值，請替換為你 Firebase 專案的實際值
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_HASH',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  );
}