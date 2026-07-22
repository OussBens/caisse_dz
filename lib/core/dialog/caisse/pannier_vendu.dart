import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_detail.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Services/Client.dart';
import '../information_dialog.dart';

Future<void> DialogPannierVendu({
  required BuildContext context,
  required String caisseName,
}) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username ?? '';
  final userCode = auth.userCode ?? '';

  // Charger les données
  final db = await DbCreator.openDb();
  final pannierService = PannierServices(db);
  final allPanniers = await PannierServices.getAllPanniers();

  // Filtrer les paniers de la caisse actuelle
  List<Pannier> panniersCaisse = allPanniers
      .where((p) => p.caisse == caisseName && p.typepannier != "SmartScan")
      .toList();

  // Charger les clients pour les filtres
  final clients = await ClientServices.getAllClients();
  final clientNames = clients.map((c) => c.nom).toList();

  // État des filtres
  DateTime dateDebut = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime dateFin = DateTime.now();

  String? selectedClientFilter;
  String? selectedModePaiementFilter;
  String? selectedTypePannierFilter;
  String? selectedEtatFilter;

  double? montantMin;
  double? montantMax;
  double? resteMin;
  double? resteMax;

  String searchText = "";

  final searchController = TextEditingController();

  // Options pour les listes déroulantes
  final modePaiementOptions = ["Espèces", "Chèque", "Carte bancaire", "Virement"];
  final typePannierOptions = ["Ticket", "BL", "BLSC"];
  final etatOptions = ["Actif", "Inactif"];

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);

          // Appliquer les filtres
          List<Pannier> panniersFiltres = panniersCaisse.where((p) {
            final dateOk = !p.date.isBefore(dateDebut) && !p.date.isAfter(dateFin);
            final clientOk = selectedClientFilter == null || selectedClientFilter!.isEmpty || p.client == selectedClientFilter;
            final modeOk = selectedModePaiementFilter == null || selectedModePaiementFilter!.isEmpty || p.modePaiement == selectedModePaiementFilter;
            final typeOk = selectedTypePannierFilter == null || selectedTypePannierFilter!.isEmpty || p.typepannier == selectedTypePannierFilter;
            final etatOk = selectedEtatFilter == null || selectedEtatFilter!.isEmpty ||
                (selectedEtatFilter == "Actif" && p.etat) ||
                (selectedEtatFilter == "Inactif" && !p.etat);
            final montantOk = (montantMin == null || p.montant >= montantMin!) &&
                (montantMax == null || p.montant <= montantMax!);
            final resteOk = (resteMin == null || p.reste >= resteMin!) &&
                (resteMax == null || p.reste <= resteMax!);
            final searchOk = searchText.isEmpty ||
                p.code!.toLowerCase().contains(searchText.toLowerCase()) ||
                p.client!.toLowerCase().contains(searchText.toLowerCase());

            return dateOk && clientOk && modeOk && typeOk && etatOk && montantOk && resteOk && searchOk;
          }).toList();

          panniersFiltres.sort((a, b) => b.date.compareTo(a.date));

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1200,
                height: 700,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/pannier_icon.png',
                  text: "${l10n.cashReceipt} - $caisseName - ${_formatDate(dateDebut)}",
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section des filtres
                    SectionDecorationFiltre(
                      padding: const EdgeInsets.all(10),
                      color: Appstyle.Tblanc,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LIGNE 1 : Client + Mode paiement + Type panier
                          Row(
                            children: [
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.client,
                                  child: TextListe(
                                    value: selectedClientFilter,
                                    items: clientNames,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedClientFilter = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.payment,
                                  child: TextListe(
                                    value: selectedModePaiementFilter,
                                    items: modePaiementOptions,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedModePaiementFilter = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.typePannier,
                                  child: TextListe(
                                    value: selectedTypePannierFilter,
                                    items: typePannierOptions,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedTypePannierFilter = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // LIGNE 2 : Montant + Reste + Status
                          Row(
                            children: [
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.amount,
                                  child: FourchettePrixWidget(
                                    couleur: Appstyle.violet,
                                    minValue: montantMin,
                                    maxValue: montantMax,
                                    onChanged: (min, max) {
                                      setState(() {
                                        montantMin = min;
                                        montantMax = max;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.remaining,
                                  child: FourchettePrixWidget(
                                    couleur: Appstyle.violet,
                                    minValue: resteMin,
                                    maxValue: resteMax,
                                    onChanged: (min, max) {
                                      setState(() {
                                        resteMin = min;
                                        resteMax = max;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.status,
                                  child: TextListe(
                                    value: selectedEtatFilter,
                                    items: etatOptions,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedEtatFilter = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // LIGNE 3 : Recherche + Bouton réinitialiser
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ChampAvecLabel(
                                  label: l10n.search,
                                  child: SearchField(
                                    controller: searchController,
                                    onChanged: (v) {
                                      setState(() {
                                        searchText = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: MainButton(
                                    text: l10n.clearFilters,
                                    color: Appstyle.gris,
                                    icon: Icons.clear_all,
                                    onPressed: () {
                                      setState(() {
                                        selectedClientFilter = null;
                                        selectedModePaiementFilter = null;
                                        selectedTypePannierFilter = null;
                                        selectedEtatFilter = null;
                                        montantMin = null;
                                        montantMax = null;
                                        resteMin = null;
                                        resteMax = null;
                                        searchText = "";
                                        searchController.clear();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Compteur des résultats
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Appstyle.violet.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${l10n.numberOfSales}: ${panniersFiltres.length}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                          ),
                          Text(
                            "${l10n.totalSales}: ${panniersFiltres.fold(0.0, (sum, p) => sum + p.montant).toStringAsFixed(2)} ${l10n.currency}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Liste des paniers
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Appstyle.violet.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: panniersFiltres.isEmpty
                            ? Center(
                          child: Text(
                            l10n.noSalesFound,
                            style: Appstyle.textM.copyWith(color: Appstyle.gris),
                          ),
                        )
                            : ListView.builder(
                          itemCount: panniersFiltres.length,
                          itemBuilder: (context, index) {
                            final p = panniersFiltres[index];
                            return _pannierTile(
                              context: context,
                              pannier: p,
                              l10n: l10n,
                              onDetail: () async {
                                await PannierDetail(context, p);
                              },
                              onShowProducts: () async {
                                await _showProductsListDialog(context, p, l10n);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.close,
                      color: Appstyle.gris,
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Widget pour afficher une ligne de panier
Widget _pannierTile({
  required BuildContext context,
  required Pannier pannier,
  required AppLocalizations l10n,
  required VoidCallback onDetail,
  required VoidCallback onShowProducts,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 2,
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pannier.code ?? "",
                style: Appstyle.textSB.copyWith(
                  color: Appstyle.violet,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${pannier.date.day}/${pannier.date.month}/${pannier.date.year}",
                style: Appstyle.textXS.copyWith(color: Appstyle.gris),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            pannier.client ?? "",
            style: Appstyle.textS,
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(pannier.typepannier).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pannier.typepannier ?? "",
                  style: Appstyle.textXS.copyWith(
                    color: _getTypeColor(pannier.typepannier),
                  ),
                ),
              ),
              Text(
                pannier.modePaiement ?? "",
                style: Appstyle.textXS.copyWith(color: Appstyle.gris),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${pannier.montant.toStringAsFixed(2)} ${l10n.currency}",
                style: Appstyle.textSB.copyWith(color: Appstyle.violet),
              ),
              if (pannier.reste > 0)
                Text(
                  "${l10n.remaining}: ${pannier.reste.toStringAsFixed(2)}",
                  style: Appstyle.textXS.copyWith(color: Colors.orange),
                ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              color: Appstyle.violet,
              onPressed: onDetail,
              tooltip: l10n.details,
            ),
            IconButton(
              icon: const Icon(Icons.list, size: 20),
              color: Appstyle.crevete,
              onPressed: onShowProducts,
              tooltip: l10n.productsList,
            ),
          ],
        ),
      ],
    ),
  );
}

/// Afficher la liste des produits d'un panier
Future<void> _showProductsListDialog(BuildContext context, Pannier pannier, AppLocalizations l10n) async {
  final db = await DbCreator.openDb();
  final ppService = PPServices(db);
  final produits = await ppService.getPPByCodePannier(pannier.code!);

  showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.4),
    builder: (_) {
      return BaseDialog(
        width: 700,
        height: 550,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.productsOfCart(pannier.code),
              style: Appstyle.textLB,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${l10n.client} : ${pannier.client}", style: Appstyle.textSB),
                Text("${l10n.date} : ${pannier.date.toString().split(" ").first}", style: Appstyle.textSB),
              ],
            ),
            Text("${l10n.total} : ${pannier.montant ?? 0} ${l10n.currency}",
                style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
          ],
        ),
        content: produits.isEmpty
            ? Center(
          child: Text(
            l10n.noProducts,
            style: Appstyle.textSB.copyWith(color: Appstyle.gris),
          ),
        )
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Appstyle.violet.withOpacity(0.1)),
                  headingTextStyle: Appstyle.textSB.copyWith(color: Appstyle.violet),
                  columns: [
                    DataColumn(label: Text(l10n.productCode)),
                    DataColumn(label: Text(l10n.productName)),
                    DataColumn(label: Text(l10n.quantity), numeric: true),
                    DataColumn(label: Text(l10n.price), numeric: true),
                    DataColumn(label: Text(l10n.total), numeric: true),
                  ],
                  rows: produits.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.codeProduit ?? "")),
                        DataCell(Text(p.nomProduit ?? "")),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Appstyle.violet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${p.quantite ?? 0}",
                              style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                            ),
                          ),
                        ),
                        DataCell(Text("${p.prix?.toStringAsFixed(2) ?? '0.00'}")),
                        DataCell(
                          Text(
                            "${p.total?.toStringAsFixed(2) ?? '0.00'}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
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
        footer: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: Icon(Icons.close, color: Appstyle.Tblanc),
            label: Text(l10n.close, style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
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

/// Obtenir la couleur selon le type de panier
Color _getTypeColor(String? type) {
  switch (type) {
    case "Ticket":
      return Appstyle.violet;
    case "BL":
      return Appstyle.blueC;
    case "BLSC":
      return Appstyle.green;
    default:
      return Appstyle.gris;
  }
}

/// Formater une date
String _formatDate(DateTime d) {
  return "${d.day.toString().padLeft(2, '0')}/"
      "${d.month.toString().padLeft(2, '0')}/"
      "${d.year}";
}