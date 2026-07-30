import 'package:latlong2/latlong.dart';

class Station {
  final String id;
  final String nameTw;
  final String nameEn;
  final String addressTw;
  final String addressEn;
  final double lat;
  final double lng;
  int? availableBikes;
  int? availableElectricBikes;
  int? emptySpaces;
  int? parkingSpaces;
  int? forbiddenSpaces;
  int? status; // 1=正常, 2=暫停營運
  double distance;
  LatLng? visualPosition; // Added for visual offsetting

  Station({
    required this.id,
    required this.nameTw,
    required this.nameEn,
    required this.addressTw,
    required this.addressEn,
    required this.lat,
    required this.lng,
    this.availableBikes,
    this.availableElectricBikes,
    this.emptySpaces,
    this.parkingSpaces,
    this.forbiddenSpaces,
    this.status,
    this.distance = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nameTw": nameTw,
      "nameEn": nameEn,
      "lat": lat,
      "lng": lng,
      "addressTw": addressTw,
      "addressEn": addressEn,
      "availableBikes": availableBikes,
      "availableElectricBikes": availableElectricBikes,
      "emptySpaces": emptySpaces,
      "parkingSpaces": parkingSpaces,
      "forbiddenSpaces": forbiddenSpaces,
      "status": status,
    };
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: (json["station_no"] ?? json["id"] ?? "").toString(),
      nameTw: json["name_tw"] ?? json["station_name"] ?? json["nameTw"] ?? json["name"] ?? "",
      nameEn: json["name_en"] ?? json["station_name_en"] ?? json["nameEn"] ?? "",
      lat: double.tryParse(json["lat"]?.toString() ?? "") ?? 0.0,
      lng: double.tryParse(json["lng"]?.toString() ?? "") ?? 0.0,
      addressTw: json["address_tw"] ?? json["address"] ?? json["addressTw"] ?? json["addr"] ?? "",
      addressEn: json["address_en"] ?? json["address_en"] ?? json["addressEn"] ?? "",
      availableBikes: _parseInt(json["available_bikes"]),
      availableElectricBikes: _parseInt(json["available_electric_bikes"]),
      emptySpaces: _parseInt(json["empty_spaces"]),
      parkingSpaces: _parseInt(json["parking_spaces"]),
      forbiddenSpaces: _parseInt(json["forbidden_spaces"]),
      status: _parseInt(json["status"]),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
