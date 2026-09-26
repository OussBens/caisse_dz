import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:caisse_dz/Services/BackupParam.dart';

/// Dossier où sont enregistrés tous les fichiers générés par l'app (exports
/// Excel, factures/BL PDF...), configurable dans Paramètres > Sauvegarde.
/// Retombe sur le dossier Documents de l'app si aucun dossier n'a été choisi.
Future<Directory> getExportDirectory() async {
  final param = await BackupParamServices.getBackupParam();
  final chosen = param.dossierDocuments;

  if (chosen != null && chosen.trim().isNotEmpty) {
    final dir = Directory(chosen);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  return getApplicationDocumentsDirectory();
}
