import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ta_client/core/config/constants.dart';
import 'package:ta_client/features/register/models/register_model.dart';

class RegisterService {
  RegisterService({required this.baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {'Content-Type': 'application/json'},
          ),
        ),
        _secureStorage = const FlutterSecureStorage();

  final String baseUrl;
  final Dio dio;
  final FlutterSecureStorage _secureStorage;

  Future<bool> register(RegisterModel model) async {
    final url = Uri.parse('$baseUrl${ApiConstants.registerEndpoint}');
    final response = await dio.post<dynamic>(
      url.toString(),
      data: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to register. Please try again.');
    }
  }

  // Cache functions for keeping registration data persisted.
  Future<void> cacheName(String name) async {
    await _secureStorage.write(
      key: SecureStorageKeys.registerName,
      value: name,
    );
  }

  Future<void> cacheUsername(String username) async {
    await _secureStorage.write(
      key: SecureStorageKeys.registerUsername,
      value: username,
    );
  }

  Future<void> cacheEmail(String email) async {
    await _secureStorage.write(
      key: SecureStorageKeys.registerEmail,
      value: email,
    );
  }

  Future<void> cachePhone(String phone) async {
    await _secureStorage.write(
      key: SecureStorageKeys.registerPhone,
      value: phone,
    );
  }

  Future<void> cachePassword(String password) async {
    await _secureStorage.write(
      key: SecureStorageKeys.registerPassword,
      value: password,
    );
  }

  Future<String?> getCachedName() async {
    return _secureStorage.read(key: SecureStorageKeys.registerName);
  }

  Future<String?> getCachedEmail() async {
    return _secureStorage.read(key: SecureStorageKeys.registerEmail);
  }

  Future<String?> getCachedPassword() async {
    return _secureStorage.read(key: SecureStorageKeys.registerPassword);
  }

  Future<void> clearCachedRegistrationData() async {
    await _secureStorage.delete(key: SecureStorageKeys.registerName);
    await _secureStorage.delete(key: SecureStorageKeys.registerUsername);
    await _secureStorage.delete(key: SecureStorageKeys.registerEmail);
    await _secureStorage.delete(key: SecureStorageKeys.registerPhone);
    await _secureStorage.delete(key: SecureStorageKeys.registerPassword);
  }
}
