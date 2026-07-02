
class Station {
  final String id;
  final String nameTw;
  final String nameEn;
  final String addressTw;
  final String addressEn;
  final double lat;
  final double lng;
  
  // Real-time data
  int availableBikes = 0;
  int availableElectricBikes = 0;
  int emptySpaces = 0;
  int totalBikes = 0; 

  // Distance data (calculated dynamically)
  String distance = "0";
  String distanceUnit = "m";
  
  Station({
    required this.id,
    required this.nameTw,
    required this.nameEn,
    required this.addressTw,
    required this.addressEn,
    required this.lat,
    required this.lng,
  });

  factory Station.empty() {
    return Station(
      id: '',
      nameTw: '',
      nameEn: '',
      addressTw: '',
      addressEn: '',
      lat: 0.0,
      lng: 0.0,
    );
  }

  static Station? fromJson(Map<String, dynamic> json) {
    try {
      final id = (json['station_no'] ?? json['id'] ?? '').toString();
      if (id.isEmpty) return null;

      return Station(
        id: id,
        nameTw: json['name_tw']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        addressTw: json['address_tw']?.toString() ?? '',
        addressEn: json['address_en']?.toString() ?? '',
        lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
        lng: double.tryParse(json['lng']?.toString() ?? '') ?? 0.0,
      )..totalBikes = json['total_spaces']?.toString().isNotEmpty == true 
          ? int.tryParse(json['total_spaces'].toString()) ?? 0 
          : 0;
    } catch (e) {
      return null;
    }
  }
}
