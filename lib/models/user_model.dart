class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double latitude;
  final double longitude;
  final String currentLocation;
  final bool isActive;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.currentLocation,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      currentLocation: json['currentLocation'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'currentLocation': currentLocation,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
