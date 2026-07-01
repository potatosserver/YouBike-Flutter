# YouBike 專案遷移說明書：Web $\rightarrow$ Flutter Android

本文件記錄將 `potatosserver/YouBike` 網頁版專案完整翻譯並重構成 Flutter Android 版本的過程、對應關係與實作邏輯。

## 1. 技術棧變更 (Technical Stack)

| 項目 | 網頁版 (Original) | Android 版 (Migrated) | 說明 |
| :--- | :--- | :--- | :--- |
| **語言** | HTML5, CSS3, JavaScript (ES6) | Dart | 從指令式 DOM 操作轉為聲明式 UI |
| **框架** | 原生 Web | Flutter 3.x | 跨平台 UI 框架 |
| **地圖引擎** | Leaflet.js | `flutter_map` | 從 JS 庫轉為 Flutter 原生插件 |
| **狀態管理** | 全域 JS 物件 (`state`) | `provider` (ChangeNotifier) | 實現數據驅動 UI 的響應式更新 |
| **網路請求** | Fetch API | `http` package | 統一異步處理 API 調用 |
| **本地存儲** | `localStorage` | `shared_preferences` | 儲存語言與深色模式偏好 |
| **定位服務** | `navigator.geolocation` | `geolocator` | 調用 Android 原生 GPS 權限 |

---

## 2. 檔案對照表 (File Correspondence)

### 2.1 視覺與佈局 (UI/UX)
| 網頁檔案 | Flutter 檔案 | 翻譯重點 |
| :--- | :--- | :--- |
| `index.html` | `lib/main.dart` $\rightarrow$ `lib/screens/home_screen.dart` | 將 HTML 結構翻譯為 `Stack` $\rightarrow$ `FlutterMap` $\rightarrow$ `DraggableScrollableSheet` 的層級結構。 |
| `css/variables.css` | `lib/widgets/app_theme.dart` | 將 CSS 變數 (`--primary-color` 等) 轉化為 `AppColors` 靜態常量類。 |
| `css/layout.css` / `components.css` | `lib/screens/home_screen.dart` | 將 CSS 的 `border-radius`, `box-shadow` 及 `Flexbox` 佈局翻譯為 `BoxDecoration` 與 `Column/Row`。 |
| `css/darkMode.css` | `lib/main.dart` (`ThemeData`) | 將 `.dark-mode` 類別切換翻譯為 `ThemeMode.dark` 與 `ThemeData` 的對應配色。 |

### 2.2 核心邏輯與服務 (Logic/Services)
| 網頁檔案 | Flutter 檔案 | 翻譯重點 |
| :--- | :--- | :--- |
| `js/config.js` | `lib/services/app_state.dart` | **完全移植**。將地區座標 `regionCoordinates` 與全域 `state` 封裝進 `AppState` 類別中。 |
| `js/main.js` | `lib/services/app_state.dart` $\rightarrow$ `HomeScreen` | 將初始化流程 `initializeApp()` 翻譯為 `AppState` 的初始化邏輯與 UI 綁定。 |
| `js/apiYoubike.js` / `apiElectric.js` | `lib/services/api_service.dart` | 翻譯 API 請求邏輯，將 JSON 數據解析為強型別的 `Station` 模型。 |
| `js/apiRoute.js` | `lib/services/route_service.dart` | 實作 OSRM API 請求，將路徑資訊翻譯為 `RouteStep` 列表。 |
| `js/mapService.js` | `lib/screens/home_screen.dart` | 將 Leaflet 的地圖初始化、Marker 渲染翻譯為 `FlutterMap` 的配置與 `MarkerLayer`。 |
| `js/language.js` | `lib/services/language_service.dart` | 將中英文對照字典完整移植至 `LanguageService` 的 `Map` 結構中。 |
| `js/loadingService.js` | `lib/widgets/loading_overlay.dart` | 還原啟動時的百分比進度條動畫與 `NotificationService` 的隨機通知提示。 |
| `js/locationTracker.js` | `lib/services/location_service.dart` | 將瀏覽器定位 API 翻譯為 `geolocator` 插件的權限請求與坐標獲取。 |
| `js/countdown.js` | `lib/services/app_state.dart` (`_startRefreshCycle`) | 使用 `Timer.periodic` 實作 60 秒自動刷新車輛數據的計時邏輯。 |
| `js/dbService.js` | `lib/services/app_state.dart` (Prefs) | 將 `localStorage` 操作翻譯為 `shared_preferences` 的異步讀寫。 |

---

## 3. 功能實作細節 (Functional Translation)

### 3.1 狀態管理 (State Management)
網頁版依賴於一個巨大的全域 `state` 物件。在 Flutter 中，我使用了 **Provider 模式**。
- **AppState**: 充當單一真相來源 (Single Source of Truth)，管理地區、語言、深色模式、站牌快取與倒數計時。
- **響應式更新**: 當 `AppState` 調用 `notifyListeners()` 時，UI 中的地圖 Marker、計時器文字與搜尋列表會立即更新，無需手動操作 DOM。

### 3.2 視覺還原 (Visual Fidelity)
- **拖拽面板**: 使用 `DraggableScrollableSheet` 完美還原了網頁版底部可上下拉伸的搜尋結果區域。
- **啟動遮罩**: 實作了一個 `Stack` 頂層的 `LoadingOverlay`，模擬原版從 $0\%$ 到 $100\%$ 的加載過程。
- **設定面板**: 將原版的 `centralSettingsPanel` 翻譯為 Flutter 的 `Drawer`，保留了所有選項 (地區、語言、深色模式)。

### 3.3 地圖與標記 (Map & Markers)
- **Marker 渲染**: 將 Leaflet 的 `L.divIcon` 翻譯為 Flutter 的 `Icon` 組件，並搭配 `AppColors.primary` 保持品牌一致性。
- **座標中心**: 實作了 `center` getter，根據當前選擇的地區自動切換地圖中心點。

---

## 4. 差異與優化 (Differences & Improvements)

1. **強型別模型**: 引入了 `Station` 與 `RouteStep` 類別，取代了 JS 的 `dynamic` 物件，大幅減少運行時錯誤。
2. **性能優化**: 透過 `Provider` 局部刷新，避免了網頁版頻繁操作 DOM 導致的性能開銷。
3. **原生權限**: 增加了 Android 的 `LocationPermission` 處理流程，確保定位功能在行動端能穩定運行。
