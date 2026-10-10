import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
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
import '../../widget/filtre/periode_rapide_filter.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

String _typeOperationClientLabel(TypeOperation type, AppLocalizations l10n) {
  switch (type) {
    case TypeOperation.pannier:
      return l10n.sale;
    case TypeOperation.retour:
      return l10n.return_;
    case TypeOperation.versement_ENT:
    case TypeOperation.versement_SRT:
      return l10n.payment;
  }
}

List<List<String>> _lignesOperationsClient(List<OperationClient> operations, AppLocalizations l10n) {
  double running = 0;
  return operations.map((op) {
    running += op.credit - op.debit;
    return [
      _formatDate(op.date),
      _typeOperationClientLabel(op.type, l10n),
      op.reference,
      NumberFormatUtil.formatMontant(op.debit, decimales: 2),
      NumberFormatUtil.formatMontant(op.credit, decimales: 2),
      NumberFormatUtil.formatMontant(running, decimales: 2),
      op.description,
    ];
  }).toList();
}

Future<void> _exportSituationClientPdf(
  BuildContext context,
  AppLocalizations l10n,
  Client client,
  List<OperationClient> operations,
  String periode,
) async {
  if (operations.isEmpty) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.information,
      titre_concerne: l10n.client,
      message: l10n.noDataToExport,
    );
    return;
  }

  final headers = [l10n.date, l10n.type, l10n.ref, l10n.debit, l10n.credit, l10n.balance, l10n.description];
  final rows = _lignesOperationsClient(operations, l10n);

  final pdfBytes = await PDFTableGenerator.generateTableReport(
    title: l10n.clientSituation(client.nom),
    subtitleLines: [periode],
    headers: headers,
    rows: rows,
  );

  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PDFPreviewDialog(
      pdfBytes: pdfBytes,
      l10n: l10n,
      onPrint: () async {
        Navigator.pop(context);
        await PDFGeneratorLatin.printPDF(pdfBytes);
      },
      onSave: () async {
        final file = await PDFGeneratorLatin.savePDF(
          pdfBytes,
          'SituationClient_${client.code}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportSuccess), backgroundColor: Appstyle.success),
        );
        await PDFGeneratorLatin.openPDF(file);
      },
      onShare: () => Navigator.pop(context),
      onCancel: () => Navigator.pop(context),
    ),
  );
}

Future<void> _exportSituationClientExcel(
  BuildContext context,
  AppLocalizations l10n,
  Client client,
  List<OperationClient> operations,
) async {
  if (operations.isEmpty) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.information,
      titre_concerne: l10n.client,
      message: l10n.noDataToExport,
    );
    return;
  }

  final fermerSpinner = ouvrirSpinnerExport(context);
  try {

    final headers = [l10n.date, l10n.type, l10n.ref, l10n.debit, l10n.credit, l10n.balance, l10n.description];
    final rows = _lignesOperationsClient(operations, l10n);

    final excelFile = await ExcelGenerator.generateOperationsExcel(
      title: l10n.clientSituation(client.nom),
      headers: headers,
      rows: rows,
      l10n: l10n,
    );

    if (!context.mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExcelPreviewDialog(
        data: rows,
        headers: headers,
        title: client.nom,
        l10n: l10n,
        excelFile: excelFile,
        onSave: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportSuccess), backgroundColor: Appstyle.success),
          );
        },
        onShare: () => Navigator.pop(context),
        onCancel: () => Navigator.pop(context),
      ),
    );
  } catch (e) {
    fermerSpinner();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: Appstyle.danger),
    );
  }
}

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
      kind: DialogKind.refuser,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  // ================= STATE =================
  DateTime dateDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime dateFin = DateTime.now();
  TypeOperation? typeFilter; // null = Tous
  String? periodeRapide;

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
                // Plus haut qu'avant (650) : 90 % de la hauteur de la fenêtre,
                // plafonné à 950 pour les grands écrans.
                height: (MediaQuery.of(context).size.height * 0.9).clamp(650.0, 950.0),

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
                          child: ChampAvecLabel(
                            label: l10n.from,
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
                        ),

                        const SizedBox(width: 12),

                        // Date fin
                        Expanded(
                          child: ChampAvecLabel(
                            label: l10n.to,
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
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ChampPeriodeRapide(
                            l10n: l10n,
                            value: periodeRapide,
                            onSelected: (key) {
                              final periode = calculerPeriodeRapide(key);
                              setState(() {
                                periodeRapide = key;
                                dateDebut = periode.debut;
                                dateFin = periode.fin;
                                dateDebutCtrl.text = _formatDate(periode.debut);
                                dateFinCtrl.text = _formatDate(periode.fin);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
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
                      text: l10n.extract,
                      textColor: Appstyle.success,
                      iconColor: Appstyle.success,
                      color: Appstyle.Tblanc,
                      icon: Icons.download,
                      onPressed: () => _exportSituationClientExcel(context, l10n, client, operations),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.extractPdf,
                      textColor: Appstyle.danger,
                      iconColor: Appstyle.danger,
                      color: Appstyle.Tblanc,
                      icon: Icons.picture_as_pdf,
                      onPressed: () => _exportSituationClientPdf(
                        context,
                        l10n,
                        client,
                        operations,
                        "${l10n.from}: ${dateDebutCtrl.text}    ${l10n.to}: ${dateFinCtrl.text}",
                      ),
                    ),
                    const SizedBox(width: 10),
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