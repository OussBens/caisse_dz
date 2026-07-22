import 'package:intl/intl.dart';

class ReceiptArabic {
  static const int lineWidth = 60;

  static String generate({
    required dynamic caisse,
    required dynamic client,
    required int panierNumber,
    required String magasinName,
    required String caissierName,
    required double verse,
    required double reste,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(now);

    buffer.writeln('');
    buffer.writeln(_center(magasinName.toUpperCase()));
    buffer.writeln('');

    buffer.writeln(_rtl('تاريخ', date));
    buffer.writeln(_rtl('رقم التذكرة', panierNumber.toString()));
    buffer.writeln(_rtl('الصندوق', caisse.nom));
    buffer.writeln(_rtl('أمين الصندوق', caissierName));

    buffer.writeln(_divider());

    buffer.writeln(_rtl('العميل', client.nom));

    buffer.writeln(_divider());
    buffer.writeln('');

    /// HEADER
    buffer.writeln(
        _padLeft('المنتج', 14) +
            _padLeft('الكمية', 10) +
            _padLeft('السعر', 14) +
            _padLeft('الإجمالي', 14)
    );

    buffer.writeln(_divider());

    /// PRODUCTS
    for (var p in caisse.produits) {
      final name = _fix(p.nom);
      final qty = p.qte.toInt().toString();
      final price = p.prix.toStringAsFixed(2);
      final total = (p.prix * p.qte).toStringAsFixed(2);

      buffer.writeln(
          _padLeft(total, 14) +
              _padLeft(price, 10) +
              _padLeft(qty, 14) +
              _padLeft(name, 14)
      );
    }

    buffer.writeln(_divider());
    buffer.writeln('');

    buffer.writeln(_rtl('الإجمالي', caisse.total.toStringAsFixed(2)));
    buffer.writeln(_rtl('مدفوع', verse.toStringAsFixed(2)));
    buffer.writeln(_rtl('الباقي', reste.toStringAsFixed(2)));

    buffer.writeln(_divider());
    buffer.writeln('');
    buffer.writeln(_center('شكراً لزيارتكم'));
    buffer.writeln(_center('نراكم قريباً'));
    buffer.writeln('');

    return buffer.toString();
  }

  static String _rtl(String label, String value) {
    final l = ': $label';
    final space = lineWidth - l.length - value.length;
    return space > 0 ? value + ' ' * space + l : '$value $l';
  }

  static String _padLeft(String text, int w) =>
      text.length >= w ? text.substring(0, w) : ' ' * (w - text.length) + text;

  static String _center(String text) {
    final space = (lineWidth - text.length) ~/ 2;
    return ' ' * space + text;
  }

  static String _divider() => '-' * lineWidth;

  static String _fix(String text) =>
      text.length > 14 ? text.substring(0, 14) : text;
}