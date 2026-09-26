import 'dart:io';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

import '../DBCreate.dart';
import '../data/models/backupParam.dart';
import '../core/utilis/api_response.dart';
import 'BackupParam.dart';

class BackupService {
  static const String _dbEntryName = 'caisse_real.db';
  static const String _midEntryName = '.mid';

  static String _timestamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  /// Empaquette la base de données chiffrée ET le fichier `.mid` (identifiant
  /// machine dont dépend la clé de déchiffrement, voir
  /// `DbCreator._getMachineId`) dans une seule archive zip vers [folder].
  /// Les deux fichiers doivent voyager ensemble : une sauvegarde qui ne
  /// contiendrait que le `.db` peut devenir indéchiffrable si le `.mid`
  /// d'origine est perdu (réinstallation, nettoyage disque, etc.).
  static Future<ApiResponse<String>> backupNow(String folder, {String? modifiedByCode}) async {
    try {
      final dbFile = File(DbCreator.getDbFilePath());
      if (!await dbFile.exists()) {
        return ApiResponse(success: false, message: "Base de données introuvable");
      }

      final archive = Archive();
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile(_dbEntryName, dbBytes.length, dbBytes));

      final midFile = File(DbCreator.getMidFilePath());
      if (await midFile.exists()) {
        final midBytes = await midFile.readAsBytes();
        archive.addFile(ArchiveFile(_midEntryName, midBytes.length, midBytes));
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        return ApiResponse(success: false, message: "Échec de la compression de la sauvegarde");
      }
      final destPath = path.join(folder, 'caisse_backup_${_timestamp()}.zip');
      await File(destPath).writeAsBytes(zipBytes);

      final param = await BackupParamServices.getBackupParam();
      param.dossierBackup = folder;
      param.derniereSauvegarde = DateTime.now();
      final db = await DbCreator.openDb();
      await BackupParamServices(db).updateBackupParam(param, modifiedByCode);

      return ApiResponse(success: true, message: "Sauvegarde créée", data: destPath);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur sauvegarde: $e");
    }
  }

  /// Restaure une sauvegarde. Accepte le nouveau format zip (`.db` + `.mid`,
  /// voir [backupNow]) et, pour compatibilité avec d'anciennes sauvegardes,
  /// un fichier `.db` seul (auquel cas le `.mid` actuel de la machine n'est
  /// pas touché — la restauration ne peut réussir que si ce `.db` a été
  /// chiffré avec la même identité machine que celle en place ici).
  /// Ferme la connexion active ; l'appelant doit redémarrer l'application
  /// ensuite pour que la nouvelle base (et le nouveau `.mid` le cas échéant)
  /// soient repris en compte.
  static Future<ApiResponse<void>> restore(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return ApiResponse(success: false, message: "Fichier de sauvegarde introuvable");
      }

      await DbCreator.closeDb();

      if (backupFilePath.toLowerCase().endsWith('.zip')) {
        final archive = ZipDecoder().decodeBytes(await backupFile.readAsBytes());

        final dbEntry = archive.files.where((f) => f.isFile && f.name == _dbEntryName).firstOrNull;
        if (dbEntry == null) {
          return ApiResponse(success: false, message: "Archive invalide : $_dbEntryName introuvable");
        }
        await File(DbCreator.getDbFilePath()).writeAsBytes(dbEntry.content as List<int>);

        final midEntry = archive.files.where((f) => f.isFile && f.name == _midEntryName).firstOrNull;
        if (midEntry != null) {
          await File(DbCreator.getMidFilePath()).writeAsBytes(midEntry.content as List<int>);
        }

        return ApiResponse(
          success: true,
          message: midEntry != null
              ? "Base restaurée. Redémarrez l'application."
              : "Base restaurée (sauvegarde sans .mid — à vérifier après redémarrage). Redémarrez l'application.",
        );
      }

      // Compatibilité ascendante : ancien format, .db seul.
      await backupFile.copy(DbCreator.getDbFilePath());
      return ApiResponse(
        success: true,
        message: "Base restaurée (ancien format, sans .mid). Redémarrez l'application.",
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur restauration: $e");
    }
  }

  /// À appeler au démarrage de l'app : déclenche une sauvegarde
  /// automatique si activée et due selon la fréquence configurée.
  static Future<void> checkAndRunAutoBackup() async {
    final param = await BackupParamServices.getBackupParam();
    if (!param.autoBackupActif || param.dossierBackup == null || param.dossierBackup!.isEmpty) {
      return;
    }

    final due = switch (param.frequence) {
      FrequenceBackup.demarrage => true,
      FrequenceBackup.quotidien =>
        param.derniereSauvegarde == null ||
            DateTime.now().difference(param.derniereSauvegarde!) >= const Duration(days: 1),
      FrequenceBackup.hebdomadaire =>
        param.derniereSauvegarde == null ||
            DateTime.now().difference(param.derniereSauvegarde!) >= const Duration(days: 7),
      _ => false,
    };

    if (due) {
      await backupNow(param.dossierBackup!);
    }
  }
}
