import 'package:flutter/material.dart';
import 'package:caisse_dz/core/dialog/pack/pack_detail.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../Services/PackDetailes.dart';
import '../../../../data/models/pack.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurPack extends StatelessWidget {
  final Pack pack;
  final VoidCallback? onDetails;

  const AfficheurPack({
    super.key,
    required this.pack,
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
                backgroundColor: Colors.deepPurple.withOpacity(0.15),
                child: const Icon(
                  Icons.all_inbox,
                  color: Colors.deepPurple,
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
                  pack.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pack.code != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "${l10n.code} : ${pack.code}",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
                if (pack.observation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    pack.observation!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
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
                const SizedBox(width: 16),
                _statCard(
                  l10n.totalQuantity,
                  (pack.quantiteTotale ?? 0).toDouble(),
                  Colors.orange,
                  isMoney: false,
                  l10n: l10n,
                ),
                const SizedBox(width: 16),
                _statCard(
                  l10n.price,
                  pack.prixVente ?? 0,
                  Colors.green,
                  l10n: l10n,
                ),
                const SizedBox(width: 16),
                FutureBuilder<int>(
                  future: ProduitPackDetailServices.getDetailsByPackNom(pack.code)
                      .then((details) => details.length),
                  builder: (context, snapshot) {
                    return _statCard(
                      l10n.productCount,
                      (snapshot.data ?? 0).toDouble(),
                      Appstyle.violet,
                      isMoney: false,
                      l10n: l10n,
                    );
                  },
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
                _infoLine(Icons.person, "${l10n.createdBy} : ${pack.creeParCode ?? "—"}"),
                _infoLine(
                  Icons.calendar_today,
                  "${l10n.dateCreated} : ${_formatDate(pack.creeLe as DateTime)}",
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
              // Bouton Liste des produits
              // Dans AfficheurPack, modifiez le bouton "Liste des produits"
              ElevatedButton(
                onPressed: () {
                  // Appel de la fonction dédiée pour la liste des produits
                  showPackProductsListDialog(context, pack, l10n);
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
                      l10n.productList,
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

  Widget _etatBadge(AppLocalizations l10n) {
    final Color color = pack.etat ? Colors.green : Colors.red;
    final String label = pack.etat ? l10n.active : l10n.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statCard(
      String label,
      double value,
      Color color, {
        bool isMoney = true,
        required AppLocalizations l10n,
      }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            isMoney
                ? "${NumberFormatUtil.formatMontant(value, decimales: 0)} ${l10n.currency}"
                : NumberFormatUtil.formatMontant(value, decimales: 0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
}