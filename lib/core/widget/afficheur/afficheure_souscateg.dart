import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../../../l10n/app_localizations.dart';

// ✅ Ajouter l'import pour les services
import '../../../../Services/Produits.dart' hide ApiResponse;
import '../../../../DBCreate.dart';

class AfficheurSousCategorie extends StatelessWidget {
  final SousCategorie sousCategorie;
  final int nombreProduits;
  final VoidCallback? onDetails;

  const AfficheurSousCategorie({
    super.key,
    required this.sousCategorie,
    this.nombreProduits = 0,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
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
          /// 🔹 Icône + état
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange.withOpacity(0.15),
                child: const Icon(
                  Icons.layers,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              _etatBadge(l10n),
            ],
          ),
          const SizedBox(width: 16),

          /// 🔹 Infos principales
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sousCategorie.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.code} : ${sousCategorie.code}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (sousCategorie.observation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sousCategorie.observation!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
                if (sousCategorie.categorieNom != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sousCategorie.categorieNom!,
                        style: TextStyle(
                          color: Appstyle.blueF,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          /// 🔹 Statistiques
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _statCard(
                  l10n.productCount,
                  nombreProduits.toDouble(),
                  Appstyle.violet,
                  isMoney: false,
                  l10n: l10n,
                ),
              ],
            ),
          ),

          /// 🔹 Infos système
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.person, "${l10n.createdBy} : ${sousCategorie.creeParCode ?? "—"}"),
                _infoLine(
                  Icons.calendar_today,
                  sousCategorie.dateCree != null
                      ? "${l10n.createdAt} : ${_formatDate(sousCategorie.dateCree!)}"
                      : "—",
                ),
              ],
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
                  style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                ),
              ),
              const SizedBox(height: 8),
              // ✅ Bouton Liste des produits
              ElevatedButton(
                onPressed: () {
                  _showSousCategorieProductsListDialog(context, sousCategorie, l10n);
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

  // ✅ Fonction pour afficher la liste des produits de la sous-catégorie
  void _showSousCategorieProductsListDialog(
      BuildContext context,
      SousCategorie sousCategorie,
      AppLocalizations l10n,
      ) async {
    try {
      final db = await DbCreator.openDb();
      final service = ProduitServices(db);

      // Récupérer les produits par sous-catégorie
      final products = await service.getProduitsBySousCategorie(sousCategorie.nom);

      if (products.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("${l10n.products} - ${sousCategorie.nom}"),
            content: Text(l10n.noProduct),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
        return;
      }

      // Afficher la liste
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.layers, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${l10n.products} - ${sousCategorie.nom}",
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.error),
          content: Text("${l10n.error}: $e"),
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

  /// 🟢 Badge état
  Widget _etatBadge(AppLocalizations l10n) {
    final bool actif = sousCategorie.etat;
    final Color color = actif ? Colors.green : Colors.red;
    final String label = actif ? l10n.active : l10n.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  /// 📊 Carte statistique
  Widget _statCard(
      String label,
      double value,
      Color color, {
        bool isMoney = true,
        required AppLocalizations l10n,
      }) {
    return Container(
      width: 110,
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
            isMoney
                ? "${value.toStringAsFixed(0)} ${l10n.currency}"
                : value.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ℹ Ligne info
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

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }
}