import 'package:flutter/material.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../widget/button/main_button.dart';
import '../widget/champ/champ_avec_label.dart';
import '../widget/champ/text_champ_l.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';

class InsertionCodebarDialog extends StatefulWidget {
  final Function(String) onBarcodeAdded;
  /// Code du produit en cours de modification, à exclure de la vérification
  /// d'unicité (ses propres codes-barres ne doivent pas se signaler eux-mêmes).
  final String? excludeProduitCode;

  const InsertionCodebarDialog({
    super.key,
    required this.onBarcodeAdded,
    this.excludeProduitCode,
  });

  @override
  State<InsertionCodebarDialog> createState() =>
      _InsertionCodebarDialogState();
}

class _InsertionCodebarDialogState
    extends State<InsertionCodebarDialog> {

  final TextEditingController barcodeController =
  TextEditingController();

  bool verifying = false;
  String? erreur;

  Future<void> ajouter() async {
    final code = barcodeController.text.trim();

    if (code.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      verifying = true;
      erreur = null;
    });

    final conflit = await ProduitServices.findProduitUsingBarcode(
      code,
      excludeProduitCode: widget.excludeProduitCode,
    );

    if (!mounted) return;

    if (conflit != null) {
      setState(() {
        verifying = false;
        erreur = l10n.barcodeAlreadyUsed(conflit.nom);
      });
      return;
    }

    widget.onBarcodeAdded(code);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      width: 500,
     couleur: Appstyle.Tblanc,

      header: TitreAvecLigne(
        imagePath: 'assets/icons/sidebar/produit_icon.png',
        text: "Insertion Code Barre",
        trailing: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: Appstyle.gris),
        ),
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// texte instruction
          Text(
            "Merci de saisir ou bien scanner le code barre pour ajouter.",
            style: TextStyle(
              fontSize: 15,
              color: Appstyle.Tnoir,
            ),
          ),

          const SizedBox(height: 20),

          ChampAvecLabel(
            obligatoire: true,
             label: 'Code Bar',
            child:  TextChampL(
              controller: barcodeController,
              hint: "Code barre",
              numeric: true,
              onChanged: (_) {
                if (erreur != null) setState(() => erreur = null);
              },
            ),
          ),
          /// champ code barre
          if (erreur != null) ...[
            const SizedBox(height: 8),
            Text(
              erreur!,
              style: const TextStyle(color: Appstyle.danger, fontWeight: FontWeight.w600),
            ),
          ],

        ],
      ),

      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MainButton(
            text: "Annuler",
            icon: Icons.cancel,
            color: Appstyle.gris,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          MainButton(
            text: "Ajouter",
            icon: Icons.check,
            color: Appstyle.violet,
            onPressed: verifying ? null : ajouter,
          ),
        ],
      ),
    );
  }
}
