// Conditional import — 編譯時依平台選對應的 storage 實作。
// dart:io (Android/iOS) → FileStationCacheStorage
// dart:html (Web)     → LocalStorageCacheStorage
//
// 兩個實作檔案各自 export 一個同名的 [createStorage()] factory，
// main service 透過 conditional import 拿到對應版本。
export 'station_cache_storage_io.dart' if (dart.library.html) 'station_cache_storage_web.dart'
    show createStorage;
