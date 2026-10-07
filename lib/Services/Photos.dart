// services/PhotoService.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PhotoService {
  static const String photosFolderName = 'product_photos';

  static Future<Directory> getPhotosDirectory() async {
    Directory appDir;

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA']!;
      appDir = Directory(path.join(appData, 'caisse_dz', photosFolderName));
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME']!;
      appDir = Directory(path.join(home, '.local/share/caisse_dz', photosFolderName));
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      appDir = Directory(path.join(home, 'Library/Application Support/caisse_dz', photosFolderName));
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      appDir = Directory(path.join(docsDir.path, photosFolderName));
    }

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return appDir;
  }

  // Chemin absolu pour une photo temporaire (sélectionnée mais pas encore
  // rattachée à un produit) — voir ButtonAddPhoto et OpenFoodFactsService.
  // Le dossier temp système est toujours accessible en écriture,
  // contrairement au répertoire de travail du process une fois l'app
  // installée (ex. Program Files), qui a causé une PathAccessException en
  // production.
  static String buildTempPhotoPath(String extension) {
    final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}$extension';
    return path.join(Directory.systemTemp.path, fileName);
  }

  // Une photo "temp_..." n'est pas encore rattachée à un produit (voir
  // [buildTempPhotoPath]). On ne teste que le nom de fichier car le chemin
  // complet inclut désormais le dossier temp système, pas seulement le nom.
  static bool isTempPhoto(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return false;
    return path.basename(photoPath).startsWith('temp_');
  }

  // Sauvegarder une seule photo

  static Future<String?> savePhoto(File sourceFile, String productCode) async {
  try {
  final photosDir = await getPhotosDirectory();
  final fileName = '${productCode}_main.jpg';  // Nom fixe pour la photo principale
  final destinationFile = File(path.join(photosDir.path, fileName));

  // Supprimer l'ancienne photo si elle existe
  if (await destinationFile.exists()) {
  await destinationFile.delete();
  debugPrint('🗑️ Ancienne photo supprimée');
  }

  // Copier la nouvelle photo
  await sourceFile.copy(destinationFile.path);
  debugPrint('📸 Photo sauvegardée: $fileName');

  return fileName;
  } catch (e) {
  debugPrint('❌ Erreur sauvegarde photo: $e');
  return null;
  }
  }


  // Obtenir le fichier de la photo
  static Future<File?> getPhotoFile(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;

    try {
      final photosDir = await getPhotosDirectory();
      final file = File(path.join(photosDir.path, fileName));

      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Erreur récupération photo: $e');
    }

    return null;
  }

  // Supprimer la photo
  static Future<void> deletePhoto(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;

    try {
      final file = await getPhotoFile(fileName);
      if (file != null && await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Photo supprimée: $fileName');
      }
    } catch (e) {
      debugPrint('Erreur suppression photo: $e');
    }
  }
}