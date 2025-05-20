// lib/features/profile/models/user_model.dart
class User {
  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.address,
    required this.birthdate,
    required this.occupationId,
    required this.occupationName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String).toLocal(),
      occupationName: json['occupationName'] as String,
      occupationId: json['occupationId'] as String?,
    );
  }
  final String id;
  final String name;
  final String username;
  final String email;
  final String address;
  final DateTime birthdate;
  final String occupationName;
  final String? occupationId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'address': address,
    'birthdate': birthdate.toUtc().toIso8601String(),
    'occupationMame': occupationName,
    'occupationId': occupationId,
  };

  Map<String, dynamic> toJsonForApiUpdate() => {
    'name': name,
    'username': username,
    'address': address,
    'birthdate': birthdate
        .toUtc()
        .toIso8601String(), // Local to UTC ISO for API
    if (occupationId != null && occupationId!.isNotEmpty)
      'occupationId': occupationId,
    // Do not send email or password for profile update here
  };

  Map<String, dynamic> toJsonForCache() => {
    'id': id, 'name': name, 'username': username, 'email': email,
    'address': address, 'birthdate': birthdate.toUtc().toIso8601String(),
    'occupationName': occupationName, 'occupationId': occupationId,
    // 'createdAt': createdAt?.toUtc().toIso8601String(),
    // 'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'occupation': occupationId != null
        ? {'id': occupationId, 'name': occupationName}
        : {'name': occupationName},
  };

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? address,
    DateTime? birthdate,
    String? occupationName,
    String? occupationId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      address: address ?? this.address,
      birthdate: birthdate ?? this.birthdate,
      occupationName: occupationName ?? this.occupationName,
      occupationId: occupationId ?? this.occupationId,
    );
  }
}
