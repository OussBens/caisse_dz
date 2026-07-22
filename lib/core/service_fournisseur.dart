import '../data/models/retour.dart';
import '../data/models/smart_scan.dart';
import '../data/models/verssement.dart';
import '../data/models/operation_fournisseur.dart';

class SituationFournisseurService {
  static List<OperationFournisseur> build({
    required List<SmartScan> smartScans,
    required List<Retour> retours,
    required List<Verssement> versements,
    required DateTime debut,
    required DateTime fin,
  }) {
    final List<OperationFournisseur> ops = [];

    // ================= ACHATS (SmartScan) =================
    for (var s in smartScans) {
      if (!s.date.isBefore(debut) && !s.date.isAfter(fin)) {
        ops.add(
          OperationFournisseur(
            type: TypeOperationFournisseur.achat,
            date: s.date,
            reference: s.code,
            debit: s.montant,   // Tu dois au fournisseur
            credit: 0,
            description: "Achat marchandises",
          ),
        );
      }
    }

    // ================= RETOURS =================
    for (var r in retours) {
      if (!r.dateCree.isBefore(debut) && !r.dateCree.isAfter(fin)) {
        ops.add(
          OperationFournisseur(
            type: TypeOperationFournisseur.retour,
            date: r.dateCree,
            reference: r.code,
            debit: 0,
            credit: 0, // Le fournisseur te doit
            description: "Retour fournisseur",
          ),
        );
      }
    }

    // ================= VERSEMENT ENTREE =================
    ops.addAll(
      versements
          .where((v) =>
      !v.date.isBefore(debut) &&
          !v.date.isAfter(fin) &&
          v.sense == 'Entrée')
          .map((v) => OperationFournisseur(
        type: TypeOperationFournisseur.versement_ENT,
        date: v.date,
        reference: v.code,
        debit: 0,
        credit: v.montant,
        description: "Versement Entrée",
      )),
    );

// ================= VERSEMENT SORTIE =================
    ops.addAll(
      versements
          .where((v) =>
      !v.date.isBefore(debut) &&
          !v.date.isAfter(fin) &&
          v.sense == 'Sortie')
          .map((v) => OperationFournisseur(
        type: TypeOperationFournisseur.versement_SRT,
        date: v.date,
        reference: v.code,
        debit: 0,
        credit: v.montant,
        description: "Versement Sortie",
      )),
    );


    // Trier par date
    ops.sort((a, b) => a.date.compareTo(b.date));

    return ops;
  }
}
