import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/magasin.dart';
import '../../../../l10n/app_localizations.dart';

// ✅ Ajouter l'import pour les services
import '../../../../Services/Produits.dart' hide ApiResponse;
import '../../../../data/models/produit.dart';
import '../../../DBCreate.dart';
import '../../../Services/MagasinDetail.dart';

class AfficheurMagasin extends StatelessWidget {
  final Magasin magasin;
  final VoidCallback? onDetails;

  const AfficheurMagasin({
    super.key,
    required this.magasin,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 🔹 Icône magasin
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.crevete.withOpacity(0.15),
                child: Icon(
                  Icons.warehouse,
                  size: 24,
                  color: Appstyle.crevete,
                ),
              ),
              const SizedBox(height: 6),
              _etatBadge(l10n),
            ],
          ),
          const SizedBox(width: 16),

          /// 🔹 Infos principales
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  magasin.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.code} : ${magasin.code}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          /// 🔹 Stats
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statCard(
                  l10n.state,
                  magasin.etat ? 1 : 0,
                  magasin.etat ? Colors.green : Colors.red,
                  customText: magasin.etat ? l10n.active : l10n.inactive,
                  isMoney: false,
                ),
                FutureBuilder<int>(
                  future: _getNombreProduits(),
                  builder: (context, snapshot) {
                    return _statCard(
                      l10n.productCount,
                      (snapshot.data ?? 0).toDouble(),
                      Appstyle.violet,
                      isMoney: false,
                      customText: "${snapshot.data ?? 0}",
                    );
                  },
                ),
              ],
            ),
          ),

          /// 🔹 Infos droite
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [],
            ),
          ),

          const SizedBox(width: 20),

          /// 🔹 Boutons d'action
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton Détails
              ElevatedButton(
                onPressed: onDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.violet,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 40),
                ),
                child: Text(
                  l10n.details,
                  style: Appstyle.textSB.copyWith(
                    color: Appstyle.Tblanc,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ✅ Bouton Liste des produits
              ElevatedButton(
                onPressed: () {
                  _showMagasinProductsListDialog(context, magasin, l10n);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.crevete,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.list, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.productsList,
                      style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<int> _getNombreProduits() async {
    final db = await DbCreator.openDb();
    final details = await ProduitMagasinDetailServices(db).getDetailsByMagasin(magasin.code);
    return details.length;
  }

  // ✅ Fonction pour afficher la liste des produits du magasin
  void _showMagasinProductsListDialog(
      BuildContext context,
      Magasin magasin,
      AppLocalizations l10n,
      ) async {
    try {
      // Récupérer les produits du magasin
      final db = await DbCreator.openDb();
      final service = ProduitMagasinDetailServices(db);
      final productDetails = await service.getDetailsByMagasin(magasin.code);


      // Récupérer les détails complets des produits
      final productService = ProduitServices(db);
      List<Produit> products = [];
      for (var detail in productDetails) {
        final product = await productService.getProduitByCode(detail.produitCode);
        if (product != null) {
          products.add(product);
        }
      }

      // Afficher la liste
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warehouse, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${l10n.products} - ${magasin.nom}",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 400,
            child: products.isEmpty
                ? Center(child: Text(l10n.noProduct))
                : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Appstyle.violet.withOpacity(0.1),
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(color: Appstyle.violet),
                      ),
                    ),
                    title: Text(
                      product.nom,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${l10n.code}: ${product.code} | ${l10n.quantity}: ${product.quantite.toStringAsFixed(0)}",
                    ),
                    trailing: Text(
                      "${product.prixVente.toStringAsFixed(2)} ${l10n.currency}",
                      style: TextStyle(
                        color: Appstyle.violet,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Erreur lors du chargement des produits: $e');
      // Afficher une erreur
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.error),
          content: Text("${l10n.noProduct}: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }
  }

  /// Badge état
  Widget _etatBadge(AppLocalizations l10n) {
    Color color = magasin.etat ? Colors.green : Colors.red;
    String label = magasin.etat ? l10n.active : l10n.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Stat Card
  Widget _statCard(
      String label,
      double value,
      Color color, {
        bool isMoney = false,
        String? suffix,
        String? customText,
      }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            customText ??
                "${value.toStringAsFixed(1)}${suffix ?? ""}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Info line
  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}