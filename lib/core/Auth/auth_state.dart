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
import 'package:caisse_dz/core/Auth/license_tier.dart';
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

  bool _isAuthenticated = false;
  bool _isActivated = false;

  // Palier de licence (voir license_tier.dart) — par défaut `premium` tant
  // qu'aucune clé d'activation n'encode encore de palier différent (aucune
  // fonctionnalité existante ne doit se retrouver masquée rétroactivement
  // par l'introduction de ce mécanisme). Le futur flux d'activation pourra
  // appeler setLicenseTier() pour le faire varier réellement.
  LicenseTier _licenseTier = LicenseTier.premium;

  String? _username ="admin";
  String? _role ="admin";
  String? _userCode="ADMIN";
  String? _userCaisseCode;

  UserParam? _userParam;
  String? _currentLanguage;
  String? _currentCurrency;
  String? _currentMagasin;
  String? _currentMagasinId;

  // Affiché une seule fois par lancement de l'app (menu "logo" de la sidebar
  // sur /caisse) — volontairement en mémoire, non persisté : contrairement au
  // flag de configuration initiale, il doit se réinitialiser à chaque
  // redémarrage du process, pas rester vrai à vie après le tout premier lancement.
  bool _hasShownStartupMenu = false;
  bool get hasShownStartupMenu => _hasShownStartupMenu;
  void markStartupMenuShown() => _hasShownStartupMenu = true;

  // État "épinglé" de la sidebar (SideBarWidget est recréé sans état partagé
  // par chaque écran — voir les 16 usages de SideBarWidget() — donc ce flag
  // doit vivre ici pour survivre à la navigation entre modules.
  bool _isSidebarPinned = false;
  bool get isSidebarPinned => _isSidebarPinned;
  void setSidebarPinned(bool value) => _isSidebarPinned = value;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MachineBindingService _machineBinding = MachineBindingService();

  static const String _secretKey = "BeNsDiGiTaLSoLuTiOnOuSsAmAiMaD2001E2026ElKaNtArA";
  static const String _rememberUsernameKey = 'remember_username';
  static const String _rememberPasswordHashKey = 'remember_password_hash';

  bool get isAuthenticated => _isAuthenticated;
  bool get isActivated => _isActivated;
  LicenseTier get licenseTier => _licenseTier;

  String? get username => _username;
  String? get userCode => _userCode;
  String? get role => _role;
  String? get userCaisseCode => _userCaisseCode;

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
      await _loadLicenseTier(machineKey);
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
  // RESET ACTIVATION (DEV/TEST ONLY)
  // ===============================
  /// L'activation (et le palier) vit entièrement dans le secure storage
  /// Windows, indépendamment de la base SQLite — supprimer la base ne
  /// réinitialise donc rien ici. Réservé aux builds debug (voir l'appelant
  /// dans login.dart, gated par `kDebugMode`) : efface toutes les clés
  /// posées par activateApp/setLicenseTier/MachineBindingService pour
  /// pouvoir retester une activation à partir de zéro sur la même machine.
  Future<void> resetActivationForTesting() async {
    await _secureStorage.delete(key: 'activated');
    await _secureStorage.delete(key: 'activation_signature');
    await _secureStorage.delete(key: 'activation_timestamp');
    await _secureStorage.delete(key: 'machine_fingerprint');
    await _secureStorage.delete(key: 'license_tier');
    await _secureStorage.delete(key: 'license_tier_signature');

    _isActivated = false;
    _isAuthenticated = false;
    _licenseTier = LicenseTier.premium;
    notifyListeners();
  }

  // ===============================
  // ACTIVATE APP WITH MACHINE BINDING
  // ===============================
  /// Essaie la clé saisie contre les 3 variantes de clé (une par palier,
  /// voir `_generateKey`) plutôt que de demander explicitement le palier
  /// dans l'écran d'activation : c'est la clé elle-même (différente par
  /// palier pour un même appareil) qui détermine quel palier est débloqué.
  Future<bool> activateApp(String enteredKey, String deviceId) async {
    final normalizedKey = enteredKey.toUpperCase();
    LicenseTier? matchedTier;
    for (final tier in LicenseTier.values) {
      if (_generateKey(deviceId, tier) == normalizedKey) {
        matchedTier = tier;
        break;
      }
    }

    if (matchedTier != null) {
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

        await setLicenseTier(matchedTier);

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
  // LICENSE TIER (Basic / Avancé / Premium)
  // ===============================
  /// Charge le palier stocké (même mécanisme de chiffrement+signature que
  /// `activated`) — retombe sur `premium` si absent/invalide, pour ne rien
  /// masquer tant qu'aucun flux d'activation ne fait réellement varier cette
  /// valeur (voir setLicenseTier).
  Future<void> _loadLicenseTier(String machineKey) async {
    try {
      final encrypted = await _secureStorage.read(key: 'license_tier');
      if (encrypted == null) {
        _licenseTier = LicenseTier.premium;
        return;
      }

      final decrypted = _decryptWithMachineKey(encrypted, machineKey);
      final signature = await _secureStorage.read(key: 'license_tier_signature');
      final expectedSignature = decrypted != null ? _generateSignature(decrypted, machineKey) : null;

      if (decrypted != null && signature == expectedSignature) {
        _licenseTier = LicenseTier.fromName(decrypted);
      } else {
        _licenseTier = LicenseTier.premium; // absent de signature valide → pas de restriction appliquée
      }
    } catch (e) {
      print('Error loading license tier: $e');
      _licenseTier = LicenseTier.premium;
    }
  }

  /// Persiste le palier de licence, chiffré et signé comme `activated`.
  /// Rien n'appelle encore cette méthode depuis l'UI — elle est prête pour
  /// le futur flux d'activation qui encodera le palier dans la clé saisie.
  Future<bool> setLicenseTier(LicenseTier tier) async {
    try {
      final machineKey = await _machineBinding.getMachineKey();
      final encrypted = _encryptWithMachineKey(tier.name, machineKey);
      await _secureStorage.write(key: 'license_tier', value: encrypted);

      final signature = _generateSignature(tier.name, machineKey);
      await _secureStorage.write(key: 'license_tier_signature', value: signature);

      _licenseTier = tier;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error setting license tier: $e');
      return false;
    }
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
  /// Premium garde exactement l'algorithme historique (deviceId seul, sans
  /// suffixe de palier) : toute clé déjà distribuée avant l'introduction des
  /// paliers doit continuer à activer l'app — en Premium, comportement
  /// identique à avant. Basic/Avancé sont de nouvelles variantes (suffixe
  /// de palier mixé dans le hash), qui n'ont jamais existé auparavant.
  String _generateKey(String deviceId, LicenseTier tier) {
    final input = tier == LicenseTier.premium ? deviceId : '$deviceId#${tier.name}';
    final mixed = _interleave(input, _secretKey);
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
  /// [rememberMe] : si vrai, mémorise username + hash du mot de passe (via
  /// flutter_secure_storage, déjà utilisé pour l'activation) pour permettre
  /// [tryAutoLogin] au prochain démarrage de l'app. Si faux, efface toute
  /// session mémorisée précédemment (décocher = désactive l'auto-login).
  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    // ✅ Toujours retirer les espaces superflus ici (pas seulement côté
    // appelant) : le hash dépend du contenu exact de la chaîne, un
    // utilisateur/mot de passe enregistré avec des espaces en trop
    // (utilisateur_nouveau.dart ne les retirait pas avant) ne matchera
    // jamais un login qui, lui, les retire.
    username = username.trim();
    password = password.trim();

    if (_isActivated) {
      const salt = 'SYSTEM_SALT';
      final hashed = hashPassword(password, salt);
      final success = await _authenticateWithHash(username, hashed);

      if (success) {
        if (rememberMe) {
          await _saveRememberedSession(username, hashed);
        } else {
          await _clearRememberedSession();
        }
      }

      return success;
    } else {
      if (username.toLowerCase() == 'demo' && password == 'demo') {
        _isAuthenticated = true;
        _username = 'Demo User';
        _role = 'demo';
        _userCode = 'DEMO';
        _userCaisseCode = null;
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
  // AUTHENTICATE WITH KNOWN PASSWORD HASH
  // (partagé par login() et tryAutoLogin(), pour ne stocker/comparer que le
  // hash côté auto-login, jamais le mot de passe en clair)
  // ===============================
  Future<bool> _authenticateWithHash(String username, String hashedPassword) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'utilisateur',
      where: 'username = ? AND password = ? AND etat = 1',
      whereArgs: [username, hashedPassword],
    );

    if (result.isEmpty) return false;

    _isAuthenticated = true;
    _username = result.first['username'] as String;
    _role = result.first['role'] as String;
    _userCode = result.first['code'] as String;
    _userCaisseCode = result.first['caisse_code'] as String?;

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

  Future<void> _saveRememberedSession(String username, String hashedPassword) async {
    await _secureStorage.write(key: _rememberUsernameKey, value: username);
    await _secureStorage.write(key: _rememberPasswordHashKey, value: hashedPassword);
  }

  Future<void> _clearRememberedSession() async {
    await _secureStorage.delete(key: _rememberUsernameKey);
    await _secureStorage.delete(key: _rememberPasswordHashKey);
  }

  // ===============================
  // AUTO-LOGIN AU DÉMARRAGE (session mémorisée)
  // ===============================
  /// Appelé une fois au démarrage de l'app (voir main.dart) : si une session
  /// a été mémorisée via login(..., rememberMe: true), reconnecte
  /// automatiquement l'utilisateur sans repasser par l'écran de login.
  Future<bool> tryAutoLogin() async {
    if (!_isActivated) return false;

    final username = await _secureStorage.read(key: _rememberUsernameKey);
    final hashedPassword = await _secureStorage.read(key: _rememberPasswordHashKey);
    if (username == null || hashedPassword == null) return false;

    return _authenticateWithHash(username, hashedPassword);
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
  /// Retourne `null` en cas de succès, sinon le message d'erreur réel
  /// remonté par le service (ex. contrainte de clé étrangère violée) — pour
  /// que l'écran Paramètres puisse afficher autre chose qu'un message
  /// générique.
  Future<String?> updateUserParameters({
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
        return null;
      }
      debugPrint('updateUserParameters (addUserParam) failed: ${response.message}');
      return response.message;
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
        return null;
      }
      debugPrint('updateUserParameters (updateUserParam) failed: ${response.message}');
      return response.message;
    }
  }

  // ===============================
  // LOGOUT
  // ===============================
  void logout({required String username, required String userCode}) async {
    final db = await DbCreator.openDb();
    final services = HistoriqueServices(db);

    await _clearRememberedSession();

    _isAuthenticated = false;
    _userCode = null;
    _username = null;
    _role = null;
    _userCaisseCode = null;
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

  // ===============================
  // UPDATE USERNAME (dialog "Mon Compte")
  // ===============================
  /// Répercute un changement de nom d'utilisateur fait depuis le dialog
  /// "Mon Compte" sans repasser par login(), pour que le nom affiché
  /// ailleurs dans l'app (ex. AccountWidget) reste à jour immédiatement.
  void updateUsername(String newUsername) {
    _username = newUsername;
    notifyListeners();
  }

  bool get isLoggedIn => _isAuthenticated;
}