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
    // Safely access the nested occupation object and its name
    var parsedOccupationName =
        'Tidak Ada Data'; // Default value or handle as nullable
    final parsedOccupationId =
        json['occupationId'] as String?; // This is correct from top level

    final occupationData = json['occupation'] as Map<String, dynamic>?;
    if (occupationData != null && occupationData['name'] != null) {
      parsedOccupationName = occupationData['name'] as String;
      // If occupationId is not at top level but inside occupation object, parse from there too
      // For your current backend response, 'occupationId' is at top level,
      // and 'occupation.id' is also available.
      // If parsedOccupationId was null and you wanted to get it from nested:
      // parsedOccupationId ??= occupationData['id'] as String?;
    } else if (json.containsKey('occupationName') &&
        json['occupationName'] != null) {
      // Fallback if backend SOMETIMES sends occupationName at top level (less ideal)
      parsedOccupationName = json['occupationName'] as String;
    }

    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      address:
          json['address'] as String? ??
          'Tidak Ada Data', // Make address nullable or provide default
      birthdate: DateTime.parse(json['birthdate'] as String).toLocal(),
      occupationName: parsedOccupationName,
      occupationId: parsedOccupationId, // This was already correct
    );
  }
  final String id;
  final String name;
  final String username;
  final String email;
  final String address; // Consider if this can be null from backend
  final DateTime birthdate;
  final String
  occupationName; // This is non-nullable, ensure it always gets a value
  final String? occupationId;

  Map<String, dynamic> toJson() => {
    // This is for general serialization, maybe not for API update
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'address': address,
    'birthdate': birthdate.toUtc().toIso8601String(),
    'occupationName': occupationName, // Corrected typo from 'occupationMame'
    'occupationId': occupationId,
  };

  Map<String, dynamic> toJsonForApiUpdate() => {
    'name': name,
    'username': username,
    'address': address,
    'birthdate': birthdate.toUtc().toIso8601String(),
    if (occupationId != null && occupationId!.isNotEmpty)
      'occupationId': occupationId,
    // Do not send email for profile update here (usually needs verification)
    // Do not send password
  };

  // toJsonForCache seems fine based on your backend structure for 'occupation'
  Map<String, dynamic> toJsonForCache() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'address': address,
    'birthdate': birthdate.toUtc().toIso8601String(),
    'occupationName': occupationName,
    'occupationId': occupationId,
    'occupation': occupationId != null && occupationName.isNotEmpty
        ? {'id': occupationId, 'name': occupationName}
        // If only occupationName is present (e.g. manually entered, no ID)
        : (occupationName.isNotEmpty ? {'name': occupationName} : null),
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
