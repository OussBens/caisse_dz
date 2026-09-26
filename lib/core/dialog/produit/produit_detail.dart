import 'dart:io';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../Services/Photos.dart';
import '../../../Services/EntrepriseParam.dart';
import '../../../data/constant.dart';
import '../../../data/models/magasin.dart';
import '../../../data/models/produit.dart';
import '../../widget/detail_widget.dart';
import '../../widget/qr_code_avec_impression.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

List<ProduitPackDetail> produitPackDetailsTest = [];
List<ProduitMagasinDetail> produitsMagasinsTest = [];
List<Magasin> magasinsListeTest = [];
List<Pack> packsTest = [];
String? categorieNomTest;
String? sousCategorieNomTest;
String? remiseNomTest;
String? boutiqueNomTest;
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

Future<void> loadAllData({required Produit prd}) async {
  try {
    final magasintest = await ProduitMagasinDetailServices.getDetailsByCode(prd.code);
    final packtest = await ProduitPackDetailServices.getDetailsByNom(prd.code);
    produitsMagasinsTest = magasintest;
    produitPackDetailsTest = packtest;
    packsTest = await PackServices.getAllPacks();
    magasinsListeTest = await MagasinServices.getAllMagasins();

    final db = await DbCreator.openDb();
    categorieNomTest = (await CategorieServices(db).getCategorieById(prd.categorieId))?.nom;
    sousCategorieNomTest = (await SousCategoriesServices(db).getSousCategorieById(prd.sousCategorieId))?.nom;
    remiseNomTest = prd.remiseId != null
        ? ((await RemiseServices(db).getRemiseById(prd.remiseId!))?.nom ?? "-")
        : "-";
    boutiqueNomTest = (await EntrepriseParamServices.getEntrepriseParam()).nomBoutique;

    final achats = await SmartScanProduitServices.getAllSmartScanProduits();
    prixMoyenTest = _calculerPrixMoyen(achats, prd.code);
    quantiteTest = await MouvementsServices.quantiteProduit(prd.code);
  } catch (e) {
    debugPrint("Erreur chargement : $e");
  }
}

Future<void> ProduitDetail(BuildContext context, Produit produit) async {
  await loadAllData(prd: produit);
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
                  "assets/icons/sidebar/produit_icon.png",
                  width: 34,
                  height: 34,
                  color: Appstyle.violet,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${produit.code}",
                      style: Appstyle.textSB,
                    ),
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
            const SizedBox(height: 16),
            _resumeChiffre(produit, l10n),
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
                        detailinfo(l10n.serialNumber, produit.numeroSerie??"-"),
                        detailinfo(l10n.multicode, produit.multicodebar ? l10n.yes : l10n.no),
                        detailinfo(l10n.service, produit.service ? l10n.yes : l10n.no),
                        detailinfo(l10n.discount, remiseNomTest),
                      ]),
                    ),
                  ),
                  /// Photos + code-barre - à droite
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPhotoSection(produit, l10n),
                      ],
                    ),
                  ),

            if (produit.codeBarre != null && produit.codeBarre!.trim().isNotEmpty) ...[
                 Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          _buildQrCodeSection(produit, l10n, boutiqueNomTest),
                      ],
                    ),
                  ),
                        ],
                ],
              ),

              /// Description
              SectionDecoration(
                title: l10n.description,
                icon: Icons.description_outlined,
                child: Text(
                  produit.description ?? "-",
                  style: Appstyle.textSB,
                ),
              ),

              /// Prix et Taxes
              SectionDecoration(
                title: l10n.priceTaxes,
                icon: Icons.payments_outlined,
                child: detailwrap([
                  detailinfo(l10n.purchasePrice, "${produit.prixAchat} ${l10n.currency}"),
                  detailinfo(l10n.averagePrice, "${NumberFormatUtil.formatMontant(prixMoyenTest, decimales: 2)} ${l10n.currency}"),
                  detailinfo(l10n.salePrice, "${produit.prixVente} ${l10n.currency}"),
                  detailinfo(l10n.vat, "${produit.tva ?? 0}%"),
                  detailinfo(l10n.marginBool, produit.margeBool ? l10n.yes : l10n.no),
                  detailinfo(l10n.marginRate, produit.margeTaux),
                  detailinfo(l10n.marginRatePercent, produit.margeTauxPrct),
                ]),
              ),

              /// Stock et Unité
              SectionDecoration(
                title: l10n.stockUnit,
                icon: Icons.inventory_2_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    detailwrap([
                      detailinfo(l10n.quantity, quantiteTest),
                      detailinfo(l10n.numberField, produit.nombre),
                      detailinfo(l10n.unitOfMeasure, produit.uniteMesure),

                      // ✅ Emballage 1
                      detailinfo(
                        "${l10n.packaging1} (Qté)",
                        produit.emballage1 != null && produit.emballage1! > 0
                            ? "${produit.emballage1!.toInt()} pièce(s)"
                            : "-",
                      ),
                      detailinfo(
                        "${l10n.packaging1} (Prix)",
                        produit.emballageP1 != null && produit.emballageP1! > 0
                            ? "${NumberFormatUtil.formatMontant(produit.emballageP1!, decimales: 2)} ${l10n.currency}"
                            : "-",
                      ),

                      // ✅ Prix par pièce pour emballage 1
                      if (produit.emballage1 != null && produit.emballage1! > 0 &&
                          produit.emballageP1 != null && produit.emballageP1! > 0)
                        detailinfo(
                          "💰 Prix/pièce (${l10n.packaging1})",
                          "${NumberFormatUtil.formatMontant((produit.emballageP1! / produit.emballage1!), decimales: 2)} ${l10n.currency}",
                          isHighlight: true,
                        ),

                      // ✅ Emballage 2
                      detailinfo(
                        "${l10n.packaging2} (Qté)",
                        produit.emballage2 != null && produit.emballage2! > 0
                            ? "${produit.emballage2!.toInt()} pièce(s)"
                            : "-",
                      ),
                      detailinfo(
                        "${l10n.packaging2} (Prix)",
                        produit.emballageP2 != null && produit.emballageP2! > 0
                            ? "${NumberFormatUtil.formatMontant(produit.emballageP2!, decimales: 2)} ${l10n.currency}"
                            : "-",
                      ),

                      // ✅ Prix par pièce pour emballage 2
                      if (produit.emballage2 != null && produit.emballage2! > 0 &&
                          produit.emballageP2 != null && produit.emballageP2! > 0)
                        detailinfo(
                          "💰 Prix/pièce (${l10n.packaging2})",
                          "${NumberFormatUtil.formatMontant((produit.emballageP2! / produit.emballage2!), decimales: 2)} ${l10n.currency}",
                          isHighlight: true,
                        ),

                      detailinfo(l10n.dateBorrowed, produit.dateEmpreint),
                    ]),
                  ],
                ),
              ),

              /// Localisation et Spécifications
              SectionDecoration(
                title: l10n.locationSpecifications,
                icon: Icons.category_outlined,
                child: detailwrap([
                  detailinfo(l10n.size, produit.taille),
                  detailinfo(l10n.color, produit.couleur),
                ]),
              ),

              /// Mouvements de stock
              SectionDecoration(
                title: l10n.stockMovements,
                icon: Icons.swap_vert,
                child: detailwrap([
                  detailinfo(l10n.totalAchat, stats.totalAchat),
                  detailinfo(l10n.totalSold, stats.totalVendu),
                  detailinfo(l10n.clientReturns, stats.totalRetourClient),
                  detailinfo(l10n.supplierReturns, stats.totalRetourFournisseur),
                  detailinfo(l10n.need, stats.besoin ? l10n.yes : l10n.no),
                  detailinfo(l10n.needStatus, stats.besoinStatus),
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

              /// Observation
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: Text(
                  produit.observation ?? "-",
                  style: Appstyle.textSB,
                ),
              ),

              /// Audit
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, produit.creeParcode),
                  detailinfo(l10n.dateCreated, produit.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, produit.modifParCode),
                  detailinfo(l10n.modifiedAt, produit.dateModif?.toString().split(" ").first),
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
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

/// 🆕 Section des photos à droite
// produit_detail.dart - Modifiez _buildPhotoSection
Widget _buildPhotoSection(Produit produit, AppLocalizations l10n) {
  return Container(
    margin: const EdgeInsets.only(left: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: Appstyle.violet, size: 20),
            const SizedBox(width: 8),
            Text(
              produit.photo != null ? l10n.photos : l10n.noPhotos,
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

/// 🆕 Section code-barre (QR) + bouton imprimer, affichée uniquement si le
/// produit a un code barre (physique ou auto-généré).
Widget _buildQrCodeSection(Produit produit, AppLocalizations l10n, String? boutiqueNom) {
  return Container(
    margin: const EdgeInsets.only(left: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.qr_code_2, color: Appstyle.violet, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.barcode,
              style: Appstyle.textSB.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: QrCodeAvecImpression(
            code: produit.codeBarre!,
            sousLabel: boutiqueNom,
            afficherImpression: produit.codeBarre!.startsWith(CodePrefix.barcode),
          ),
        ),
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
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: snapshot.hasError
              ? Icon(Icons.broken_image, color: Colors.grey[400], size: 48)
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
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPhotos,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
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
          title: const Text(
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

// Dans produit_detail.dart
Widget _resumeChiffre(Produit p, AppLocalizations l10n) {
  return StatsCard(
    items: [
      StatsItem(
        label: l10n.quantity,
        value: quantiteTest,
      ),
      StatsItem(
        label: l10n.purchasePrice,
        value: "${p.prixAchat} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.averagePrice,
        value: "${NumberFormatUtil.formatMontant(prixMoyenTest, decimales: 2)} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.salePrice,
        value: "${p.prixVente} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.margin,
        value: p.margeTaux,
      ),
    ],
  );
}

Widget _affichagePacks(Produit produit, AppLocalizations l10n) {
  final packsProduit = produitPackDetailsTest
      .where((r) => r.produitCode == produit.code)
      .toList();

  if (packsProduit.isEmpty) {
    return Text(
      l10n.noPacks,
      style: Appstyle.textSB.copyWith(color: Appstyle.gris),
    );
  }

  return Wrap(
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
  );
}

Widget _affichageMagasins(Produit produit, AppLocalizations l10n) {
  if (produitsMagasinsTest.isEmpty) {
    return Text(
      l10n.noStores,
      style: Appstyle.textSB.copyWith(color: Appstyle.gris),
    );
  }

  return Wrap(
    spacing: 10,
    runSpacing: 8,
    children: produitsMagasinsTest.map((r) {
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
  );
}
Widget detailinfo(String label, dynamic value, {bool isHighlight = false}) {
  if (value == null || value.toString().isEmpty) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            "$label :",
            style: Appstyle.textXSB.copyWith(
              color: Appstyle.gris,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.toString(),
            style: Appstyle.textSB.copyWith(
              color: isHighlight ? Appstyle.violet : Appstyle.Tnoir,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}