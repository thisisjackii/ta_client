// lib/core/services/hive_service.dart
import 'dart:convert'; // For json operations

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  // Box name for JWT
  static const String _secureBoxName = 'secureBox';
  static const String _jwtTokenKey = 'jwt_token';

  // Ensures a box is open, throws if not. This is a safeguard.
  // With global init in bootstrap, this check should always pass.
  Future<Box<T>> getOpenBox<T>(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      // This should ideally not be reached if bootstrap.dart opens all boxes.
      // Opening it here can be a fallback but might indicate an issue in startup logic.
      debugPrint(
        '[HiveService] WARNING: Box "$boxName" was not open. Attempting to open now. This should have been done in bootstrap.',
      );
      try {
        return await Hive.openBox<T>(boxName);
      } catch (e) {
        debugPrint(
          '[HiveService] CRITICAL ERROR: Failed to open box "$boxName" on demand: $e',
        );
        throw HiveError('Box "$boxName" could not be opened.');
      }
    }
    return Hive.box<T>(boxName);
  }

  // --- JWT Token Specific Methods ---
  Future<String?> getAuthToken() async {
    try {
      final box = await getOpenBox<String>(_secureBoxName);
      final token = box.get(_jwtTokenKey);
      debugPrint(
        '[HiveService] GET from "$_secureBoxName" | key: "$_jwtTokenKey" | token found: ${token != null && token.isNotEmpty}',
      );
      return token;
    } catch (e) {
      debugPrint(
        '[HiveService] ERROR GET from "$_secureBoxName" | key: "$_jwtTokenKey" | Error: $e',
      );
      return null;
    }
  }

  Future<void> setAuthToken(String token) async {
    try {
      final box = await getOpenBox<String>(_secureBoxName);
      await box.put(_jwtTokenKey, token);
      debugPrint(
        '[HiveService] PUT to "$_secureBoxName" | key: "$_jwtTokenKey" | token set.',
      );
    } catch (e) {
      debugPrint(
        '[HiveService] ERROR PUT to "$_secureBoxName" | key: "$_jwtTokenKey" | Error: $e',
      );
    }
  }

  Future<void> deleteAuthToken() async {
    try {
      final box = await getOpenBox<String>(_secureBoxName);
      await box.delete(_jwtTokenKey);
      debugPrint(
        '[HiveService] DELETE from "$_secureBoxName" | key: "$_jwtTokenKey"',
      );
    } catch (e) {
      debugPrint(
        '[HiveService] ERROR DELETE from "$_secureBoxName" | key: "$_jwtTokenKey" | Error: $e',
      );
    }
  }

  // --- Generic Getters/Setters with Logging ---

  Future<T?> get<T>(String boxName, dynamic key) async {
    try {
      final box = await getOpenBox<T>(boxName);
      final value = box.get(key);
      debugPrint(
        '[HiveService] GET from "$boxName" | key: "$key" | value: ${value != null ? value.toString().substring(0, (value.toString().length > 100 ? 100 : value.toString().length)) : 'null'}...',
      );
      return value;
    } catch (e) {
      debugPrint(
        '[HiveService] ERROR GET from "$boxName" | key: "$key" | Error: $e',
      );
      return null; // Or rethrow depending on how critical the get is
    }
  }

  Future<void> put<T>(String boxName, dynamic key, T value) async {
    try {
      final box = await getOpenBox<T>(boxName);
      await box.put(key, value);
      debugPrint(
        '[HiveService] PUT to "$boxName" | key: "$key" | value: ${value.toString().substring(0, (value.toString().length > 100 ? 100 : value.toString().length))}...',
      );
    } catch (e) {
      debugPrint(
        '[HiveService] ERROR PUT to "$boxName" | key: "$key" | Error: $e',
      );
      // Consider rethrowing if puts are critical
    }
  }

  Future<void> delete(String boxName, dynamic key) async {
    try {
      final box = await getOpenBox<dynamic>(
        boxName,
      ); // Type T might not be known for delete
      await box.delete(key);
      debugPrint('[HiveService] DELETE from "$boxName" | key: "$key"');
    } catch (e) {
      debugPrint(
        '[HiveService] ERROR DELETE from "$boxName" | key: "$key" | Error: $e',
      );
    }
  }

  Future<void> clearBox(String boxName) async {
    try {
      final box = await getOpenBox<dynamic>(boxName);
      final count = await box.clear();
      debugPrint(
        '[HiveService] CLEARED box "$boxName" | $count items removed.',
      );
    } catch (e) {
      debugPrint('[HiveService] ERROR CLEARING box "$boxName" | Error: $e');
    }
  }

  Map<dynamic, T> getBoxEntries<T>(String boxName) {
    // This one assumes box is already open from bootstrap, otherwise it would need to be async
    if (!Hive.isBoxOpen(boxName)) {
      debugPrint(
        '[HiveService] WARNING: getBoxEntries called on unopened box "$boxName". Returning empty map.',
      );
      return {};
    }
    final box = Hive.box<T>(boxName);
    debugPrint(
      '[HiveService] GET ALL ENTRIES from "$boxName" | count: ${box.length}',
    );
    return box.toMap();
  }

  // --- Helpers for JSON String storage specifically ---

  Future<String?> getJsonString(String boxName, dynamic key) async {
    return get<String>(boxName, key);
  }

  Future<void> putJsonString(
    String boxName,
    dynamic key,
    String jsonString,
  ) async {
    return put<String>(boxName, key, jsonString);
  }

  // Helper to get a list of objects from a single JSON string entry in a box
  Future<List<T>> getListFromJsonStringKey<T>(
    String boxName,
    String listKey,
    T Function(Map<String, dynamic> json) fromJsonFactory,
  ) async {
    await getOpenBox<String>(boxName); // Ensure box is open
    final listJson = await getJsonString(boxName, listKey);
    if (listJson != null && listJson.isNotEmpty) {
      try {
        final decodedList = json.decode(listJson) as List<dynamic>;
        debugPrint(
          '[HiveService] GET LIST from "$boxName" | key: "$listKey" | count: ${decodedList.length}',
        );
        return decodedList
            .map(
              (jsonItem) => fromJsonFactory(jsonItem as Map<String, dynamic>),
            )
            .toList();
      } catch (e) {
        debugPrint(
          '[HiveService] Error deserializing list from "$boxName" key "$listKey": $e. Corrupted data?',
        );
        await delete(boxName, listKey); // Delete corrupted data
        return [];
      }
    }
    return [];
  }

  // Helper to put a list of objects as a single JSON string entry
  Future<void> putListAsJsonStringKey<T>(
    String boxName,
    String listKey,
    List<T> list,
    Map<String, dynamic> Function(T item) toJsonFactory,
  ) async {
    await getOpenBox<String>(boxName); // Ensure box is open
    final jsonList = list.map((item) => toJsonFactory(item)).toList();
    await putJsonString(boxName, listKey, json.encode(jsonList));
    debugPrint(
      '[HiveService] PUT LIST to "$boxName" | key: "$listKey" | count: ${list.length}',
    );
  }
}
