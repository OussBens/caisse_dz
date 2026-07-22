// core/Auth/auth_state.dart (Updated)
import 'dart:convert';
import 'dart:math';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/UserParam.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/userparam.dart';
import 'package:caisse_dz/services/machine_binding_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

class AuthState extends ChangeNotifier {
  static AuthState? _instance;
  static LocaleProvider? _localeProvider;

  static AuthState getInstance(LocaleProvider localeProvider) {
    _localeProvider = localeProvider;
    _instance ??= AuthState._internal();
    return _instance!;
  }

  factory AuthState() {
    if (_instance == null) {
      throw Exception('AuthState not initialized. Call AuthState.getInstance(localeProvider) first.');
    }
    return _instance!;
  }

  AuthState._internal();

  bool _isAuthenticated = true;
  bool _isActivated = true;

  String? _username ="admin";
  String? _role ="admin";
  String? _userCode="ADMIN";

  UserParam? _userParam;
  String? _currentLanguage;
  String? _currentCurrency;
  String? _currentMagasin;
  String? _currentMagasinId;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MachineBindingService _machineBinding = MachineBindingService();

  static const String _secretKey = "BeNsDiGiTaLSoLuTiOnOuSsAmAiMaD2001E2026ElKaNtArA";

  bool get isAuthenticated => _isAuthenticated;
  bool get isActivated => _isActivated;

  String? get username => _username;
  String? get userCode => _userCode;
  String? get role => _role;

  UserParam? get userParam => _userParam;
  String? get currentLanguage => _currentLanguage;
  String? get currentCurrency => _currentCurrency;
  String? get currentMagasin => _currentMagasin;
  String? get currentMagasinId => _currentMagasinId;

  // ===============================
  // LOAD ACTIVATION WITH MACHINE VERIFICATION
  // ===============================
  Future<void> loadActivationState() async {
    try {
      // First check if machine is authorized
      final isAuthorized = await _machineBinding.isMachineAuthorized();

      if (!isAuthorized) {
        _isActivated = false;
        await _secureStorage.delete(key: 'activated');
        notifyListeners();
        return;
      }

      // Get activation status with machine-specific decryption
      final encryptedActivation = await _secureStorage.read(key: 'activated');
      if (encryptedActivation == null) {
        _isActivated = false;
        notifyListeners();
        return;
      }

      // Decrypt using machine-specific key
      final machineKey = await _machineBinding.getMachineKey();
      final decrypted = _decryptWithMachineKey(encryptedActivation, machineKey);

      if (decrypted != null && decrypted == 'true') {
        // Verify signature
        final signature = await _secureStorage.read(key: 'activation_signature');
        final expectedSignature = _generateSignature(decrypted, machineKey);

        if (signature == expectedSignature) {
          _isActivated = true;
        } else {
          _isActivated = false; // Tampering detected
          await _secureStorage.delete(key: 'activated');
        }
      } else {
        _isActivated = false;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading activation state: $e');
      _isActivated = false;
      notifyListeners();
    }
  }

  // ===============================
  // ACTIVATE APP WITH MACHINE BINDING
  // ===============================
  Future<bool> activateApp(String enteredKey, String deviceId) async {
    final generatedKey = _generateKey(deviceId);

    if (enteredKey.toUpperCase() == generatedKey) {
      try {
        // Get machine-specific encryption key
        final machineKey = await _machineBinding.getMachineKey();

        // Encrypt activation data with machine key
        final encrypted = _encryptWithMachineKey('true', machineKey);
        await _secureStorage.write(key: 'activated', value: encrypted);

        // Store signature
        final signature = _generateSignature('true', machineKey);
        await _secureStorage.write(key: 'activation_signature', value: signature);

        // Store machine fingerprint
        await _machineBinding.storeMachineFingerprint();

        // Store device ID and timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final encryptedTimestamp = _encryptWithMachineKey(timestamp.toString(), machineKey);
        await _secureStorage.write(key: 'activation_timestamp', value: encryptedTimestamp);

        _isActivated = true;
        notifyListeners();
        return true;
      } catch (e) {
        print('Error activating app: $e');
        return false;
      }
    }

    return false;
  }

  // ===============================
  // MACHINE-SPECIFIC ENCRYPTION
  // ===============================
  String _encryptWithMachineKey(String data, String machineKey) {
    // Simple XOR encryption with machine key (for demo - use proper encryption in production)
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

  String _generateSignature(String data, String machineKey) {
    final combined = data + machineKey + _secretKey;
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // ===============================
  // VERIFY ACTIVATION ON APP START
  // ===============================
  Future<bool> verifyActivationOnStart() async {
    final isAuthorized = await _machineBinding.isMachineAuthorized();
    if (!isAuthorized) {
      _isActivated = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }

    // Check if activation data is valid for this machine
    final encryptedActivation = await _secureStorage.read(key: 'activated');
    if (encryptedActivation == null) {
      _isActivated = false;
      notifyListeners();
      return false;
    }

    final machineKey = await _machineBinding.getMachineKey();
    final decrypted = _decryptWithMachineKey(encryptedActivation, machineKey);

    if (decrypted != 'true') {
      _isActivated = false;
      notifyListeners();
      return false;
    }

    return true;
  }

  // ===============================
  // GENERATE SECURE KEY
  // ===============================
  String _generateKey(String deviceId) {
    final mixed = _interleave(deviceId, _secretKey);
    final bytes = utf8.encode(mixed);
    final digest = sha256.convert(bytes);
    return digest.toString().toUpperCase();
  }

  String _interleave(String a, String b) {
    final buffer = StringBuffer();
    final maxLength = a.length > b.length ? a.length : b.length;

    for (int i = 0; i < maxLength; i++) {
      if (i < a.length) buffer.write(a[i]);
      if (i < b.length) buffer.write(b[i]);
    }

    return buffer.toString();
  }

  // ===============================
  // HASH PASSWORD
  // ===============================
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  // ===============================
  // LOGIN
  // ===============================
  Future<bool> login(String username, String password) async {
    final db = await DbCreator.openDb();

    const salt = 'SYSTEM_SALT';
    final hashed = hashPassword(password, salt);

    if (_isActivated) {
      final result = await db.query(
        'utilisateur',
        where: 'username = ? AND password = ? AND etat = 1',
        whereArgs: [username, hashed],
      );

      if (result.isNotEmpty) {
        _isAuthenticated = true;
        _username = result.first['username'] as String;
        _role = result.first['role'] as String;
        _userCode = result.first['code'] as String;

        await loadUserParameters();
        notifyListeners();

        final services = HistoriqueServices(db);
        int idm = await _GetNextHistoriqueId();
        String codem = 'HS$idm${DateTime.now().millisecondsSinceEpoch}';
        Historique histo = Historique(
            id: idm,
            code: codem,
            type: 'Login',
            desc: "l'utilisateur $_username a Login le ${DateTime.now()}",
            oper: 'Login',
            dateCree: DateTime.now(),
            creeParCode: _userCode!
        );
        await services.addHistorique(histo);
        return true;
      }

      return false;
    } else {
      if (username.toLowerCase() == 'demo' && password == 'demo') {
        _isAuthenticated = true;
        _username = 'Demo User';
        _role = 'demo';
        _userCode = 'DEMO';
        notifyListeners();

        final db = await DbCreator.openDb();
        final services = HistoriqueServices(db);
        int idm = await _GetNextHistoriqueId();
        String codem = 'HS$idm${DateTime.now().millisecondsSinceEpoch}';
        Historique histo = Historique(
            id: idm,
            code: codem,
            type: 'Login',
            desc: "l'utilisateur demo a Login le ${DateTime.now()}",
            oper: 'Login',
            dateCree: DateTime.now(),
            creeParCode: 'DEMO'
        );
        await services.addHistorique(histo);
        return true;
      }
      return false;
    }
  }

  // ===============================
  // LOAD USER PARAMETERS
  // ===============================
  Future<void> loadUserParameters() async {
    if (_username != null && _isAuthenticated) {
      final userParam = await UserParamServices.getUserParamByUsername(_username!);

      final oldParam = _userParam;
      final oldLang = _currentLanguage;
      final oldCurrency = _currentCurrency;
      final oldMagasin = _currentMagasin;

      if (userParam != null) {
        _userParam = userParam;
        _currentMagasin = userParam.magasin;
        _currentLanguage = userParam.language;
        _currentCurrency = userParam.currency;
        _currentMagasinId = userParam.magasinid;

        if (_localeProvider != null && _currentLanguage != null) {
          await _localeProvider!.setLocale(_currentLanguage!);
        }
      } else {
        _userParam = null;
        _currentMagasin = null;
        _currentLanguage = 'fr';
        _currentCurrency = null;
        _currentMagasinId = null;

        if (_localeProvider != null) {
          await _localeProvider!.setLocale('fr');
        }
      }

      final hasChanged = oldParam?.id != _userParam?.id ||
          oldLang != _currentLanguage ||
          oldCurrency != _currentCurrency ||
          oldMagasin != _currentMagasin;

      if (hasChanged) {
        notifyListeners();
      }
    }
  }

  // ===============================
  // UPDATE USER PARAMETERS
  // ===============================
  Future<bool> updateUserParameters({
    required String language,
    required String currency,
    required String magasin,
    required String magasinId,
    required String modifiedBy,
    required String modifiedByCode,
    required String reason,
  }) async {
    final db = await DbCreator.openDb();
    final services = UserParamServices(db);

    if (_userParam == null) {
      final newParam = UserParam(
        id: 0,
        nom: _username!,
        creeLe: DateTime.now(),
        magasin: magasin,
        language: language,
        currency: currency,
        magasinid: magasinId,
        creeParCode: modifiedByCode,
      );

      final response = await services.addUserParam(
        newParam,
        modifiedBy,
        modifiedByCode,
      );

      if (response.success && response.data != null) {
        final createdParam = await UserParamServices.getUserParamByUsername(_username!);
        _userParam = createdParam;
        _currentMagasin = magasin;
        _currentLanguage = language;
        _currentCurrency = currency;
        _currentMagasinId = magasinId;

        if (_localeProvider != null) {
          await _localeProvider!.setLocale(language);
        }

        notifyListeners();
        return true;
      }
      return false;
    } else {
      final updatedParam = UserParam(
        id: _userParam!.id,
        nom: _userParam!.nom,
        creeLe: _userParam!.creeLe,
        magasin: magasin,
        language: language,
        currency: currency,
        magasinid: magasinId,
        creeParCode: _userParam!.creeParCode,
      );

      final response = await services.updateUserParam(
        updatedParam,
        modifiedBy,
        modifiedByCode,
        reason,
      );

      if (response.success) {
        _userParam = updatedParam;
        _currentMagasin = magasin;
        _currentLanguage = language;
        _currentCurrency = currency;
        _currentMagasinId = magasinId;

        if (_localeProvider != null) {
          await _localeProvider!.setLocale(language);
        }

        notifyListeners();
        return true;
      }
      return false;
    }
  }

  // ===============================
  // LOGOUT
  // ===============================
  void logout({required String username, required String userCode}) async {
    final db = await DbCreator.openDb();
    final services = HistoriqueServices(db);

    _isAuthenticated = false;
    _userCode = null;
    _username = null;
    _role = null;
    _userParam = null;
    _currentLanguage = null;
    _currentCurrency = null;
    _currentMagasin = null;
    _currentMagasinId = null;

    int idm = await _GetNextHistoriqueId();
    String codem = 'HS$idm${DateTime.now().millisecondsSinceEpoch}';
    Historique histo = Historique(
        id: idm,
        code: codem,
        type: 'Logout',
        desc: "l'utilisateur $username a Logout le ${DateTime.now()}",
        oper: 'Logout',
        dateCree: DateTime.now(),
        creeParCode: userCode
    );
    await services.addHistorique(histo);
    notifyListeners();
  }

  bool get isLoggedIn => _isAuthenticated;
}