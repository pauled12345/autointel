class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String? vin;
  final String? nickname;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    this.vin,
    this.nickname,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      vin: json['vin'] as String?,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      if (vin != null) 'vin': vin,
      if (nickname != null) 'nickname': nickname,
    };
  }
}
