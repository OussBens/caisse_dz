import 'package:flutter/material.dart';
import '../../../data/models/histore.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/detail_widget.dart';
import '../base_dialog.dart';

Future<void> HistoriqueDetail(
    BuildContext context,
    Historique historique,
    ) async {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width: 1100,
        height: 600,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/sidebar/historique_icon.png",
                  width: 34,
                  height: 34,
                  color: Appstyle.violet,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      historique.code,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.year} : ${historique.dateCree.year}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    _getTranslatedOperation(historique.oper, l10n),
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.violet,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              detailsection(l10n.generalInformation),
              detailwrap([
                detailinfo("ID", historique.id.toString()),
                detailinfo(l10n.operationOn, _getTranslatedType(historique.type, l10n)),
                detailinfo(l10n.operation, _getTranslatedOperation(historique.oper, l10n)),
                detailinfo(l10n.code, historique.code),
              ]),

              detailsection(l10n.description),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  // La description réelle est stockée dans `desc` (les
                  // créations d'historique renseignent ce champ) ; `observation`
                  // reste presque toujours nul.
                  historique.desc ?? historique.observation ?? "",
                  style: Appstyle.textSB,
                ),
              ),

              detailsection(l10n.audit),
              detailwrap([
                detailinfo(l10n.createdBy, historique.creeParCode),
                detailinfo(l10n.creatorCode, historique.creeParCode),
                detailinfo(
                  l10n.createdAt,
                  "${historique.dateCree.day}/${historique.dateCree.month}/${historique.dateCree.year}",
                ),
                detailinfo(
                  l10n.time,
                  "${historique.dateCree.hour.toString().padLeft(2, '0')}:${historique.dateCree.minute.toString().padLeft(2, '0')}",
                ),
              ]),
            ],
          ),
        ),

        // ================= FOOTER =================
        footer: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.close),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

String _getTranslatedOperation(String oper, AppLocalizations l10n) {
  switch (oper) {
    case 'insertion':
      return l10n.insertion;
    case 'modification':
      return l10n.modification;
    case 'suppression':
      return l10n.suppression;
    case 'login':
      return l10n.login;
    case 'logout':
      return l10n.logout;
    default:
      return oper;
  }
}

String _getTranslatedType(String type, AppLocalizations l10n) {
  switch (type) {
    case 'produit':
      return l10n.produit;
    case 'client':
      return l10n.client;
    case 'fournisseur':
      return l10n.fournisseur;
    case 'caisse':
      return l10n.caisse;
    case 'panier':
      return l10n.panier;
    case 'versement':
      return l10n.versement;
    case 'transfert':
      return l10n.transfert;
    case 'zakat':
      return l10n.zakat;
    case 'utilisateur':
      return l10n.utilisateur;
    case 'role':
      return l10n.role;
    case 'magasin':
      return l10n.magasin;
    case 'categorie':
      return l10n.categorie;
    case 'souscategorie':
      return l10n.sousCategorie;
    case 'pack':
      return l10n.pack;
    case 'remise':
      return l10n.remise;
    case 'besoin':
      return l10n.besoin;
    case 'besoinList':
    case 'besoin_list':
      return l10n.besoinList;
    case 'historique':
      return l10n.historique;
    default:
      return type;
  }
}