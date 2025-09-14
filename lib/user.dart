class User {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime lastUpdate;

  User({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.lastUpdate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}
