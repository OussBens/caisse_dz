import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/caisse_session/ouverture_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Remplace le simple message bloquant "Aucune session ouverte" : montre le
/// même message, plus la liste des caisses pour en choisir une (pré-sélection
/// sur [caisseInitiale]) et un bouton pour l'ouvrir directement, sans quitter
/// le flux en cours (vente, achat, retour…). [onSessionOuverte] est appelé
/// après une ouverture réussie pour permettre à l'appelant de relancer
/// l'action initiale.
Future<void> CaisseFermeeDialog({
  required BuildContext context,
  required List<CaisseGestion> caisses,
  required CaisseGestion caisseInitiale,
  VoidCallback? onSessionOuverte,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // Conservé à part : le `context` capturé par les builders imbriqués
  // ci-dessous (StatefulBuilder) est celui de CE dialog, invalidé dès qu'on
  // le ferme via Navigator.pop. L'utiliser ensuite pour ouvrir
  // OuvertureCaisseDialog provoquait "Looking up a deactivated widget's
  // ancestor is unsafe" dès que l'ouverture de session prenait un peu de
  // temps (I/O DB) après la fermeture de ce dialog.
  final BuildContext callerContext = context;
  CaisseGestion caisseSelectionnee = caisseInitiale;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 700,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: l10n.attention,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aucuneSessionOuverte(caisseInitiale.nomCaisse),
                      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 16),
                    ChampAvecLabel(
                      label: l10n.cashRegister,
                      child: TextListe(
                        value: caisseSelectionnee.nomCaisse,
                        items: caisses.map((c) => c.nomCaisse).toList(),
                        clearable: false,
                        onChanged: (v) {
                          final choisie = caisses.where((c) => c.nomCaisse == v).firstOrNull;
                          if (choisie != null) {
                            setState(() => caisseSelectionnee = choisie);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      icon: Icons.cancel,
                      color: Appstyle.gris,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.ouvrirCaisse,
                      icon: Icons.lock_open,
                      color: Appstyle.violet,
                      onPressed: () async {
                        Navigator.pop(context);
                        if (!callerContext.mounted) return;
                        await OuvertureCaisseDialog(
                          context: callerContext,
                          caisse: caisseSelectionnee,
                          onSuccess: onSessionOuverte,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
