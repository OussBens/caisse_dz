import 'dart:ui';

import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/ClotureCaisse.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/cloture_caisse/cloture_caisse_pdf.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialog de clôture de caisse (rapport Z) : sélection d'une caisse,
/// confirmation de la période à clôturer (depuis la dernière clôture, ou
/// depuis toujours si aucune), puis clôture immédiate + impression du
/// rapport — pas d'étape de prévisualisation séparée, le rapport imprimé
/// EST la confirmation de ce qui vient d'être clôturé.
Future<void> ClotureCaisseNouveau(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userCode = auth.userCode;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  final caisses = (await GCServices.getAllCaisses()).where((c) => c.etat).toList();

  String? selectedCaisseNom;
  String? selectedCaisseCode;
  DateTime? derniereCloture;
  bool loadingPeriode = false;

  if (!context.mounted) return;
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          Future<void> onCaisseChanged(String? nom) async {
            final code = caisses.firstWhere((c) => c.nomCaisse == nom).code;
            setState(() {
              selectedCaisseNom = nom;
              selectedCaisseCode = code;
              loadingPeriode = true;
            });
            final derniere = await ClotureCaisseServices.getDerniereClotureDate(code);
            setState(() {
              derniereCloture = derniere;
              loadingPeriode = false;
            });
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 700,
                height: 380,
                header: TitreAvecLigne(
                  imagePath: "assets/icons/sidebar/caisse_icon.png",
                  text: l10n.newClosure,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChampAvecLabel(
                      label: l10n.selectCashRegisterToClose,
                      obligatoire: true,
                      distance: 260,
                      child: TextListe(
                        value: selectedCaisseNom ?? "",
                        obligatoire: true,
                        items: caisses.map((c) => c.nomCaisse).toList(),
                        onChanged: onCaisseChanged,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedCaisseCode != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Appstyle.grisC.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: loadingPeriode
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.closurePeriod,
                                    style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${l10n.from}: ${derniereCloture != null ? _formatDate(derniereCloture!) : '—'}    "
                                    "${l10n.to}: ${_formatDate(DateTime.now())}",
                                    style: Appstyle.textSB,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.confirmClosureMessage,
                                    style: Appstyle.textXS.copyWith(color: Appstyle.TgrisC),
                                  ),
                                ],
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
                      text: l10n.newClosure,
                      icon: Icons.lock_outline,
                      color: Appstyle.violet,
                      onPressed: selectedCaisseCode == null
                          ? null
                          : () async {
                              final response = await ClotureCaisseServices.cloturer(
                                caisseCode: selectedCaisseCode!,
                                userCode: userCode,
                              );

                              if (!response.success || response.data == null) {
                                if (!context.mounted) return;
                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.error,
                                  titre_concerne: l10n.cashRegisterClosures,
                                  message: response.message,
                                );
                                return;
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              await genererEtAfficherRapportZ(
                                context,
                                l10n,
                                response.data!,
                                selectedCaisseNom!,
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

String _formatDate(DateTime d) {
  return "${d.day.toString().padLeft(2, '0')}/"
      "${d.month.toString().padLeft(2, '0')}/"
      "${d.year} "
      "${d.hour.toString().padLeft(2, '0')}:"
      "${d.minute.toString().padLeft(2, '0')}";
}
