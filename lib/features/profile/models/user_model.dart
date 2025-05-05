// lib/features/profile/models/user_model.dart
class User {

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.address,
    required this.birthdate,
    required this.occupation,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String),
      occupation: json['occupation'] as String,
    );
  }
  final String id;
  final String name;
  final String username;
  final String email;
  final String address;
  final DateTime birthdate;
  final String occupation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'address': address,
    'birthdate': birthdate.toIso8601String(),
    'occupation': occupation,
  };
  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? address,
    DateTime? birthdate,
    String? occupation,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      address: address ?? this.address,
      birthdate: birthdate ?? this.birthdate,
      occupation: occupation ?? this.occupation,
    );
  }
}
