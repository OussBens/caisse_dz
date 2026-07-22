import 'package:caisse_dz/data/models/verssement.dart';

import '../../data/models/operation_client.dart';
import '../../data/models/pannier.dart';
import '../../data/models/retour.dart';

class SituationClientService {
  static List<OperationClient> build({
    required List<Pannier> panniers,
    required List<Retour> retours,
    required List<Verssement> versements,
    required DateTime debut,
    required DateTime fin,
  }) {
    final List<OperationClient> list = [];

    list.addAll(
      panniers
          .where((p) => p.date != null && !p.date.isBefore(debut) && !p.date.isAfter(fin))
          .map((p) => OperationClient(
        type: TypeOperation.pannier,
        date: p.date,
        reference: p.code,
        debit: p.montant,
        credit: 0,
        description: 'Achat',
      )),
    );

    list.addAll(
      retours
          .where((r) => r.dateCree != null && !r.dateCree.isBefore(debut) && !r.dateCree!.isAfter(fin))
          .map((r) => OperationClient(
        type: TypeOperation.retour,
        date: r.dateCree,
        reference: r.code ,
        debit: 0,
        credit: r.quantite,
        description: 'Retour',
      )),
    );

    list.addAll(
      versements
          .where((v) =>
      v.date != null &&
          !v.date.isBefore(debut) &&
          !v.date.isAfter(fin) &&
          v.sense == 'Entrée')
          .map((v) => OperationClient(
        type: TypeOperation.versement_ENT,
        date: v.date,
        reference: v.code ,
        debit: 0,
        credit: v.montant ,
        description: 'Versement Entrée',
      )),
    );
    list.addAll(
      versements
          .where((v) =>
      v.date != null &&
          !v.date.isBefore(debut) &&
          !v.date.isAfter(fin) &&
          v.sense == 'Sortie')
          .map((v) => OperationClient(
        type: TypeOperation.versement_SRT,
        date: v.date,
        reference: v.code ,
        debit: 0,
        credit: v.montant ,
        description: 'Versement Sortie',
      )),
    );

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}
