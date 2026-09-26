class FrequenceBackup {
  static const String demarrage = 'demarrage';
  static const String quotidien = 'quotidien';
  static const String hebdomadaire = 'hebdomadaire';

  static const List<String> values = [demarrage, quotidien, hebdomadaire];
}

class BackupParam {
  int id;
  String? dossierBackup;
  // ✅ Dossier où sont enregistrés tous les fichiers générés par l'app
  // (Excel, PDF de facture/BL...) — null = dossier Documents par défaut.
  String? dossierDocuments;
  bool autoBackupActif;
  String frequence;
  DateTime? derniereSauvegarde;

  String? modifParCode;

  BackupParam({
    required this.id,
    required this.autoBackupActif,
    required this.frequence,
    this.dossierBackup,
    this.dossierDocuments,
    this.derniereSauvegarde,
    this.modifParCode,
  });

  factory BackupParam.fromMap(Map<String, dynamic> map) {
    return BackupParam(
      id: map['id'] as int,
      dossierBackup: map['dossier_backup'] as String?,
      dossierDocuments: map['dossier_documents'] as String?,
      autoBackupActif: map['auto_backup_actif'] == 1,
      frequence: map['frequence'] as String? ?? FrequenceBackup.demarrage,
      derniereSauvegarde: map['derniere_sauvegarde'] != null
          ? DateTime.parse(map['derniere_sauvegarde'] as String)
          : null,
      modifParCode: map['modif_par_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'dossier_backup': dossierBackup,
    'dossier_documents': dossierDocuments,
    'auto_backup_actif': autoBackupActif ? 1 : 0,
    'frequence': frequence,
    'derniere_sauvegarde': derniereSauvegarde?.toIso8601String(),
    'modif_par_code': modifParCode,
  };
}
