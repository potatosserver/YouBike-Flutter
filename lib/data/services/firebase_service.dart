// FirebaseService — 平台分流入口
// Web：stub（全 no-op）
// Android：native（Firebase + Firestore + FCM）

export 'firebase_service_stub.dart'
    if (dart.library.io) 'firebase_service_native.dart';
