import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../DBCreate.dart';
import '../../../Services/MagasinDetail.dart';
import '../../../Services/Produits.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/magasin.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

List<Produit> produitsMagasin = [];
List<Produit> produitsTest    = [];
List<ProduitMagasinDetail> produitsMagasinsTest = [];

Future<void> laodAlldata({required Magasin magasine}) async {
  final db = await DbCreator.openDb();
  final produit = await ProduitServices.getAllProduits();
  final detail  = await ProduitMagasinDetailServices(db).getDetailsByMagasin(magasine.code);
  produitsTest  = produit;
  produitsMagasinsTest = detail;
}

Future<void> MagasinDetail(BuildContext context, Magasin magasin) async {
  await laodAlldata(magasine: magasin);
  final int nombreProduits = produitsMagasinsTest.length;
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width: 950,
        height: 600,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/sidebar/magasin_icon.png",
                  width: 34,
                  height: 34,
                  color: Appstyle.violet,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      magasin.nom ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${magasin.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    magasin.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeMagasin(magasin, l10n, nombreProduits),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= INFORMATIONS GENERALES =================
              SectionDecoration(
                title: l10n.generalInformation,
                icon: Icons.store_outlined,
                child: detailwrap([
                  detailinfo(l10n.name, magasin.nom),
                  detailinfo(l10n.address, magasin.adresse),
                  detailinfo(l10n.status, magasin.etat ? l10n.active : l10n.inactive),
                  detailinfo(l10n.productCount, nombreProduits),
                ]),
              ),

              // ================= OBSERVATION =================
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    magasin.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              // ================= AUDIT =================
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, magasin.creeParCode),
                  detailinfo(
                    l10n.createdAt,
                    magasin.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, magasin.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    magasin.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, magasin.annulParCode),
                  detailinfo(l10n.cancellationReason, magasin.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

        // ================= FOOTER =================
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: Text(l10n.productsList),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.crevete,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                showDialog(
                  barrierColor: Appstyle.gris.withOpacity(0.4),
                  context: context,
                  builder: (_) => _dialogListeProduitsRemise(context, magasin, l10n),
                );
              },
            ),

            const SizedBox(width: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: Text(l10n.close),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    },
  );
}

// ================= RESUME =================
Widget _resumeMagasin(Magasin m, AppLocalizations l10n, int nombreProduits) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.productCount, nombreProduits),
        detailbadge(l10n.status, m.etat ? l10n.active : l10n.inactive),
      ],
    ),
  );
}

Widget _dialogListeProduitsRemise(BuildContext context, Magasin magasin, AppLocalizations l10n) {
  final produits = produitsMagasinsTest
      .where((p) => p.magasinCode == magasin.code)
      .toList();

  return BaseDialog(
    width: 700,
    height: 550,

    // ───────── HEADER ─────────
    header: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.productsOfStore(magasin.code ?? ''),
            style: Appstyle.textLB,
          ),
          const SizedBox(height: 8),
          Text(
            "${l10n.store} : ${magasin.nom}",
            style: Appstyle.textSB,
          ),
        ],
      ),
    ),

    // ───────── CONTENT ─────────
    content: produits.isEmpty
        ? Center(
      child: Text(
        l10n.noProductsAssociated,
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
              columns: [
                DataColumn(label: Text(l10n.productCode)),
                DataColumn(label: Text(l10n.productName)),
              ],
              rows: produits.map((p) {
                final produitNom = produitsTest.firstWhereOrNull((pr) => pr.code == p.produitCode)?.nom ?? p.produitCode;
                return DataRow(
                  cells: [
                    DataCell(Text(p.produitCode)),
                    DataCell(Text(produitNom)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    ),

    // ───────── FOOTER ─────────
    footer: Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        icon: Icon(Icons.close, color: Appstyle.Tblanc),
        label: Text(
          l10n.close,
          style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Appstyle.violet,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  );
}