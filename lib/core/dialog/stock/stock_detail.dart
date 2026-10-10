import 'dart:io';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/detail_widget.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../Services/Photos.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

List<ProduitPackDetail> produitPackDetailsTest = [];
List<ProduitMagasinDetail> produitsMagasinsTest = [];
List<Magasin> magasinsListeTest = [];
List<Pack> packsTest = [];
String? categorieNomTest;
String? sousCategorieNomTest;
String? remiseNomTest;
String? fournisseurNomTest;
double prixMoyenTest = 0;
// ✅ Quantité calculée depuis le journal des mouvements — remplace Produit.quantite.
double quantiteTest = 0;

/// Prix moyen pondéré d'achat = Σ(prix × quantité) / Σ(quantité), calculé à
/// partir de l'historique d'achats du produit (SmartScan).
double _calculerPrixMoyen(List<SmartScanProduit> achats, String codeProduit) {
  final lignes = achats.where((a) => a.codeProduit == codeProduit).toList();
  final quantiteTotale = lignes.fold(0.0, (sum, a) => sum + a.quantite);
  if (quantiteTotale == 0) return 0;
  final montantTotal = lignes.fold(0.0, (sum, a) => sum + (a.prix * a.quantite));
  return montantTotal / quantiteTotale;
}

Future<void> _LoadAllData({required Produit produit}) async {
  final db = await DbCreator.openDb();
  produitPackDetailsTest = await ProduitPackDetailServices.getAllDetails();
  produitsMagasinsTest = await ProduitMagasinDetailServices.getAllDetails();
  packsTest = await PackServices.getAllPacks();
  magasinsListeTest = await MagasinServices.getAllMagasins();

  categorieNomTest = (await CategorieServices(db).getCategorieById(produit.categorieId))?.nom;
  sousCategorieNomTest = (await SousCategoriesServices(db).getSousCategorieById(produit.sousCategorieId))?.nom;
  remiseNomTest = produit.remiseId != null
      ? (await RemiseServices(db).getRemiseById(produit.remiseId!))?.nom
      : null;
  fournisseurNomTest = produit.fournisseurCode != null
      ? (await FournisseurServices.getFournisseurByCode(produit.fournisseurCode!))?.nom
      : null;

  final achats = await SmartScanProduitServices.getAllSmartScanProduits();
  prixMoyenTest = _calculerPrixMoyen(achats, produit.code);
  quantiteTest = await MouvementsServices.quantiteProduit(produit.code);
}

Future<void> StockDetail(BuildContext context, Produit produit) async {
  await _LoadAllData(produit: produit);
  final stats = await ProduitServices.getProduitStats(produit);

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;

      return BaseDialog(
        width: 1100,
        height: 700,

        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/sidebar/stock_icon.png",
                  width: 34,
                  height: 34,
                  color: Appstyle.violet,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produit.nom,
                        style: Appstyle.textLB.copyWith(fontSize: 20)),
                    Text("${l10n.code}: ${produit.code}", style: Appstyle.textSB),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    produit.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: produit.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: produit.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: produit.etat ? 2 : 0,
                )
              ],
            ),

            const SizedBox(height: 12),

            _resumeChiffre(produit, l10n, stats),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Première ligne avec General Information et Photos côte à côte
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// General Information - à gauche
                  Expanded(
                    flex: 2,
                    child: SectionDecoration(
                      title: l10n.generalInformation,
                      icon: Icons.info_outline,
                      child: detailwrap([
                        detailinfo(l10n.brand, produit.marque),
                        detailinfo(l10n.category, categorieNomTest),
                        detailinfo(l10n.subcategory, sousCategorieNomTest),
                        detailinfo(l10n.barcode, produit.codeBarre),
                        detailinfo(l10n.serialNumber, produit.numeroSerie),
                        detailinfo(l10n.multicode, produit.multicodebar == true ? l10n.yes : l10n.no),
                        detailinfo(l10n.service, produit.service == true ? l10n.yes : l10n.no),
                        detailinfo(l10n.discount, remiseNomTest),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 20),
                  /// Photos - à droite
                  Expanded(
                    flex: 1,
                    child: _buildPhotoSection(produit, l10n),
                  ),
                ],
              ),


              /// Prix et Taxes
              SectionDecoration(
                title: l10n.priceTaxes,
                icon: Icons.paid,
                child: detailwrap([
                  detailinfo(l10n.purchasePrice, "${produit.prixAchat} ${l10n.currency}"),
                  detailinfo(l10n.averagePrice, "${NumberFormatUtil.formatMontant(prixMoyenTest, decimales: 2)} ${l10n.currency}"),
                  detailinfo(l10n.salePrice, "${produit.prixVente} ${l10n.currency}"),
                  detailinfo(l10n.vat, "${produit.tva ?? 0}%"),
                  detailinfo(l10n.marginBool, produit.margeBool == true ? l10n.yes : l10n.no),
                  detailinfo(l10n.marginRate, produit.margeTaux),
                ]),
              ),

              /// Stock et Unité
              SectionDecoration(
                title: l10n.stockUnit,
                icon: Icons.garage,
                child: detailwrap([
                  detailinfo(l10n.quantity, quantiteTest),
                  detailinfo(l10n.numberField, produit.nombre),
                  detailinfo(l10n.unitOfMeasure, produit.uniteMesure),
                  detailinfo(l10n.dateBorrowed, produit.dateEmpreint),
                ]),
              ),

              /// Mouvements de stock
              SectionDecoration(
                title: l10n.stockMovements,
                icon: Icons.swap_vert,
                child: detailwrap([
                  detailinfo(l10n.lastPurchaseQuantity, stats.quantiteDernierAchat),
                  detailinfo(
                    l10n.lastPurchaseDate,
                    stats.dateDernierAchat?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.totalAchat, stats.totalAchat),
                  detailinfo(l10n.totalSold, stats.totalVendu),
                  detailinfo(l10n.clientReturns, stats.totalRetourClient),
                  detailinfo(l10n.supplierReturns, stats.totalRetourFournisseur),
                  detailinfo(l10n.need, stats.besoin ? l10n.yes : l10n.no),
                  detailinfo(l10n.needStatus, stats.besoinStatus),
                ]),
              ),


              /// Localisation et Spécifications
              SectionDecoration(
                title: l10n.locationSpecifications,
                icon: Icons.garage,
                child: detailwrap([
                  detailinfo(l10n.size, produit.taille),
                  detailinfo(l10n.color, produit.couleur),
                ]),
              ),


              /// Packs
              SectionDecoration(
                title: l10n.packs,
                icon: Icons.local_offer_outlined,
                child: _affichagePacks(produit, l10n),
              ),

              /// Magasins
              SectionDecoration(
                title: l10n.stores,
                icon: Icons.store_outlined,
                child: _affichageMagasins(produit, l10n),
              ),


              /// Fournisseur
              SectionDecoration(
                title: l10n.supplier,
                icon: Icons.people_alt_sharp,
                child: detailwrap([
                  detailinfo(l10n.supplier, fournisseurNomTest),
                ]),
              ),


              /// Emballage
              SectionDecoration(
                title: l10n.packaging,
                icon: Icons.backpack_rounded,
                child: detailwrap([
                  detailinfo(l10n.packaging1, produit.emballage1),
                  detailinfo(l10n.packaging2, produit.emballage2),
                ]),
              ),

              /// Observation
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    produit.observation?.isNotEmpty == true
                        ? produit.observation
                        : "-",
                  ),
                ]),
              ),


              /// Audit
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, produit.creeParcode),
                  detailinfo(l10n.dateCreated,
                      produit.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, produit.modifParCode),
                  detailinfo(l10n.modifiedAt,
                      produit.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, produit.annulerParCode),
                  detailinfo(l10n.cancellationReason, produit.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

        footer: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.close),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

/// 🆕 Section des photos à droite
// stock_detail.dart - Remplacez _buildPhotoSection
Widget _buildPhotoSection(Produit produit, AppLocalizations l10n) {
  return Container(
    margin: const EdgeInsets.only(left: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Appstyle.neutral100,
      borderRadius: BorderRadius.circular(Appstyle.radiusLG),
      border: Border.all(color: Appstyle.neutral150),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: Appstyle.violet, size: 20),
            const SizedBox(width: 8),
            Text(
              produit.photo != null && produit.photo!.isNotEmpty
                  ? l10n.photos
                  : l10n.noPhotos,
              style: Appstyle.textSB.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ✅ Affichage d'une seule photo
        if (produit.photo != null && produit.photo!.isNotEmpty)
          _buildSinglePhoto(produit.photo!)
        else
          _buildEmptyPhotosWidget(l10n),
      ],
    ),
  );
}

/// ✅ Nouvelle fonction pour une seule photo
Widget _buildSinglePhoto(String photoName) {
  return FutureBuilder<File?>(
    future: PhotoService.getPhotoFile(photoName),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data != null) {
        return GestureDetector(
          onTap: () => _showFullScreenPhoto(context, snapshot.data!.path),
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: Appstyle.shadowTint.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
              child: Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
              ),
            ),
          ),
        );
      }

      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Appstyle.neutral150,
          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        ),
        child: Center(
          child: snapshot.hasError
              ? Icon(Icons.broken_image, color: Appstyle.neutral300, size: 48)
              : const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    },
  );
}
/// Widget quand aucune photo
Widget _buildEmptyPhotosWidget(AppLocalizations l10n) {
  return Container(
    height: 300,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      border: Border.all(color: Appstyle.neutral150),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Appstyle.neutral300,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPhotos,
            style: TextStyle(
              color: Appstyle.neutral500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}



/// Élément photo individuel
Widget _buildPhotoItem(String photoName, int index) {
  return FutureBuilder<File?>(
    future: PhotoService.getPhotoFile(photoName),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data != null) {
        return GestureDetector(
          onTap: () => _showFullScreenPhoto(context, snapshot.data!.path),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: Appstyle.shadowTint.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
              child: Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        );
      }

      // État de chargement ou erreur
      return Container(
        decoration: BoxDecoration(
          color: Appstyle.neutral150,
          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        ),
        child: Center(
          child: snapshot.hasError
              ? Icon(Icons.broken_image, color: Appstyle.neutral300, size: 32)
              : const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    },
  );
}

/// Affichage plein écran d'une photo
void _showFullScreenPhoto(BuildContext context, String photoPath) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Aperçu photo',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              File(photoPath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}

// stock_detail.dart - Remplacer _resumeChiffre
Widget _resumeChiffre(Produit p, AppLocalizations l10n, ProduitStats stats) {
  return Column(
    children: [
      StatsCard(
        backgroundColor: Appstyle.violet.withOpacity(0.7),
        items: [
          StatsItem(
            label: l10n.quantity,
            value: quantiteTest,
            icon: Icons.inventory_2_outlined,
          ),
          StatsItem(
            label: l10n.purchasePrice,
            value: "${p.prixAchat} ${l10n.currency}",
            icon: Icons.shopping_bag_outlined,
          ),
          StatsItem(
            label: l10n.averagePrice,
            value: "${NumberFormatUtil.formatMontant(prixMoyenTest, decimales: 2)} ${l10n.currency}",
            icon: Icons.equalizer,
          ),
          StatsItem(
            label: l10n.salePrice,
            value: "${p.prixVente} ${l10n.currency}",
            icon: Icons.attach_money,
          ),
          StatsItem(
            label: l10n.margin,
            value: p.margeTaux,
            icon: Icons.trending_up,
          ),
        ],
      ),
      const SizedBox(height: 8),
      StatsCard(
        backgroundColor: Appstyle.indigo.withOpacity(0.7),
        items: [
          StatsItem(
            label: l10n.totalAchat,
            value: stats.totalAchat,
            icon: Icons.shopping_cart_outlined,
          ),
          StatsItem(
            label: l10n.totalSold,
            value: stats.totalVendu,
            icon: Icons.sell_outlined,
          ),
          StatsItem(
            label: l10n.totalReturns,
            value: stats.totalRetourClient + stats.totalRetourFournisseur,
            icon: Icons.undo,
          ),
          StatsItem(
            label: l10n.lastPurchaseDate,
            value: stats.dateDernierAchat?.toString().split(" ").first ?? '-',
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    ],
  );
}

Widget _affichagePacks(Produit produit, AppLocalizations l10n) {
  final packsProduit = produitPackDetailsTest
      .where((r) => r.produitCode == produit.code)
      .toList();

  if (packsProduit.isEmpty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        l10n.noPacks,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Wrap(
      spacing: 10,
      runSpacing: 8,
      children: packsProduit.map((r) {
        return Chip(
          label: Text(
            packsTest.firstWhereOrNull((p) => p.code == r.packCode)?.nom ?? r.packCode,
            style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
          ),
          backgroundColor: Appstyle.violet.withOpacity(0.8),
        );
      }).toList(),
    ),
  );
}

Widget _affichageMagasins(Produit produit, AppLocalizations l10n) {
  final magasinsProduit = produitsMagasinsTest
      .where((r) => r.produitCode == produit.code)
      .toList();

  if (magasinsProduit.isEmpty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        l10n.noStores,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Wrap(
      spacing: 10,
      runSpacing: 8,
      children: magasinsProduit.map((r) {
        final magasinNom = magasinsListeTest.firstWhereOrNull((m) => m.code == r.magasinCode)?.nom
            ?? r.magasinCode;
        return Chip(
          label: Text(
            magasinNom,
            style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
          ),
          backgroundColor: Appstyle.violet.withOpacity(0.8),
        );
      }).toList(),
    ),
  );
}