import 'dart:io';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/qr_code_avec_impression.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import '../../../../data/models/produit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../DBCreate.dart';
import '../../../Services/Categorie.dart';
import '../../../Services/Fournisseur.dart';
import '../../../Services/Photos.dart';
import '../../../Services/Mouvement.dart';
import '../../../Services/Produits.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurProduit extends StatelessWidget {
  final Produit produit;
  final VoidCallback? onDetails;
  final bool afficherprixachat;
  final bool afficheurBorder;
  final bool afficherStatsAvancees;
  final bool detail_but_icon; // 👈 NOUVEAU PARAMÈTRE

  const AfficheurProduit({
    super.key,
    required this.produit,
    this.onDetails,
    this.afficherprixachat = true,
    this.afficheurBorder = false,
    this.afficherStatsAvancees = true,
    this.detail_but_icon = false, // 👈 VALEUR PAR DÉFAUT
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: afficheurBorder ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        border: afficheurBorder
            ? Border.all(
          color: Colors.black.withOpacity(0.2),
          width: 1,
        )
            : null,
        boxShadow: afficheurBorder
            ? null
            : [
          BoxShadow(
            color: Appstyle.shadowTint.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
              produit.nom,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          Row(
            children: [
              /// 🆕 PHOTO DU PRODUIT
              _buildProductPhoto(context),

              const SizedBox(width: 16),

              /// 🔹 Infos principales
              Expanded(
                flex:6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [

                        if (produit.remiseId != null) ...[
                          _remiseBadge(l10n),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${l10n.marque} : ${produit.marque}",
                      style: TextStyle(color: Appstyle.ink500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${l10n.code} : ${produit.code}",
                      style: TextStyle(color: Appstyle.ink500),
                    ),
                  ],
                ),
              ),

              /// 🔹 Stats Produit
              Expanded(
                flex: 12,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _statCard(l10n.salePrice, produit.prixVente, Appstyle.success, l10n: l10n),
                    if (afficherprixachat)
                      _statCard(l10n.purchasePrice, produit.prixAchat, Appstyle.warning, l10n: l10n),
                    FutureBuilder<double>(
                      future: MouvementsServices.quantiteProduit(produit.code),
                      builder: (context, snapshot) {
                        return _statCard(l10n.quantity, snapshot.data ?? 0, Appstyle.info, isMoney: false, l10n: l10n);
                      },
                    ),
                    if (afficherStatsAvancees)
                      FutureBuilder<ProduitStats>(
                        future: ProduitServices.getProduitStats(produit),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final stats = snapshot.data!;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _statCard(l10n.totalSold, stats.totalVendu, Appstyle.successInk, isMoney: false, l10n: l10n),
                              _statCard(l10n.clientReturns, stats.totalRetourClient, Appstyle.danger, isMoney: false, l10n: l10n),
                              _textBadge(l10n.need, stats.besoin ? l10n.yes : l10n.no, stats.besoin ? Appstyle.danger : Appstyle.success),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),

              /// 🔹 Infos droite
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String?>(
                      future: _nomCategorie(produit.categorieId),
                      builder: (context, snapshot) => _infoLine(
                        Icons.category,
                        "${l10n.categorie} : ${snapshot.data ?? "—"}",
                      ),
                    ),
                    FutureBuilder<String?>(
                      future: _nomFournisseur(produit.fournisseurCode),
                      builder: (context, snapshot) => _infoLine(
                        Icons.local_shipping,
                        "${l10n.fournisseur} : ${snapshot.data ?? "—"}",
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        detail_but_icon
                            ? _buildIconButton(context, l10n) // 👈 Bouton icône
                            : _buildTextButton(context, l10n), // 👈 Bouton texte
                        if (_aCodeBarreGenereEnInterne) ...[
                          const SizedBox(width: 8),
                          _buildImprimerCodeBarreButton(context, l10n),
                        ],
                      ],
                    ),
                  ],
                ),
              ),


              /// 🔹 Bouton Détails (conditionnel)
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Vrai si le code barre du produit a été généré automatiquement en
  /// interne (préfixe CDZ, cf. [ProduitServices.generateAutoBarcode]) : ce
  /// code n'existe sur aucune étiquette physique, il faut donc pouvoir
  /// réimprimer son code barre/QR code.
  bool get _aCodeBarreGenereEnInterne {
    final code = produit.codeBarre;
    return code != null && code.startsWith(CodePrefix.barcode);
  }

  /// 🟣 Bouton d'impression du code barre/QR code auto-généré (CDZ)
  Widget _buildImprimerCodeBarreButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Appstyle.indigo,
        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Appstyle.indigo.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.print, color: Colors.white, size: 18),
        onPressed: () => _afficherDialogCodeBarre(context, l10n),
        tooltip: l10n.print,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 20),
      ),
    );
  }

  void _afficherDialogCodeBarre(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierColor: Appstyle.gris.withOpacity(0.4),
      builder: (_) => BaseDialog(
        width: 420,
        height: 460,
        header: TitreAvecLigne(
          imagePath: 'assets/icons/sidebar/produit_icon.png',
          text: l10n.barcode,
        ),
        content: SingleChildScrollView(
          child: QrCodeAvecImpression(
            code: produit.codeBarre!,
            sousLabel: produit.nom,
          ),
        ),
        footer: Align(
          alignment: Alignment.centerRight,
          child: MainButton(
            text: l10n.close,
            color: Appstyle.gris,
            icon: Icons.close,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  /// 🔵 Bouton texte original (MainButton)
  Widget _buildTextButton(BuildContext context, AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: onDetails,
      style: ElevatedButton.styleFrom(
        backgroundColor: Appstyle.violet,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        ),
      ),
      child: Text(
        l10n.details,
        style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
      ),
    );
  }

  /// 🟣 Bouton icône avec point d'interrogation
  Widget _buildIconButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Appstyle.violet,
        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Appstyle.violet.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.question_mark,
          color: Colors.white,
          size: 18,
        ),
        onPressed: onDetails,
        tooltip: l10n.details,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        constraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 20,
        ),
      ),
    );
  }

  Future<String?> _nomCategorie(int categorieId) async {
    final db = await DbCreator.openDb();
    return (await CategorieServices(db).getCategorieById(categorieId))?.nom;
  }

  Future<String?> _nomFournisseur(String? fournisseurCode) async {
    if (fournisseurCode == null) return null;
    return (await FournisseurServices.getFournisseurByCode(fournisseurCode))?.nom;
  }

  /// 🆕 Widget pour afficher la photo
  Widget _buildProductPhoto(BuildContext context) {
    if (produit.photo == null || produit.photo!.isEmpty) {
      final Color couleur = Appstyle.couleurSousCategorie(produit.sousCategorieId);
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        ),
        child: Icon(
          Icons.inventory_2,
          size: 35,
          color: couleur.withOpacity(0.6),
        ),
      );
    }

    return FutureBuilder<File?>(
      future: PhotoService.getPhotoFile(produit.photo),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            child: Image.file(
              snapshot.data!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          );
        }

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Appstyle.neutral150,
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
          ),
          child: const Icon(
            Icons.broken_image,
            size: 30,
            color: Appstyle.gris,
          ),
        );
      },
    );
  }

  Widget _remiseBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Appstyle.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 12, color: Appstyle.warning),
          const SizedBox(width: 4),
          Text(
            l10n.discount,
            style: const TextStyle(
              color: Appstyle.warning,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _etatBadge(AppLocalizations l10n, {double quantite = 0}) {
    Color color = produit.etat ? Appstyle.success : Appstyle.danger;
    String label = produit.etat ? l10n.active : l10n.inactive;

    if (quantite <= 0) {
      color = Appstyle.warning;
      label = l10n.outOfStock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
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
      width: 100,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            isMoney
                ? "${NumberFormatUtil.formatMontant(value, decimales: 0)} ${l10n.currency}"
                : NumberFormatUtil.formatMontant(value, decimales: 0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷 Badge texte (besoin / statut besoin)
  Widget _textBadge(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
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
          Icon(icon, size: 16, color: Appstyle.gris),
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