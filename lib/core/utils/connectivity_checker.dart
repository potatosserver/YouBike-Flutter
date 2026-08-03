// ConnectivityChecker — 平台分流統一入口
//
// 條件匯出策略：
//   - 原生（Android / iOS）：connectivity_checker_native（connectivity_plus）
//   - Web：connectivity_checker_stub（dart:js_interop 讀 navigator.connection）

export 'connectivity_checker_native.dart'
    if (dart.library.js_interop) 'connectivity_checker_stub.dart';