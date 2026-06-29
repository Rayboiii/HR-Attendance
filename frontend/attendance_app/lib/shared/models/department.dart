class Department {
  const Department({
    required this.id,
    required this.name,
    required this.radiusMeters,
    this.locationLat,
    this.locationLng,
  });

  final String id;
  final String name;
  final double radiusMeters;
  final double? locationLat;
  final double? locationLng;

  bool get hasLocation => locationLat != null && locationLng != null;

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 0,
        locationLat: (json['locationLat'] as num?)?.toDouble(),
        locationLng: (json['locationLng'] as num?)?.toDouble(),
      );
}
