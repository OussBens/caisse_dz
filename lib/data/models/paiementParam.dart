class PaiementParam {
  int id;
  bool especesVisible;
  bool carteVisible;
  bool chequeVisible;
  bool virementVisible;

  DateTime? dateModif;
  String? modifParCode;

  PaiementParam({
    required this.id,
    required this.especesVisible,
    required this.carteVisible,
    required this.chequeVisible,
    required this.virementVisible,
    this.dateModif,
    this.modifParCode,
  });

  factory PaiementParam.fromMap(Map<String, dynamic> map) {
    return PaiementParam(
      id: map['id'] as int,
      especesVisible: map['especes_visible'] == 1,
      carteVisible: map['carte_visible'] == 1,
      chequeVisible: map['cheque_visible'] == 1,
      virementVisible: map['virement_visible'] == 1,
      dateModif: map['date_modif'] != null
          ? DateTime.parse(map['date_modif'] as String)
          : null,
      modifParCode: map['modif_par_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'especes_visible': especesVisible ? 1 : 0,
    'carte_visible': carteVisible ? 1 : 0,
    'cheque_visible': chequeVisible ? 1 : 0,
    'virement_visible': virementVisible ? 1 : 0,
    'date_modif': dateModif?.toIso8601String(),
    'modif_par_code': modifParCode,
  };

  /// Correspondance positionnelle avec `ListsConst.modePaiementList`
  /// (Espèces, Carte, Chèque, Virement, Points).
  bool isVisible(String frenchKey) {
    switch (frenchKey) {
      case 'Espèces':
        return especesVisible;
      case 'Carte':
        return carteVisible;
      case 'Chèque':
        return chequeVisible;
      case 'Virement':
        return virementVisible;
      // "Points" n'est pas un mode togglable ici : sa visibilité dépend du
      // programme de bonus (Paramters.activeBonus), géré séparément par
      // PaiementParamServices.visibleDisplayList(inclurePoints: ...).
      case 'Points':
        return false;
      default:
        return true;
    }
  }
}
