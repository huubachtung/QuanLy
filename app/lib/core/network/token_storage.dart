import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;
  
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserData = 'user_data';

  TokenStorage(this._storage);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    if (userId != null) {
      await _storage.write(key: _keyUserId, value: userId);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _keyUserData, value: jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _keyUserData);
    if (data != null) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
