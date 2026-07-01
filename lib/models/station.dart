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

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] ?? '',
      nameTw: json['name_tw'] ?? '',
      nameEn: json['name_en'] ?? '',
      addressTw: json['address_tw'] ?? '',
      addressEn: json['address_en'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  void updateRealtimeData(Map<String, dynamic> data) {
    availableBikes = data['available_bikes'] ?? 0;
    availableElectricBikes = data['available_ebikes'] ?? 0;
    totalBikes = data['total_bikes'] ?? 0;
    totalElectricBikes = data['total_ebikes'] ?? 0;
  }
}
