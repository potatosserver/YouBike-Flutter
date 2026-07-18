# YouBike 微笑單車 — 全台即時查詢 App

> 全台 YouBike 微笑單車即時查詢 Android App，使用 Flutter 打造。
> Material Design 3 · 橘色品牌設計 · 零靜態分析錯誤

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## ✨ 功能特色

- 🗺️ **全台站點地圖** — 支援 13 縣市、9,338+ 個 YouBike 站點，使用 `flutter_map` 搭配聚類標記
- 📍 **GPS 即時定位** — 自動定位目前位置，顯示附近站點，支援脈衝動畫標記
- 🔍 **智慧搜尋** — 依站點名稱、地址快速搜尋，結果依距離排序
- 🚶 **步行導航** — 整合 GraphHopper API，提供步行路線規劃與步驟指引
- ⚡ **即時車輛數據** — 60 秒自動更新可借/可停數量，支援手動刷新
- 🔋 **電動車資訊** — 顯示電動輔助自行車電池電量詳情
- ⭐ **釘選站點** — 將常用站點釘選置頂，快速查看
- 🌐 **多語系支援** — 繁體中文 / English，自動跟隨系統語言
- 🎨 **Material Design 3** — 橘色品牌種子色，支援淺色/深色/系統主題切換
- 📶 **網路狀態感知** — 自動偵測連線狀態，離線時友善提示

---

## 📸 畫面截圖

| 地圖主畫面 | 站點卡片 | 步行導航 |
|:---:|:---:|:---:|
| 地圖 + 搜尋面板 | 即時車輛數據 | 路線步驟指引 |

---

## 🏗️ 架構概覽

```
lib/
├── main.dart                    ← 啟動入口 (Zero-Jump 初始化)
├── core/
│   ├── l10n/                    ← ARB 多語系 (zh_TW / en)
│   ├── router/                  ← GoRouter 路由表
│   ├── services/                ← 無狀態服務層 (10 個)
│   ├── theme/                   ← M3 主題 + 品牌色
│   └── utils/                   ← 結構化 Log 服務
├── data/
│   ├── models/                  ← Station 資料模型
│   └── services/                ← API / 配置 / 語系 / 導航服務
├── providers/                   ← ChangeNotifier ViewModels
└── ui/
    ├── app.dart                 ← MaterialApp.router 入口
    ├── screens/                 ← 頁面 (主畫面/設定/主題/語言/區域)
    └── widgets/                 ← 可複用元件 (地圖/標記/卡片/面板)
```

### 核心服務呼叫鏈

```
CardRefreshCoordinator (統一口)
  ├─ 1. LocationResolver    → 決定參考座標 (GPS or 區域中心)
  ├─ 2. StationSorter       → 距離排序 + 釘選置頂 + 取前 10
  ├─ 3. RealtimeUpdater     → API 批次即時車輛數據
  └─ 4. MapMoveTrigger      → 地圖動畫移動
```

---

## 🚀 快速開始

### 環境需求

- **Flutter SDK** ≥ 3.0
- **Dart SDK** ≥ 3.0
- **Android Studio** / **VS Code**
- **Android 模擬器** 或實體裝置 (API 21+)

### 安裝與執行

```bash
# 1. 複製專案
git clone <repo-url>
cd YouBike-Flutter

# 2. 安裝依賴
flutter pub get

# 3. 產生多語系檔案
flutter gen-l10n

# 4. 執行專案
flutter run
```

### 靜態分析

```bash
flutter analyze
# 0 errors · 0 warnings · 0 infos
```

---

## 📦 主要依賴

| 套件 | 用途 |
|---|---|
| [`flutter_map`](https://pub.dev/packages/flutter_map) | 地圖顯示 (OpenStreetMap) |
| [`provider`](https://pub.dev/packages/provider) | 狀態管理 |
| [`go_router`](https://pub.dev/packages/go_router) | 宣告式路由 |
| [`geolocator`](https://pub.dev/packages/geolocator) | GPS 定位 |
| [`http`](https://pub.dev/packages/http) | HTTP 請求 |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | 本地偏好持久化 |
| [`sliding_up_panel`](https://pub.dev/packages/sliding_up_panel) | 滑動面板 |
| [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) | 網路狀態偵測 |
| [`flutter_html`](https://pub.dev/packages/flutter_html) | HTML 內容渲染 |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | 外部連結開啟 |

---

## 🎨 品牌色

| 顏色 | Hex | 用途 |
|---|---|---|
| 🟠 品牌橘 | `#FF9800` | 種子色、啟動畫面、進度條 |
| 🟡 標記黃 | `#FFD700` | 站點標記、聚類圓 |
| 🔵 導航藍 | `Colors.blue` | 導航圖標、GPS 脈衝、站點名稱 |
| 🟢 電動綠 | `#4CAF50` | 電動車圖標、電池百分比 |

---

## 📄 授權

本專案採用 MIT 授權條款。詳見 [LICENSE](LICENSE) 檔案。

---

## 🙏 致謝

- 資料來源：[YouBike 微笑單車](https://www.youbike.com.tw/)
- 地圖服務：[OpenStreetMap](https://www.openstreetmap.org/)
- 導航服務：[GraphHopper](https://www.graphhopper.com/)
- 圖標：[Material Design Icons](https://fonts.google.com/icons)
