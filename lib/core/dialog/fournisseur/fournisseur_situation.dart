import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/Services/export_spinner.dart';

import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
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
import '../../widget/filtre/periode_rapide_filter.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

String _typeOperationFournisseurLabel(TypeOperationFournisseur type, AppLocalizations l10n) {
  switch (type) {
    case TypeOperationFournisseur.achat:
      return l10n.purchase;
    case TypeOperationFournisseur.retour:
      return l10n.return_;
    case TypeOperationFournisseur.versement_ENT:
    case TypeOperationFournisseur.versement_SRT:
      return l10n.payment;
  }
}

List<List<String>> _lignesOperationsFournisseur(List<OperationFournisseur> operations, AppLocalizations l10n) {
  double running = 0;
  return operations.map((op) {
    running += op.credit - op.debit;
    return [
      _formatDate(op.date),
      _typeOperationFournisseurLabel(op.type, l10n),
      op.reference,
      NumberFormatUtil.formatMontant(op.debit, decimales: 2),
      NumberFormatUtil.formatMontant(op.credit, decimales: 2),
      NumberFormatUtil.formatMontant(running, decimales: 2),
      op.description,
    ];
  }).toList();
}

Future<void> _exportSituationFournisseurPdf(
  BuildContext context,
  AppLocalizations l10n,
  Fournisseur fournisseur,
  List<OperationFournisseur> operations,
  String periode,
) async {
  if (operations.isEmpty) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.information,
      titre_concerne: l10n.fournisseur,
      message: l10n.noDataToExport,
    );
    return;
  }

  final headers = [l10n.date, l10n.type, l10n.ref, l10n.debit, l10n.credit, l10n.balance, l10n.description];
  final rows = _lignesOperationsFournisseur(operations, l10n);

  final pdfBytes = await PDFTableGenerator.generateTableReport(
    title: l10n.supplierSituation(fournisseur.nom),
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
          'SituationFournisseur_${fournisseur.code}_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

Future<void> _exportSituationFournisseurExcel(
  BuildContext context,
  AppLocalizations l10n,
  Fournisseur fournisseur,
  List<OperationFournisseur> operations,
) async {
  if (operations.isEmpty) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.information,
      titre_concerne: l10n.fournisseur,
      message: l10n.noDataToExport,
    );
    return;
  }

  final fermerSpinner = ouvrirSpinnerExport(context);
  try {

    final headers = [l10n.date, l10n.type, l10n.ref, l10n.debit, l10n.credit, l10n.balance, l10n.description];
    final rows = _lignesOperationsFournisseur(operations, l10n);

    final excelFile = await ExcelGenerator.generateOperationsExcel(
      title: l10n.supplierSituation(fournisseur.nom),
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
        title: fournisseur.nom,
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
      kind: DialogKind.refuser,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  DateTime dateDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime dateFin = DateTime.now();
  TypeOperationFournisseur? typeFilter;
  String? periodeRapide;

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
                .where((s) => s.fournisseurCode == fournisseur.code)
                .toList(),
            retours: retours
                .where((r) => r.fournisseur_code == fournisseur.code)
                .toList(),
            versements: versements
                .where((v) => v.beneficiareCode == fournisseur.code && v.typebeneficiare=='Fournisseur')
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
                // Plus haut qu'avant (650) : 90 % de la hauteur de la fenêtre,
                // plafonné à 950 pour les grands écrans.
                height: (MediaQuery.of(context).size.height * 0.9).clamp(650.0, 950.0),

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/fournisseur_icon.png',
                  text: l10n.supplierSituation(fournisseur.nom),
                ),

                content: Column(
                  children: [
                    Row(
                      children: [
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
                      text: l10n.extract,
                      textColor: Appstyle.success,
                      iconColor: Appstyle.success,
                      color: Appstyle.Tblanc,
                      icon: Icons.download,
                      onPressed: () => _exportSituationFournisseurExcel(context, l10n, fournisseur, operations),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.extractPdf,
                      textColor: Appstyle.danger,
                      iconColor: Appstyle.danger,
                      color: Appstyle.Tblanc,
                      icon: Icons.picture_as_pdf,
                      onPressed: () => _exportSituationFournisseurPdf(
                        context,
                        l10n,
                        fournisseur,
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