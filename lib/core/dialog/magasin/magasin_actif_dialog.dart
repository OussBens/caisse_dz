import 'dart:ui';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/magasin.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

/// Choix du magasin actif de la session — jusqu'ici `AuthState.currentMagasin`
/// / `currentMagasinId` (issus de UserParam) n'étaient jamais réellement
/// éditables : InitialSetupDialog se contentait de les re-sauvegarder tels
/// quels. Ce dialog est le premier point d'entrée qui les fait pointer vers
/// un vrai magasin choisi dans la table `magasins` (cf. écran de gestion des
/// magasins, étape précédente).
///
/// Convention retenue (rien ne l'imposait avant, aucun code n'écrivait
/// encore de vraie valeur) : `magasin` = nom affichable, `magasinId` = code
/// stable (ex. "MAG0000"), pour rester cohérent avec le FK utilisé partout
/// ailleurs (produit_magasin_detail.magasin_code...).
Future<void> MagasinActifDialog(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userCode = auth.userCode;
  if (userCode == null) return;

  final tousLesMagasins = await MagasinServices.getAllMagasins();
  final magasinsActifs = tousLesMagasins.where((m) => m.etat).toList();

  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;

  String? selectedCode = magasinsActifs
      .firstWhere(
        (m) => m.code == auth.currentMagasinId,
        orElse: () => magasinsActifs.isNotEmpty ? magasinsActifs.first : Magasin(
          id: 0, code: '', nom: '', etat: true, dateCree: DateTime.now(), creeParCode: userCode,
        ),
      )
      .code;
  if (selectedCode!.isEmpty) selectedCode = null;

  bool isSaving = false;

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
                width: 480,
                height: 480,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/magasin_icon.png',
                  text: l10n.defaultStore,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ⚠️ Ce choix ne pilote QUE l'affichage/pré-remplissage pour
                    // cet utilisateur — les ventes suivent toujours le magasin
                    // configuré sur la caisse utilisée (voir Gestion des
                    // caisses), pas ce réglage.
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Appstyle.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Appstyle.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Ce réglage n'affecte que votre affichage personnel. "
                              "Les ventes suivent toujours le magasin configuré sur "
                              "la caisse utilisée (Gestion des caisses).",
                              style: Appstyle.textXS.copyWith(color: Appstyle.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: magasinsActifs.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noStoreAvailable,
                                style: Appstyle.textSB.copyWith(color: Appstyle.TgrisC),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: magasinsActifs.length,
                              itemBuilder: (context, index) {
                                final m = magasinsActifs[index];
                                final selected = m.code == selectedCode;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                                  onTap: () => setState(() => selectedCode = m.code),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected ? Appstyle.violet.withOpacity(0.12) : Appstyle.surface,
                                      borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                                      border: Border.all(
                                        color: selected ? Appstyle.violet : Appstyle.border,
                                        width: selected ? 1.6 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: selected ? Appstyle.violet : Appstyle.textMuted,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.nom,
                                                style: Appstyle.textSB.copyWith(
                                                  color: selected ? Appstyle.violet : Appstyle.textPrimary,
                                                ),
                                              ),
                                              if (m.adresse != null && m.adresse!.isNotEmpty)
                                                Text(
                                                  m.adresse!,
                                                  style: Appstyle.textXS.copyWith(color: Appstyle.textMuted),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
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
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.violet,
                      loading: isSaving,
                      onPressed: selectedCode == null
                          ? null
                          : () async {
                              setState(() => isSaving = true);

                              final magasin = magasinsActifs.firstWhere((m) => m.code == selectedCode);
                              final error = await auth.updateUserParameters(
                                language: auth.currentLanguage ?? 'fr',
                                currency: auth.currentCurrency ?? 'DZD',
                                magasin: magasin.nom,
                                magasinId: magasin.code,
                                modifiedBy: auth.username ?? '',
                                modifiedByCode: userCode,
                                reason: "Changement de magasin actif",
                              );

                              if (!context.mounted) return;

                              if (error != null) {
                                setState(() => isSaving = false);
                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.error,
                                  titre_concerne: l10n.magasin,
                                  message: error,
                                );
                                return;
                              }

                              Navigator.pop(context);
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
