// FirebaseService — 平台分流統一入口
//
// 條件匯出策略（dart.library.io）：
//   - Web（dart2js）：全部 stub，零 Firebase 依賴，APK 不含 Firebase SDK
//   - 原生（Android / iOS）：完整 Firebase + Firestore + FCM
//
// 匯出的 class（平台適配）：
//   - FirebaseCoreService
//   - FirestoreDeviceStatsService
//   - FcmTokenService
//   - FcmMessageHandler
//   - FirebaseService（向後相容 wrapper）

export 'firebase/firebase_core_stub.dart'
    if (dart.library.io) 'firebase/firebase_core_service.dart';

export 'firebase/firestore_device_stats_stub.dart'
    if (dart.library.io) 'firebase/firestore_device_stats_service.dart';

export 'firebase/fcm_service_stub.dart'
    if (dart.library.io) 'firebase/fcm_service.dart';

export 'firebase_service_compat.dart';