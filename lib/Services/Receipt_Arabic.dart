import 'package:intl/intl.dart';

import 'receipt_print_helper.dart' show barcodeMarker;
import 'package:caisse_dz/core/utilis/number_format.dart';

class ReceiptArabic {
  static const int defaultLineWidth = 60;

  static String generate({
    required dynamic caisse,
    required dynamic client,
    required dynamic panierNumber,
    required String magasinName,
    required String caissierName,
    required double verse,
    required double reste,
    String? telephone,
    String? messagePersonnalise,
    int lineWidth = defaultLineWidth,
    double? pointsGagnes,
  }) {
    final buffer = StringBuffer();
    final printDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final ticketDate = DateFormat('dd/MM/yyyy HH:mm').format(caisse.date as DateTime);

    // A. اسم المتجر
    buffer.writeln('');
    buffer.writeln(_center(magasinName.toUpperCase(), lineWidth));

    // B. الهاتف (بدل العنوان)
    if (telephone != null && telephone.isNotEmpty) {
      buffer.writeln(_center('هاتف: $telephone', lineWidth));
    }
    buffer.writeln('');

    // C. رقم التذكرة / التاريخ / العميل
    buffer.writeln(_rtl('رقم التذكرة', panierNumber.toString(), lineWidth));
    buffer.writeln(_rtl('تاريخ', ticketDate, lineWidth));
    buffer.writeln(_rtl('العميل', client.nom, lineWidth));
    buffer.writeln('');

    // D. الباركود الخاص بالسلة، في الوسط
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
    buffer.writeln(
        _padLeft('الإجمالي', totalW) +
            _padLeft('السعر', priceW) +
            _padLeft('الكمية', qtyW) +
            _padLeft('المنتج', nameW)
    );

    buffer.writeln(_divider(lineWidth));

    /// F. المنتجات
    for (var p in caisse.produits) {
      final name = _fix(p.nom, nameW);
      final qty = p.qte.toInt().toString();
      final price = NumberFormatUtil.formatMontant(p.prix, decimales: 2);
      final total = NumberFormatUtil.formatMontant((p.prix * p.qte), decimales: 2);

      buffer.writeln(
          _padLeft(total, totalW) +
              _padLeft(price, priceW) +
              _padLeft(qty, qtyW) +
              _padLeft(name, nameW)
      );
    }

    buffer.writeln(_divider(lineWidth));
    buffer.writeln('');

    // G. الخصم (إن وجد)
    if (caisse.remiseActive == true && caisse.remise > 0) {
      buffer.writeln(_rtl('المجموع قبل الخصم', NumberFormatUtil.formatMontant(caisse.totalAchat, decimales: 2), lineWidth));
      final remiseLabel = (caisse.remisenom != null && (caisse.remisenom as String).isNotEmpty)
          ? 'الخصم (${caisse.remisenom})'
          : 'الخصم';
      buffer.writeln(_rtl(remiseLabel, '-${NumberFormatUtil.formatMontant(caisse.remise, decimales: 2)}', lineWidth));
    }

    // H. عدد المواد / الإجمالي النهائي
    // ✅ Chaque champ sur sa propre ligne : les combiner via _twoCol n'est
    // pas garanti de tenir dans lineWidth (montant/nom de caisse variables),
    // ce qui provoquait un retour à la ligne côté PDF.
    buffer.writeln(_rtl('عدد المواد', caisse.nombreArticles.toString(), lineWidth));
    buffer.writeln(_rtl('الإجمالي', NumberFormatUtil.formatMontant(caisse.total, decimales: 2), lineWidth));
    buffer.writeln(_rtl('مدفوع', NumberFormatUtil.formatMontant(verse, decimales: 2), lineWidth));
    buffer.writeln(_rtl('الباقي', NumberFormatUtil.formatMontant(reste, decimales: 2), lineWidth));
    if (pointsGagnes != null && pointsGagnes > 0) {
      buffer.writeln(_rtl('نقاط الولاء المكتسبة', NumberFormatUtil.formatMontant(pointsGagnes, decimales: 2), lineWidth));
    }

    buffer.writeln(_divider(lineWidth));
    buffer.writeln('');

    // I. أمين الصندوق / J. الصندوق + تاريخ الطباعة
    buffer.writeln(_rtl('أمين الصندوق', caissierName, lineWidth));
    buffer.writeln(_rtl('الصندوق', caisse.caisse, lineWidth));
    buffer.writeln(_rtl('طبع في', printDate, lineWidth));

    buffer.writeln(_divider(lineWidth));
    buffer.writeln('');

    // رسالة الشكر
    if (messagePersonnalise != null && messagePersonnalise.isNotEmpty) {
      buffer.writeln(_center(messagePersonnalise, lineWidth));
    } else {
      buffer.writeln(_center('شكراً لزيارتكم', lineWidth));
      buffer.writeln(_center('نراكم قريباً', lineWidth));
    }
    buffer.writeln('');

    return buffer.toString();
  }

  static String _rtl(String label, String value, int lineWidth) {
    final l = ': $label';
    final space = lineWidth - l.length - value.length;
    return space > 0 ? value + ' ' * space + l : '$value $l';
  }

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
