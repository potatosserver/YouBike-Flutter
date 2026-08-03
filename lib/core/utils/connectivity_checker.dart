// ConnectivityChecker — 平台分流統一入口
//
// 條件匯出策略：
//   - Web：conn_checker_stub（讀取 navigator.connection.effectiveType）
//   - 原生：conn_checker_native（connectivity_plus）

export 'connectivity_checker_stub.dart'
    if (dart.library.js_interop) 'connectivity_checker_native.dart';