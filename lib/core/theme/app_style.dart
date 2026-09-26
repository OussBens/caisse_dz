import 'package:flutter/material.dart';
class Appstyle
{
  //color


  static const Color violet = const Color(0XFF755DB3);
  static const Color violetC = const Color(0XFFF6F4FD);
  static const Color crevete = const Color(0XFFFF8989);
  static const Color lavande = const Color(0XFF866F88);
  static const Color indigo = const Color(0XFF57315A);
  static const Color jaune = const Color(0XFFECBB5F);
  static const Color gris = const Color(0XFF858585);
  static const Color grisC = const Color(0XFFCFCFCF);
  static const Color grisSC = const Color(0XFFF8F8F8);
  static const  Color grisnew = const Color(0XFFF6F6F6);
  static const Color grischamp = const Color(0XFFF3F3F3);
  static const Color blueF = const Color(0XFF442C80);
  static const Color blueC = const Color(0XFF558CD2);
  static const Color maron = const Color(0XFFC08252);
  static const Color maron2 = const Color(0XFF7E5973);
  static const Color green = const Color(0XFF52B8A5);
  static const Color green2 = const Color(0XFF4E7984);
  static const Color red = const Color(0XFFD24728);

 // color text
  static  const Color Tnoir = const Color(0XFF0A1629);
  static  const Color TnoirC = const Color(0XFF4E4E4E);
  static const Color TgrisF = const Color(0XFF404040);
  static const Color TgrisC = const Color(0XFF91929E);
  static const Color Tblue = const Color(0XFF408CFE);
  static const Color Tred = const Color(0XFFFF3B00);
  static const Color Tblanc = const Color(0XFFFFFFFF);

  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6C5DD3), // Primary
      Color(0xFF9B80ED), // Primary Dark
    ],
  );
  static const LinearGradient disabledGradient = LinearGradient(
    colors: [
      Color(0xFF7D7D7D),
      Color(0xFF999999),
    ],
  );



  static TextStyle textXS =  TextStyle(fontFamily:'NunitoSans',fontSize: 13,fontWeight: FontWeight.w400);
  static TextStyle textXSB =  TextStyle(fontFamily:'NunitoSans',fontSize: 13,fontWeight: FontWeight.w700);
  static TextStyle textS =  TextStyle(fontFamily:'NunitoSans',fontSize: 14,fontWeight: FontWeight.w400);
  static TextStyle textSB =  TextStyle(fontFamily:'NunitoSans',fontSize: 14,fontWeight: FontWeight.w700);
  static TextStyle textM =  TextStyle(fontFamily:'NunitoSans',fontSize: 18,fontWeight: FontWeight.w400);
  static TextStyle textMB =  TextStyle(fontFamily:'NunitoSans',fontSize: 18,fontWeight: FontWeight.w700);
  static TextStyle textL =  TextStyle(fontFamily:'NunitoSans',fontSize: 22,fontWeight: FontWeight.w400);
  static TextStyle textLB =  TextStyle(fontFamily:'NunitoSans',fontSize: 22,fontWeight: FontWeight.w700);
  static TextStyle textXL =  TextStyle(fontFamily:'NunitoSans',fontSize: 26,fontWeight: FontWeight.w400);
  static TextStyle textXLB =  TextStyle(fontFamily:'NunitoSans',fontSize: 26,fontWeight: FontWeight.w700);
  static TextStyle textXXL =  TextStyle(fontFamily:'NunitoSans',fontSize: 34,fontWeight: FontWeight.w400);
  static TextStyle textXXLB =  TextStyle(fontFamily:'NunitoSans',fontSize: 34,fontWeight: FontWeight.w700);

  static TextStyle textpop_XS =  TextStyle(fontFamily:'Poppins',fontSize: 12,fontWeight: FontWeight.w400);
  static TextStyle textpop_XSB =  TextStyle(fontFamily:'Poppins',fontSize: 12,fontWeight: FontWeight.w700);
  static TextStyle textpop_S =  TextStyle(fontFamily:'Poppins',fontSize: 14,fontWeight: FontWeight.w400);
  static TextStyle textpop_SB =  TextStyle(fontFamily:'Poppins',fontSize: 14,fontWeight: FontWeight.w700);
  static TextStyle textpop_M =  TextStyle(fontFamily:'Poppins',fontSize: 16,fontWeight: FontWeight.w400);
  static TextStyle textpop_MB =  TextStyle(fontFamily:'Poppins',fontSize: 16,fontWeight: FontWeight.w700);
  static TextStyle textpop_L =  TextStyle(fontFamily:'Poppins',fontSize: 20,fontWeight: FontWeight.w400);
  static TextStyle textpop_LB =  TextStyle(fontFamily:'Poppins',fontSize: 20,fontWeight: FontWeight.w700);
  static TextStyle textpop_XL =  TextStyle(fontFamily:'Poppins',fontSize: 34,fontWeight: FontWeight.w400);
  static TextStyle textpop_XLB =  TextStyle(fontFamily:'Poppins',fontSize: 34,fontWeight: FontWeight.w700);

  // ── Design tokens (fondations design system, phase 0) ──────────────
  // Rôles sémantiques : alias vers les couleurs de marque ci-dessus, pour
  // que le futur code raisonne en rôle (succès, erreur, surface...) plutôt
  // qu'en teinte nommée. Les couleurs de marque restent la seule source de
  // vérité — ces alias ne créent pas de nouvelles valeurs de couleur.
  static const Color primary = violet;
  static const Color primaryDark = indigo;
  static const Color success = green;
  static const Color warning = jaune;
  static const Color danger = red;
  static const Color info = blueC;
  static const Color surface = Tblanc;
  static const Color background = grisnew;
  static const Color textPrimary = Tnoir;
  static const Color textSecondary = TgrisC;
  static const Color textMuted = gris;
  static const Color border = grisC;

  // Échelle d'espacement (multiples de 4) — à utiliser pour tout nouveau
  // padding/margin plutôt que des valeurs ad hoc, afin de garder un rythme
  // visuel cohérent entre modules.
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXL = 24;
  static const double spaceXXL = 32;

  // Échelle de rayons de bordure.
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 24;

  // Ombres standard (carte au repos / carte survolée ou active) — évite
  // que chaque widget ne redéfinisse ses propres valeurs de blur/opacité.
  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
  static List<BoxShadow> shadowHover({Color? color}) => [
        BoxShadow(
          color: (color ?? violet).withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

}