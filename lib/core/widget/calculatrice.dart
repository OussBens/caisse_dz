import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'button/main_button.dart';

class CalculatriceWidget extends StatelessWidget {
  final Function(String) onButtonPressed;

  const CalculatriceWidget({super.key, required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    final List<List<Map<String, dynamic>>> buttons = [
      // LIGNE 1
      [
        {"text": "", "color": Appstyle.neutral200, "action": "CLEAR_PANIER", "shortcut": "F10", "iconPath": "assets/icons/action/supprimer_icon.png", "iconColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 0)},
        {"text": "", "action": "UP", "shortcut": "+", "icon": Icons.arrow_upward, "color": Appstyle.Tblanc, "textColor": Colors.black, "iconColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 0)},
        {"text": "7", "color": Appstyle.Tblanc, "textColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "8", "color": Appstyle.Tblanc, "textColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "9", "color": Appstyle.Tblanc, "textColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": l10n.ticket, "action": "ENCAISSEMENT_TICKET", "shortcut": "F4", "flex": 2, "color": Appstyle.violet, "textColor": Colors.white, "icon": Icons.payment, "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8), "iconRight": !isRTL},
        {
          "text": l10n.cashReceipt,
          "action": "CASH_RECEIPT",
          "shortcut": "R",
          "flex": 2,
          "color": Appstyle.jaune,
          "textColor": Colors.white,
          "icon": Icons.receipt,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": !isRTL
        }

      ],
      // LIGNE 2
      [

        {"text": "", "color": Appstyle.neutral200, "iconPath": "assets/icons/info_icon.png", "iconColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "", "action": "DOWN", "shortcut": "-", "icon": Icons.arrow_downward, "color": Appstyle.Tblanc, "textColor": Colors.black, "iconColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "4", "color": Appstyle.Tblanc, "textColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "5", "color": Appstyle.Tblanc, "textColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "6", "color": Appstyle.Tblanc, "textColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": l10n.save, "action": "ENREGISTER_TICKET", "shortcut": "F6", "flex": 2, "color": Appstyle.crevete, "textColor": Colors.white, "icon": Icons.save, "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8), "iconRight": !isRTL}
       , {
          "text": l10n.productRevenue,
          "action": "CASH_RECEIPT_PRODUIT",
          "shortcut": "P",
          "flex": 2,
          "color": Appstyle.maron,
          "textColor": Colors.white,
          "icon": Icons.inventory_2,
          "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          "iconRight": !isRTL
        }
      ],
      // LIGNE 3
      [
        {"text": "", "color": Appstyle.neutral200, "action": "NEW_CLIENT", "shortcut": "C", "iconPath": "assets/icons/nouveau_client_icon.png", "iconColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": l10n.clear, "action": "CLEAR", "shortcut": "", "color": Appstyle.danger, "textColor": Colors.white, "icon": Icons.clear, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "1", "color": Appstyle.Tblanc, "textColor": Colors.black, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "2", "color": Appstyle.Tblanc, "textColor": Colors.black, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "3", "color": Appstyle.Tblanc, "textColor": Colors.black, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": l10n.cancel, "action": "SUPPRIMER_CAISSE", "shortcut": "F9", "flex": 2, "color": Appstyle.gris, "textColor": Colors.white, "icon": Icons.cancel, "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8), "iconRight": !isRTL}
          ,  {
        "text": l10n.quickEntry,
        "action": "QUICK_ENTRY",
        "shortcut": "E",
        "flex": 2,
        "color": Appstyle.blueC,
        "textColor": Colors.white,
        "icon": Icons.add_business,
        "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        "iconRight": !isRTL
      }


      ],
      // LIGNE 4
      [

        {"text": "", "color": Appstyle.neutral200, "action": "NEW_PRODUCT", "shortcut": "N", "iconPath": "assets/icons/nouveau_produit_icon.png", "iconColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "", "color": Appstyle.neutral200, "action": "REMISE", "shortcut": "Ctr+R", "iconPath": "assets/icons/cardwidget/remise_icon.png", "iconColor": Appstyle.Tnoir, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "0", "color": Appstyle.Tblanc, "textColor": Colors.black, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": ".", "color": Appstyle.Tblanc, "textColor": Colors.black, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": "C", "color": Appstyle.warning, "textColor": Colors.white, "icon": Icons.backspace, "padding": EdgeInsets.symmetric(vertical: 18)},
        {"text": l10n.encaisserBLSC, "action": "ENCAISSEMENT_BLSC", "shortcut": "F5", "flex": 2, "color": Appstyle.green, "textColor": Colors.white, "icon": Icons.receipt_long, "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8), "iconRight": !isRTL}
        ,  {
        "text": "PACK",
        "action": "PACK",
        "shortcut": "Ctrl+P",
        "flex":2,
        "color": Appstyle.indigo,
        "textColor": Colors.white,
        "icon": Icons.all_inbox,
        "padding": EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        "iconRight": !isRTL
      }

      ],

    ];

    return Directionality(
      textDirection: textDirection,
      child: Column(
        children: buttons.map((line) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              textDirection: textDirection,
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
                      shortcutLabel: btn["shortcut"],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}