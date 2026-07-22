import 'package:intl/intl.dart';

class ReceiptLatin {
  static const int lineWidth = 60;

  static String generate({
    required dynamic caisse,
    required dynamic client,
    required int panierNumber,
    required String magasinName,
    required String caissierName,
    required double verse,
    required double reste,
    required String lang, // "fr" or "en"
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(now);

    /// Labels
    final labels = lang == "fr"
        ? {
      "date": "Date",
      "ticket": "Ticket",
      "caisse": "Caisse",
      "cashier": "Caissier",
      "client": "Client",
      "product": "Produit",
      "qty": "Qté",
      "price": "Prix",
      "total": "Total",
      "paid": "Payé",
      "change": "Reste",
      "thanks": "Merci pour votre visite",
      "bye": "À bientôt"
    }
        : {
      "date": "Date",
      "ticket": "Ticket",
      "caisse": "Register",
      "cashier": "Cashier",
      "client": "Client",
      "product": "Product",
      "qty": "Qty",
      "price": "Price",
      "total": "Total",
      "paid": "Paid",
      "change": "Change",
      "thanks": "Thank you for your visit",
      "bye": "See you soon"
    };

    buffer.writeln('');
    buffer.writeln(_center(magasinName.toUpperCase()));
    buffer.writeln('');

    buffer.writeln(_ltr(labels["date"]!, date));
    buffer.writeln(_ltr(labels["ticket"]!, panierNumber.toString()));
    buffer.writeln(_ltr(labels["caisse"]!, caisse.nom));
    buffer.writeln(_ltr(labels["cashier"]!, caissierName));

    buffer.writeln(_divider());

    buffer.writeln(_ltr(labels["client"]!, client.nom));

    buffer.writeln(_divider());
    buffer.writeln('');

    /// HEADER
    buffer.writeln(
        _padRight(labels["product"]!, 14) +
            _padRight(labels["qty"]!, 10) +
            _padRight(labels["price"]!, 14) +
            _padRight(labels["total"]!, 14)
    );

    buffer.writeln(_divider());

    /// PRODUCTS
    for (var p in caisse.produits) {
      final name = _fix(p.nom);
      final qty = p.qte.toInt().toString();
      final price = p.prix.toStringAsFixed(2);
      final total = (p.prix * p.qte).toStringAsFixed(2);

      buffer.writeln(
          _padRight(name, 14) +
              _padRight(qty, 10) +
              _padRight(price, 14) +
              _padRight(total, 14)
      );
    }

    buffer.writeln(_divider());
    buffer.writeln('');

    buffer.writeln(_ltr(labels["total"]!, caisse.total.toStringAsFixed(2)));
    buffer.writeln(_ltr(labels["paid"]!, verse.toStringAsFixed(2)));
    buffer.writeln(_ltr(labels["change"]!, reste.toStringAsFixed(2)));

    buffer.writeln(_divider());
    buffer.writeln('');
    buffer.writeln(_center(labels["thanks"]!));
    buffer.writeln(_center(labels["bye"]!));
    buffer.writeln('');

    return buffer.toString();
  }

  static String _ltr(String label, String value) {
    final l = '$label :';
    final space = lineWidth - l.length - value.length;
    return space > 0 ? l + ' ' * space + value : '$l $value';
  }

  static String _padRight(String text, int w) =>
      text.length >= w ? text.substring(0, w) : text + ' ' * (w - text.length);

  static String _center(String text) {
    final space = (lineWidth - text.length) ~/ 2;
    return ' ' * space + text;
  }

  static String _divider() => '-' * lineWidth;

  static String _fix(String text) =>
      text.length > 14 ? text.substring(0, 14) : text;
}