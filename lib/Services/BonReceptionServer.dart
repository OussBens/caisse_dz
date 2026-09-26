// services/BonReceptionServer.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/BonReception.dart';
import 'package:caisse_dz/Services/BonReceptionPhotos.dart';
import 'package:caisse_dz/Services/CatalogService.dart';
import 'package:caisse_dz/Services/CatalogSyncService.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Photos.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/RoleDetail.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/secure_storage_service.dart';
import 'package:caisse_dz/core/utilis/prix_vente_calculator.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/bon_reception.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_code_detail.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../core/utilis/api_response.dart';

/// Appareil mobile appairé avec ce desktop (informatif : affiché dans le
/// dialog de connexion, ne sert pas de contrôle d'accès par appareil).
class PairedDevice {
  final String deviceId;
  final String deviceName;
  final DateTime pairedAt;

  const PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.pairedAt,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'paired_at': pairedAt.toIso8601String(),
      };

  factory PairedDevice.fromJson(Map<String, dynamic> json) => PairedDevice(
        deviceId: json['device_id'] as String,
        deviceName: json['device_name'] as String? ?? 'Téléphone',
        pairedAt: DateTime.tryParse(json['paired_at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Serveur HTTP local permettant à l'app mobile compagnon de s'appairer
/// avec ce desktop, de s'authentifier, puis de synchroniser des données
/// (photos de bons de réception, ventes, produits, stock...) sur le même
/// réseau WiFi.
///
/// Endpoints :
/// - GET  /api/discovery        : confirme la présence du desktop.
/// - POST /api/pairing/confirm  : échange un code d'appairage éphémère
///   contre un `desktop_token` durable, requis par toutes les routes
///   suivantes (header `X-Desktop-Token`).
/// - POST /api/auth/login       : authentifie un utilisateur existant et
///   retourne un `token` de session (stocké dans `utilisateur.api_token`),
///   requis en plus (header `Authorization: Bearer`) par les routes
///   protégées par [_requireAuthenticatedUser].
/// - POST /api/reception/upload : reçoit une photo + métadonnées (multipart).
/// - GET  /api/fournisseurs     : liste des fournisseurs (dropdown mobile).
///
/// Implémenté avec `dart:io HttpServer` brut (pas de dépendance `shelf`
/// supplémentaire) — seulement quelques routes, le paquet `mime` déjà présent
/// suffit pour parser le multipart/form-data.
class BonReceptionServer {
  BonReceptionServer._internal();

  static final BonReceptionServer instance = BonReceptionServer._internal();

  static const String portPrefKey = 'bon_reception_server_port';
  static const int defaultPort = 8080;
  static const int maxPhotoBytes = 20 * 1024 * 1024; // 20 Mo

  static const String _desktopTokenKey = 'bon_reception_desktop_token';
  static const String _desktopNameKey = 'bon_reception_desktop_name';
  static const String _pairedDevicesPrefKey = 'bon_reception_paired_devices';
  static const Duration pairingCodeTtl = Duration(minutes: 5);
  static const String _pairingCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans 0/O, 1/I

  HttpServer? _server;
  int? _port;
  String? _desktopToken;
  String? _desktopName;
  String? _pairingCode;
  DateTime? _pairingCodeExpiresAt;

  int? get port => _port;
  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  final ValueNotifier<DateTime?> lastPingAt = ValueNotifier(null);
  final ValueNotifier<String?> pairingCode = ValueNotifier(null);
  final ValueNotifier<DateTime?> pairingCodeExpiresAt = ValueNotifier(null);
  final ValueNotifier<List<PairedDevice>> pairedDevices = ValueNotifier(const []);

  String get desktopName => _desktopName ?? Platform.localHostname;

  /// Notifié après chaque upload réussi, pour rafraîchir l'écran sans polling.
  void Function(BonReception bon)? onBonReceived;

  /// Charge (ou crée) le token durable du desktop et le nom affiché, requis
  /// pour l'appairage. Appelé automatiquement au démarrage du serveur.
  Future<void> _ensureDesktopIdentity() async {
    final storage = SecureStorageService();
    _desktopToken ??= await storage.readSecureDataTyped<String>(_desktopTokenKey);
    if (_desktopToken == null) {
      _desktopToken = const Uuid().v4();
      await storage.writeSecureData(_desktopTokenKey, _desktopToken);
    }

    final prefs = await SharedPreferences.getInstance();
    _desktopName ??= prefs.getString(_desktopNameKey);

    if (pairedDevices.value.isEmpty) {
      final saved = prefs.getString(_pairedDevicesPrefKey);
      if (saved != null) {
        try {
          pairedDevices.value = (jsonDecode(saved) as List)
              .map((e) => PairedDevice.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }
  }

  Future<void> setDesktopName(String name) async {
    _desktopName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_desktopNameKey, name);
  }

  /// Génère un nouveau code d'appairage à usage unique (valable
  /// [pairingCodeTtl]), encodé dans le QR et affiché en clair pour saisie
  /// manuelle sur le téléphone.
  String generatePairingCode() {
    final rand = Random.secure();
    final code = List.generate(
      8,
      (_) => _pairingCodeAlphabet[rand.nextInt(_pairingCodeAlphabet.length)],
    ).join();
    _pairingCode = code;
    _pairingCodeExpiresAt = DateTime.now().add(pairingCodeTtl);
    pairingCode.value = code;
    pairingCodeExpiresAt.value = _pairingCodeExpiresAt;
    return code;
  }

  void clearPairingCode() {
    _pairingCode = null;
    _pairingCodeExpiresAt = null;
    pairingCode.value = null;
    pairingCodeExpiresAt.value = null;
  }

  Future<void> _persistPairedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pairedDevicesPrefKey,
      jsonEncode(pairedDevices.value.map((d) => d.toJson()).toList()),
    );
  }

  static Future<int> getSavedPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(portPrefKey) ?? defaultPort;
  }

  static Future<void> savePort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(portPrefKey, port);
  }

  static Future<List<String>> localIPv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    return interfaces.expand((i) => i.addresses).map((a) => a.address).toList();
  }

  Future<ApiResponse<int>> start({int port = defaultPort}) async {
    if (isRunning.value) {
      if (_port == port) {
        return ApiResponse(success: true, message: 'Déjà démarré', data: port);
      }
      await stop();
    }

    try {
      await _ensureDesktopIdentity();
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
      _server = server;
      _port = port;
      isRunning.value = true;
      await savePort(port);

      server.listen((request) {
        _handleRequest(request).catchError((e) {
          debugPrint('Erreur serveur réception: $e');
          try {
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..close();
          } catch (_) {}
        });
      });

      return ApiResponse(success: true, message: 'Serveur démarré', data: port);
    } catch (e) {
      _server = null;
      _port = null;
      isRunning.value = false;
      return ApiResponse(success: false, message: 'Impossible de démarrer le serveur: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
    isRunning.value = false;
  }

  /// Vérifie le header `X-Desktop-Token` (requis sur toutes les routes sauf
  /// `/api/discovery` et `/api/pairing/confirm`). Écrit une réponse 401 et
  /// retourne `false` si absent/invalide — l'appelant doit alors s'arrêter
  /// sans fermer la réponse une seconde fois.
  Future<bool> _requireDesktopToken(HttpRequest request) async {
    final token = request.headers.value('x-desktop-token');
    if (_desktopToken == null || token != _desktopToken) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Token desktop invalide ou manquant — appairez le téléphone'}));
      await request.response.close();
      return false;
    }
    return true;
  }

  /// Vérifie `X-Desktop-Token` puis `Authorization: Bearer {user_token}` et
  /// retourne l'utilisateur authentifié (voir POST /api/auth/login), ou
  /// `null` si la réponse 401 a déjà été écrite.
  Future<Utilisateur?> _requireAuthenticatedUser(HttpRequest request) async {
    if (!await _requireDesktopToken(request)) return null;

    final authHeader = request.headers.value('authorization');
    final userToken = (authHeader != null && authHeader.startsWith('Bearer '))
        ? authHeader.substring(7)
        : null;

    final user = userToken != null && userToken.isNotEmpty
        ? await UtilisateurServices.getUtilisateurByApiToken(userToken)
        : null;

    if (user == null) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Session invalide — reconnectez-vous'}));
      await request.response.close();
      return null;
    }
    return user;
  }

  /// Même schéma de hachage que AuthState.hashPassword / utilisateur_nouveau.dart.
  String _hashPassword(String password) {
    const salt = 'SYSTEM_SALT';
    return sha256.convert(utf8.encode(password + salt)).toString();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method == 'GET' && request.uri.path == '/api/discovery') {
      lastPingAt.value = DateTime.now();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'app': 'CaisseDZ', 'status': 'ok'}));
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/pairing/confirm') {
      await _handlePairingConfirm(request);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/auth/login') {
      await _handleLogin(request);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/reception/upload') {
      await _handleUpload(request);
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/fournisseurs') {
      await _handleFournisseurs(request);
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/clients') {
      await _handleClients(request);
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/auth/session') {
      await _handleAuthSession(request);
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/products/search') {
      await _handleProductSearch(request);
      return;
    }

    if (request.method == 'GET' &&
        request.uri.pathSegments.length == 4 &&
        request.uri.pathSegments[0] == 'api' &&
        request.uri.pathSegments[1] == 'products' &&
        request.uri.pathSegments[2] == 'barcode') {
      await _handleProductByBarcode(request, request.uri.pathSegments[3]);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/smartscan/upload') {
      await _handleSmartScanUpload(request);
      return;
    }

    if (request.method == 'GET' &&
        request.uri.pathSegments.length == 4 &&
        request.uri.pathSegments[0] == 'api' &&
        request.uri.pathSegments[1] == 'photos' &&
        request.uri.pathSegments[2] == 'products') {
      await _handleProductPhoto(request, request.uri.pathSegments[3]);
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/sync/pull') {
      await _handleSyncPull(request);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/sync/push/stock-movement') {
      await _handleSyncPushStockMovement(request);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/sync/push/product') {
      await _handleSyncPushProduct(request);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/sync/push/return') {
      await _handleSyncPushReturn(request);
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/sync/push/sale') {
      await _handleSyncPushSale(request);
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Not found'}));
    await request.response.close();
  }

  /// Échange un code d'appairage éphémère (affiché/scanné sur le desktop)
  /// contre le `desktop_token` durable que le mobile réutilisera pour
  /// authentifier ses uploads suivants (header `X-Desktop-Token`).
  Future<void> _handlePairingConfirm(HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final token = data['pairing_token'] as String?;
      final deviceId = data['device_id'] as String?;
      final deviceName = (data['device_name'] as String?)?.trim();

      if (token == null || deviceId == null || deviceId.isEmpty) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write(jsonEncode({'error': 'pairing_token et device_id requis'}));
        await request.response.close();
        return;
      }

      final isValid = _pairingCode != null &&
          _pairingCode == token &&
          _pairingCodeExpiresAt != null &&
          DateTime.now().isBefore(_pairingCodeExpiresAt!);

      if (!isValid) {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write(jsonEncode({'error': "Code d'appairage invalide ou expiré"}));
        await request.response.close();
        return;
      }

      await _ensureDesktopIdentity();

      final devices = [...pairedDevices.value];
      final device = PairedDevice(
        deviceId: deviceId,
        deviceName: (deviceName == null || deviceName.isEmpty) ? 'Téléphone' : deviceName,
        pairedAt: DateTime.now(),
      );
      final existingIndex = devices.indexWhere((d) => d.deviceId == deviceId);
      if (existingIndex >= 0) {
        devices[existingIndex] = device;
      } else {
        devices.add(device);
      }
      pairedDevices.value = devices;
      await _persistPairedDevices();

      // Code à usage unique : consommé après un appairage réussi.
      clearPairingCode();

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({
          'success': true,
          'desktop_token': _desktopToken,
          'desktop_name': desktopName,
        }));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Requête invalide: $e'}));
    }
    await request.response.close();
  }

  /// Authentifie un utilisateur `utilisateur` existant (même schéma de hash
  /// que la connexion desktop, voir [_hashPassword]) et génère un `token` de
  /// session stocké dans `utilisateur.api_token`, requis ensuite par les
  /// routes protégées par [_requireAuthenticatedUser].
  Future<void> _handleLogin(HttpRequest request) async {
    if (!await _requireDesktopToken(request)) return;

    request.response.headers.contentType = ContentType.json;
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final username = (data['username'] as String?)?.trim();
      final password = (data['password'] as String?)?.trim();

      if (username == null || username.isEmpty || password == null || password.isEmpty) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write(jsonEncode({'success': false, 'error': 'username et password requis'}));
        await request.response.close();
        return;
      }

      final hashed = _hashPassword(password);
      final user = await UtilisateurServices.findUtilisateurByUsername(username);

      if (user == null || !user.etat || user.password != hashed) {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write(jsonEncode({'success': false, 'error': 'Identifiants invalides'}));
        await request.response.close();
        return;
      }

      final token = const Uuid().v4();
      final db = await DbCreator.openDb();
      await UtilisateurServices(db).setApiToken(user.id, token);

      final roleDetail = await RoleDetailServices.getRoleByCode(user.role_code);

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({
          'success': true,
          'token': token,
          'user': {
            'id': user.id,
            'nom': user.username,
            'role': user.role,
            'permissions': roleDetail?.permissionsList ?? <String>[],
          },
        }));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'success': false, 'error': 'Requête invalide: $e'}));
    }
    await request.response.close();
  }

  /// Liste des fournisseurs actifs, pour peupler un dropdown côté mobile
  /// (écran réception).
  Future<void> _handleFournisseurs(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    final fournisseurs = await FournisseurServices.getAllFournisseurs();
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'fournisseurs': fournisseurs
            .where((f) => f.etat)
            .map((f) => {'code': f.code, 'nom': f.nom, 'telephone': f.telephone})
            .toList(),
      }));
    await request.response.close();
  }

  /// Liste des clients actifs, pour le module Panier mobile (autocomplétion/
  /// sélection d'un client existant) — même schéma que [_handleFournisseurs].
  Future<void> _handleClients(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    final clients = await ClientServices.getAllClients();
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'clients': clients
            .where((c) => c.etat)
            .map((c) => {'code': c.code, 'nom': c.nom, 'telephone': c.telephone})
            .toList(),
      }));
    await request.response.close();
  }

  /// Valide un `user_token` déjà obtenu (POST /api/auth/login) sans effectuer
  /// d'autre opération — permet au mobile de revalider une session persistée
  /// (secure storage, pas de DB) au démarrage plutôt que de forcer un nouveau
  /// login, tout en détectant un utilisateur désactivé/supprimé entretemps.
  Future<void> _handleAuthSession(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    final roleDetail = await RoleDetailServices.getRoleByCode(user.role_code);

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'user': {
          'id': user.id,
          'nom': user.username,
          'role': user.role,
          'permissions': roleDetail?.permissionsList ?? <String>[],
        },
      }));
    await request.response.close();
  }

  /// Catalogue incrémental (marques, catégories, produits + codes-barres +
  /// stock agrégé) — seul mécanisme qui alimente le catalogue local du
  /// mobile. `since` (ISO8601, optionnel) filtre sur `date_modif` (ou
  /// `date_cree` si jamais modifié depuis) pour ne renvoyer que les entités
  /// touchées depuis le dernier pull réussi.
  ///
  /// `brands` reste toujours vide : il n'existe pas de table Marque côté
  /// desktop, `marque` n'est qu'un champ texte libre sur `produits`.
  /// `seuil_alerte` est le seuil global (`parametre.minimum`), il n'existe
  /// pas de seuil par produit côté desktop.
  Future<void> _handleSyncPull(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    final sinceRaw = request.uri.queryParameters['since'];
    final since = sinceRaw != null ? DateTime.tryParse(sinceRaw) : null;

    final db = await DbCreator.openDb();
    final serverTime = DateTime.now().toIso8601String();

    final categorieMaps = since != null
        ? await db.query('categories', where: 'COALESCE(date_modif, date_cree) > ?', whereArgs: [since.toIso8601String()])
        : await db.query('categories');

    final categories = categorieMaps
        .map((m) => {
              'id': m['id'],
              'nom': m['nom'],
              'updated_at': m['date_modif'] ?? m['date_cree'],
            })
        .toList();

    final sousCategorieMaps = since != null
        ? await db.query('sous_categories', where: 'COALESCE(date_modif, date_cree) > ?', whereArgs: [since.toIso8601String()])
        : await db.query('sous_categories');

    final sousCategories = sousCategorieMaps
        .map((m) => {
              'id': m['id'],
              'category_id': m['categorie_id'],
              'nom': m['nom'],
              'updated_at': m['date_modif'] ?? m['date_cree'],
            })
        .toList();

    final produitMaps = since != null
        ? await db.query('produits', where: 'COALESCE(date_modif, date_cree) > ?', whereArgs: [since.toIso8601String()])
        : await db.query('produits');

    final param = await ParamServices.getParam();
    final secondaryBarcodesByProduitCode = await _loadSecondaryBarcodesByProduitCode();
    final magasinDetailService = ProduitMagasinDetailServices(db);

    final products = <Map<String, dynamic>>[];
    for (final m in produitMaps) {
      products.add(await _produitToJson(
        Produit.fromMap(m),
        magasinDetailService,
        secondaryBarcodesByProduitCode,
        param.Minimum,
      ));
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'server_time': serverTime,
        'brands': const [],
        'categories': categories,
        'sous_categories': sousCategories,
        'products': products,
      }));
    await request.response.close();
  }

  /// Table `produit_code_detail` (codes-barres secondaires), indexée par
  /// code produit — reconstruite à chaque appel (pas de cache) car peu
  /// coûteuse et évite tout risque de désynchronisation.
  Future<Map<String, List<String>>> _loadSecondaryBarcodesByProduitCode() async {
    final codeDetails = await ProduitServices.getAllCodeDetails();
    final Map<String, List<String>> byProduitCode = {};
    for (final d in codeDetails) {
      byProduitCode.putIfAbsent(d.produitCode, () => []).add(d.CodeBar);
    }
    return byProduitCode;
  }

  /// Sérialisation JSON d'un produit, partagée entre le pull catalogue
  /// (`/api/sync/pull`) et les lookups unitaires (`/api/products/barcode/*`,
  /// `/api/products/search`) — même forme d'objet dans les trois cas.
  Future<Map<String, dynamic>> _produitToJson(
    Produit produit,
    ProduitMagasinDetailServices magasinDetailService,
    Map<String, List<String>> secondaryBarcodesByProduitCode,
    double seuilAlerte,
  ) async {
    final barcodes = <String>[
      if (produit.codeBarre != null && produit.codeBarre!.isNotEmpty) produit.codeBarre!,
      ...(secondaryBarcodesByProduitCode[produit.code] ?? const []),
    ];
    final quantite = await MouvementsServices.quantiteProduit(produit.code);

    return {
      'id': produit.id,
      'code_produit': produit.code,
      'nom': produit.nom,
      'description': produit.description,
      'brand_id': null,
      'category_id': produit.categorieId,
      'couleur': produit.couleur,
      'taille': produit.taille,
      'photo_url': _photoUrlFor(produit.photo),
      'prix_achat': produit.prixAchat,
      'prix_vente': produit.prixVente,
      'updated_at': (produit.dateModif ?? produit.dateCree).toIso8601String(),
      'source': 'desktop',
      'barcodes': barcodes,
      'stock': {
        'quantite': quantite,
        'seuil_alerte': seuilAlerte,
      },
    };
  }

  /// Transforme un nom de fichier photo local (`produit.photo`, ex.
  /// "PRD000123_main.jpg") en chemin exploitable par le mobile via
  /// [_handleProductPhoto] — le mobile connaît déjà l'ip/port du desktop
  /// pairé (voir pairing) et n'a qu'à préfixer ce chemin.
  String? _photoUrlFor(String? photoFileName) {
    if (photoFileName == null || photoFileName.isEmpty) return null;
    return '/api/photos/products/$photoFileName';
  }

  /// Sert le fichier binaire d'une photo produit — nécessaire pour que
  /// `photo_url` (voir [_photoUrlFor]) soit réellement récupérable par le
  /// mobile, qui n'a pas d'accès disque au poste desktop. Le nom de fichier
  /// vient de l'URL (contrôlable par l'appelant) : restreint à
  /// lettres/chiffres/points/tirets pour empêcher toute traversée de
  /// répertoire (`../..`).
  Future<void> _handleProductPhoto(HttpRequest request, String filename) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    if (!RegExp(r'^[\w.\-]+$').hasMatch(filename)) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Nom de fichier invalide'}));
      await request.response.close();
      return;
    }

    final file = await PhotoService.getPhotoFile(filename);
    if (file == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Photo introuvable'}));
      await request.response.close();
      return;
    }

    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final bytes = await file.readAsBytes();
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.parse(mimeType)
      ..add(bytes);
    await request.response.close();
  }

  /// Lookup d'un produit par code-barres (principal ou secondaire), pour un
  /// client mobile "live" qui n'entretient pas de cache local et ne veut pas
  /// tirer tout le catalogue (`/api/sync/pull`) à chaque scan.
  ///
  /// Délègue à [CatalogService.lookupByBarcode] — la même cascade que le
  /// flux "nouveau produit IA" du desktop (local -> catalogue distant
  /// CaisseDZ -> Mantouj -> Open Food Facts -> Open Beauty Facts) — pour ne
  /// jamais avoir deux implémentations de cette cascade dans l'app. Un
  /// produit trouvé en local renvoie `product` (avec stock réel, faisant
  /// autorité) comme avant ; un résultat trouvé uniquement à distance renvoie
  /// `suggestion` (pas encore un produit local, juste de quoi pré-remplir un
  /// formulaire de création rapide côté mobile, `POST /api/sync/push/product`).
  Future<void> _handleProductByBarcode(HttpRequest request, String barcode) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    request.response.headers.contentType = ContentType.json;

    final lookup = await CatalogService().lookupByBarcode(barcode);

    if (lookup == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'success': false, 'error': 'Produit introuvable'}));
      await request.response.close();
      return;
    }

    if (lookup.source == CatalogLookupSource.local) {
      final db = await DbCreator.openDb();
      final param = await ParamServices.getParam();
      final secondaryBarcodesByProduitCode = await _loadSecondaryBarcodesByProduitCode();
      final magasinDetailService = ProduitMagasinDetailServices(db);

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({
          'success': true,
          'source': 'local',
          'product': await _produitToJson(
            lookup.existingProduit!,
            magasinDetailService,
            secondaryBarcodesByProduitCode,
            param.Minimum,
          ),
        }));
      await request.response.close();
      return;
    }

    final suggestion = lookup.suggestion!;
    request.response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({
        'success': true,
        'source': _catalogSourceKey(lookup.source),
        'suggestion': {
          'nom': suggestion.nom,
          'marque': suggestion.marque,
          'categorie': suggestion.categorie,
          'code_barre': suggestion.codeBarre ?? barcode,
          'photo_url': suggestion.photoUrl,
          'taille': suggestion.taille,
          'couleur': suggestion.couleur,
          'source_label': suggestion.sourceLabel,
        },
      }));
    await request.response.close();
  }

  /// Clé JSON stable (indépendante des libellés affichables, qui peuvent
  /// changer) identifiant la source d'une suggestion distante.
  String _catalogSourceKey(CatalogLookupSource source) {
    switch (source) {
      case CatalogLookupSource.local:
        return 'local';
      case CatalogLookupSource.catalogApi:
        return 'catalog_dz';
      case CatalogLookupSource.mantouj:
        return 'mantouj';
      case CatalogLookupSource.openFood:
        return 'open_food_facts';
      case CatalogLookupSource.openBeauty:
        return 'open_beauty_facts';
    }
  }

  /// Recherche texte (nom / code / code-barres principal ou secondaire),
  /// pour le champ de recherche du module Produit mobile — même pattern que
  /// `appliquerFiltre` côté desktop, sans cache local côté mobile.
  Future<void> _handleProductSearch(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    request.response.headers.contentType = ContentType.json;

    final query = (request.uri.queryParameters['q'] ?? '').trim();
    final db = await DbCreator.openDb();
    final magasinDetailService = ProduitMagasinDetailServices(db);
    final secondaryBarcodesByProduitCode = await _loadSecondaryBarcodesByProduitCode();
    final param = await ParamServices.getParam();

    List<Map<String, dynamic>> produitMaps;
    if (query.isEmpty) {
      produitMaps = await db.query('produits', orderBy: 'nom ASC', limit: 30);
    } else {
      final like = '%$query%';
      final matchingCodes = secondaryBarcodesByProduitCode.entries
          .where((e) => e.value.any((code) => code.toLowerCase().contains(query.toLowerCase())))
          .map((e) => e.key)
          .toList();

      final whereParts = ['nom LIKE ?', 'code LIKE ?', 'code_barre LIKE ?'];
      final whereArgs = <Object?>[like, like, like];
      if (matchingCodes.isNotEmpty) {
        whereParts.add('code IN (${List.filled(matchingCodes.length, '?').join(',')})');
        whereArgs.addAll(matchingCodes);
      }

      produitMaps = await db.query(
        'produits',
        where: whereParts.join(' OR '),
        whereArgs: whereArgs,
        orderBy: 'nom ASC',
        limit: 30,
      );
    }

    final products = <Map<String, dynamic>>[];
    for (final m in produitMaps) {
      products.add(await _produitToJson(
        Produit.fromMap(m),
        magasinDetailService,
        secondaryBarcodesByProduitCode,
        param.Minimum,
      ));
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({'success': true, 'products': products}));
    await request.response.close();
  }

  /// Résout un produit envoyé par le mobile : priorité au `remote_product_id`
  /// (id desktop reçu lors d'un pull/push précédent), sinon repli sur le
  /// `barcode` scanné (principal ou secondaire).
  Future<String?> _resolveProduitCodeForSync(Database db, {int? remoteProductId, String? barcode}) async {
    if (remoteProductId != null) {
      final produit = await ProduitServices(db).getProduitById(remoteProductId);
      if (produit != null) return produit.code;
    }
    if (barcode != null && barcode.isNotEmpty) {
      return await ProduitServices.getProduitCodeByBarcode(barcode);
    }
    return null;
  }

  /// Crée un SmartScan à 1 produit (nbrProduit=1) pour un mouvement d'entrée
  /// envoyé par le mobile, même schéma que la "Entrée rapide" desktop
  /// (voir entree_nouveau.dart) mais sans le versement fournisseur
  /// automatique — le mobile n'envoie aucune information de paiement, créer
  /// un versement "réglé intégralement" serait fabriquer une transaction
  /// financière qui n'a pas eu lieu.
  Future<int> _pushStockMovementItem(Database db, Map<String, dynamic> item, Utilisateur user, String? deviceId) async {
    final produitCode = await _resolveProduitCodeForSync(
      db,
      remoteProductId: item['remote_product_id'] as int?,
      barcode: item['barcode'] as String?,
    );
    if (produitCode == null) {
      throw StateError('Produit introuvable (barcode=${item['barcode']}, remote_product_id=${item['remote_product_id']})');
    }

    final serviceProduit = ProduitServices(db);
    final produit = await serviceProduit.getProduitByCode(produitCode);
    if (produit == null) {
      throw StateError('Produit $produitCode introuvable');
    }

    final quantite = (item['quantite'] as num).toDouble();
    // Second stock parallèle "Nombre" (Paramètres > Nombre et Quantité) —
    // extension du contrat, absente si le mobile ne l'envoie pas.
    final nombre = (item['nombre'] as num?)?.toDouble();
    final prixAchat = (item['prix_achat'] as num?)?.toDouble() ?? 0;
    final fournisseurCode = await _resolveFournisseurCode(item['fournisseur'] as String?);
    final createdAtRaw = item['created_at'] as String?;
    final date = (createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null) ?? DateTime.now();

    final serviceSS = SmartScanServices(db);
    final serviceSSP = SmartScanProduitServices(db);
    final serviceMagasinDetail = ProduitMagasinDetailServices(db);
    final serviceMouvement = MouvementsServices(db);

    final smartScanId = await SmartScanServices.getNextSmartScanId(db);
    final smartScan = SmartScan(
      id: smartScanId,
      code: CodeGenerator.generateCode(prefix: CodePrefix.smartscan, id: smartScanId, digitCount: 6),
      date: date,
      montant: quantite * prixAchat,
      nbrProduit: 1,
      fournisseurCode: fournisseurCode,
      etat: true,
      observation: item['commentaire'] as String?,
      dateCree: DateTime.now(),
      creeParCode: user.code,
      deviceIdMobile: deviceId,
    );
    final ssResponse = await serviceSS.addSmartScan(smartScan);
    if (!ssResponse.success || ssResponse.data == null) {
      throw StateError(ssResponse.message);
    }

    final ligneId = await SmartScanProduitServices.getNextSmartScanProduitId(db);
    final ligne = SmartScanProduit(
      id: ligneId,
      codeSmartScan: smartScan.code,
      codeProduit: produit.code,
      quantite: quantite,
      nombre: nombre,
      prix: prixAchat,
      prixVente: produit.prixVente,
      total: quantite * prixAchat,
      etat: true,
      creeParCode: user.code,
      creeLe: DateTime.now(),
    );
    await serviceSSP.addSmartScanProduit(ligne);

    if (!produit.service) {
      if (nombre != null) produit.nombre += nombre;
    }
    produit.prixAchat = prixAchat;
    produit.modifParCode = user.code;
    await serviceProduit.updateProduit(produit);

    final magasinCode = await _resolveMagasinCodeForUser(db, user);
    final magasinDetail = await serviceMagasinDetail.getSingleByProduitAndMagasin(produit.code, magasinCode);
    if (magasinDetail != null) {
      if (nombre != null) {
        await serviceMagasinDetail.updateNombre(magasinDetail.id, magasinDetail.nombre + nombre);
      }
    } else {
      final detailId = await ProduitMagasinDetailServices.getNextId(db);
      await serviceMagasinDetail.addProduitMagasinDetail(ProduitMagasinDetail(
        id: detailId,
        magasinCode: magasinCode,
        produitCode: produit.code,
        dateCree: DateTime.now(),
        creeParCode: user.code,
        nombre: nombre ?? 0,
      ));
    }

    final mouvementId = await MouvementsServices.getNextMouvementId(db);
    await serviceMouvement.addMouvement(Mouvement(
      id: mouvementId,
      code: CodeGenerator.generateCode(prefix: CodePrefix.mouvement, id: mouvementId, digitCount: 8),
      date: date,
      codeProduit: produit.code,
      quantite: quantite,
      nombre: nombre,
      prixAchat: prixAchat,
      prixVente: produit.prixVente,
      fournisseurCode: fournisseurCode,
      type: ListsConst.typeMouvement[1], // "Achat"
      magasinCode: magasinCode, // même valeur que produit_magasin_detail ci-dessus
      etat: true,
      codeOperation: smartScan.code,
      dateCree: DateTime.now(),
      creeParCode: user.code,
    ));

    return smartScanId;
  }

  /// Mouvements de stock envoyés par le mobile (entrées uniquement pour
  /// l'instant) — chaque item crée un SmartScan à 1 produit (voir
  /// [_pushStockMovementItem]). `device_id` est optionnel, au niveau racine
  /// de la requête (pas par item : tous les items d'un même batch viennent
  /// du même appareil).
  Future<void> _handleSyncPushStockMovement(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    request.response.headers.contentType = ContentType.json;
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];
      final deviceId = data['device_id'] as String?;

      final db = await DbCreator.openDb();
      final mapping = <Map<String, dynamic>>[];

      for (final rawItem in items) {
        final item = rawItem as Map<String, dynamic>;
        try {
          final remoteId = await _pushStockMovementItem(db, item, user, deviceId);
          mapping.add({'local_id': item['local_id'], 'remote_id': remoteId});
        } catch (e) {
          debugPrint('push/stock-movement item ${item['local_id']} ignoré: $e');
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({'success': true, 'mapping': mapping}));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'success': false, 'error': 'Requête invalide: $e'}));
    }
    await request.response.close();
  }

  /// Catégorie/sous-catégorie de repli pour un produit créé sans catégorie
  /// choisie — même convention que produit_nouveau.dart ("Sans Categorie" /
  /// "Sans Sous-Catego", cherchées par nom plutôt que par id codé en dur).
  Future<int> _defaultCategorieId(Database db) async {
    final maps = await db.query('categories', where: 'nom = ?', whereArgs: ['Sans Categorie'], limit: 1);
    return maps.isNotEmpty ? maps.first['id'] as int : 1;
  }

  Future<int> _defaultSousCategorieId(Database db) async {
    final maps = await db.query('sous_categories', where: 'nom = ?', whereArgs: ['Sans Sous-Catego'], limit: 1);
    return maps.isNotEmpty ? maps.first['id'] as int : 1;
  }

  /// Décode une photo envoyée en base64 par le mobile (avec ou sans préfixe
  /// data URI, ex. "data:image/jpeg;base64,...") et l'enregistre comme
  /// fichier via [PhotoService] — le reste de l'app (fiche produit, push
  /// catalogue DZ via [CatalogSyncService]) attend un nom de fichier local
  /// dans `produit.photo`, jamais du base64 brut. Retourne `null` (photo
  /// ignorée sans bloquer la création du produit) si le champ est vide ou
  /// invalide.
  Future<String?> _decodeAndSaveProductPhoto(String? photoField, String produitCode) async {
    if (photoField == null || photoField.isEmpty) return null;

    try {
      final base64Data = photoField.contains(',') ? photoField.substring(photoField.indexOf(',') + 1) : photoField;
      final bytes = base64Decode(base64Data);
      return await PhotoService.savePhotoBytes(bytes, produitCode);
    } catch (e) {
      debugPrint('Photo produit ignorée (base64 invalide): $e');
      return null;
    }
  }

  /// Crée ou met à jour un produit envoyé par le mobile.
  ///
  /// `brand_id` est ignoré (pas de table Marque côté desktop — décision
  /// actée). `remote_id` (extension du contrat, comme `device_id` pour
  /// push/stock-movement) identifie le produit desktop à mettre à jour pour
  /// `operation: "update"` — sans lui, impossible de savoir quelle ligne
  /// modifier, donc on retombe sur une création. `barcode`/`barcodes`
  /// (extension du contrat, absente de la spec initiale) portent le(s)
  /// code-barre(s) scanné(s) : sans ça un produit créé depuis le mobile
  /// n'aurait aucun moyen d'être retrouvé par scan ensuite.
  Future<int> _pushProduitItem(Database db, Map<String, dynamic> item, Utilisateur user, String? deviceId) async {
    final serviceProduit = ProduitServices(db);
    final remoteId = item['remote_id'] as int?;
    final operation = item['operation'] as String?;

    if (operation == 'update' && remoteId != null) {
      final existing = await serviceProduit.getProduitById(remoteId);
      if (existing != null) {
        final nom = (item['nom'] as String?)?.trim();
        if (nom != null && nom.isNotEmpty) existing.nom = nom;
        if (item['description'] != null) existing.description = item['description'] as String?;
        if (item['marque'] != null) existing.marque = (item['marque'] as String).trim();
        if (item['couleur'] != null) existing.couleur = item['couleur'] as String?;
        if (item['taille'] != null) existing.taille = item['taille'] as String?;
        if (item['photo'] != null) {
          existing.photo = await _decodeAndSaveProductPhoto(item['photo'] as String?, existing.code) ?? existing.photo;
        }
        if (item['category_id'] != null) existing.categorieId = item['category_id'] as int;
        if (item['sous_category_id'] != null) existing.sousCategorieId = item['sous_category_id'] as int;
        if (item['fournisseur'] != null) {
          existing.fournisseurCode = await _resolveFournisseurCode(item['fournisseur'] as String?);
        }
        if (item['prix_achat'] != null) existing.prixAchat = (item['prix_achat'] as num).toDouble();
        if (item['prix_vente'] != null) existing.prixVente = (item['prix_vente'] as num).toDouble();
        if (item['prix_achat'] != null || item['prix_vente'] != null) {
          if (existing.prixAchat > 0 && existing.prixVente > 0) {
            existing.margeTaux = existing.prixVente - existing.prixAchat;
            existing.margeTauxPrct = (existing.margeTaux / existing.prixAchat) * 100;
          }
        }
        existing.modifParCode = user.code;
        existing.deviceIdMobile = deviceId ?? existing.deviceIdMobile;

        final response = await serviceProduit.updateProduit(existing);
        if (!response.success) throw StateError(response.message);
        return existing.id;
      }
      // remote_id fourni mais introuvable côté desktop -> repli création.
    }

    final nom = (item['nom'] as String?)?.trim();
    if (nom == null || nom.isEmpty) {
      throw StateError('nom manquant');
    }

    final categorieId = (item['category_id'] as int?) ?? await _defaultCategorieId(db);
    final sousCategorieId = (item['sous_category_id'] as int?) ?? await _defaultSousCategorieId(db);

    final barcodes = <String>[
      if (item['barcode'] is String && (item['barcode'] as String).isNotEmpty) item['barcode'] as String,
      ...((item['barcodes'] as List?)?.map((e) => e.toString()) ?? const []),
    ];
    final primaryBarcode = barcodes.isNotEmpty ? barcodes.first : null;

    // Même calcul de marge par défaut que le formulaire rapide desktop
    // (produit_nouveau.dart) : si le mobile envoie un prix d'achat sans
    // prix de vente, on applique la marge système au lieu de laisser 0.
    final prixAchat = (item['prix_achat'] as num?)?.toDouble() ?? 0;
    double prixVente = (item['prix_vente'] as num?)?.toDouble() ?? 0;
    var margeAuto = false;
    if (prixVente <= 0 && prixAchat > 0) {
      final param = await ParamServices.getParam();
      prixVente = PrixVenteCalculator.calculAuto(
        prixAchat,
        margeType: param.typeMarge,
        margeTaux: param.typeMarge == "Montant" ? param.TauxMargeMontant : param.TauxMargePerncetage,
      );
      margeAuto = true;
    }

    // Marge réelle déduite des prix finaux (achat/vente), qu'ils viennent du
    // mobile ou du calcul auto ci-dessus — au lieu de laisser marge_taux à 0
    // comme avant, ce qui laissait la fiche produit incomplète.
    final margeTaux = prixAchat > 0 && prixVente > 0 ? prixVente - prixAchat : 0.0;
    final margeTauxPrct = prixAchat > 0 ? (margeTaux / prixAchat) * 100 : 0.0;

    // Même résolution que push/stock-movement (nom fournisseur envoyé par le
    // mobile -> code local), avec repli sur le fournisseur système "Général"
    // si absent/inconnu — auparavant fournisseurCode n'était jamais renseigné
    // ici, ce qui laissait le champ vide en base.
    final fournisseurCode = await _resolveFournisseurCode(item['fournisseur'] as String?);

    final newId = await ProduitServices.getNextProduitId(db);
    final produitCode = CodeGenerator.generateCode(prefix: CodePrefix.produit, id: newId, digitCount: 6);
    final photoFileName = await _decodeAndSaveProductPhoto(item['photo'] as String?, produitCode);

    final produit = Produit(
      id: newId,
      nom: nom,
      code: produitCode,
      marque: (item['marque'] as String?)?.trim() ?? '',
      description: item['description'] as String?,
      codeBarre: primaryBarcode,
      fournisseurCode: fournisseurCode,
      categorieId: categorieId,
      sousCategorieId: sousCategorieId,
      multicodebar: barcodes.length > 1,
      prixVente: prixVente,
      prixAchat: prixAchat,
      margeBool: margeAuto,
      margeTaux: margeTaux,
      margeTauxPrct: margeTauxPrct,
      tva: AppConst.tvaParDefaut,
      uniteMesure: ListsConst.uniteMesureList.first,
      service: false,
      etat: true,
      dateCree: DateTime.now(),
      creeParcode: user.code,
      couleur: item['couleur'] as String?,
      taille: item['taille'] as String?,
      photo: photoFileName,
      deviceIdMobile: deviceId,
    );

    final response = await serviceProduit.addProduit(produit);
    if (!response.success) throw StateError(response.message);

    for (final code in barcodes.skip(1)) {
      final detailId = await ProduitServices.getNextId(db);
      await serviceProduit.addProduitCodeDetail(ProduitCodeDetail(
        id: detailId,
        produitCode: produit.code,
        CodeBar: code,
        dateCree: DateTime.now(),
        creeParCode: user.code,
      ));
    }

    // Même auto-push que la création locale (produit_nouveau.dart) : un
    // produit créé depuis le mobile sans code-barres n'a rien à faire dans
    // le catalogue partagé (recherche inter-boutiques par code-barres).
    if (barcodes.isNotEmpty) {
      unawaited(CatalogSyncService().pushProduitToCatalog(
        produit,
        barcodesSupplementaires: barcodes.skip(1).toList(),
      ));
    }

    return newId;
  }

  /// Produits créés/modifiés depuis le mobile. `device_id` optionnel, au
  /// niveau racine de la requête (même convention que push/stock-movement).
  Future<void> _handleSyncPushProduct(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    request.response.headers.contentType = ContentType.json;
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];
      final deviceId = data['device_id'] as String?;

      final db = await DbCreator.openDb();
      final mapping = <Map<String, dynamic>>[];

      for (final rawItem in items) {
        final item = rawItem as Map<String, dynamic>;
        try {
          final remoteId = await _pushProduitItem(db, item, user, deviceId);
          mapping.add({'local_id': item['local_id'], 'remote_id': remoteId});
        } catch (e) {
          debugPrint('push/product item ${item['local_id']} ignoré: $e');
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({'success': true, 'mapping': mapping}));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'success': false, 'error': 'Requête invalide: $e'}));
    }
    await request.response.close();
  }

  /// Crée un retour client ou fournisseur envoyé par le mobile.
  ///
  /// `reference_sale_id`/`reference_bon_id` sont les `remote_id` numériques
  /// reçus lors d'un push précédent (sale -> panniers.id, stock-movement ->
  /// smart_scan.id) — `retour_correspond_de` stocke le `code` métier
  /// correspondant, pas l'id brut, donc on résout l'un vers l'autre ici.
  /// `client_code`/`fournisseur_code` ne sont pas dans le payload mobile :
  /// ils sont déduits de la vente/du bon référencé quand disponible. Sans
  /// référence résolue, le retour reste quand même enregistré (juste non
  /// rattaché à un client/fournisseur précis).
  Future<int> _pushReturnItem(Database db, Map<String, dynamic> item, Utilisateur user, String? deviceId) async {
    final produitCode = await _resolveProduitCodeForSync(
      db,
      remoteProductId: item['remote_product_id'] as int?,
      barcode: item['barcode'] as String?,
    );
    if (produitCode == null) {
      throw StateError('Produit introuvable (barcode=${item['barcode']}, remote_product_id=${item['remote_product_id']})');
    }

    final serviceProduit = ProduitServices(db);
    final produit = await serviceProduit.getProduitByCode(produitCode);
    if (produit == null) {
      throw StateError('Produit $produitCode introuvable');
    }

    final typeRaw = (item['type'] as String?)?.toLowerCase();
    final type = typeRaw == 'fournisseur' ? 'Fournisseur' : 'Client';

    final quantite = (item['quantite'] as num).toDouble();
    // Second stock parallèle "Nombre" — extension du contrat, absente si le
    // mobile ne l'envoie pas.
    final nombre = (item['nombre'] as num?)?.toDouble();
    final createdAtRaw = item['created_at'] as String?;
    final date = (createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null) ?? DateTime.now();

    String? clientCode;
    String? fournisseurCode;
    String? retourCorrespondDe;

    if (type == 'Client') {
      final referenceSaleId = item['reference_sale_id'] as int?;
      if (referenceSaleId != null) {
        final pannier = await PannierServices(db).getPannierById(referenceSaleId);
        if (pannier != null) {
          retourCorrespondDe = pannier.code;
          clientCode = pannier.client_code;
        }
      }
    } else {
      final referenceBonId = item['reference_bon_id'] as int?;
      if (referenceBonId != null) {
        final smartScan = await SmartScanServices(db).getSmartScanById(referenceBonId);
        if (smartScan != null) {
          retourCorrespondDe = smartScan.code;
          fournisseurCode = smartScan.fournisseurCode;
        }
      }
    }

    final retourId = await RetourServices.getNextRetourId(db);
    final retour = Retour(
      id: retourId,
      code: CodeGenerator.generateCode(prefix: CodePrefix.retour, id: retourId, digitCount: 6),
      codeProduit: produit.code,
      quantite: quantite,
      nombre: nombre,
      date: date,
      prixAchat: produit.prixAchat,
      prixVente: produit.prixVente,
      type: type,
      client_code: clientCode,
      fournisseur_code: fournisseurCode,
      retourCorrespondDe: retourCorrespondDe,
      etat: true,
      observation: item['motif'] as String?,
      dateCree: DateTime.now(),
      creeParCode: user.code,
      deviceIdMobile: deviceId,
    );

    final response = await RetourServices(db).addRetour(retour);
    if (!response.success) throw StateError(response.message);

    // Stock : + pour retour client, - pour retour fournisseur.
    if (!produit.service) {
      if (nombre != null) {
        produit.nombre += (type == 'Client' ? nombre : -nombre);
      }
    }
    produit.modifParCode = user.code;
    await serviceProduit.updateProduit(produit);

    final serviceMagasinDetail = ProduitMagasinDetailServices(db);
    final magasinCode = await _resolveMagasinCodeForUser(db, user);
    final magasinDetail = await serviceMagasinDetail.getSingleByProduitAndMagasin(produit.code, magasinCode);
    if (type == 'Client') {
      if (magasinDetail != null) {
        if (nombre != null) {
          await serviceMagasinDetail.updateNombre(magasinDetail.id, magasinDetail.nombre + nombre);
        }
      } else {
        final detailId = await ProduitMagasinDetailServices.getNextId(db);
        await serviceMagasinDetail.addProduitMagasinDetail(ProduitMagasinDetail(
          id: detailId,
          magasinCode: magasinCode,
          produitCode: produit.code,
          dateCree: DateTime.now(),
          creeParCode: user.code,
          nombre: nombre ?? 0,
        ));
      }
    } else if (magasinDetail != null) {
      if (nombre != null) {
        await serviceMagasinDetail.decrementNombre(magasinDetail.id, nombre);
      }
    }

    final mouvementId = await MouvementsServices.getNextMouvementId(db);
    await MouvementsServices(db).addMouvement(Mouvement(
      id: mouvementId,
      code: CodeGenerator.generateCode(prefix: CodePrefix.mouvement, id: mouvementId, digitCount: 8),
      date: date,
      codeProduit: produit.code,
      quantite: quantite,
      nombre: nombre,
      prixAchat: produit.prixAchat,
      prixVente: produit.prixVente,
      fournisseurCode: fournisseurCode,
      clientCode: clientCode,
      type: ListsConst.typeMouvement[2], // "Retour"
      magasinCode: magasinCode, // même valeur que produit_magasin_detail ci-dessus
      etat: true,
      codeOperation: retour.code,
      dateCree: DateTime.now(),
      creeParCode: user.code,
    ));

    return retourId;
  }

  /// Retours client/fournisseur envoyés par le mobile. `device_id` optionnel,
  /// au niveau racine de la requête (même convention que les autres push).
  Future<void> _handleSyncPushReturn(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    request.response.headers.contentType = ContentType.json;
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];
      final deviceId = data['device_id'] as String?;

      final db = await DbCreator.openDb();
      final mapping = <Map<String, dynamic>>[];

      for (final rawItem in items) {
        final item = rawItem as Map<String, dynamic>;
        try {
          final remoteId = await _pushReturnItem(db, item, user, deviceId);
          mapping.add({'local_id': item['local_id'], 'remote_id': remoteId});
        } catch (e) {
          debugPrint('push/return item ${item['local_id']} ignoré: $e');
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({'success': true, 'mapping': mapping}));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'success': false, 'error': 'Requête invalide: $e'}));
    }
    await request.response.close();
  }

  /// Résout le client d'une vente mobile par téléphone (créé s'il n'existe
  /// pas), sinon repli sur le client "Comptoire" (client système générique,
  /// seedé dans DBCreate._insertDefaultData). Le nom de repli inclut le
  /// téléphone pour éviter une collision UNIQUE(nom) entre deux clients
  /// mobile anonymes différents.
  Future<Client> _resolveOuCreerClient(Database db, Utilisateur user, {String? telephone, String? nom}) async {
    if (telephone != null && telephone.isNotEmpty) {
      final maps = await db.query('clients', where: 'telephone = ?', whereArgs: [telephone], limit: 1);
      if (maps.isNotEmpty) return Client.fromMap(maps.first);

      final newId = await ClientServices.getNextClientId(db);
      final client = Client(
        id: newId,
        nom: (nom != null && nom.isNotEmpty) ? nom : 'Client $telephone',
        etat: true,
        type: 'Consommateur',
        code: CodeGenerator.generateCode(prefix: CodePrefix.client, id: newId, digitCount: 6),
        wilaya: '',
        dateCree: DateTime.now(),
        telephone: telephone,
        creeParCode: user.code,
      );
      final response = await ClientServices(db).addClient(client);
      if (response.success) return client;
      // Nom déjà pris -> repli sur le client comptoir plutôt que d'échouer toute la vente.
    }

    final defaultMaps = await db.query('clients', where: 'nom = ?', whereArgs: ['Comptoire'], limit: 1);
    if (defaultMaps.isNotEmpty) return Client.fromMap(defaultMaps.first);
    throw StateError('Client comptoir introuvable');
  }

  /// Crée une vente (panier + lignes) envoyée par le mobile.
  ///
  /// Idempotent sur `uuid` : un retry réseau du mobile après timeout ne crée
  /// pas de doublon, l'`id` du panier existant est simplement renvoyé.
  /// `caisse_code` est verrouillé sur la caisse attachée à l'utilisateur
  /// connecté (même règle que pour tout rôle non-Admin côté desktop, voir
  /// `utilisateur.caisse_code`), repli sur la caisse système sinon.
  /// Contrairement à push/stock-movement et push/return, la vente contient
  /// bien `total` + `mode_paiement` : un versement "Paiement" intégral est
  /// donc créé (une vente encaissée implique un paiement immédiat, ce n'est
  /// pas une donnée fabriquée comme le serait un versement fournisseur sans
  /// confirmation de paiement).
  Future<int> _pushSaleItem(Database db, Map<String, dynamic> item, Utilisateur user, String? deviceId) async {
    final uuid = item['uuid'] as String?;
    if (uuid != null && uuid.isNotEmpty) {
      final existing = await db.query('panniers', where: 'uuid = ?', whereArgs: [uuid], limit: 1);
      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }
    }

    final lignesRaw = (item['items'] as List?) ?? const [];
    if (lignesRaw.isEmpty) {
      throw StateError('Vente sans article');
    }

    final serviceProduit = ProduitServices(db);
    final serviceMagasinDetail = ProduitMagasinDetailServices(db);
    final servicePP = PPServices(db);

    final lignesResolues = <({Produit produit, double quantite, double prixUnitaire})>[];
    for (final rawLigne in lignesRaw) {
      final ligne = rawLigne as Map<String, dynamic>;
      final produitCode = await _resolveProduitCodeForSync(
        db,
        remoteProductId: ligne['remote_product_id'] as int?,
        barcode: ligne['barcode'] as String?,
      );
      if (produitCode == null) {
        throw StateError('Produit introuvable dans la vente (barcode=${ligne['barcode']})');
      }
      final produit = await serviceProduit.getProduitByCode(produitCode);
      if (produit == null) {
        throw StateError('Produit $produitCode introuvable');
      }
      final quantite = (ligne['quantite'] as num).toDouble();
      final prixUnitaire = (ligne['prix_unitaire'] as num?)?.toDouble() ?? produit.prixVente;
      lignesResolues.add((produit: produit, quantite: quantite, prixUnitaire: prixUnitaire));
    }

    final client = await _resolveOuCreerClient(
      db,
      user,
      telephone: (item['client_telephone'] as String?)?.trim(),
      nom: (item['client_nom'] as String?)?.trim(),
    );

    final caisseCode = user.caisseCode ?? 'CIS0000';
    final caisseMaps = await db.query('caisseGestion', where: 'code = ?', whereArgs: [caisseCode], limit: 1);
    final caisseNom = caisseMaps.isNotEmpty ? caisseMaps.first['nom_caisse'] as String : caisseCode;

    final createdAtRaw = item['created_at'] as String?;
    final date = (createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null) ?? DateTime.now();
    final modePaiementRaw = (item['mode_paiement'] as String?)?.trim();
    final modePaiement = (modePaiementRaw == null || modePaiementRaw.isEmpty) ? 'Espèces' : modePaiementRaw;
    final total = (item['total'] as num?)?.toDouble() ??
        lignesResolues.fold<double>(0.0, (s, l) => s + l.quantite * l.prixUnitaire);
    final montantAchat = lignesResolues.fold<double>(0.0, (s, l) => s + l.quantite * l.produit.prixAchat);

    final pannierId = await PannierServices.getNextPannierId(db);
    final pannier = Pannier(
      id: pannierId,
      code: CodeGenerator.generateCode(prefix: CodePrefix.pannier, id: pannierId, digitCount: 7),
      date: date,
      montant: total,
      montantAchat: montantAchat,
      marge: total - montantAchat,
      client_code: client.code,
      modePaiement: modePaiement,
      caisse_code: caisseCode,
      caissier_code: user.code,
      caisse: caisseNom,
      etat: true,
      typepannier: ListsConst.typePannier[2], // "Ticket"
      nombreArticle: lignesResolues.length,
      quantiteProduit: lignesResolues.fold(0.0, (s, l) => s + l.quantite).round(),
      dateCree: DateTime.now(),
      uuid: uuid,
      deviceIdMobile: deviceId,
    );

    final response = await PannierServices(db).addPannier(pannier);
    if (!response.success) throw StateError(response.message);

    final magasinCode = await _resolveMagasinCodeForUser(db, user);
    for (final l in lignesResolues) {
      final ppId = await PPServices.getNextPPId(db);
      await servicePP.addPP(PannierProduit(
        id: ppId,
        codePannier: pannier.code,
        codeProduit: l.produit.code,
        quantite: l.quantite,
        prix: l.prixUnitaire,
        total: l.prixUnitaire * l.quantite,
        prixAchat: l.produit.prixAchat,
        totalAchat: l.produit.prixAchat * l.quantite,
        etat: true,
        creeParCode: user.code,
        creeLe: DateTime.now(),
      ));

      l.produit.modifParCode = user.code;
      await serviceProduit.updateProduit(l.produit);

      final mouvementId = await MouvementsServices.getNextMouvementId(db);
      await MouvementsServices(db).addMouvement(Mouvement(
        id: mouvementId,
        code: CodeGenerator.generateCode(prefix: CodePrefix.mouvement, id: mouvementId, digitCount: 8),
        date: date,
        codeProduit: l.produit.code,
        quantite: l.quantite,
        prixAchat: l.produit.prixAchat,
        prixVente: l.prixUnitaire,
        clientCode: client.code,
        type: ListsConst.typeMouvement[0], // "Vente"
        magasinCode: magasinCode, // même valeur que produit_magasin_detail ci-dessus
        etat: true,
        codeOperation: pannier.code,
        dateCree: DateTime.now(),
        creeParCode: user.code,
      ));
    }

    client.dernierAchat = DateTime.now();
    client.modifParCode = user.code;
    await ClientServices(db).updateClient(client);

    if (total > 0) {
      final nextVerssementId = await VerssementServices.getNextVerssementId(db);
      await VerssementServices(db).addverssement(Verssement(
        id: nextVerssementId,
        code: CodeGenerator.generateCode(prefix: CodePrefix.verssement, id: nextVerssementId, digitCount: 6),
        date: date,
        typebeneficiare: "Client",
        beneficiareCode: client.code,
        montant: total,
        etat: true,
        mode_paiement: modePaiement,
        sense: 'Entrée',
        type: "Paiement",
        dateCree: DateTime.now(),
        creeParCode: user.code,
        caisse: caisseNom,
        codeOperation: pannier.code,
      ));
    }

    return pannierId;
  }

  /// Ventes envoyées par le mobile. `device_id` optionnel, au niveau racine
  /// de la requête (même convention que les autres push).
  Future<void> _handleSyncPushSale(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    request.response.headers.contentType = ContentType.json;
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];
      final deviceId = data['device_id'] as String?;

      final db = await DbCreator.openDb();
      final mapping = <Map<String, dynamic>>[];

      for (final rawItem in items) {
        final item = rawItem as Map<String, dynamic>;
        try {
          final remoteId = await _pushSaleItem(db, item, user, deviceId);
          mapping.add({'local_id': item['local_id'], 'remote_id': remoteId});
        } catch (e) {
          debugPrint('push/sale item ${item['local_id']} ignoré: $e');
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({'success': true, 'mapping': mapping}));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'success': false, 'error': 'Requête invalide: $e'}));
    }
    await request.response.close();
  }

  Future<void> _handleUpload(HttpRequest request) async {
    if (!await _requireDesktopToken(request)) return;

    final contentType = request.headers.contentType;
    if (contentType == null ||
        contentType.mimeType != 'multipart/form-data' ||
        !contentType.parameters.containsKey('boundary')) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'multipart/form-data avec boundary requis'}));
      await request.response.close();
      return;
    }

    final boundary = contentType.parameters['boundary']!;

    String? fournisseur, numBon, commentaire, deviceId, originalFileName, dateReceptionRaw;
    List<int>? photoBytes;

    try {
      final transformer = MimeMultipartTransformer(boundary);
      await for (final part in transformer.bind(request)) {
        final disposition = part.headers['content-disposition'];
        if (disposition == null) continue;

        final headerValue = HeaderValue.parse(disposition);
        final fieldName = headerValue.parameters['name'];
        final filename = headerValue.parameters['filename'];

        if (filename != null && filename.isNotEmpty) {
          final builder = BytesBuilder(copy: false);
          var total = 0;
          await for (final chunk in part) {
            total += chunk.length;
            if (total > maxPhotoBytes) {
              throw const FormatException('Photo trop volumineuse (> 20 Mo)');
            }
            builder.add(chunk);
          }
          photoBytes = builder.takeBytes();
          originalFileName = filename;
        } else {
          final value = await utf8.decoder.bind(part).join();
          switch (fieldName) {
            case 'fournisseur':
              fournisseur = value;
              break;
            case 'num_bon':
              numBon = value;
              break;
            case 'commentaire':
              commentaire = value;
              break;
            case 'device_id':
              deviceId = value;
              break;
            case 'date_reception':
              dateReceptionRaw = value;
              break;
          }
        }
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Erreur de lecture: $e'}));
      await request.response.close();
      return;
    }

    if (photoBytes == null || photoBytes.isEmpty) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Photo manquante'}));
      await request.response.close();
      return;
    }

    try {
      final relativePath = await BonReceptionPhotoService.savePhotoBytes(
        photoBytes,
        originalFileName ?? 'photo.jpg',
      );

      final fournisseurCode = await _resolveFournisseurCode(fournisseur);
      final dateReception = (dateReceptionRaw != null ? DateTime.tryParse(dateReceptionRaw) : null) ?? DateTime.now();

      final db = await DbCreator.openDb();
      final service = BonReceptionServices(db);
      final response = await service.addBonReception(BonReception(
        id: 0,
        fournisseur: fournisseur,
        fournisseurCode: fournisseurCode,
        numBon: numBon,
        commentaire: commentaire,
        cheminPhoto: relativePath,
        dateReception: dateReception,
        deviceId: deviceId,
      ));

      request.response.headers.contentType = ContentType.json;
      if (response.success && response.data != null) {
        final bon = await service.getBonReceptionById(response.data!);
        if (bon != null) onBonReceived?.call(bon);
        request.response
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'statut': 'ok', 'id': response.data}));
      } else {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({'error': response.message}));
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Erreur serveur: $e'}));
    }

    await request.response.close();
  }

  /// Attache une photo (bon de livraison/facture) à un SmartScan déjà créé
  /// via POST /api/sync/push/stock-movement — flux en 2 temps côté mobile
  /// (créer le mouvement, puis envoyer la photo avec le `remote_id` reçu),
  /// pour ne pas dupliquer la logique de [_pushStockMovementItem].
  Future<void> _handleSmartScanUpload(HttpRequest request) async {
    final user = await _requireAuthenticatedUser(request);
    if (user == null) return;

    final contentType = request.headers.contentType;
    if (contentType == null ||
        contentType.mimeType != 'multipart/form-data' ||
        !contentType.parameters.containsKey('boundary')) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': false, 'error': 'multipart/form-data avec boundary requis'}));
      await request.response.close();
      return;
    }

    final boundary = contentType.parameters['boundary']!;

    String? smartScanRemoteIdRaw, originalFileName;
    List<int>? photoBytes;

    try {
      final transformer = MimeMultipartTransformer(boundary);
      await for (final part in transformer.bind(request)) {
        final disposition = part.headers['content-disposition'];
        if (disposition == null) continue;

        final headerValue = HeaderValue.parse(disposition);
        final fieldName = headerValue.parameters['name'];
        final filename = headerValue.parameters['filename'];

        if (filename != null && filename.isNotEmpty) {
          final builder = BytesBuilder(copy: false);
          var total = 0;
          await for (final chunk in part) {
            total += chunk.length;
            if (total > maxPhotoBytes) {
              throw const FormatException('Photo trop volumineuse (> 20 Mo)');
            }
            builder.add(chunk);
          }
          photoBytes = builder.takeBytes();
          originalFileName = filename;
        } else if (fieldName == 'smartscan_remote_id') {
          smartScanRemoteIdRaw = await utf8.decoder.bind(part).join();
        }
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': false, 'error': 'Erreur de lecture: $e'}));
      await request.response.close();
      return;
    }

    final smartScanId = int.tryParse(smartScanRemoteIdRaw ?? '');
    request.response.headers.contentType = ContentType.json;

    if (photoBytes == null || photoBytes.isEmpty) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'success': false, 'error': 'Photo manquante'}));
      await request.response.close();
      return;
    }
    if (smartScanId == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'success': false, 'error': 'smartscan_remote_id manquant ou invalide'}));
      await request.response.close();
      return;
    }

    final db = await DbCreator.openDb();
    final serviceSS = SmartScanServices(db);
    final smartScan = await serviceSS.getSmartScanById(smartScanId);
    if (smartScan == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'success': false, 'error': 'SmartScan introuvable'}));
      await request.response.close();
      return;
    }

    try {
      final relativePath = await BonReceptionPhotoService.savePhotoBytes(
        photoBytes,
        originalFileName ?? 'photo.jpg',
        folder: 'smart_scans',
      );

      smartScan.cheminPhoto = relativePath;
      smartScan.modifParCode = user.code;
      final response = await serviceSS.updateSmartScan(smartScan);

      if (response.success) {
        request.response
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'chemin_photo': relativePath}));
      } else {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({'success': false, 'error': response.message}));
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'success': false, 'error': 'Erreur serveur: $e'}));
    }

    await request.response.close();
  }

  /// Fait correspondre le nom de fournisseur envoyé par le mobile (texte
  /// libre, éventuellement absent) à un fournisseur existant par nom
  /// (insensible à la casse/espaces). À défaut de correspondance — ou si le
  /// mobile n'a rien envoyé —, retombe sur le fournisseur système "Général".
  Future<String> _resolveFournisseurCode(String? fournisseurName) async {
    if (fournisseurName != null && fournisseurName.trim().isNotEmpty) {
      final saisie = fournisseurName.trim().toLowerCase();
      final fournisseurs = await FournisseurServices.getAllFournisseurs();
      for (final f in fournisseurs) {
        if (f.nom.trim().toLowerCase() == saisie) return f.code;
      }
    }
    return AppConst.fournisseurGeneralCode;
  }

  /// Magasin de la caisse attachée à l'utilisateur mobile authentifié (même
  /// mécanisme que la caisse elle-même juste au-dessus) — remplace les
  /// anciens 'MAG0000' figés, qui ignoraient à quel magasin l'utilisateur
  /// mobile est réellement rattaché.
  Future<String> _resolveMagasinCodeForUser(Database db, Utilisateur user) async {
    final caisseCode = user.caisseCode ?? 'CIS0000';
    final caisseMaps = await db.query('caisseGestion', where: 'code = ?', whereArgs: [caisseCode], limit: 1);
    if (caisseMaps.isEmpty) return 'MAG0000';
    return caisseMaps.first['magasin_code'] as String? ?? 'MAG0000';
  }
}
