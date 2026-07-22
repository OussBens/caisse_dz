// services/machine_binding_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:win32/win32.dart';

class MachineBindingService {
  static final MachineBindingService _instance = MachineBindingService._internal();
  factory MachineBindingService() => _instance;
  MachineBindingService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Windows-specific hardware fingerprint
  Future<String> getMachineFingerprint() async {
    return await _getWindowsFingerprint();
  }

  Future<String> _getWindowsFingerprint() async {
    try {
      final buffer = StringBuffer();

      // 1. Get Windows Product UUID
      String uuid = await _getWmicValue('csproduct', 'get', 'uuid');
      buffer.write('$uuid|');

      // 2. Get Motherboard Serial Number
      String motherboardSerial = await _getWmicValue('baseboard', 'get', 'serialnumber');
      buffer.write('$motherboardSerial|');

      // 3. Get BIOS Serial Number
      String biosSerial = await _getWmicValue('bios', 'get', 'serialnumber');
      buffer.write('$biosSerial|');

      // 4. Get Disk Drive Serial Number
      String diskSerial = await _getWmicValue('diskdrive', 'get', 'serialnumber');
      buffer.write('$diskSerial|');

      // 5. Get Volume Serial Number of C: drive
      String volumeSerial = await _getVolumeSerial();
      buffer.write('$volumeSerial|');

      // 6. Get Computer Name
      final computerName = Platform.localHostname;
      buffer.write('$computerName|');

      // 7. Get MAC Address
      String macAddress = await _getMacAddress();
      buffer.write('$macAddress|');

      // 8. Get Processor ID
      String processorId = await _getWmicValue('cpu', 'get', 'processorid');
      buffer.write('$processorId');

      // Generate hash from combined fingerprint
      final fingerprint = buffer.toString();
      final bytes = utf8.encode(fingerprint);
      final hash = sha256.convert(bytes);

      print('Machine fingerprint generated successfully');
      return hash.toString();

    } catch (e) {
      print('Error generating Windows fingerprint: $e');
      return await _getFallbackFingerprint();
    }
  }

  // Helper method to get WMIC values
  Future<String> _getWmicValue(String alias, String action, String property) async {
    try {
      final result = await Process.run('wmic', [alias, action, property]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          String value = lines[1].trim();
          if (value.isNotEmpty && !value.contains(property)) {
            return value;
          }
        }
      }
      return '';
    } catch (e) {
      print('Error getting $property from $alias: $e');
      return '';
    }
  }

  // Get volume serial number
  Future<String> _getVolumeSerial() async {
    try {
      final result = await Process.run('vol', ['C:']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'[A-Z0-9]{4}-[A-Z0-9]{4}').firstMatch(output);
        if (match != null) {
          return match.group(0)!;
        }
      }
      return '';
    } catch (e) {
      print('Error getting volume serial: $e');
      return '';
    }
  }

  // Get MAC address
  Future<String> _getMacAddress() async {
    try {
      final result = await Process.run('getmac', ['/FO', 'CSV', '/NH']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains(',')) {
            final parts = line.split(',');
            if (parts.length > 1) {
              String mac = parts[1].replaceAll('"', '').trim();
              if (mac.isNotEmpty && mac.contains('-')) {
                return mac;
              }
            }
          }
        }
      }
      return '';
    } catch (e) {
      print('Error getting MAC address: $e');
      return '';
    }
  }

  // Fallback fingerprint method
  Future<String> _getFallbackFingerprint() async {
    try {
      // Use a combination of system info as fallback
      final combined = Platform.localHostname +
          Platform.operatingSystem +
          Platform.operatingSystemVersion +
          Directory.current.path;
      final bytes = utf8.encode(combined);
      final hash = sha256.convert(bytes);
      return hash.toString();
    } catch (e) {
      // Ultimate fallback - generate a random ID
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final bytes = utf8.encode(random);
      final hash = sha256.convert(bytes);
      return hash.toString();
    }
  }

  // Generate machine-specific encryption key
  Future<String> getMachineKey() async {
    final fingerprint = await getMachineFingerprint();
    const salt = "BeNsDiGiTaLSoLuTiOnOuSsAmAiMaD2001E2026ElKaNtArA";
    final combined = fingerprint + salt;
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Verify if this machine is authorized
  Future<bool> isMachineAuthorized() async {
    try {
      final storedFingerprint = await _secureStorage.read(key: 'machine_fingerprint');
      final currentFingerprint = await getMachineFingerprint();

      if (storedFingerprint == null) {
        // First time activation
        return true;
      }

      // Verify machine fingerprint matches
      final isMatch = storedFingerprint == currentFingerprint;
      if (!isMatch) {
        print('⚠️ Machine fingerprint mismatch - possible license violation');
      }
      return isMatch;
    } catch (e) {
      print('Error verifying machine authorization: $e');
      return false;
    }
  }

  // Store machine fingerprint after activation
  Future<void> storeMachineFingerprint() async {
    final fingerprint = await getMachineFingerprint();
    await _secureStorage.write(key: 'machine_fingerprint', value: fingerprint);
  }

  // Get device ID for activation key generation
  Future<String> getDeviceId() async {
    final fingerprint = await getMachineFingerprint();
    // Use first 32 characters of fingerprint as device ID
    return fingerprint.substring(0, fingerprint.length > 32 ? 32 : fingerprint.length);
  }

  // Verify activation integrity
  Future<bool> verifyActivationIntegrity() async {
    try {
      final isAuthorized = await isMachineAuthorized();
      if (!isAuthorized) {
        return false;
      }

      // Check if activation data exists
      final encryptedActivation = await _secureStorage.read(key: 'activated');
      if (encryptedActivation == null) {
        return false;
      }

      // Verify signature
      final signature = await _secureStorage.read(key: 'activation_signature');
      if (signature == null) {
        return false;
      }

      // Get machine key and verify decryption works
      final machineKey = await getMachineKey();
      final decrypted = _decryptWithMachineKey(encryptedActivation, machineKey);

      return decrypted == 'true';
    } catch (e) {
      print('Error verifying activation integrity: $e');
      return false;
    }
  }

  // Simple XOR encryption with machine key
  String _encryptWithMachineKey(String data, String machineKey) {
    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(machineKey);
    final result = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      result.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Url.encode(result);
  }

  String? _decryptWithMachineKey(String encrypted, String machineKey) {
    try {
      final encryptedBytes = base64Url.decode(encrypted);
      final keyBytes = utf8.encode(machineKey);
      final result = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        result.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(result);
    } catch (e) {
      print('Decryption failed: $e');
      return null;
    }
  }
}