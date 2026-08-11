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
      id: json['id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      vin: json['vin'],
      nickname: json['nickname'],
    );
  }
}
