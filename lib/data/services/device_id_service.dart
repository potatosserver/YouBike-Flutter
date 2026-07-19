// DeviceIdService — 平台分流入口
// Web：stub（fallback 值）
// Native：device_info_plus + SHA256

export 'device_id_service_stub.dart'
    if (dart.library.io) 'device_id_service_native.dart';
