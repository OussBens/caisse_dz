// services/encrypted_preferences.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

class EncryptedPreferences {
  static final EncryptedPreferences _instance = EncryptedPreferences._internal();
  factory EncryptedPreferences() => _instance;
  EncryptedPreferences._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Cache for decrypted values to reduce decryption overhead
  final Map<String, dynamic> _cache = {};

  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      await _loadAllToCache();
    }
  }

  // Load all encrypted data to cache
  Future<void> _loadAllToCache() async {
    if (_prefs == null) return;

    final Set<String> keys = _prefs!.getKeys();
    for (final key in keys) {
      final String? encryptedValue = _prefs!.getString(key);
      if (encryptedValue != null) {
        try {
          final decrypted = _secureStorage.decryptData(encryptedValue);
          _cache[key] = jsonDecode(decrypted);
        } catch (e) {
          print('Failed to decrypt $key: $e');
        }
      }
    }
  }

  // Set a value (encrypted)
  Future<void> setBool(String key, bool value) async {
    await _setValue(key, value);
  }

  Future<void> setString(String key, String value) async {
    await _setValue(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await _setValue(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await _setValue(key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _setValue(key, value);
  }

  Future<void> _setValue(String key, dynamic value) async {
    await init();

    final jsonString = jsonEncode(value);
    final encrypted = _secureStorage.encryptData(jsonString);

    await _prefs?.setString(key, encrypted);
    _cache[key] = value; // Update cache
  }

  // Get values (from cache or decrypt)
  bool? getBool(String key) {
    return _getValue<bool>(key);
  }

  String? getString(String key) {
    return _getValue<String>(key);
  }

  int? getInt(String key) {
    return _getValue<int>(key);
  }

  double? getDouble(String key) {
    return _getValue<double>(key);
  }

  List<String>? getStringList(String key) {
    return _getValue<List<String>>(key);
  }

  T? _getValue<T>(String key) {
    if (_cache.containsKey(key)) {
      final value = _cache[key];
      if (value is T) {
        return value;
      }
    }
    return null;
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    await init();
    return _prefs?.containsKey(key) ?? false;
  }

  // Remove a key
  Future<void> remove(String key) async {
    await init();
    await _prefs?.remove(key);
    _cache.remove(key);
  }

  // Clear all data
  Future<void> clear() async {
    await init();
    await _prefs?.clear();
    _cache.clear();
  }

  // Get all keys (decrypted)
  Set<String> getKeys() {
    return _cache.keys.toSet();
  }

  // Verify data integrity with checksum
  Future<bool> verifyIntegrity(String key) async {
    try {
      await init();
      final String? encrypted = _prefs?.getString(key);
      if (encrypted == null) return false;

      // Try to decrypt, if it fails, data is corrupted/modified
      _secureStorage.decryptData(encrypted);
      return true;
    } catch (e) {
      return false;
    }
  }
}