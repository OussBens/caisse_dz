import 'dart:ui';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dialog affiché à l'ouverture du dashboard pour demander à l'utilisateur
/// de choisir la période (date début / date fin) avant d'afficher les
/// statistiques. Reprend le pattern de [ConfirmationDialog] (BaseDialog +
/// flou d'arrière-plan) et le style des champs date de [PeriodeDateFilter].
Future<void> PeriodeDashboardDialog({
  required BuildContext context,
  required DateTime initialDateDebut,
  required DateTime initialDateFin,
  required String Function(DateTime) formatDate,
  required void Function(DateTime debut, DateTime fin) onConfirmer,
}) {
  final l10n = AppLocalizations.of(context)!;
  DateTime debut = initialDateDebut;
  DateTime fin = initialDateFin;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickDebut() async {
            final picked = await showDatePicker(
              context: dialogContext,
              initialDate: debut,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setDialogState(() {
                debut = picked;
                if (fin.isBefore(debut)) fin = debut;
              });
            }
          }

          Future<void> pickFin() async {
            final picked = await showDatePicker(
              context: dialogContext,
              initialDate: fin.isBefore(debut) ? debut : fin,
              firstDate: debut,
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setDialogState(() => fin = picked);
            }
          }

          Widget dateField(String label, DateTime value, VoidCallback onTap) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Appstyle.gris.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  readOnly: true,
                  onTap: onTap,
                  controller: TextEditingController(text: formatDate(value)),
                  decoration: InputDecoration(
                    labelText: label,
                    border: InputBorder.none,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                ),
              ),
            );
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 620,
                height: 380,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/info_icon.png',
                  text: "${l10n.confirmation} - ${l10n.dashboard}",
                ),
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.pleaseSelectTwoDates,
                      textAlign: TextAlign.center,
                      style: Appstyle.textSB.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        dateField(l10n.from, debut, pickDebut),
                        const SizedBox(width: 12),
                        dateField(l10n.to, fin, pickFin),
                      ],
                    ),
                  ],
                ),
                footer: Align(
                  alignment: Alignment.centerRight,
                  child: MainButton(
                    text: l10n.confirm,
                    color: Appstyle.violet,
                    noIcon: true,
                    onPressed: () {
                      onConfirmer(debut, fin);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
