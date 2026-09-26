import 'dart:async';

import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import '../../../data/models/caisse.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialog/information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class ProduitPanier {
  String nom;
  String code;
  String colis;
  double prix;
  double prixachat;
  double qte;
  // Nombre de pièces physiques (Paramètres > Nombre et Quantité), saisi
  // librement — indépendant de qte/piecesParEmballage. Voir Produit.nombre.
  double? nombre;
  // Reflète Produit.nombreActif au moment de l'ajout au panier : contrôle si
  // la cellule "Nombre" de cette ligne est éditable ou vide (voir la colonne
  // "Nombre" dans TableauCaisse, affichée dès qu'UN produit du panier a
  // l'option active, mais éditable seulement pour CE produit-là).
  bool nombreActif;
  int? piecesParEmballage;
  int? produitId;
  String? packNom;

  /// Prix unitaire avant application d'une remise produit automatique
  /// (voir caisse_screen.dart::_remiseProduitApplicable) — null si aucune
  /// remise n'a été appliquée à l'ajout au panier.
  double? prixOriginal;

  /// Nom de la remise produit appliquée, le cas échéant (voir [prixOriginal]).
  String? remiseNom;

  bool get isFromPack => packNom != null && packNom!.isNotEmpty;
  bool get aRemise => prixOriginal != null;

  ProduitPanier({
    required this.nom,
    required this.code,
    required this.colis,
    required this.prix,
    required this.prixachat,
    required this.qte,
    this.nombre,
    this.nombreActif = false,
    this.piecesParEmballage,
    this.produitId,
    this.packNom,
    this.prixOriginal,
    this.remiseNom,
  });

  double get montant => prix * qte;
  double get quantiteReelleEnPieces => qte * (piecesParEmballage ?? 1);
}

class TableauCaisse extends StatefulWidget {
  final String? caissenom;
  final double size;
  final List<ProduitPanier> produits;
  final bool readOnly;

  /// Affiche la colonne "Code" — masquée quand un panneau latéral affiche
  /// déjà le code produit, pour gagner de la place (voir caisse_screen.dart).
  final bool showCode;

  /// Affiche la colonne éditable "Nombre" (Paramètres > Nombre et Quantité)
  /// — masquée par défaut, activée par caisse_screen.dart si le paramètre
  /// est actif.
  final bool afficherNombre;

  final ProduitPanier? selectedProduit;
  final Function(ProduitPanier produit)? onProduitSelected;
  final Function(ProduitPanier produit)? onProduitDoubleClick;
  final Function(double total, double remise)? onTotalChanged;
  final Function(ProduitPanier produit)? onProduitDelete;

  final RemiseInfo? remiseInfo;
  final bool remiseActive;
  final double remiseValue;

  final Future<bool> Function(ProduitPanier produit, double nouvelleQte)? onVerifyStock;

  const TableauCaisse({
    super.key,
    this.caissenom,
    required this.size,
    required this.produits,
    this.showCode = true,
    this.afficherNombre = false,
    this.onTotalChanged,
    this.selectedProduit,
    this.onProduitSelected,
    this.onProduitDoubleClick,
    this.onProduitDelete,
    this.readOnly = false,
    this.onVerifyStock,
    this.remiseInfo,
    this.remiseActive = false,
    this.remiseValue = 0,
  });

  @override
  State<TableauCaisse> createState() => _TableauCaisseState();
}

class _TableauCaisseState extends State<TableauCaisse> {
  double get total => widget.produits.fold(0.0, (s, p) => s + p.montant);

  final ScrollController _horizontalScrollController = ScrollController();

  // Controller/FocusNode persistants par ligne (clé = objet ProduitPanier).
  // Un TextEditingController recréé à chaque frappe (comme avant, dans le
  // .map() du build) fait retomber le curseur en position 0 et donne
  // l'impression d'une saisie "inversée". On ne resynchronise le texte
  // depuis p.qte que si le champ n'a pas le focus (ex. quantité incrémentée
  // en rajoutant le même produit au panier ailleurs dans l'écran).
  final Map<ProduitPanier, TextEditingController> _qteControllers = {};
  final Map<ProduitPanier, FocusNode> _qteFocusNodes = {};

  // Même pattern que _qteControllers, pour la colonne "Nombre" (Paramètres >
  // Nombre et Quantité) — un contrôleur par ligne, pas recréé à chaque frappe.
  final Map<ProduitPanier, TextEditingController> _nombreControllers = {};
  final Map<ProduitPanier, FocusNode> _nombreFocusNodes = {};

  TextEditingController _qteControllerFor(ProduitPanier p) {
    final text = QuantiteFormat.format(p.qte);
    final focus = _qteFocusNodes.putIfAbsent(p, () => FocusNode());
    var ctrl = _qteControllers[p];
    if (ctrl == null) {
      ctrl = TextEditingController(text: text);
      _qteControllers[p] = ctrl;
    } else if (!focus.hasFocus && ctrl.text != text) {
      ctrl.text = text;
    }
    return ctrl;
  }

  TextEditingController _nombreControllerFor(ProduitPanier p) {
    final text = p.nombre != null ? QuantiteFormat.format(p.nombre!) : '';
    final focus = _nombreFocusNodes.putIfAbsent(p, () => FocusNode());
    var ctrl = _nombreControllers[p];
    if (ctrl == null) {
      ctrl = TextEditingController(text: text);
      _nombreControllers[p] = ctrl;
    } else if (!focus.hasFocus && ctrl.text != text) {
      ctrl.text = text;
    }
    return ctrl;
  }

  void _pruneQteControllers() {
    final produitsActuels = widget.produits.toSet();
    final codesAbsents = _qteControllers.keys.where((p) => !produitsActuels.contains(p)).toList();
    for (final p in codesAbsents) {
      _qteControllers.remove(p)?.dispose();
      _qteFocusNodes.remove(p)?.dispose();
    }
    final codesAbsentsNombre = _nombreControllers.keys.where((p) => !produitsActuels.contains(p)).toList();
    for (final p in codesAbsentsNombre) {
      _nombreControllers.remove(p)?.dispose();
      _nombreFocusNodes.remove(p)?.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant TableauCaisse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTotalChanged?.call(total, widget.remiseValue);
      });
    }
  }

  void _removeProduit(ProduitPanier produit) {
    setState(() {
      widget.produits.remove(produit);
      if (widget.onProduitDelete != null) {
        widget.onProduitDelete!(produit);
      }
      final nouveauTotal = total;
      widget.onTotalChanged?.call(nouveauTotal, widget.remiseValue);
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    for (final c in _qteControllers.values) {
      c.dispose();
    }
    for (final f in _qteFocusNodes.values) {
      f.dispose();
    }
    for (final c in _nombreControllers.values) {
      c.dispose();
    }
    for (final f in _nombreFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pruneQteControllers();
    final l10n = AppLocalizations.of(context)!;
    final totalApresRemise = total - widget.remiseValue;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final bool isLargeScreen = screenWidth >= 900;

    // ✅ Définir les largeurs des colonnes
    double colCheckbox, colCode, colProduit, colColis, colPrix, colQte, colQtePiece, colNombre, colMt, colSuppr;
    double fontSize, iconSize, checkboxScale, columnSpacing, horizontalMargin;

    if (isSmallScreen) {
      colCheckbox = 18;
      colCode = 50;
      colProduit = 60;
      colColis = 45;
      colPrix = 40;
      colQte = 30;
      colQtePiece = 50;
      colNombre = 34;
      colMt = 40;
      colSuppr = 28;
      fontSize = 9;
      iconSize = 12;
      checkboxScale = 0.6;
      columnSpacing = 2;
      horizontalMargin = 2;
    } else if (isMediumScreen) {
      colCheckbox = 18;
      colCode = 54;
      colProduit = 80;
      colColis = 50;
      colPrix = 50;
      colQte = 40;
      colQtePiece = 70;
      colNombre = 44;
      colMt = 50;
      colSuppr = 30;
      fontSize = 10;
      iconSize = 14;
      checkboxScale = 0.7;
      columnSpacing = 4;
      horizontalMargin = 4;
    } else {
      colCheckbox = 18;
      colCode = 60;
      colProduit = 120;
      colColis = 60;
      colPrix = 50;
      colQte = 50;
      colQtePiece = 70;
      colNombre = 55;
      colMt = 60;
      colSuppr = 30;
      fontSize = 12;
      iconSize = 16;
      checkboxScale = 0.8;
      columnSpacing = 8;
      horizontalMargin = 8;
    }

    // ✅ Calculer la largeur totale du tableau
    final int nbColonnes = (widget.showCode ? 9 : 8) + (widget.afficherNombre ? 1 : 0);
    final totalWidth = colCheckbox + (widget.showCode ? colCode : 0) + colProduit + colColis + colPrix + colQte + colQtePiece +
        (widget.afficherNombre ? colNombre : 0) + colMt + colSuppr +
        (columnSpacing * (nbColonnes - 1)) + (horizontalMargin * 2);

    return Column(
      children: [
        /// ───────── TABLE ─────────
        SizedBox(
          width: double.infinity,
          height: widget.size,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // ✅ Utiliser constraints.maxWidth au lieu de screenWidth
              final availableWidth = constraints.maxWidth;
              final bool needsScroll = totalWidth > availableWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: SizedBox(
                  // ✅ Si le tableau est plus large que l'espace disponible, utiliser la largeur totale
                  // ✅ Sinon, utiliser la largeur disponible
                  width: needsScroll ? totalWidth : availableWidth,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columnSpacing: columnSpacing,
                    horizontalMargin: horizontalMargin,
                    headingRowHeight: isSmallScreen ? 32 : (isMediumScreen ? 35 : 38),
                    dataRowHeight: isSmallScreen ? 40 : (isMediumScreen ? 45 : 50),
                    headingRowColor: MaterialStateProperty.all(Appstyle.blueC),
                    headingTextStyle: Appstyle.textpop_SB.copyWith(
                      color: Appstyle.Tblanc,
                      fontSize: isSmallScreen ? 9 : (isMediumScreen ? 10 : 12),
                    ),

                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: colCheckbox,
                          child: Center(
                            child: Text(
                              "",
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ),
                      ),
                      if (widget.showCode)
                        DataColumn(
                          label: SizedBox(
                            width: colCode,
                            child: Text(
                              l10n.code,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ),
                      DataColumn(
                        label: SizedBox(
                          width: colProduit,
                          child: Text(
                            l10n.productName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colColis,
                          child: Text(
                            l10n.parcel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colPrix,
                          child: Text(
                            l10n.price,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colQte,
                          child: Text(
                            l10n.qty,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colQtePiece,
                          child: Text(
                            l10n.quantityPieces,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      if (widget.afficherNombre)
                        DataColumn(
                          label: SizedBox(
                            width: colNombre,
                            child: Text(
                              l10n.numberField,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ),
                      DataColumn(
                        label: SizedBox(
                          width: colMt,
                          child: Text(
                            l10n.total,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colSuppr,
                          child: Center(
                            child: Text(
                              "",
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ),
                      ),
                    ],

                    rows: widget.produits.map((p) {
                      final bool isSelected = widget.selectedProduit == p;
                      final quantiteReelle = p.quantiteReelleEnPieces;

                      String colisDisplay = p.colis.isEmpty ? "---" : p.colis;
                      Color colisColor = Appstyle.TgrisF;

                      if (p.isFromPack) {
                        colisDisplay = p.packNom ?? p.colis;
                        colisColor = Appstyle.violet;
                      } else if (p.piecesParEmballage != null && p.piecesParEmballage! > 1) {
                        colisDisplay = p.colis;
                        colisColor = Appstyle.violet;
                      } else {
                        colisDisplay = "---";
                      }

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                              (states) => isSelected ? Appstyle.violet.withOpacity(0.15) : null,
                        ),
                        cells: [
                          // ✅ CHECKBOX
                          DataCell(
                            Center(
                              child: Transform.scale(
                                scale: checkboxScale,
                                child: Checkbox(
                                  value: isSelected,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: widget.readOnly ? null : (_) => widget.onProduitSelected?.call(p),
                                  activeColor: Appstyle.violet,
                                ),
                              ),
                            ),
                          ),

                          // ✅ CODE
                          if (widget.showCode)
                            DataCell(
                              GestureDetector(
                                onDoubleTap: () {
                                  if (!widget.readOnly) {
                                    widget.onProduitDoubleClick?.call(p);
                                  }
                                },
                                child: SizedBox(
                                  width: colCode,
                                  child: Text(
                                    p.code,
                                    overflow: TextOverflow.ellipsis,
                                    style: Appstyle.textpop_S.copyWith(
                                      color: isSelected ? Appstyle.violet : Appstyle.TgrisF,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // ✅ NOM PRODUIT
                          DataCell(
                            GestureDetector(
                              onDoubleTap: () {
                                if (!widget.readOnly) {
                                  widget.onProduitDoubleClick?.call(p);
                                }
                              },
                              child: SizedBox(
                                width: colProduit,
                                child: Row(
                                  children: [
                                    if (p.isFromPack)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 2),
                                        child: Icon(
                                          Icons.all_inbox,
                                          size: iconSize * 0.7,
                                          color: Appstyle.violet,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        p.nom,
                                        overflow: TextOverflow.ellipsis,
                                        style: Appstyle.textpop_S.copyWith(
                                          color: isSelected ? Appstyle.violet : Appstyle.TgrisF,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: fontSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ✅ COLIS / PACK
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                              decoration: BoxDecoration(
                                color: p.isFromPack || (p.piecesParEmballage != null && p.piecesParEmballage! > 1)
                                    ? Appstyle.violet.withOpacity(0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: SizedBox(
                                width: colColis,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (p.isFromPack)
                                      Icon(
                                        Icons.all_inbox,
                                        size: iconSize * 0.5,
                                        color: colisColor,
                                      ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        colisDisplay,
                                        overflow: TextOverflow.ellipsis,
                                        style: Appstyle.textpop_S.copyWith(
                                          color: colisColor,
                                          fontStyle: p.isFromPack ? FontStyle.italic : FontStyle.normal,
                                          fontWeight: p.isFromPack ? FontWeight.w500 : FontWeight.normal,
                                          fontSize: isSmallScreen ? fontSize * 0.85 : fontSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ✅ PRIX
                          DataCell(
                            SizedBox(
                              width: colPrix,
                              child: Text(
                                "${NumberFormatUtil.formatMontant(p.prix, decimales: 2)}",
                                overflow: TextOverflow.ellipsis,
                                style: Appstyle.textpop_S.copyWith(
                                  color: Appstyle.TgrisF,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                          ),

                          // ✅ QUANTITÉ
                          DataCell(
                            widget.readOnly
                                ? SizedBox(
                              width: colQte,
                              child: Text(
                                QuantiteFormat.format(p.qte),
                                overflow: TextOverflow.ellipsis,
                                style: Appstyle.textpop_SB.copyWith(
                                  color: Appstyle.Tblue,
                                  fontSize: fontSize,
                                ),
                              ),
                            )
                                : SizedBox(
                              width: colQte,
                              child: TextField(
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                controller: _qteControllerFor(p),
                                focusNode: _qteFocusNodes[p],
                                inputFormatters: QuantiteFormat.inputFormatters,
                                style: Appstyle.textpop_SB.copyWith(
                                  color: Appstyle.Tblue,
                                  fontSize: fontSize,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  constraints: BoxConstraints(minHeight: isSmallScreen ? 20 : 25),
                                ),
                                onChanged: (v) async {
                                  final nouvelleQte = double.tryParse(v.replaceAll(',', '.')) ?? 1;
                                  if (nouvelleQte <= 0) {
                                    _removeProduit(p);
                                    return;
                                  }

                                  if (widget.onVerifyStock != null) {
                                    final stockOk = await widget.onVerifyStock!(p, nouvelleQte);
                                    if (!stockOk) {
                                      setState(() {});
                                      return;
                                    }
                                  }

                                  setState(() {
                                    p.qte = nouvelleQte;
                                    widget.onProduitSelected?.call(p);
                                    widget.onTotalChanged?.call(total, widget.remiseValue);
                                  });
                                },
                              ),
                            ),
                          ),

                          // ✅ QUANTITÉ RÉELLE
                          DataCell(
                            SizedBox(
                              width: colQtePiece,
                              child: Text(
                                quantiteReelle.toInt().toString(),
                                overflow: TextOverflow.ellipsis,
                                style: Appstyle.textpop_S.copyWith(
                                  color: (p.piecesParEmballage != null && p.piecesParEmballage! > 1)
                                      ? Colors.orange.shade700
                                      : Appstyle.TgrisF,
                                  fontWeight: (p.piecesParEmballage != null && p.piecesParEmballage! > 1)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                          ),

                          // ✅ NOMBRE (Paramètres > Nombre et Quantité) — colonne visible dès
                          // qu'UN produit du panier a l'option active, mais éditable/affichée
                          // uniquement sur les lignes des produits qui l'ont eux-mêmes activée.
                          if (widget.afficherNombre)
                            DataCell(
                              !p.nombreActif
                                  ? SizedBox(width: colNombre)
                                  : widget.readOnly
                                      ? SizedBox(
                                          width: colNombre,
                                          child: Text(
                                            p.nombre != null ? QuantiteFormat.format(p.nombre!) : '',
                                            overflow: TextOverflow.ellipsis,
                                            style: Appstyle.textpop_SB.copyWith(
                                              color: Appstyle.Tblue,
                                              fontSize: fontSize,
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          width: colNombre,
                                          child: TextField(
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            controller: _nombreControllerFor(p),
                                            focusNode: _nombreFocusNodes[p],
                                            inputFormatters: QuantiteFormat.inputFormatters,
                                            style: Appstyle.textpop_SB.copyWith(
                                              color: Appstyle.Tblue,
                                              fontSize: fontSize,
                                            ),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                              isDense: true,
                                              border: const OutlineInputBorder(),
                                              constraints: BoxConstraints(minHeight: isSmallScreen ? 20 : 25),
                                            ),
                                            onChanged: (v) {
                                              final saisie = v.replaceAll(',', '.').trim();
                                              setState(() {
                                                p.nombre = saisie.isEmpty ? null : double.tryParse(saisie);
                                              });
                                            },
                                          ),
                                        ),
                            ),

                          // ✅ MONTANT
                          DataCell(
                            SizedBox(
                              width: colMt,
                              child: Text(
                                NumberFormatUtil.formatMontant(p.montant, decimales: 2),
                                overflow: TextOverflow.ellipsis,
                                style: Appstyle.textpop_S.copyWith(
                                  color: Appstyle.TgrisF,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                          ),

                          // ✅ SUPPRIMER
                          DataCell(
                            widget.readOnly
                                ? SizedBox(width: colSuppr)
                                : Container(
                              width: colSuppr,
                              height: colSuppr,
                              alignment: Alignment.center,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(colSuppr / 2),
                                  onTap: () => _removeProduit(p),
                                  child: Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                    size: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),
        Divider(thickness: 1.5, color: Appstyle.indigo),
        const SizedBox(height: 10),

        /// ───────── RÉCAP ─────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.caissenom ?? "",
                style: Appstyle.textpop_LB.copyWith(
                  color: Appstyle.gris,
                  fontSize: isSmallScreen ? 14 : (isMediumScreen ? 16 : 18),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.produits.isNotEmpty && widget.remiseValue > 0)
                  Text(
                    "${l10n.discount} : -${NumberFormatUtil.formatMontant(widget.remiseValue, decimales: 2)} ${l10n.currency}",
                    style: Appstyle.textpop_S.copyWith(
                      color: Colors.green,
                      fontSize: isSmallScreen ? 10 : (isMediumScreen ? 11 : 12),
                    ),
                  )
                else if (widget.produits.isNotEmpty &&
                    widget.remiseInfo != null &&
                    widget.remiseInfo!.montantCondition > 0 &&
                    !widget.remiseActive)
                  Text(
                    l10n.conditionalDiscountToActivate(
                      NumberFormatUtil.formatMontant(widget.remiseInfo!.montantCondition, decimales: 2),
                      l10n.currency,
                    ),
                    style: Appstyle.textpop_S.copyWith(
                      color: Colors.orange,
                      fontSize: isSmallScreen ? 10 : (isMediumScreen ? 11 : 12),
                    ),
                  ),

                Text(
                  "${l10n.total} : ${NumberFormatUtil.formatMontant(totalApresRemise, decimales: 2)} ${l10n.currency}",
                  style: Appstyle.textpop_SB.copyWith(
                    fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                    color: widget.remiseValue > 0 ? Colors.green : Appstyle.TgrisF,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}