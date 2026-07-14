# Flutter L10n 最佳實踐指南

## 📦 正規方式檢查清單

### 1. 專案結構
```
your_project/
├── l10n.yaml                          # ✅ 必需的配置檔
├── lib/
│   ├── core/
│   │   ├── l10n/
│   │   │   ├── app_en.arb            # 英文翻譯
│   │   │   ├── app_zh.arb            # 中文翻譯
│   │   │   ├── app_localizations.dart  # 生成檔（勿編輯）
│   │   │   ├── app_localizations_en.dart
│   │   │   ├── app_localizations_zh.dart
│   │   │   └── l10n_extension.dart    # 助手類別（推薦）
│   │   └── router/
│   ├── ui/
│   │   └── app.dart                   # 主應用配置
│   └── main.dart
├── pubspec.yaml
```

### 2. pubspec.yaml 配置
```yaml
flutter:
  generate: true  # 自動生成 l10n 檔案

dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
```

### 3. l10n.yaml 配置
```yaml
arb-dir: lib/core/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
synthetic-locale: false
supported-locales:
  - en
  - zh
```

### 4. .arb 檔案格式規範

**✅ 好的範例：**
```json
{
  "@@locale": "en",
  "@@context": "Application strings",
  "appTitle": "YouBike",
  "@appTitle": {
    "description": "Application title shown in header"
  },
  "greetingMessage": "Hello {name}",
  "@greetingMessage": {
    "description": "Greeting message with user name",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "John"
      }
    }
  }
}
```

### 5. 程式碼中使用 L10n

**❌ 不推薦的方式：**
```dart
// 重複編寫 AppLocalizations.of(context)!
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle);
```

**✅ 推薦方式（使用擴展）：**
```dart
// 直接透過 context 訪問
Text(context.l10n.appTitle)
```

**✅ 或使用 switch 表達式：**
```dart
String _translateNotice(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'init_starting' => l10n.init_starting,
    'init_syncing' => l10n.init_syncing,
    _ => key,
  };
}
```

### 6. App 配置最佳實踐

```dart
class MyApp extends StatelessWidget {
  // 集中管理支持的語言
  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 重要！
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      // ...
    );
  }
}
```

## 🚀 生成流程

每次更新 .arb 檔案後，執行：

```bash
flutter gen-l10n
```

或自動方式（啟用 `generate: true`）：
```bash
flutter pub get
```

## ✨ 進階技巧

### 使用複數和數字格式化

```json
{
  "itemCount": "{count, plural, =0{No items} one{1 item} other{{count} items}}",
  "@itemCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

### 性別化字串

```json
{
  "userGreeting": "{gender, select, male{He is} female{She is} other{They are}} here.",
  "@userGreeting": {
    "placeholders": {
      "gender": {
        "type": "String"
      }
    }
  }
}
```

## 🔍 常見問題

1. **為什麼翻譯沒有出現？**
   - 確保執行 `flutter gen-l10n`
   - 檢查 `supportedLocales` 是否包含目標語言
   - 檢查 `localizationsDelegates` 是否設定正確

2. **怎樣才能動態切換語言？**
   - 使用 Provider 或其他狀態管理器
   - 更新 `AppConfigService.currentLang`
   - MaterialApp 的 `locale` 參數會自動更新

3. **怎樣處理缺失的翻譯鍵？**
   - 使用 `nullable-getter: false` 確保有預設值
   - 使用 switch 表達式的 `_` 捕捉未知鍵
