import 'package:intl/intl.dart';

import 'receipt_print_helper.dart' show barcodeMarker;
import 'package:caisse_dz/core/utilis/number_format.dart';

class ReceiptLatin {
  static const int defaultLineWidth = 60;

  static String generate({
    required dynamic caisse,
    required dynamic client,
    required dynamic panierNumber,
    required String magasinName,
    required String caissierName,
    required double verse,
    required double reste,
    required String lang, // "fr" or "en"
    String? telephone,
    String? messagePersonnalise,
    int lineWidth = defaultLineWidth,
    double? pointsGagnes,
  }) {
    final buffer = StringBuffer();
    final printDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final ticketDate = DateFormat('dd/MM/yyyy HH:mm').format(caisse.date as DateTime);

    /// Labels
    final labels = lang == "fr"
        ? {
      "date": "Date",
      "ticket": "Ticket N",
      "phone": "Tél",
      "caisse": "Caisse",
      "cashier": "Caissier",
      "client": "Client",
      "product": "Produit",
      "qty": "Qté",
      "price": "Prix",
      "total": "Total",
      "subtotal": "Total avant remise",
      "discount": "Remise",
      "paid": "Payé",
      "change": "Reste",
      "points": "Points fidélité gagnés",
      "articles": "Nb. articles",
      "printedOn": "Imprimé le",
      "thanks": "Merci pour votre visite",
      "bye": "À bientôt"
    }
        : {
      "date": "Date",
      "ticket": "Ticket N",
      "phone": "Tel",
      "caisse": "Register",
      "cashier": "Cashier",
      "client": "Client",
      "product": "Product",
      "qty": "Qty",
      "price": "Price",
      "total": "Total",
      "subtotal": "Total before discount",
      "discount": "Discount",
      "paid": "Paid",
      "change": "Change",
      "points": "Loyalty points earned",
      "articles": "Items",
      "printedOn": "Printed on",
      "thanks": "Thank you for your visit",
      "bye": "See you soon"
    };

    // A. Nom du magasin
    buffer.writeln('');
    buffer.writeln(_center(magasinName.toUpperCase(), lineWidth));

    // B. Téléphone (remplace l'adresse)
    if (telephone != null && telephone.isNotEmpty) {
      buffer.writeln(_center('${labels["phone"]!}: $telephone', lineWidth));
    }
    buffer.writeln('');

    // C. Ticket N / Date / Client
    buffer.writeln(_ltr(labels["ticket"]!, panierNumber.toString(), lineWidth));
    buffer.writeln(_ltr(labels["date"]!, ticketDate, lineWidth));
    buffer.writeln(_ltr(labels["client"]!, client.nom, lineWidth));
    buffer.writeln('');

    // D. Code barre du pannier, centré
    buffer.writeln(barcodeMarker);
    buffer.writeln(_center(panierNumber.toString(), lineWidth));
    buffer.writeln('');

    buffer.writeln(_divider(lineWidth));

    // ✅ Largeurs de colonnes calculées à partir de lineWidth (voir
    // ImprimanteParam.ligneCaracteres : 29 en 58mm, 41 en 80mm, calé sur la
    // largeur imprimable réelle du PDF) plutôt que des valeurs fixes, pour
    // que qté/prix/total ne soient jamais renvoyés à la ligne suivante.
    final qtyW = lineWidth <= 32 ? 4 : 5;
    final priceW = lineWidth <= 32 ? 8 : 10;
    final totalW = lineWidth <= 32 ? 9 : 11;
    final nameW = lineWidth - qtyW - priceW - totalW;

    /// E. HEADER
    // ✅ Qté en premier, alignée à gauche (comme sa valeur) : un padLeft
    // ici collerait le dernier chiffre de la quantité au premier caractère
    // du nom du produit, sans espace entre les deux colonnes.
    buffer.writeln(
        _padRight(labels["qty"]!, qtyW) +
            _padRight(labels["product"]!, nameW) +
            _padLeft(labels["price"]!, priceW) +
            _padLeft(labels["total"]!, totalW)
    );

    buffer.writeln(_divider(lineWidth));

    /// F. PRODUITS
    for (var p in caisse.produits) {
      final name = _fix(p.nom, nameW);
      final qty = p.qte.toInt().toString();
      final price = NumberFormatUtil.formatMontant(p.prix, decimales: 2);
      final total = NumberFormatUtil.formatMontant((p.prix * p.qte), decimales: 2);

      buffer.writeln(
          _padRight(qty, qtyW) +
              _padRight(name, nameW) +
              _padLeft(price, priceW) +
              _padLeft(total, totalW)
      );
    }

    buffer.writeln(_divider(lineWidth));
    buffer.writeln('');

    // G. Remise (si active)
    if (caisse.remiseActive == true && caisse.remise > 0) {
      buffer.writeln(_ltr(labels["subtotal"]!, NumberFormatUtil.formatMontant(caisse.totalAchat, decimales: 2), lineWidth));
      final remiseLabel = (caisse.remisenom != null && (caisse.remisenom as String).isNotEmpty)
          ? '${labels["discount"]} (${caisse.remisenom})'
          : labels["discount"]!;
      buffer.writeln(_ltr(remiseLabel, '-${NumberFormatUtil.formatMontant(caisse.remise, decimales: 2)}', lineWidth));
    }

    // H. Nombre d'articles / Total final
    // ✅ Chaque champ sur sa propre ligne (label + valeur) : les combiner
    // sur une ligne via _twoCol n'est pas garanti de tenir dans lineWidth
    // (nom de caisse ou montant variables), ce qui provoquait un retour à
    // la ligne côté PDF.
    buffer.writeln(_ltr(labels["articles"]!, caisse.nombreArticles.toString(), lineWidth));
    buffer.writeln(_ltr(labels["total"]!, NumberFormatUtil.formatMontant(caisse.total, decimales: 2), lineWidth));
    buffer.writeln(_ltr(labels["paid"]!, NumberFormatUtil.formatMontant(verse, decimales: 2), lineWidth));
    buffer.writeln(_ltr(labels["change"]!, NumberFormatUtil.formatMontant(reste, decimales: 2), lineWidth));
    if (pointsGagnes != null && pointsGagnes > 0) {
      buffer.writeln(_ltr(labels["points"]!, NumberFormatUtil.formatMontant(pointsGagnes, decimales: 2), lineWidth));
    }

    buffer.writeln(_divider(lineWidth));
    buffer.writeln('');

    // I. Caissier / J. Caisse + date d'impression
    buffer.writeln(_ltr(labels["cashier"]!, caissierName, lineWidth));
    buffer.writeln(_ltr(labels["caisse"]!, caisse.caisse, lineWidth));
    buffer.writeln(_ltr(labels["printedOn"]!, printDate, lineWidth));

    buffer.writeln(_divider(lineWidth));
    buffer.writeln('');

    // Message de remerciement
    if (messagePersonnalise != null && messagePersonnalise.isNotEmpty) {
      buffer.writeln(_center(messagePersonnalise, lineWidth));
    } else {
      buffer.writeln(_center(labels["thanks"]!, lineWidth));
      buffer.writeln(_center(labels["bye"]!, lineWidth));
    }
    buffer.writeln('');

    return buffer.toString();
  }

  static String _ltr(String label, String value, int lineWidth) {
    final l = '$label :';
    final space = lineWidth - l.length - value.length;
    return space > 0 ? l + ' ' * space + value : '$l $value';
  }

  static String _padRight(String text, int w) =>
      text.length >= w ? text.substring(0, w) : text + ' ' * (w - text.length);

  static String _padLeft(String text, int w) =>
      text.length >= w ? text.substring(0, w) : ' ' * (w - text.length) + text;

  static String _center(String text, int lineWidth) {
    final space = (lineWidth - text.length) ~/ 2;
    return space > 0 ? ' ' * space + text : text;
  }

  static String _divider(int lineWidth) => '-' * lineWidth;

  static String _fix(String text, int width) =>
      text.length > width ? text.substring(0, width) : text;
}
