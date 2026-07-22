// utils/code_generator.dart
import 'package:caisse_dz/data/constant.dart'; // Importez les constantes

class CodeGenerator {
  /// Génère un code formaté avec préfixe et nombre de chiffres
  ///
  /// [prefix] : Le préfixe du code (ex: CodePrefix.pannier)
  /// [id] : L'ID numérique à formater
  /// [digitCount] : Nombre de chiffres total (ex: 6 pour "PN000035")
  ///
  /// Retourne un code formaté (ex: "PN000035")
  static String generateCode({
    required String prefix,
    required int id,
    required int digitCount,
  }) {
    final formattedId = id.toString().padLeft(digitCount, '0');
    return '$prefix$formattedId';
  }

  /// Génère un code avec timestamp (ex: PN1735123456789)
  static String generateCodeWithTimestamp({
    required String prefix,
    required int id,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix$id$timestamp';
  }

  /// Génère un code avec date (ex: PN20241225-0001)
  static String generateCodeWithDate({
    required String prefix,
    required int id,
    required int digitCount,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final formattedId = id.toString().padLeft(digitCount, '0');
    return '$prefix$dateStr-$formattedId';
  }

  /// Extrait le numéro d'un code formaté
  static int? extractNumberFromCode({
    required String code,
    required String prefix,
  }) {
    if (!code.startsWith(prefix)) return null;
    final numberPart = code.substring(prefix.length);
    return int.tryParse(numberPart);
  }

  /// Vérifie si un code est valide selon le préfixe
  static bool isValidCode({
    required String code,
    required String prefix,
    required int digitCount,
  }) {
    if (!code.startsWith(prefix)) return false;
    final numberPart = code.substring(prefix.length);
    if (numberPart.length != digitCount) return false;
    return int.tryParse(numberPart) != null;
  }

  /// Génère un code pour une entité spécifique
  static String generateEntityCode({
    required String entityType, // "produit", "client", "pannier", etc.
    required int id,
    required int digitCount,
  }) {
    String prefix;
    switch (entityType) {
      case "produit":
        prefix = CodePrefix.produit;
        break;
      case "client":
        prefix = CodePrefix.client;
        break;
      case "pannier":
        prefix = CodePrefix.pannier;
        break;
      case "mouvement":
        prefix = CodePrefix.mouvement;
        break;
      case "historique":
        prefix = CodePrefix.historique;
        break;
      case "verssement":
        prefix = CodePrefix.verssement;
        break;
      case "facture":
        prefix = CodePrefix.facture;
        break;
      case "bonLivraison":
        prefix = CodePrefix.bonLivraison;
        break;
      case "categorie":
        prefix = CodePrefix.categorie;
        break;
      case "sousCategorie":
        prefix = CodePrefix.sousCategorie;
        break;
      case "fournisseur":
        prefix = CodePrefix.fournisseur;
        break;
      case "magasin":
        prefix = CodePrefix.magasin;
        break;
      case "remise":
        prefix = CodePrefix.remise;
        break;
      case "pack":
        prefix = CodePrefix.pack;
        break;
      case "utilisateur":
        prefix = CodePrefix.utilisateur;
        break;
      case "caisse":
        prefix = CodePrefix.caisse;
        break;
      default:
        prefix = "ID";
    }
    return generateCode(
      prefix: prefix,
      id: id,
      digitCount: digitCount,
    );
  }
}