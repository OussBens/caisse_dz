import 'dart:ui';

import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/tableau/operation/tableau_operation_f.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/fournisseur.dart';
import '../../../data/models/operation_fournisseur.dart';
import '../../../data/models/retour.dart';
import '../../../data/models/smart_scan.dart';
import '../../../data/models/verssement.dart';
import '../../service_fournisseur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/date_champ.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<void> SituationFournisseurDialog(
    BuildContext context, {
      required Fournisseur fournisseur,
      required List<SmartScan> smartScans,
      required List<Retour> retours,
      required List<Verssement> versements,
    }) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  DateTime dateDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime dateFin = DateTime.now();
  TypeOperationFournisseur? typeFilter;

  final dateDebutCtrl = TextEditingController(text: _formatDate(dateDebut));
  final dateFinCtrl = TextEditingController(text: _formatDate(dateFin));

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          final operations = SituationFournisseurService.build(
            smartScans: smartScans
                .where((s) => s.fournisseur == fournisseur.nom)
                .toList(),
            retours: retours
                .where((r) => r.fournisseur == fournisseur.nom)
                .toList(),
            versements: versements
                .where((v) => v.beneficiare == fournisseur.nom && v.typebeneficiare=='Fournisseur')
                .toList(),
            debut: dateDebut,
            fin: dateFin,
          ).where((op) {
            /// ✅ FILTRE DATE
            final inDateRange = !op.date.isBefore(dateDebut) && !op.date.isAfter(dateFin);

            final matchType = typeFilter == null || op.type == typeFilter;

            return matchType && inDateRange;
          }).toList();

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1200,
                height: 650,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/fournisseur_icon.png',
                  text: l10n.supplierSituation(fournisseur.nom),
                ),

                content: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextDate(
                            hint: l10n.startDate,
                            controller: dateDebutCtrl,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: dateDebut,
                                firstDate: DateTime(2000),
                                lastDate: dateFin,
                              );
                              if (d != null) {
                                setState(() {
                                  dateDebut = d;
                                  dateDebutCtrl.text = _formatDate(d);
                                });
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: TextDate(
                            hint: l10n.endDate,
                            controller: dateFinCtrl,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: dateFin,
                                firstDate: dateDebut,
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                setState(() {
                                  dateFin = d;
                                  dateFinCtrl.text = _formatDate(d);
                                });
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ChampAvecLabel(
                            label: l10n.type,
                            child: TextListe(
                              value: typeFilter?.name ?? l10n.all,
                              items: [
                                l10n.all,
                                "achat",
                                "retour",
                                "versement_ENT",
                                "versement_SRT",
                              ],
                              onChanged: (v) {
                                setState(() {
                                  if (v == l10n.all) {
                                    typeFilter = null;
                                    return;
                                  }

                                  try {
                                    typeFilter = TypeOperationFournisseur.values.byName(v!);
                                  } catch (_) {
                                    typeFilter = null;
                                  }
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        MainButton(
                          text: l10n.refresh,
                          color: Appstyle.violet,
                          icon: Icons.refresh,
                          onPressed: () {
                            setState(() {
                              dateDebut = DateTime.now().subtract(const Duration(days: 30));
                              dateFin = DateTime.now();

                              dateDebutCtrl.text = _formatDate(dateDebut);
                              dateFinCtrl.text = _formatDate(dateFin);

                              typeFilter = null;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: TableauSituationFournisseurAdvanced(
                        operations: operations,
                      ),
                    ),
                  ],
                ),

                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.close,
                      color: Appstyle.gris,
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
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

/// ================= UTILS =================
String _formatDate(DateTime d) {
  return "${d.day.toString().padLeft(2, '0')}/"
      "${d.month.toString().padLeft(2, '0')}/"
      "${d.year}";
}