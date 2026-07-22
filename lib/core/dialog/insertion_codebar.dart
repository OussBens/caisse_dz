import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/champ/champ_avec_label.dart';
import '../widget/champ/text_champ_l.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';

class InsertionCodebarDialog extends StatefulWidget {
  final Function(String) onBarcodeAdded;

  const InsertionCodebarDialog({
    super.key,
    required this.onBarcodeAdded,
  });

  @override
  State<InsertionCodebarDialog> createState() =>
      _InsertionCodebarDialogState();
}

class _InsertionCodebarDialogState
    extends State<InsertionCodebarDialog> {

  final TextEditingController barcodeController =
  TextEditingController();

  void ajouter() {
    final code = barcodeController.text.trim();

    if (code.isEmpty) return;

    widget.onBarcodeAdded(code);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      width: 500,
      couleur: Appstyle.violetC,

      header: Row(
        children: [
          TitreAvecLigne(
            imagePath: 'assets/icons/sidebar/produit_icon.png',
            text: "Insertion Code Barre",
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close, color: Appstyle.gris),
          ),
        ],
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
            ),
          ),
          /// champ code barre

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
            onPressed: ajouter,
          ),
        ],
      ),
    );
  }
}