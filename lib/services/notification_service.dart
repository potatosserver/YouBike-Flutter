class NotificationService {
  // 翻譯自 loadingService.js: showRandomNotice
  static const List<String> _notices = [
    "YouBike 2.0 讓通勤更方便！",
    "記得騎乘完畢後將車輛停在正確的站牌區域喔！",
    "使用 YouBike 減少碳排放，保護地球環境。",
    "發現 YouBike 故障？請透過官方 App 通報。",
    "嘗試探索不同的騎乘路徑，發現城市的另一面。",
    "YouBike 2.0E 電動單車，讓爬坡不再吃力！",
    "騎乘 YouBike 前，請檢查煞車與輪胎狀態。",
  ];

  static String getRandomNotice() {
    // In a real app, use Random()
    return _notices[0]; 
  }
}
