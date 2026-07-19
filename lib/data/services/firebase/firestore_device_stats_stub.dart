// firestore_device_stats_stub.dart — Web stub
//
// Web 平台無 Firestore，所有方法都是 no-op。

/// Web stub — Firestore device_stats 文件操作
class FirestoreDeviceStatsService {
  static FirestoreDeviceStatsService? _instance;

  FirestoreDeviceStatsService._();

  static FirestoreDeviceStatsService get instance {
    _instance ??= FirestoreDeviceStatsService._();
    return _instance!;
  }

  Future<void> reportAppActive() async {}
  Future<void> deleteDeviceStats() async {}
}