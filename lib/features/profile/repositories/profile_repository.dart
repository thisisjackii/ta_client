// lib/features/profile/repositories/profile_repository.dart
import 'package:ta_client/features/profile/models/user_model.dart';
import 'package:ta_client/features/profile/services/profile_service.dart';

class ProfileRepository {
  ProfileRepository({required ProfileService service}) : _service = service;
  final ProfileService _service;

  Future<User> getProfile() => _service.fetchProfile();
  Future<User> saveProfile(User user) => _service.updateProfile(user);
}
