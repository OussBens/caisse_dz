import 'dart:ui';

import 'package:caisse_dz/Services/FiscalExportService.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

/// Dialog d'export de contrôle fiscal : choix d'une période, puis génération
/// d'un fichier JSON auto-vérifiable (registre fiscal + tickets + clôtures,
/// voir FiscalExportService) prêt à remettre à l'administration en cas de
/// contrôle.
Future<void> ExportFiscalDialog(BuildContext context) async {
  final now = DateTime.now();
  DateTime dateDebut = DateTime(now.year, now.month, 1);
  DateTime dateFin = now;
  final dateDebutCtrl = TextEditingController(text: dateDebut.toString().split(' ').first);
  final dateFinCtrl = TextEditingController(text: dateFin.toString().split(' ').first);

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 600,
                height: 320,
                header: TitreAvecLigne(
                  imagePath: "assets/icons/sidebar/caisse_icon.png",
                  text: l10n.fiscalControlExport,
                ),
                content: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ChampAvecLabel(
                        label: l10n.from,
                        obligatoire: true,
                        child: TextDate(
                          controller: dateDebutCtrl,
                          hint: l10n.selectDatew,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dateDebut,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                dateDebut = picked;
                                dateDebutCtrl.text = picked.toString().split(' ').first;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ChampAvecLabel(
                        label: l10n.to,
                        obligatoire: true,
                        child: TextDate(
                          controller: dateFinCtrl,
                          hint: l10n.selectDatew,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dateFin,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                dateFin = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                                dateFinCtrl.text = picked.toString().split(' ').first;
                              });
                            }
                          },
                        ),
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
                      text: l10n.extract,
                      icon: Icons.download,
                      color: Appstyle.violet,
                      onPressed: () async {
                        final file = await FiscalExportService.exporterControleFiscal(
                          dateDebut: dateDebut,
                          dateFin: dateFin,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.exportSuccess),
                            backgroundColor: Colors.green,
                            action: SnackBarAction(
                              label: l10n.open,
                              onPressed: () => OpenFile.open(file.path),
                            ),
                          ),
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
