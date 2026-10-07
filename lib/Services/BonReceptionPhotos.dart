// services/BonReceptionPhotos.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Stockage des photos de bons de réception (jointes depuis le disque ;
/// d'anciens bons ont été reçus depuis l'app mobile, retirée), organisées par date
/// comme demandé : bons_reception/YYYY/MM/DD/<uuid>_<nom_original>.
///
/// Le chemin stocké en base est toujours RELATIF (ex: "2026/08/09/xxx.jpg",
/// séparateurs '/'), jamais absolu — même logique que [PhotoService] qui ne
/// stocke qu'un nom de fichier et résout le chemin complet à la demande.
class BonReceptionPhotoService {
  static const String rootFolderName = 'bons_reception';
  static final Uuid _uuid = Uuid();

  /// [folder] permet de stocker sous une racine différente (ex. 'smart_scans'
  /// pour les photos jointes à un SmartScan mobile) tout en réutilisant la
  /// même logique de dossier daté/nom sûr. Défaut = [rootFolderName], donc
  /// rétrocompatible avec les appels existants (bons de réception).
  static Future<Directory> getRootDirectory({String? folder}) async {
    final folderName = folder ?? rootFolderName;
    Directory appDir;

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA']!;
      appDir = Directory(path.join(appData, 'caisse_dz', folderName));
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME']!;
      appDir = Directory(path.join(home, '.local/share/caisse_dz', folderName));
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      appDir = Directory(path.join(home, 'Library/Application Support/caisse_dz', folderName));
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      appDir = Directory(path.join(docsDir.path, folderName));
    }

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return appDir;
  }

  static String _relativeDayFolder(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  static Future<String> _reserveRelativePath(String originalFileName, DateTime date, {String? folder}) async {
    final rootDir = await getRootDirectory(folder: folder);
    final relativeDayFolder = _relativeDayFolder(date);
    final dayDir = Directory(path.joinAll([rootDir.path, ...relativeDayFolder.split('/')]));

    if (!await dayDir.exists()) {
      await dayDir.create(recursive: true);
    }

    final safeName = path.basename(originalFileName).replaceAll(RegExp(r'[^\w.\-]'), '_');
    final fileName = '${_uuid.v4()}_$safeName';

    return '$relativeDayFolder/$fileName';
  }

  /// Copie [sourceFile] (photo jointe depuis le disque) dans le dossier daté
  /// et retourne le chemin relatif à stocker en base.
  static Future<String> savePhoto(File sourceFile, {DateTime? date, String? folder}) async {
    final now = date ?? DateTime.now();
    final relativePath = await _reserveRelativePath(path.basename(sourceFile.path), now, folder: folder);
    final rootDir = await getRootDirectory(folder: folder);
    final destinationFile = File(path.joinAll([rootDir.path, ...relativePath.split('/')]));

    await sourceFile.copy(destinationFile.path);
    debugPrint('📸 Photo sauvegardée: $relativePath');

    return relativePath;
  }

  static Future<File?> getPhotoFile(String? relativePath, {String? folder}) async {
    if (relativePath == null || relativePath.isEmpty) return null;

    try {
      final rootDir = await getRootDirectory(folder: folder);
      final file = File(path.joinAll([rootDir.path, ...relativePath.split('/')]));

      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Erreur récupération photo: $e');
    }

    return null;
  }

  static Future<void> deletePhoto(String? relativePath, {String? folder}) async {
    if (relativePath == null || relativePath.isEmpty) return;

    try {
      final file = await getPhotoFile(relativePath, folder: folder);
      if (file != null && await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Photo supprimée: $relativePath');
      }
    } catch (e) {
      debugPrint('Erreur suppression photo bon de réception: $e');
    }
  }
}
