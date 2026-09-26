import 'dart:typed_data';

import 'package:caisse_dz/Services/EntrepriseParam.dart';
import 'package:caisse_dz/Services/ImprimanteParam.dart';
import 'package:caisse_dz/Services/LogoService.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/PannierReprint.dart';
import 'package:caisse_dz/Services/Receipt_Arabic.dart';
import 'package:caisse_dz/Services/Receipt_EN_FR.dart';
import 'package:caisse_dz/Services/pdf_generator_ar.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/receipt_print_helper.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/status_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/pannier.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import '../../../core/dialog/pannier/pannier_detail.dart'; // Pour showProductsListDialog

class AfficheurPanier extends StatelessWidget {
  final Pannier pannier;
  final double verse;
  final double reste;
  final int nbrVersement;
  final bool hasRetour;
  final VoidCallback? onDetails;

  const AfficheurPanier({
    super.key,
    required this.pannier,
    required this.verse,
    required this.reste,
    required this.nbrVersement,
    this.hasRetour = false,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = _formatDate(pannier.date);
    final heure = _formatHeure(pannier.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 🔹 Icône
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(
              Icons.shopping_basket,
              size: 36,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 10),

          /// 🔹 Infos Panier
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${l10n.panier} N° ${pannier.code}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text("${l10n.client} : ${pannier.client_code ?? ""}",
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _etatBadge(l10n),
                    if (hasRetour) ...[
                      const SizedBox(width: 6),
                      StatusBadge(text: l10n.hasReturn, color: Colors.orange),
                    ],
                  ],
                ),
              ],
            ),
          ),

          /// 🔹 Stats
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard(l10n.total, pannier.montant, Colors.deepPurple, l10n),
                _statCard(l10n.paid, verse, Colors.green, l10n),
                _statCard(l10n.remaining, reste, Colors.blue, l10n),
                _statCardInt(l10n.numberOfPayments, nbrVersement, Colors.orange, l10n),
              ],
            ),
          ),

          /// 🔹 Infos droite
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.calendar_today, "${l10n.date} : $date"),
                _infoLine(Icons.access_time, "${l10n.time} : $heure"),
                _infoLine(Icons.person, "${l10n.caissier} : ${pannier.caissier_code}"),
              ],
            ),
          ),

          /// 🔹 Boutons d'action
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton Détails
              ElevatedButton(
                onPressed: onDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.violet,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 40),
                ),
                child: Text(
                  l10n.details,
                  style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                ),
              ),
              const SizedBox(height: 8),
              // ✅ NOUVEAU BOUTON : Liste des produits
              ElevatedButton(
                onPressed: () {
                  showProductsListDialog(context, pannier, l10n);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.crevete,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.list, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.productList,
                      style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ✅ Réimprimer le ticket (thermique) ou le BL (PDF) déjà
              // enregistré pour ce panier, selon son type.
              ElevatedButton(
                onPressed: () => _reimprimerPannier(context, pannier, verse, reste, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.print, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.print,
                      style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, double value, Color color, AppLocalizations l10n) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            "${NumberFormatUtil.formatMontant(value, decimales: 0)} ${l10n.currency}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCardInt(String label, int value, Color color, AppLocalizations l10n) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            "$value",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _etatBadge(AppLocalizations l10n) {
    Color color = pannier.etat ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        pannier.etat ? l10n.actif : l10n.inactif,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";
}

String _formatHeure(DateTime date) {
  return "${date.hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')}";
}

/// Réimprime le document déjà émis pour ce panier : ticket thermique si
/// [pannier.typepannier] == "Ticket", sinon facture PDF (BL / BL_SC), en
/// reconstruisant les données depuis les produits enregistrés du panier.
Future<void> _reimprimerPannier(
  BuildContext context,
  Pannier pannier,
  double verse,
  double reste,
  AppLocalizations l10n,
) async {
  final caisse = await PannierReprintService.buildCaisseState(pannier);
  final client = await PannierReprintService.resolveClient(pannier.client_code);
  final entreprise = await EntrepriseParamServices.getEntrepriseParam();
  final languageCode = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

  if (pannier.typepannier == "Ticket") {
    final imprimanteParam = await ImprimanteParamServices.getImprimanteParam();
    final receiptText = languageCode == 'ar'
        ? ReceiptArabic.generate(
            caisse: caisse,
            client: client,
            panierNumber: pannier.code,
            magasinName: entreprise.nomBoutique,
            caissierName: pannier.caissier_code,
            verse: verse,
            reste: reste,
            telephone: entreprise.telephone,
            messagePersonnalise: entreprise.messageTicket,
            lineWidth: imprimanteParam.ligneCaracteres,
          )
        : ReceiptLatin.generate(
            caisse: caisse,
            client: client,
            panierNumber: pannier.code,
            magasinName: entreprise.nomBoutique,
            caissierName: pannier.caissier_code,
            verse: verse,
            reste: reste,
            lang: languageCode,
            telephone: entreprise.telephone,
            messagePersonnalise: entreprise.messageTicket,
            lineWidth: imprimanteParam.ligneCaracteres,
          );

    if (!context.mounted) return;
    await imprimerRecuThermique(
      context: context,
      receiptText: receiptText,
      barcodeData: pannier.code,
      l10n: l10n,
      imprimanteParam: imprimanteParam,
    );
    return;
  }

  // BL / BL_SC : réimpression via PDF (facture), même format que l'encaissement.
  final invoiceType = pannier.typepannier == "BL_SC" ? "BLSC" : "BL";
  final logoBytes = await LogoService.loadLogoBytes(entreprise.logoPath);

  Uint8List pdfBytes;
  if (languageCode == 'ar') {
    final arabicGenerator = PDFGeneratorArabic();
    await arabicGenerator.loadFonts();
    pdfBytes = await arabicGenerator.generateInvoice(
      caisse: caisse,
      client: client,
      magasinName: entreprise.nomBoutique,
      caissierName: pannier.caissier_code,
      verse: verse,
      reste: reste,
      invoiceNumber: pannier.code,
      invoiceType: invoiceType,
      adresse: entreprise.adresse,
      logoBytes: logoBytes,
    );
  } else {
    pdfBytes = await PDFGeneratorLatin.generateInvoice(
      caisse: caisse,
      client: client,
      magasinName: entreprise.nomBoutique,
      caissierName: pannier.caissier_code,
      verse: verse,
      reste: reste,
      invoiceNumber: pannier.code,
      invoiceType: invoiceType,
      l10n: l10n,
      adresse: entreprise.adresse,
      logoBytes: logoBytes,
    );
  }

  if (!context.mounted) return;
  final action = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PDFPreviewDialog(
      pdfBytes: pdfBytes,
      l10n: l10n,
      onPrint: () => Navigator.pop(context, 'print'),
      onSave: () => Navigator.pop(context, 'save'),
      onShare: () => Navigator.pop(context, 'share'),
      onCancel: () => Navigator.pop(context, 'cancel'),
    ),
  );

  if (action == null || action == 'cancel') return;

  if (action == 'print') {
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    if (!context.mounted) return;
    await InformationDialog(
      context: context,
      titre_type_message: l10n.success,
      titre_concerne: l10n.ticket,
      message: l10n.printSuccess,
    );
    return;
  }

  if (action == 'save' || action == 'share') {
    final fileName = 'Facture_${pannier.code}.pdf';
    final file = await PDFGeneratorLatin.savePDF(pdfBytes, fileName);

    if (action == 'share') {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.invoiceShared,
        subject: l10n.invoice,
      );
    } else {
      if (!context.mounted) return;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.success,
        titre_concerne: l10n.invoice,
        message: ('${l10n.invoiceSaved}: ${file.path}'),
      );
    }
  }
}