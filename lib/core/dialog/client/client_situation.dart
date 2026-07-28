import 'dart:ui';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/client.dart';
import '../../../../data/models/pannier.dart';
import '../../../../data/models/retour.dart';
import '../../../../data/models/verssement.dart';
import '../../../../data/models/operation_client.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../service_client.dart';
import '../../tableau/operation/tableau_operation.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/date_champ.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<void> SituationClientDialog(
    BuildContext context, {
      required Client client,
      required List<Pannier> panniers,
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

  // ================= STATE =================
  DateTime dateDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime dateFin = DateTime.now();
  TypeOperation? typeFilter; // null = Tous

  final dateDebutCtrl = TextEditingController(text: _formatDate(dateDebut));
  final dateFinCtrl = TextEditingController(text: _formatDate(dateFin));

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          List<Pannier>    pannierF     = panniers.where( (sc) => sc.client_code == client.code).toList();
          List<Retour>     retourF      = retours.where( (sc) => sc.client_code == client.code).toList();
          List<Verssement> verssementF  = versements.where((sc) => sc.beneficiareCode == client.code && sc.typebeneficiare == 'Client').toList();

          // ================= DATA =================
          final operations = SituationClientService.build(
            panniers: pannierF,
            retours: retourF,
            versements: verssementF,
            debut: dateDebut,
            fin: dateFin,
          ).where((op) {
            /// ✅ FILTRE DATE
            final inDateRange =
                !op.date.isBefore(dateDebut) &&
                    !op.date.isAfter(dateFin);

            /// ✅ FILTRE TYPE
            final matchType =
                typeFilter == null || op.type == typeFilter;

            return inDateRange && matchType;
          }).toList();

          // ================= UI =================
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1200,
                height: 650,

                // ================= HEADER =================
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/client_icon.png',
                  text: l10n.clientSituation(client.nom ?? ''),
                ),

                // ================= CONTENT =================
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Date début
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

                        // Date fin
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

                        // Type opération avec TextListe
                        Expanded(
                          child: ChampAvecLabel(
                            label: l10n.type,
                            child: TextListe(
                              value: typeFilter?.name ?? l10n.all,
                              items: [
                                l10n.all,
                                "pannier",
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
                                    typeFilter = TypeOperation.values.byName(v!);
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
                              /// ✅ reset dates
                              dateDebut = DateTime.now().subtract(const Duration(days: 30));
                              dateFin   = DateTime.now();

                              dateDebutCtrl.text = _formatDate(dateDebut);
                              dateFinCtrl.text   = _formatDate(dateFin);

                              /// ✅ reset type
                              typeFilter = null;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Tableau situation client
                    Expanded(
                      child: TableauSituationClientAdvanced(
                        operations: operations,
                      ),
                    ),
                  ],
                ),

                // ================= FOOTER =================
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