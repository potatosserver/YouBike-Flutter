class Station {
  final String id;
  final String nameTw;
  final String nameEn;
  final String addressTw;
  final String addressEn;
  final double lat;
  final double lng;
  
  // Real-time data
  int availableBikes;
  int availableElectricBikes;
  int totalBikes;
  int totalElectricBikes;

  Station({
    required this.id,
    required this.nameTw,
    required this.nameEn,
    required this.addressTw,
    required this.addressEn,
    required this.lat,
    required this.lng,
    this.availableBikes = 0,
    this.availableElectricBikes = 0,
    this.totalBikes = 0,
    this.totalElectricBikes = 0,
  });

  // 使用 static method 代替 factory 以支持可空返回 (null if invalid)
  static Station? fromJson(Map<String, dynamic> json) {
    try {
      // 嚴格檢查座標是否存在且為數字
      final latRaw = json['lat'];
      final lngRaw = json['lng'];
      
      if (latRaw == null || lngRaw == null) return null;
      
      return Station(
        id: json['id']?.toString() ?? '',
        nameTw: json['name_tw']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        addressTw: json['address_tw']?.toString() ?? '',
        addressEn: json['address_en']?.toString() ?? '',
        lat: (latRaw as num).toDouble(),
        lng: (lngRaw as num).toDouble(),
      );
    } catch (e) {
      // 記錄單個站牌解析失敗，但不崩潰整個 App
      return null;
    }
  }

  void updateRealtimeData(Map<String, dynamic> data) {
    availableBikes = data['available_bikes'] ?? 0;
    availableElectricBikes = data['available_ebikes'] ?? 0;
    totalBikes = data['total_bikes'] ?? 0;
    totalElectricBikes = data['total_ebikes'] ?? 0;
  }
}
