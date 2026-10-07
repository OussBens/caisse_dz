/// Palier de licence de l'installation — détermine quelles capacités sont
/// débloquées (nombre de caisses, gestion multi-magasin...), indépendamment
/// du rôle de l'utilisateur connecté (RoleDetail) qui reste orthogonal :
/// le palier dit ce que l'installation a acheté, le rôle dit ce qu'un
/// utilisateur donné peut faire à l'intérieur de ça.
///
/// Deux paliers seulement : Basic (caisse unique, magasin unique) et Avancé
/// (multi-caisse et multi-magasin) — l'ancien 3ᵉ palier "Premium" a été
/// fusionné dans Avancé (mêmes capacités). Toute clé Premium déjà émise
/// reste valide : voir AuthState._generateKey, qui garde le format historique
/// (sans suffixe) pour `avance`.
enum LicenseTier {
  basic,
  avance;

  static LicenseTier fromName(String? name) {
    return LicenseTier.values.firstWhere(
      (t) => t.name == name,
      orElse: () => LicenseTier.avance,
    );
  }
}
