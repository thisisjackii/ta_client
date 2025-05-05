// lib/features/profile/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart';
import 'package:ta_client/features/profile/models/user_model.dart';

class ProfileService {
  ProfileService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client());

  final String _baseUrl;
  final http.Client _client;

  Future<User> fetchProfile() async {
    final resp = await _client.get(Uri.parse('$_baseUrl/users/profile'));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return User.fromJson((data['user'] ?? data) as Map<String, dynamic>);
    }
    throw Exception('Failed to load profile');
  }

  Future<User> updateProfile(User user) async {
    final resp = await _client.put(
      Uri.parse('$_baseUrl/users/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return User.fromJson((data['user'] ?? data) as Map<String, dynamic>);
    }
    throw Exception('Failed to update profile');
  }
}
