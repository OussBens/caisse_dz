import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

import '../DBCreate.dart';

/// Gère le logo unique de la boutique, affiché sur les tickets/BL.
/// Rangé sous le même dossier applicatif que la base de données
/// (`DbCreator.getLocalFolder()`), contrairement à `PhotoService` qui
/// utilise un dossier différent.
class LogoService {
  static const String logoFolderName = 'logo';

  static Future<Directory> getLogoDirectory() async {
    final dir = Directory(path.join(DbCreator.getLocalFolder(), logoFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copie [sourceFile] comme logo unique de la boutique (écrase l'ancien
  /// logo, quelle que soit son extension d'origine). Retourne le nom de
  /// fichier à stocker dans `entreprise_param.logo_path`.
  static Future<String?> saveLogo(File sourceFile) async {
    try {
      final logoDir = await getLogoDirectory();
      final ext = path.extension(sourceFile.path);
      final fileName = 'logo$ext';

      for (final existing in logoDir.listSync()) {
        if (existing is File && path.basenameWithoutExtension(existing.path) == 'logo') {
          await existing.delete();
        }
      }

      final destinationFile = File(path.join(logoDir.path, fileName));
      await sourceFile.copy(destinationFile.path);
      return fileName;
    } catch (e) {
      debugPrint('Erreur sauvegarde logo: $e');
      return null;
    }
  }

  static Future<File?> getLogoFile(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;

    try {
      final logoDir = await getLogoDirectory();
      final file = File(path.join(logoDir.path, fileName));
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Erreur récupération logo: $e');
    }
    return null;
  }

  /// Charge les octets du logo, prêts à être injectés dans un PDF
  /// (`pw.MemoryImage`). Retourne `null` si aucun logo n'est configuré.
  static Future<Uint8List?> loadLogoBytes(String? fileName) async {
    final file = await getLogoFile(fileName);
    if (file == null) return null;
    return file.readAsBytes();
  }

  static Future<void> deleteLogo(String? fileName) async {
    final file = await getLogoFile(fileName);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }
}
