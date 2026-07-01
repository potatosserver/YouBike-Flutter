class LanguageService {
  // 翻譯自 language.js
  static const Map<String, Map<String, String>> _texts = {
    'zh': {
      'title': 'YouBike 站牌搜尋',
      'search_placeholder': '請輸入站牌名稱、地址',
      'settings_title': '系統設定',
      'region_select': '地區選擇',
      'location_service': '位置服務',
      'dark_mode': '深色模式',
      'lang_toggle': '中英文切換',
      'update_countdown': '秒後更新',
      'address': '地址',
      'slots': '可停空位數',
      'route_info': '路徑資訊',
      'no_results': '查無符合結果',
      'loading': '進入中',
    },
    'en': {
      'title': 'YouBike Site Search',
      'search_placeholder': 'Enter station name or address',
      'settings_title': 'System Settings',
      'region_select': 'Region Selection',
      'location_service': 'Location Service',
      'dark_mode': 'Dark Mode',
      'lang_toggle': 'Language Toggle',
      'update_countdown': 's until update',
      'address': 'Address',
      'slots': 'Available Slots',
      'route_info': 'Route Information',
      'no_results': 'No results found',
      'loading': 'Loading...',
    },
  };

  static String getText(String key, String lang) {
    return _texts[lang]?[key] ?? _texts['en']![key] ?? key;
  }
}
