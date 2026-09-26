/// Types d'imprimante supportés par le module Paramètres.
class TypeImprimante {
  static const String bluetooth = 'bluetooth';
  static const String usb = 'usb';
  static const String reseau = 'reseau';
  static const String normale = 'normale';

  static const List<String> values = [bluetooth, usb, reseau, normale];
}

class ImprimanteParam {
  int id;
  String typeImprimante;
  String? nomImprimante;
  String? adresseIp;
  int? port;
  String? macBluetooth;
  int largeurRouleau;

  DateTime? dateModif;
  String? modifParCode;

  ImprimanteParam({
    required this.id,
    required this.typeImprimante,
    required this.largeurRouleau,
    this.nomImprimante,
    this.adresseIp,
    this.port,
    this.macBluetooth,
    this.dateModif,
    this.modifParCode,
  });

  factory ImprimanteParam.fromMap(Map<String, dynamic> map) {
    return ImprimanteParam(
      id: map['id'] as int,
      typeImprimante: map['type_imprimante'] as String? ?? TypeImprimante.bluetooth,
      largeurRouleau: map['largeur_rouleau'] as int? ?? 80,
      nomImprimante: map['nom_imprimante'] as String?,
      adresseIp: map['adresse_ip'] as String?,
      port: map['port'] as int?,
      macBluetooth: map['mac_bluetooth'] as String?,
      dateModif: map['date_modif'] != null
          ? DateTime.parse(map['date_modif'] as String)
          : null,
      modifParCode: map['modif_par_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type_imprimante': typeImprimante,
    'nom_imprimante': nomImprimante,
    'adresse_ip': adresseIp,
    'port': port,
    'mac_bluetooth': macBluetooth,
    'largeur_rouleau': largeurRouleau,
    'date_modif': dateModif?.toIso8601String(),
    'modif_par_code': modifParCode,
  };

  /// Nombre de caractères par ligne pour le ticket texte, selon la largeur
  /// du rouleau (58mm ou 80mm). Calé sur la largeur imprimable réelle du PDF
  /// (voir receipt_print_helper.dart : police Courier taille 8.5, marge
  /// 2.5mm) pour que les lignes ne soient jamais coupées ni renvoyées à la
  /// ligne suivante.
  int get ligneCaracteres => largeurRouleau <= 58 ? 29 : 41;
}
