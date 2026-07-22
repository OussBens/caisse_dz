import 'dart:math';
import 'package:caisse_dz/data/models/produit.dart';

class ReceiptScannerWindows {

  static bool isDeliveryNote(String ocrText) {
    int hits = 0;
    final seen = <String>{};
    void hit(String tag) { if (seen.add(tag)) hits++; }

    for (final rawLine in ocrText.split('\n')) {
      final line  = rawLine.trim();
      final upper = line.toUpperCase();

      if (RegExp(r'\bBL\d{5,}\b').hasMatch(upper))                        hit('BL_NUM');
      if (upper.contains('BON') && upper.contains('LIVRAISON'))            hit('BON_LIVRAISON');
      if (upper.contains('BON DE LIVRAISON'))                              hit('BON_LIVRAISON');
      if (upper.contains('FACTURE'))                                       hit('FACTURE');
      if (upper.contains('DESIGNATION') || upper.contains('DÉSIGNATION')) hit('DESIGNATION');
      if (upper.contains('MONTANT TTC'))                                   hit('MONTANT_TTC');
      if (upper.contains('MONTANT HT'))                                    hit('MONTANT_HT');
      if (upper.contains('PU HT'))                                         hit('PU_HT');
      if (upper.contains('COLISAGE'))                                      hit('COLISAGE');
      if (upper.contains('PRIX V TTC'))                                    hit('PRIX_TTC');
      if (upper.contains('NET A PAYER'))                                   hit('NET_PAYER');
      if (RegExp(r'\b\d+\s*[xX×]\s*\d+\b').hasMatch(line))               hit('COLISAGE_DATA');
      if (line.contains('فاتورة'))                                         hit('AR_FACTURE');
      if (line.contains('الكمية'))                                         hit('AR_QTE');
      if (line.contains('السعر'))                                          hit('AR_PRIX');
      if (line.contains('المجموع'))                                        hit('AR_TOTAL');

      if (line.contains('|') && line.contains('---'))                     hit('MARKDOWN_TABLE');
      if (line.startsWith('|') && line.endsWith('|') && line.contains('|')) hit('TABLE_ROW');
    }

    print('📋 Delivery-note score: $hits hits [${seen.join(', ')}]');


    return hits >= 2 || seen.contains('MARKDOWN_TABLE');
  }

  static List<ReceiptItem> parseMarkdownTableDeliveryNote(
      String text, List<Produit> products) {
    print('=== PARSING MARKDOWN TABLE DELIVERY NOTE ===');

    final items = <ReceiptItem>[];
    final lines = text.split('\n');

    bool inTable = false;
    List<String> headers = [];
    int headerRowIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.contains('|') &&
          (line.contains('N°') || line.contains('CODE') ||
              line.contains('Nom') || line.contains('Qté') ||
              line.contains('Prix') || line.contains('MONTANT') ||
              line.contains('DÉSIGNATION') || line.contains('DESIGNATION'))) {
        inTable = true;
        headerRowIndex = i;
        headers = line.split('|').map((s) => s.trim().toUpperCase()).toList();
        print('Table headers: $headers');
        continue;
      }

      if (line.contains('|') && line.contains('---')) {
        continue;
      }

      if (inTable && line.contains('|') && !line.contains('---') && i > headerRowIndex) {
        final cells = line.split('|').map((s) => s.trim()).toList();

        if (cells.length < 5) continue;

        int nomIdx = -1, qteIdx = -1, prixIdx = -1, montantIdx = -1;

        for (int j = 0; j < headers.length && j < cells.length; j++) {
          final header = headers[j].toUpperCase();

          if (header.contains('NOM') || header.contains('DÉSIGNATION') ||
              header == 'DESIGNATION' || header.contains('ARTICLE')) {
            nomIdx = j;
          }
          else if (header == 'QTÉ' || header == 'QTE' || header == 'QTÉ' || header.contains('QUANTITÉ')) {

            if (qteIdx == -1) {
              qteIdx = j;
            }
          }
          else if (header == 'PRIX' || header.contains('PU') || header == 'PRIX' ||
              header.contains('PRIX V TTC') || (header.contains('PRIX') && !header.contains('MONTANT'))) {
            prixIdx = j;
          }
          else if (header == 'MONTANT HT' || header == 'MONTANT TTC' ||
              header.contains('MONTANT') || header == 'TOTAL') {
            montantIdx = j;
          }
        }

        if (qteIdx == -1) {
          for (int j = 0; j < cells.length; j++) {
            if (j < cells.length && cells[j].trim().isNotEmpty) {
              final val = _parseNumber(cells[j]);

              if (val > 0 && val < 1000 && val == val.truncateToDouble()) {
                qteIdx = j;
                break;
              }
            }
          }
        }

        if (nomIdx == -1) nomIdx = 2;     // Product name is usually column 3
        if (qteIdx == -1) qteIdx = 3;     // Quantity is usually column 4
        if (prixIdx == -1) prixIdx = 6;   // Unit price is usually column 7
        if (montantIdx == -1) montantIdx = 8; // Total is usually column 9

        print('Column mapping - Nom:$nomIdx, Qte:$qteIdx, Prix:$prixIdx, Montant:$montantIdx');

        if (nomIdx < cells.length && nomIdx != -1) {
          String productName = cells[nomIdx].trim();

          productName = productName
              .replaceAll(RegExp(r'^\d+\s*'), '')
              .replaceAll(RegExp(r'^[|\\/\s]+'), '')
              .trim();

          if (productName.isEmpty || productName == '---' || productName.length < 3) continue;

          if (productName.contains('N°') || productName.contains('CODE') ||
              productName == 'Désignation' || productName == 'DESIGNATION') continue;

          double quantity = 1.0;
          if (qteIdx < cells.length && qteIdx != -1 && cells[qteIdx].isNotEmpty) {
            quantity = _parseNumber(cells[qteIdx]);
            if (quantity == 0) quantity = 1.0;
            print('  Quantity for "$productName": ${cells[qteIdx]} → $quantity');
          }

          double unitPrice = 0.0;
          if (prixIdx < cells.length && prixIdx != -1 && cells[prixIdx].isNotEmpty) {
            unitPrice = _parseNumber(cells[prixIdx]);
          }

          double totalPrice = 0.0;
          if (montantIdx < cells.length && montantIdx != -1 && cells[montantIdx].isNotEmpty) {
            totalPrice = _parseNumber(cells[montantIdx]);
          }

          if (totalPrice == 0 && quantity > 0 && unitPrice > 0) {
            totalPrice = quantity * unitPrice;
          }
          if (unitPrice == 0 && totalPrice > 0 && quantity > 0) {
            unitPrice = totalPrice / quantity;
          }

          if (quantity > 0 && totalPrice > 0 && productName.isNotEmpty) {
            final matchedName = findBestMatch(productName, products);
            final matchedCode = matchedName.isNotEmpty
                ? (products.where((p) => p.nom == matchedName).firstOrNull?.code ?? '')
                : '';

            items.add(ReceiptItem(
              originalName: productName,
              matchedProductName: matchedName,
              matchedProductCode: matchedCode,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
              confidence: matchedName.isNotEmpty ? 0.85 : 0.6,
            ));

            print('  ✓ "$productName" | qty=$quantity | unit=$unitPrice | total=$totalPrice');
          }
        }
      }
    }

    print('=== TABLE PARSER FOUND ${items.length} ITEMS ===');
    return items;
  }

  static double _parseNumber(String s) {
    if (s.isEmpty) return 0.0;

    // Remove DA, DZD, etc.
    String cleaned = s.replaceAll(RegExp(r'[^\d\s,.-]'), '');
    // Remove spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    // Handle French number format (space as thousand separator)
    cleaned = cleaned.replaceAll(RegExp(r'(\d)\s(\d{3})'), r'$1$2');
    // Replace comma with dot for decimal
    cleaned = cleaned.replaceAll(',', '.');

    return double.tryParse(cleaned) ?? 0.0;
  }

  static List<ReceiptItem> parseDeliveryNoteText(
      String text, List<Produit> products) {
    if (text.trim().isEmpty) return [];
    print('=== LOCAL DELIVERY NOTE PARSER ===');

    final footerKeywords = [
      'Nb.U.', 'POIDS', 'TOTAL', 'Versement', 'Reste', 'Solde',
      'Préparateur', 'Ancien Solde', 'Solde au'
    ];

    String normaliseNum(String s) {
      s = s.replaceAllMapped(
          RegExp(r'(\d)\s(\d{3})(?!\d)'), (m) => '${m.group(1)}${m.group(2)}');
      return s.replaceAll(',', '.');
    }

    double? pn(String s) => double.tryParse(normaliseNum(s.trim()));

    List<double> extractNums(String s) {
      final out = <double>[];
      for (final m in RegExp(r'[\d][\d\s]*(?:[.,]\d+)?').allMatches(s)) {
        final v = pn(m.group(0)!);
        if (v != null && v > 0) out.add(v);
      }
      return out;
    }

    final skipRx = RegExp(
      r'(BON\s*(DE\s*)?LIVRAISON|DESIGNATION|D[ÉE]SIGNATION|'
      r'N\s*[°o]\s*(RC|IF|ART|NIF)|'
      r'TOTAL\s*(TTC|HT)|NET\s*A\s*PAYER|ANCIEN\s*SOLDE|'
      r'MONTANT\s*DU\s*BON|VERSEMENT|NOUVEAU\s*SOLDE|'
      r'NOMBRE\s*DE\s*PRODUIT|ARRETE|MODE\s*DE\s*PAIEMENT|'
      r'QTE|PRIX\s*V\s*TTC|MONTANT\s*(TTC|HT)|PU\s*HT|'
      r'COLISAGE|VRAC|NIF|N\.I\.[FSA]|N\.R\.C|N\.A\.I|'
      r'MT\s*HT|TVA|R\.%|PAGE\s*\d|ERP\d|SITWANE|SIL[WV]ANE|'
      r'المجموع|الكمية|السعر|'
      r'Nb\.U\.|POIDS|Pr[ée]parateur)',
      caseSensitive: false,
    );

    final colisageRx = RegExp(r'\b(\d+)\s*[xX×]\s*(\d+)\b');
    final items = <ReceiptItem>[];

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Skip footer lines
      if (footerKeywords.any((k) => line.toUpperCase().contains(k.toUpperCase()))) {
        continue;
      }

      if (skipRx.hasMatch(line.toUpperCase())) continue;

      final cm = colisageRx.firstMatch(line);
      if (cm != null) {
        final outerQty = double.tryParse(cm.group(1)!) ?? 1.0;
        final leftPart  = line.substring(0, cm.start).trim();
        final rightPart = line.substring(cm.end).trim();

        var desig = leftPart
            .replaceAll(RegExp(r'^\d+\s*[|\\]?\s*'), '')
            .replaceAll(
            RegExp(r'\b([A-Z0-9][A-Z0-9\-]{1,20})\s+\1\b',
                caseSensitive: false), '')
            .replaceAll(RegExp(r'^\s*[A-Z0-9][A-Z0-9\-]{1,20}\s*',
            caseSensitive: false), '')
            .replaceAll(RegExp(r'[-—]{2,}'), ' ')
            .replaceAll('|', ' ')
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();

        if (desig.length < 3) continue;
        if (skipRx.hasMatch(desig.toUpperCase())) continue;

        final rightClean = rightPart
            .replaceAll(RegExp(r'\b0\b'), '')
            .replaceAll(RegExp(r'[-—|)]'), ' ');
        final rightNums = extractNums(rightClean);

        double unitPrice  = 0;
        double totalPrice = 0;

        if (rightNums.length >= 2) {
          unitPrice  = rightNums.first;
          totalPrice = rightNums.last;
          if (totalPrice > 0 && unitPrice > totalPrice && outerQty > 1) {
            final tmp = unitPrice; unitPrice = totalPrice; totalPrice = tmp;
          }
        } else if (rightNums.length == 1) {
          unitPrice  = rightNums.first;
          totalPrice = unitPrice * outerQty;
        }

        if (unitPrice <= 0 || outerQty <= 0) continue;
        if (totalPrice <= 0) totalPrice = unitPrice * outerQty;

        final codeM = RegExp(r'\b([A-Z0-9][A-Z0-9\-]{1,20})\b',
            caseSensitive: false).firstMatch(leftPart);
        final rawCode = codeM?.group(1) ?? '';

        final dbByCode = rawCode.isNotEmpty
            ? products
            .where((p) => p.code.toUpperCase() == rawCode.toUpperCase())
            .firstOrNull
            : null;
        final matchedName = dbByCode?.nom ?? findBestMatch(desig, products);
        final matchedCode = dbByCode?.code ??
            (matchedName.isNotEmpty
                ? (products
                .where((p) => p.nom == matchedName)
                .firstOrNull
                ?.code ??
                rawCode)
                : rawCode);

        items.add(ReceiptItem(
          originalName:       desig,
          matchedProductName: matchedName,
          matchedProductCode: matchedCode,
          quantity:   outerQty,
          unitPrice:  unitPrice,
          totalPrice: totalPrice,
          confidence: dbByCode != null ? 1.0 : (matchedName.isNotEmpty ? 0.75 : 0.5),
        ));
        continue;
      }

      final priceMatches =
      RegExp(r'([\d\s]+[.,]\d{2})').allMatches(line).toList();
      if (priceMatches.length >= 2) {
        final unitPrice =
            pn(priceMatches[priceMatches.length - 2].group(1)!) ?? 0;
        final totalPrice = pn(priceMatches.last.group(1)!) ?? 0;
        if (unitPrice <= 0 || totalPrice <= 0) continue;

        var desig = line
            .substring(0, priceMatches[priceMatches.length - 2].start)
            .replaceAll(RegExp(r'^\d+\s*[|\\]?\s*'), '')
            .replaceAll(RegExp(r'^\s*[A-Z0-9][A-Z0-9\-]{1,20}\s*',
            caseSensitive: false), '')
            .replaceAll(RegExp(r'[-—]{2,}'), ' ')
            .replaceAll('|', ' ')
            .trim();

        if (desig.length < 3) continue;
        if (skipRx.hasMatch(desig.toUpperCase())) continue;

        final qty = (unitPrice > 0 && totalPrice > unitPrice)
            ? (totalPrice / unitPrice).roundToDouble()
            : 1.0;

        final matchedName = findBestMatch(desig, products);
        final matchedCode = matchedName.isNotEmpty
            ? (products
            .where((p) => p.nom == matchedName)
            .firstOrNull
            ?.code ??
            '')
            : '';

        items.add(ReceiptItem(
          originalName:       desig,
          matchedProductName: matchedName,
          matchedProductCode: matchedCode,
          quantity:   qty,
          unitPrice:  unitPrice,
          totalPrice: totalPrice,
          confidence: matchedName.isNotEmpty ? 0.7 : 0.4,
        ));
      }
    }

    print('=== DELIVERY NOTE PARSED ${items.length} ITEMS ===');
    for (final i in items) {
      print('  "${i.originalName}" | code=${i.matchedProductCode}'
          ' qty=${i.quantity} unit=${i.unitPrice} total=${i.totalPrice}');
    }
    return items;
  }

  // ─────────────────────────────────────────────────────────────────────────── //
  //  Local grocery-receipt parser
  // ─────────────────────────────────────────────────────────────────────────── //

  static List<ReceiptItem> parseReceiptText(
      String text, List<Produit> products)
  {
    if (text.trim().isEmpty) return [];
    final cleaned = _preCleanOcrText(text);
    print('=== LOCAL RECEIPT PARSER ===');

    final items   = <ReceiptItem>[];
    final lines   = cleaned.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || _isHeaderOrFooter(trimmed)) continue;

      var clean = trimmed
          .replaceAll('DZD', ' ')
          .replaceAll(RegExp(r'\bDA\b'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final numMatches =
      RegExp(r'\b\d+(?:[.,]\d+)?\b').allMatches(clean).toList();
      if (numMatches.length < 2) continue;

      final numbers = <double>[];
      for (final m in numMatches) {
        var s = m.group(0)!;
        if (s.contains(',') && !s.contains('.')) s = s.replaceAll(',', '.');
        final v = double.tryParse(s);
        if (v != null && v > 0 && v < 1e12) numbers.add(v);
      }
      if (numbers.length < 2) continue;

      final total = numbers.last;
      double qty = 1.0;
      if (numbers.length >= 2) {
        if (numbers[0] <= 999 &&
            numbers[0] == numbers[0].truncateToDouble() &&
            numbers[0] < total) {
          qty = numbers[0];
        } else if (numbers.length >= 3) {
          qty = numbers[0];
        }
      }

      final lastMatch = numMatches.last;
      var name = clean.substring(0, lastMatch.start).trim();
      name = name
          .replaceAll(RegExp(r'^\d+'), '')
          .replaceAll(RegExp(r'^[\W_]+'), '')
          .replaceAll(RegExp(r'[\W_]+$'), '')
          .trim();

      if (name.isEmpty || name.length < 2) continue;

      final matchedName = findBestMatch(name, products);
      final unitPrice   = total / qty;

      items.add(ReceiptItem(
        originalName:       name,
        matchedProductName: matchedName,
        matchedProductCode: matchedName.isNotEmpty
            ? (products
            .where((p) => p.nom == matchedName)
            .firstOrNull
            ?.code ??
            '')
            : '',
        quantity:   qty,
        unitPrice:  unitPrice,
        totalPrice: total,
        confidence: matchedName.isNotEmpty ? 0.7 : 0.4,
      ));
    }

    final merged  = <ReceiptItem>[];
    final seen    = <String, ReceiptItem>{};

    for (final item in items) {
      final key = item.originalName.toLowerCase();
      if (seen.containsKey(key)) {
        final existing = seen[key]!;
        seen[key] = ReceiptItem(
          originalName:       item.originalName,
          matchedProductName: item.matchedProductName,
          matchedProductCode: item.matchedProductCode,
          quantity:   existing.quantity + item.quantity,
          unitPrice:  existing.unitPrice,
          totalPrice: existing.totalPrice + item.totalPrice,
          confidence: max(existing.confidence, item.confidence),
        );
      } else {
        seen[key] = item;
      }
    }
    merged.addAll(seen.values);

    print('=== PARSED ${merged.length} ITEMS ===');
    for (final i in merged) {
      print('  "${i.originalName}" → "${i.matchedProductName}"'
          ' qty=${i.quantity} unit=${i.unitPrice} total=${i.totalPrice}');
    }
    return merged;
  }

  // ─────────────────────────────────────────────────────────────────────────── //
  //  Shared text helpers
  // ─────────────────────────────────────────────────────────────────────────── //

  static String _preCleanOcrText(String raw) {
    final lines = raw.split('\n');
    final fixed = <String>[];
    for (var line in lines) {
      var l = line;
      l = l.replaceAll(RegExp(r'\$'), '');
      l = l.replaceAll('«', ' ').replaceAll('»', ' ');
      l = l.replaceAllMapped(
          RegExp(r'(\d+[,.]00)(\d)'), (m) => '${m.group(1)} ${m.group(2)}');
      l = l.replaceAll(RegExp(r' {3,}'), '  ');
      l = l.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF]'), '');
      fixed.add(l);
    }
    return fixed.join('\n');
  }

  static bool _isHeaderOrFooter(String line) {
    final upper = line.toUpperCase();
    final lower = line.toLowerCase();
    if (RegExp(r'\b(Discount|Remise|Reduction|Sale)\b',
        caseSensitive: false).hasMatch(line)) return true;
    if (RegExp(r'\b(Tax|Taxes|TVA)\b',
        caseSensitive: false).hasMatch(line)) return true;
    if (RegExp(r'\bTotal\b', caseSensitive: false).hasMatch(line) &&
        RegExp(r'\d').hasMatch(line)) return true;
    const frKw = [
      'Produit', 'Qté', '---', '===', 'MAGASIN', 'PRINCIPAL', 'WELCOME',
      'TEL', 'Date :', 'Date:', 'Ticket', 'Caisse', 'Caissier', 'Client',
      'Payé', 'Paye', 'Reste', 'Merci', 'bientôt', 'bientot', 'Abientot',
      'visite', 'VERSEMENT',
    ];
    const enKw = [
      'TOTAL', 'TAX', 'SUBTOTAL', 'CHANGE', 'CASH', 'CREDIT', 'CASHIER',
      'THANK YOU', 'THANK', 'SHOPPING', 'GROCERY', 'STORE', 'DIR ', 'MAIN:',
      'RX:', 'YOUR CASHIER', 'FOR QUESTIONS', 'WELCOME', 'TEL', 'PLEASE CALL',
      'VONS', 'SAFEWAY', 'KROGER', 'WALMART', 'VERSEMENT', 'DISCOUNT',
    ];
    if (RegExp(r'^\(?\d{3}\)?[\s\-]\d{3}[\s\-]\d{4}').hasMatch(line))
      return true;
    if (RegExp(r'\b[A-Z]{2}\s+\d{5}\b').hasMatch(line)) return true;
    if (RegExp(r'^\d[\d\s]{6,}$').hasMatch(line.trim())) return true;
    if (frKw.any((k) => lower.contains(k.toLowerCase()))) return true;
    if (enKw.any((k) => upper.contains(k))) return true;
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────── //
  //  Fuzzy product matching
  // ─────────────────────────────────────────────────────────────────────────── //

  static String _norm(String t) {
    t = t.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    return t
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _lev(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final m = List.generate(
        a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) m[i][0] = i;
    for (int j = 0; j <= b.length; j++) m[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        m[i][j] = [m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + cost]
            .reduce(min);
      }
    }
    return 1.0 - (m[a.length][b.length] / max(a.length, b.length));
  }

  static String _extractArabicProductName(String rawLine) {
    final arabicRegex = RegExp(
        r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+');
    final arabicMatches = arabicRegex.allMatches(rawLine);
    if (arabicMatches.isNotEmpty) {
      final arabicParts = <String>[];
      for (final match in arabicMatches) {
        final arabicText = match.group(0)!;
        String cleaned = arabicText
            .replaceAll(RegExp(r'[0-9]'), '')
            .replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '')
            .trim();
        if (cleaned.isNotEmpty && cleaned.length > 2) {
          arabicParts.add(cleaned);
        }
      }
      if (arabicParts.isNotEmpty) {
        return arabicParts.reduce((a, b) => a.length > b.length ? a : b);
      }
    }
    return '';
  }

  static String _cleanProductName(String rawName, {bool preferArabic = true}) {
    String cleaned = rawName;
    if (preferArabic) {
      final arabicName = _extractArabicProductName(rawName);
      if (arabicName.isNotEmpty) cleaned = arabicName;
    }
    cleaned = cleaned
        .replaceAll(RegExp(r'^\d+\s*[|\\]?\s*'), '')
        .replaceAll(
        RegExp(r'^\s*[A-Z0-9][A-Z0-9\-]{1,20}\s*', caseSensitive: false),
        '')
        .replaceAll(RegExp(r'[-—]{2,}'), ' ')
        .replaceAll('|', ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (preferArabic && _hasArabic(cleaned)) {
      cleaned =
          cleaned.replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '').trim();
    }
    return cleaned;
  }

  static bool _hasArabic(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  static String findBestMatch(String name, List<Produit> products) {
    if (products.isEmpty) return '';

    String best       = '';
    double bestScore  = 0;

    final cleanedName = _cleanProductName(name, preferArabic: true);
    final normName    = _norm(cleanedName);
    final searchName  = normName.length > 2
        ? normName
        : _norm(_cleanProductName(name, preferArabic: false));

    for (final p in products) {
      final productHasArabic = _hasArabic(p.nom);
      final searchHasArabic  = _hasArabic(searchName);

      double score = _lev(searchName, _norm(p.nom));

      if (productHasArabic && searchHasArabic) {
        score += 0.15;
      } else if (!productHasArabic && !searchHasArabic) {
        score += 0.05;
      }

      if (score < 0.55) {
        final rw = searchName.split(' ').where((w) => w.length > 2).toList();
        final pw = _norm(p.nom).split(' ').where((w) => w.length > 2).toList();
        int hits = 0;
        for (final w in rw) {
          if (pw.any((x) => x.contains(w) || w.contains(x))) hits++;
        }
        if (hits > 0) {
          score = 0.55 + (hits / max(rw.length, pw.length)) * 0.3;
        }
      }

      if (score > bestScore && score > 0.55) {
        bestScore = score;
        best      = p.nom;
      }
    }
    return best;
  }
}

// ─────────────────────────────────────────────────────────────────────────── //
//  Data model
// ─────────────────────────────────────────────────────────────────────────── //

class ReceiptItem {
  final String originalName;
  final String matchedProductName;
  final String matchedProductCode;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double confidence;

  const ReceiptItem({
    required this.originalName,
    required this.matchedProductName,
    required this.matchedProductCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.confidence,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
    originalName:       json['original_name']?.toString()        ?? '',
    matchedProductName: json['matched_product_name']?.toString() ?? '',
    matchedProductCode: json['matched_product_code']?.toString() ?? '',
    quantity:   (json['quantity']    as num?)?.toDouble() ?? 0,
    unitPrice:  (json['unit_price']  as num?)?.toDouble() ?? 0,
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    confidence: (json['confidence']  as num?)?.toDouble() ?? 0,
  );

  static List<ReceiptItem> fromJsonList(List<dynamic> list) =>
      list.map((j) => ReceiptItem.fromJson(j as Map<String, dynamic>)).toList();

  ReceiptItem copyWith({
    String? originalName,
    String? matchedProductName,
    String? matchedProductCode,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    double? confidence,
  }) =>
      ReceiptItem(
        originalName:       originalName       ?? this.originalName,
        matchedProductName: matchedProductName ?? this.matchedProductName,
        matchedProductCode: matchedProductCode ?? this.matchedProductCode,
        quantity:   quantity   ?? this.quantity,
        unitPrice:  unitPrice  ?? this.unitPrice,
        totalPrice: totalPrice ?? this.totalPrice,
        confidence: confidence ?? this.confidence,
      );
}