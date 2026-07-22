import 'dart:async';

import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/caisse.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialog/information_dialog.dart';

class ProduitPanier {
  String nom;
  String code;
  String colis;
  double prix;
  double prixachat;
  double qte;
  int? piecesParEmballage;
  int? produitId;
  String? packNom;
  bool get isFromPack => packNom != null && packNom!.isNotEmpty;

  ProduitPanier({
    required this.nom,
    required this.code,
    required this.colis,
    required this.prix,
    required this.prixachat,
    required this.qte,
    this.piecesParEmballage,
    this.produitId,
    this.packNom,
  });

  double get montant => prix * qte;
  double get quantiteReelleEnPieces => qte * (piecesParEmballage ?? 1);
}

class TableauCaisse extends StatefulWidget {
  final String? caissenom;
  final double size;
  final List<ProduitPanier> produits;
  final bool readOnly;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalApresRemise = total - widget.remiseValue;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final bool isLargeScreen = screenWidth >= 900;

    // ✅ Définir les largeurs des colonnes
    double colCheckbox, colCode, colProduit, colColis, colPrix, colQte, colQtePiece, colMt, colSuppr;
    double fontSize, iconSize, checkboxScale, columnSpacing, horizontalMargin;

    if (isSmallScreen) {
      colCheckbox = 18;
      colCode = 50;
      colProduit = 60;
      colColis = 45;
      colPrix = 40;
      colQte = 30;
      colQtePiece = 30;
      colMt = 40;
      colSuppr = 28;
      fontSize = 9;
      iconSize = 12;
      checkboxScale = 0.6;
      columnSpacing = 2;
      horizontalMargin = 2;
    } else if (isMediumScreen) {
      colCheckbox = 26;
      colCode = 54;
      colProduit = 80;
      colColis = 50;
      colPrix = 50;
      colQte = 40;
      colQtePiece = 50;
      colMt = 50;
      colSuppr = 30;
      fontSize = 10;
      iconSize = 14;
      checkboxScale = 0.7;
      columnSpacing = 4;
      horizontalMargin = 4;
    } else {
      colCheckbox = 26;
      colCode = 60;
      colProduit = 120;
      colColis = 60;
      colPrix = 50;
      colQte = 50;
      colQtePiece = 50;
      colMt = 60;
      colSuppr = 30;
      fontSize = 12;
      iconSize = 16;
      checkboxScale = 0.8;
      columnSpacing = 8;
      horizontalMargin = 8;
    }

    // ✅ Calculer la largeur totale du tableau
    final totalWidth = colCheckbox + colCode + colProduit + colColis + colPrix + colQte + colQtePiece + colMt + colSuppr +
        (columnSpacing * 8) + (horizontalMargin * 2);

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
                      DataColumn(
                        label: SizedBox(
                          width: colCode,
                          child: Text(
                            "Code",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colProduit,
                          child: Text(
                            "Produit",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colColis,
                          child: Text(
                            "Colis",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colPrix,
                          child: Text(
                            "Prix",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colQte,
                          child: Text(
                            "Qté",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colQtePiece,
                          child: Text(
                            "Qté (pce)",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colMt,
                          child: Text(
                            "Mt",
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
                                "${p.prix.toStringAsFixed(2)}",
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
                                p.qte.toString(),
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
                                controller: TextEditingController(text: p.qte.toString()),
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
                                  final nouvelleQte = double.tryParse(v) ?? 1;
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

                          // ✅ MONTANT
                          DataCell(
                            SizedBox(
                              width: colMt,
                              child: Text(
                                p.montant.toStringAsFixed(2),
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
                    "${l10n.discount} : -${widget.remiseValue.toStringAsFixed(2)} ${l10n.currency}",
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
                    "Remise conditionnelle: +${widget.remiseInfo!.montantCondition.toStringAsFixed(2)} DA pour activer",
                    style: Appstyle.textpop_S.copyWith(
                      color: Colors.orange,
                      fontSize: isSmallScreen ? 10 : (isMediumScreen ? 11 : 12),
                    ),
                  ),

                Text(
                  "${l10n.total} : ${totalApresRemise.toStringAsFixed(2)} ${l10n.currency}",
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