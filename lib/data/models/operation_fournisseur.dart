enum TypeOperationFournisseur {
  achat,
  retour,
  versement_ENT,
  versement_SRT,
}

class OperationFournisseur {
  final TypeOperationFournisseur type;
  final DateTime date;
  final String reference;
  final double debit;   // Ce que TU dois au fournisseur
  final double credit;  // Ce que TU as payé

  final String description;

  OperationFournisseur({
    required this.type,
    required this.date,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.description,
  });
}
