# YouBike + Moovo 合併計畫（批次版）

> **目標**：「API 邊界兩條、其餘全部一個程式碼」
>
> — 兩條 API client 各自獨立；模型、ViewModel、UI 全部透過同一條 facade 走，內部不認得「來源」。

---

## 0. 不變的硬約束

- `lib/data/services/api_service.dart` (`ApiService`)
- `lib/data/services/moovo/moovo_api_client.dart` (`MoovoApiClient`)
↑ 兩條到此為止；下面一律透過 Repository facade 整合。

> 任何時候有人問「這樣會不會解耦到太抽象」，就停在 Repository facade 退回上一層實作，不要過度設計。

---

## 1. 分批規劃

| Batch | 步驟 | 名稱 | 收斂點 |
|---|---|---|---|
| **A** | 1–4 | 資料層鷹架 | Batch A 結束時：`flutter analyze` 0 error；App 使用者 0 變化；但介面/Repo/Sorter/VM 全就位 |
| **B** | 5 | UI 端接管 | **使用者真正可體驗合併效果**：sidebar 同一卡片、同一個 onTap handler |
| **C** | 6–7 | Popup / Route panel 一體化 | 兩來源的彈窗/路線對話框全部同一 widget |
| **D** | 8–12 | 清理 | 撤掉廢棄檔、標 deprecated 的 entry 全部移除 |

### 各 batch 內部步驟

| # | 名稱 | 改什麼 | 風險 | Gate |
|---|---|---|---|---|
| **1** | 抽 `BikeStation` 介面 + 兩個 adapter | 新 `lib/data/models/bike_station.dart`；`Station.toBike()`、`MoovoStation.toBike()` 工廠。**VM/UI 全不動** | 極低 | `flutter analyze` 0 |
| **2** | 共用 `BikeStationSorter` | 抽出共用排序/釘選/距離計算，舊 `StationSorter` 內部轉呼叫保留 deprecated | 低 | 同上 |
| **3** | Repository facade | 新 `lib/data/services/bike_station_repository.dart`，把兩條 API 收一起。`fetchByRegion`、`fetchRealtime(ids)` | 中 | 同上 |
| **4** | 合併 ViewModel | 新 `BikeStationViewModel` 既管 YouBike 也管 Moovo；兩舊 VM 暫留但 deprecated | 中 | 同上 |

> ⏸ **Batch A 結束** — 停下來讓使用者檢查：跑 App 看一切正常；你此時才決定要不要進 Batch B。

| **5** | UI 面板單一卡片 | `search_panel` 撤掉雙 onTap、單 shape；`BikeStationCard` 為唯一卡片 | 中 | `flutter analyze` 0 |

> ⏸ **Batch B 結束** — 關鍵停點：視覺/觸覺皆已合一。你可以摸、勾、點兩來源的站點卡片，看全順。這裡就是「可體驗合併效果」的地方。

| **6** | 共用 popup widget | `ui/widgets/bike_station_popup.dart` 取代 `if is Station / if is MoovoStation` | 中 | `flutter analyze` 0 |
| **7** | Route panel 拿掉 `isMoovo` flag | 內部用介面；`isMoovo` deprecated | 低 | 同上 |

> ⏸ **Batch C 結束** — 彈窗/導航也一體化

| **8** | Marker 統一 | `BikePinMarker.color` 仍保留（綠/黃視覺線索） | 極低 | 同上 |
| **9** | 集中 distance | 兩 VM 內各自 haversine 計算被刪，改呼叫集中點 | 極低 | 同上 |
| **10** | 釘選 id prefix 走型別 | `mv:` 字串 prefix 改為 `BikeStationSource` enum 隔離前綴 | 低 | 同上 |
| **11** | 設定頁 Beta 版入口友善化 | 視覺，不動行為 | 低 | 同上 |
| **12** | 撤回廢棄檔 | 確認 `StationCard`（舊）/ `StationSorter`（舊）/ `isMoovo` flag 無 caller 後刪 | 極低 | 同上 |

---

## 2. 驗收 gate（每步都跑）

```bash
export PATH="/home/user/development/flutter/bin:$PATH"
flutter analyze
```

> Build 由使用者自己跑，不在這份 plan 的 gate 範圍。

進階驗證（只在改了實際行為的步，使用者否自行驗）：

- 手動：開地圖、點 marker、進 search、輸入字串、選 pinned、導航
- 看 log：`flutter logs`（moovo refresh、youbike refresh 是否仍正確 fanout）

---

## 3. 完成檢視表

| # | 完成 | 驗收（最後一條要被打勾） |
|---|---|---|
| 1 | ✅ | `lib/data/models/bike_station.dart` 新檔存在；`Station.toBike()` 與 `MoovoStation.toBike()` 兩個 adapter 方法存在；`flutter analyze` 0 error |
| 2 | ✅ | 新 `lib/core/services/bike_station_sorter.dart` 存在；舊 `StationSorter.sortAndPick` 行為等價透過新 sorter；至少一個內部 call-site 切換到新排序；`flutter analyze` 0 error |
| 3 | ✅ | `lib/data/services/bike_station_repository.dart` 已建立，公開 `fetchYouBikeStations` / `fetchMoovoStations`；`flutter analyze` 0 error |
| 4 | ✅ | 新 `BikeStationViewModel` 融合兩源列表 + 同 refresh cycle；`flutter analyze` 0 error |
| 5 | ✅ | `search_panel` 內換到 `BikeStationViewModel` 單入口、`_buildStationPanel` 單 shape、跨城搜邏輯刪除；`flutter analyze` 0 error |
| 6 | ✅ | `map_view.dart` popup 只用 `BikeStation`，兩 Selector 合 1 個 `Consumer<BikeVM>`，`selected is Station` / `is MoovoStation` 全消；`flutter analyze` 0 |
| 7 | ✅ | `RouteDetailPanel` 拿掉 `isMoovo` flag 改用 `BikeStationSource?` source；`search_panel` call site 改傳 `BikeStationSource.moovo`；`flutter analyze` 0 |
| 8 | ☐ | 結尾清理；`flutter analyze` 0 error |
| 9 | ☐ | 結尾清理；`flutter analyze` 0 error |
| 10 | ☐ | 結尾清理；`flutter analyze` 0 error |
| 11 | ☐ | 結尾清理；`flutter analyze` 0 error |
| 12 | ☐ | 結尾清理；`flutter analyze` 0 error |

---

## 4. 反悔 escape hatch

每一步都設計成「commit 後再用 PR 撤回也方便」：
- 新介面 / 新檔 都**新加**而非**取代**
- 舊東西標 deprecated 但不刪，直到下一個步驟驗證該舊入口已 0 caller 才移除
- 若任一步失敗，可停在該步，小修或退回上一個 working state

---

## 5. 目前狀態

- ✅ Step 5 完成 — `search_panel` 單一 VM 入口；analyze 0
- ⏸ **Batch B 完成** — 側欄已合併，App 上有感
- 🔜 Step 6 待做 — popup widget