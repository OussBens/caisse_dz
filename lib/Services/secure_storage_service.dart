// services/secure_storage_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Your secret key for encryption (store this securely)
  static const String _encryptionKey = "BeNsDiGiTaLSoLuTiOnOuSsAmAiMaD2001E2026ElKaNtArA";

  // Generate a proper encryption key
  encrypt.Key get _key {
    final List<int> bytes = utf8.encode(_encryptionKey);
    final Digest hashed = sha256.convert(bytes);
    // Convert List<int> to Uint8List
    final Uint8List keyBytes = Uint8List.fromList(hashed.bytes);
    return encrypt.Key(keyBytes);
  }

  // IV dérivé de manière déterministe (et non aléatoire) pour que les données
  // chiffrées lors d'un lancement précédent restent déchiffrables au lancement
  // suivant — un IV aléatoire par process rendait tout EncryptedPreferences
  // illisible dès le redémarrage de l'application.
  encrypt.IV get _iv {
    final bytes = utf8.encode('${_encryptionKey}_iv');
    final hashed = sha256.convert(bytes);
    return encrypt.IV(Uint8List.fromList(hashed.bytes.sublist(0, 16)));
  }

  // Encrypt and store data
  Future<void> writeSecureData(String key, dynamic value) async {
    try {
      final String jsonString = jsonEncode(value);
      final String encrypted = _encryptData(jsonString);
      await _storage.write(key: key, value: encrypted);
    } catch (e) {
      print('Error writing secure data: $e');
      rethrow;
    }
  }

  // Read and decrypt data
  Future<dynamic> readSecureData(String key) async {
    try {
      final String? encrypted = await _storage.read(key: key);
      if (encrypted == null) return null;

      final String decrypted = _decryptData(encrypted);
      return jsonDecode(decrypted);
    } catch (e) {
      print('Error reading secure data: $e');
      return null;
    }
  }

  // Read with type safety
  Future<T?> readSecureDataTyped<T>(String key) async {
    final dynamic data = await readSecureData(key);
    return data as T?;
  }

  // Delete data
  Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }

  // Check if data exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Public encryption methods (made public for EncryptedPreferences)
  String encryptData(String plainText) {
    return _encryptData(plainText);
  }

  String decryptData(String encryptedText) {
    return _decryptData(encryptedText);
  }

  // Private encryption methods
  String _encryptData(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String _decryptData(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    final decrypted = encrypter.decrypt(encrypted, iv: _iv);
    return decrypted;
  }
}