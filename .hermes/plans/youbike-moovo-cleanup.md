# Step 8-12: 最終清理 + 舊 VM 移除

## 操作

| 步 | 動作 |
|---|---|
| 8 | home_update_button.dart → 改用 `BikeStationViewModel` |
| 9 | home_screen.dart → 改 mapTrigger 從新 VM、location button 改 new VM  |
| 10 | app_wrapper.dart → 改 init fetch 用新 VM |
| 11 | main.dart → 移除舊 StationVM / MoovoVM providers |
| 12 | 移除全專案中不再使用的 import 和 properties |

## 風險

home_screen 的 mapTrigger attach 已被新 VM 的 trigger 處理，但 step 6 已不再依賴舊 mapTrigger — 新 VM 有 _trigger 可單獨使用。確認沒有迴圈依賴再移除。再接 main.dart 清舊 Providers。

## 驗收

- flutter analyze 0