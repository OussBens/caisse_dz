import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'button/main_button.dart';

class CalculatriceSmallWidget extends StatelessWidget {
  final Function(String) onButtonPressed;

  const CalculatriceSmallWidget({super.key, required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<List<Map<String, dynamic>>> buttons = [
      [
        {
          "text": l10n.encaisserTicket,
          "action": "ENCAISSEMENT_TICKET",
          "flex": 2,
          "color": Appstyle.violet,
          "textColor": Colors.white,
          "icon": Icons.payment,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        },
        {
          "text": l10n.enregistrer,
          "action": "ENREGISTER_TICKET",
          "flex": 2,
          "color": Appstyle.crevete,
          "textColor": Colors.white,
          "icon": Icons.save,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        }
      ],
      [
        {
          "text": l10n.encaisserBLSC,
          "action": "ENCAISSEMENT_BLSC",
          "flex": 2,
          "color": Appstyle.green,
          "textColor": Colors.white,
          "icon": Icons.receipt_long,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        },
        {
          "text": l10n.annuler,
          "action": "SUPPRIMER_CAISSE",
          "flex": 2,
          "color": Appstyle.gris,
          "textColor": Colors.white,
          "icon": Icons.cancel,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        }
      ],
      [
        {
          "text": l10n.newClient,
          "action": "NEW_CLIENT",
          "flex": 2,
          "color": Appstyle.indigo,
          "textColor": Colors.white,
          "icon": Icons.person_add,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        },
        {
          "text": l10n.newProduct,
          "action": "NEW_PRODUCT",
          "flex": 2,
          "color": Appstyle.jaune,
          "textColor": Colors.white,
          "icon": Icons.production_quantity_limits,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        }
      ],
      [
        {
          "text": l10n.quickEntry,
          "action": "QUICK_ENTRY",
          "flex": 2,
          "color": Appstyle.blueC,
          "textColor": Colors.white,
          "icon": Icons.add_business,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        },
        {
          "text": l10n.cashReceipt,
          "action": "CASH_RECEIPT",
          "flex": 2,
          "color": Appstyle.green2,
          "textColor": Colors.white,
          "icon": Icons.receipt,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        }
      ],
      // ✅ NOUVELLE LIGNE : Bouton PACK
      [
        {
          "text": "PACK",
          "action": "PACK",
          "flex": 2,
          "color": Appstyle.violet,
          "textColor": Colors.white,
          "icon": Icons.all_inbox,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        },
        {
          "text": l10n.discount,
          "action": "REMISE",
          "flex": 2,
          "color": Appstyle.crevete,
          "textColor": Colors.white,
          "icon": Icons.percent,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": true
        }
      ],
    ];

    return Column(
      children: buttons.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: line.map((btn) {
              final flex = btn["flex"] ?? 1;
              final color = btn["color"] ?? Appstyle.indigo;
              final icon = btn["icon"];
              final padding = btn["padding"] as EdgeInsets?;
              final textcolor = btn["textColor"] ?? Appstyle.Tnoir;
              final iconright = btn["iconRight"] ?? false;
              final iconPath = btn["iconPath"];

              return Expanded(
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: MainButton(
                    text: btn["text"],
                    color: color,
                    onPressed: () => onButtonPressed(
                      btn["action"] ?? btn["text"],
                    ),
                    icon: icon,
                    iconPath: iconPath,
                    noIcon: icon == null && iconPath == null,
                    padding: padding,
                    textColor: textcolor,
                    iconOnRight: iconright,
                    iconColor: btn["iconColor"],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}