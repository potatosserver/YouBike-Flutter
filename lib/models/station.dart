class Station {
  final String id;
  final String nameTw;
  final String nameEn;
  final String addressTw;
  final String addressEn;
  final double lat;
  final double lng;
  
  // Real-time data (from apiYoubike.js / apiElectric.js)
  int? available20;
  int? availableE;
  int? emptySpaces;

  Station({
    required this.id,
    required this.nameTw,
    required this.nameEn,
    required this.addressTw,
    required this.addressEn,
    required this.lat,
    required this.lng,
    this.available20,
    this.availableE,
    this.emptySpaces,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['station_no']?.toString() ?? '',
      nameTw: json['name_tw'] ?? '',
      nameEn: json['name_en'] ?? '',
      addressTw: json['address_tw'] ?? '',
      addressEn: json['address_en'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse(json['lng'].toString()) ?? 0.0,
    );
  }

  void updateRealtimeData(Map<String, dynamic> data) {
    available20 = data['available_2_0'];
    availableE = data['available_e'];
    emptySpaces = data['empty_spaces'];
  }
}

class RouteStep {
  final String instruction;
  final double distance; // meters
  final int duration;    // seconds

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
  });
}
