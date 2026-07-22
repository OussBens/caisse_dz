enum TypeOperation { pannier, retour, versement_ENT, versement_SRT}

class OperationClient {
  final TypeOperation type;
  final DateTime      date;
  final String        reference;
  final double        debit;
  final double        credit;
  final String        description;
  OperationClient({
    required this.date,
    required this.type,
    required this.debit,
    required this.credit,
    required this.reference,
    required this.description,
  });
}
