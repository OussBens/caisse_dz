/// Palier de licence de l'installation — détermine quelles capacités sont
/// débloquées (nombre de caisses, gestion multi-magasin...), indépendamment
/// du rôle de l'utilisateur connecté (RoleDetail) qui reste orthogonal :
/// le palier dit ce que l'installation a acheté, le rôle dit ce qu'un
/// utilisateur donné peut faire à l'intérieur de ça.
enum LicenseTier {
  basic,
  avance,
  premium;

  static LicenseTier fromName(String? name) {
    return LicenseTier.values.firstWhere(
      (t) => t.name == name,
      orElse: () => LicenseTier.premium,
    );
  }
}
