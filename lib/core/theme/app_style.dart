import 'package:flutter/material.dart';
class Appstyle
{
  // ── Design system CaisseDZ (rebrand) ──────────────────────────────────
  // Valeurs issues du design system « CaisseDZ Design System » (Claude
  // Design) — voir docs/04_charte_graphique.md. Les NOMS historiques
  // ci-dessous sont conservés (compatibilité : ~3 000 usages dans l'app),
  // seules leurs valeurs suivent la nouvelle marque. Pour du nouveau code,
  // préférer les rôles sémantiques (primary, surface, textPrimary…).

  // Échelle violette (marque)
  static const Color purple50 = Color(0xFFF3F0FF);
  static const Color purple100 = Color(0xFFE8E2FF);
  static const Color purple200 = Color(0xFFD2C7FF);
  static const Color purple300 = Color(0xFFB3A1FF);
  static const Color purple400 = Color(0xFF9077FA);
  static const Color purple500 = Color(0xFF7B5CF5);
  static const Color purple600 = Color(0xFF6A4CF0);
  static const Color purple700 = Color(0xFF5638CC);
  static const Color purple800 = Color(0xFF422BA0);
  static const Color purple900 = Color(0xFF2E1F70);
  static const Color purple950 = Color(0xFF1B1245);

  // Neutres
  static const Color neutral50 = Color(0xFFF6F6FA);
  static const Color neutral100 = Color(0xFFF1F0F6);
  static const Color neutral150 = Color(0xFFEEEDF4);
  static const Color neutral200 = Color(0xFFE7E5F0);
  static const Color neutral300 = Color(0xFFB4B2C4);
  static const Color neutral500 = Color(0xFF8A889E);
  static const Color neutral900 = Color(0xFF1B1A2E);
  static const Color ink500 = Color(0xFF6A6780);
  static const Color ink800 = Color(0xFF262238);

  //color — noms historiques, valeurs du design system
  static const Color violet = purple600;        // primary
  static const Color violetC = purple50;        // fond violet très clair (champs, hover, catégories)
  static const Color crevete = purple500;       // ancien accent corail → CTA violet (une seule couleur de marque)
  static const Color lavande = ink500;
  static const Color indigo = purple700;        // primary-pressed / primary-ink
  static const Color jaune = Color(0xFFE0A100); // warning
  static const Color gris = neutral500;         // texte / icônes inactifs (text-2)
  static const Color grisC = neutral300;        // bordures, texte désactivé (text-3)
  static const Color grisSC = neutral100;       // fond désactivé
  static const  Color grisnew = neutral50;      // fond d'écran (bg)
  static const Color grischamp = neutral100;    // fond de champ (surface-2)
  static const Color blueF = purple800;
  static const Color blueC = Color(0xFF3B6FF5); // info
  static const Color maron = purple800;         // ancien brun → violet foncé
  static const Color maron2 = purple900;
  static const Color green = Color(0xFF16A34A); // success
  static const Color green2 = Color(0xFF0F7A37); // success-ink
  static const Color red = Color(0xFFE5395F);   // danger

 // color text
  static  const Color Tnoir = neutral900;       // text-1
  static  const Color TnoirC = ink800;
  static const Color TgrisF = ink500;
  static const Color TgrisC = neutral500;       // text-2
  static const Color Tblue = purple600;         // liens et titres de section (primary)
  static const Color Tred = Color(0xFFE5395F);
  static const Color Tblanc = Color(0xFFFFFFFF);

  // Palette utilisée pour attribuer automatiquement une couleur à chaque
  // sous-catégorie (voir [couleurSousCategorie]) — mêmes teintes de marque
  // que le reste de l'appli plutôt que des couleurs Material génériques.
  static const List<Color> _paletteSousCategorie = [
    purple600, blueC, green, jaune, red, purple800, purple400, Color(0xFF6E96FF),
    Color(0xFF34D399), Color(0xFFFBBF24), Color(0xFFF87191), ink500,
  ];

  /// Couleur stable pour une sous-catégorie donnée (même sous-catégorie =
  /// toujours la même couleur, sans configuration manuelle) — utilisée comme
  /// repli visuel quand un produit de cette sous-catégorie n'a pas de photo
  /// (voir card_product.dart, afficher_produit_selectionner.dart,
  /// afficheur_produit.dart, afficheur_produit_stock.dart).
  static Color couleurSousCategorie(int sousCategorieId) {
    return _paletteSousCategorie[sousCategorieId % _paletteSousCategorie.length];
  }

  // Dégradé « hero » (en-têtes) et dégradé des boutons d'action (CTA).
  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple600, Color(0xFFA996FB)],
  );
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple500, purple600, purple700],
    stops: [0, 0.55, 1],
  );
  static const LinearGradient disabledGradient = LinearGradient(
    colors: [neutral300, neutral500],
  );



  // Typographie : Inter (latin) ; l'arabe, absent d'Inter, passe
  // automatiquement par Alexandria (fontFamilyFallback). Gras = semibold
  // (600) comme le design system, bold (700) pour les très grands titres.
  static const String fontLatin = 'Inter';
  static const String fontArabic = 'Alexandria';
  static const List<String> _fallback = [fontArabic];

  static TextStyle textXS =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 13,fontWeight: FontWeight.w400);
  static TextStyle textXSB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 13,fontWeight: FontWeight.w600);
  static TextStyle textS =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 14,fontWeight: FontWeight.w400);
  static TextStyle textSB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 14,fontWeight: FontWeight.w600);
  static TextStyle textM =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 18,fontWeight: FontWeight.w400);
  static TextStyle textMB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 18,fontWeight: FontWeight.w600);
  static TextStyle textL =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 22,fontWeight: FontWeight.w400);
  static TextStyle textLB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 22,fontWeight: FontWeight.w600);
  static TextStyle textXL =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 26,fontWeight: FontWeight.w400);
  static TextStyle textXLB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 26,fontWeight: FontWeight.w600);
  static TextStyle textXXL =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 34,fontWeight: FontWeight.w400);
  static TextStyle textXXLB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 34,fontWeight: FontWeight.w700);

  static TextStyle textpop_XS =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 12,fontWeight: FontWeight.w400);
  static TextStyle textpop_XSB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 12,fontWeight: FontWeight.w600);
  static TextStyle textpop_S =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 14,fontWeight: FontWeight.w400);
  static TextStyle textpop_SB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 14,fontWeight: FontWeight.w600);
  static TextStyle textpop_M =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 16,fontWeight: FontWeight.w400);
  static TextStyle textpop_MB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 16,fontWeight: FontWeight.w600);
  static TextStyle textpop_L =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 20,fontWeight: FontWeight.w400);
  static TextStyle textpop_LB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 20,fontWeight: FontWeight.w600);
  static TextStyle textpop_XL =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 34,fontWeight: FontWeight.w400);
  static TextStyle textpop_XLB =  TextStyle(fontFamily:'Inter',fontFamilyFallback: _fallback,fontSize: 34,fontWeight: FontWeight.w700);

  // ── Design tokens (fondations design system, phase 0) ──────────────
  // Rôles sémantiques : alias vers les couleurs de marque ci-dessus, pour
  // que le futur code raisonne en rôle (succès, erreur, surface...) plutôt
  // qu'en teinte nommée. Les couleurs de marque restent la seule source de
  // vérité — ces alias ne créent pas de nouvelles valeurs de couleur.
  static const Color primary = violet;
  static const Color primaryDark = indigo;
  static const Color primarySoft = Color(0xFFECE8FF);
  static const Color onPrimary = Tblanc;
  static const Color success = green;
  static const Color successSoft = Color(0xFFE6F7EE);
  static const Color successInk = green2;
  static const Color warning = jaune;
  static const Color warningSoft = Color(0xFFFFF6DD);
  static const Color warningInk = Color(0xFF8F6400);
  static const Color danger = red;
  static const Color dangerSoft = Color(0xFFFDE8EE);
  static const Color dangerInk = Color(0xFFC2254A);
  static const Color info = blueC;
  static const Color infoSoft = Color(0xFFE6EEFF);
  static const Color infoInk = Color(0xFF2A55CC);
  static const Color surface = Tblanc;
  static const Color surface2 = neutral100;       // chips, champs, boutons icône
  static const Color surfaceBorder = neutral150;  // bordure des cartes
  static const Color background = grisnew;
  static const Color textPrimary = Tnoir;
  static const Color textSecondary = TgrisC;
  static const Color textMuted = gris;
  static const Color border = grisC;
  static const Color disabledBg = neutral100;
  static const Color disabledFg = neutral300;
  static Color get focusRing => purple600.withOpacity(0.32);
  static const Color scrim = Color(0x7A0E0C16);

  /// Teinte « soft » (fond de badge, d'icône teintée) associée à un rôle.
  static Color softPour(Color c) {
    if (c == success) return successSoft;
    if (c == danger) return dangerSoft;
    if (c == warning) return warningSoft;
    if (c == info) return infoSoft;
    if (c == primary || c == crevete) return primarySoft;
    return c.withOpacity(0.12);
  }

  /// Teinte « ink » (texte sur fond soft, contraste 4.5:1) associée à un rôle.
  static Color inkPour(Color c) {
    if (c == success) return successInk;
    if (c == danger) return dangerInk;
    if (c == warning) return warningInk;
    if (c == info) return infoInk;
    if (c == primary || c == crevete) return primaryDark;
    return c;
  }

  // Échelle d'espacement (multiples de 4) — à utiliser pour tout nouveau
  // padding/margin plutôt que des valeurs ad hoc, afin de garder un rythme
  // visuel cohérent entre modules.
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXL = 24;
  static const double spaceXXL = 32;

  // Échelle de rayons de bordure (design system).
  static const double radiusXS = 6;
  static const double radiusSM = 8;
  static const double radiusMD = 12;      // champs, boutons icône
  static const double radiusButton = 14;
  static const double radiusLG = 16;
  static const double radiusCard = 20;
  static const double radiusXL = 24;
  static const double radiusDialog = 28;
  static const double radiusPill = 999;

  // Ombres standard (carte au repos / carte survolée ou active) — évite
  // que chaque widget ne redéfinisse ses propres valeurs de blur/opacité.
  // Teinte des ombres du design system (rgba(40,30,90,…)) — à utiliser au
  // lieu du noir pour toute BoxShadow.
  static const Color shadowTint = Color(0xFF281E5A);
  static const Color shadowSoft = Color(0x12281E5A);   // ~7 % (ombre de carte)
  static const Color shadowMedium = Color(0x29281E5A); // ~16 %

  static List<BoxShadow> get shadowCard => const [
        BoxShadow(color: Color(0x0F281E5A), blurRadius: 16, offset: Offset(0, 4)),
      ];
  static List<BoxShadow> get shadowRaised => const [
        BoxShadow(color: Color(0x1A281E5A), blurRadius: 28, offset: Offset(0, 8)),
      ];
  static List<BoxShadow> shadowHover({Color? color}) => [
        BoxShadow(
          color: (color ?? violet).withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

}