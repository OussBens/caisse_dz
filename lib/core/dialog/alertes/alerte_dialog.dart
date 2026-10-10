import 'package:caisse_dz/Services/Alertes.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';

/// Nombre maximum de lignes listées par section (le reste est résumé en
/// « + N autres », le module concerné donnant la liste complète).
const int _maxLignesParSection = 8;

/// Dialog « Alertes » : produits en rupture / expirés / bientôt expirés,
/// clients et fournisseurs au crédit le plus élevé, sessions de caisse non
/// clôturées. Chaque section n'est calculée et affichée que si l'utilisateur
/// a accès au module correspondant.
///
/// Ouvert par la cloche de l'en-tête (ConnectionStatusBar) et
/// automatiquement à la connexion avant le menu rapide (AppShell) — dans ce
/// cas [seulementSiAlertes] évite d'ouvrir un dialog vide.
Future<void> AlerteDialog(BuildContext context, {bool seulementSiAlertes = false}) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final role = auth.roleDetail;
  final admin = auth.estAdmin;
  final voirProduits = admin || role?.produit == true || role?.stock == true || role?.besoin == true;
  final voirClients = admin || role?.client == true;
  final voirFournisseurs = admin || role?.fournisseur == true;
  final voirSessions = admin || role?.gestionCaisse == true;

  final alertes = await AlertesServices.getAlertes(
    magasinsConsultation: auth.magasinsConsultation,
    produits: voirProduits,
    clients: voirClients,
    fournisseurs: voirFournisseurs,
    sessions: voirSessions,
  );
  AlertesServices.nombreAlertes.value = alertes.total;

  if (!context.mounted) return;
  if (seulementSiAlertes && alertes.total == 0) return;

  final router = GoRouter.of(context);
  // Module des produits : Besoin (qui a les onglets rupture / expirés) s'il
  // est accessible, sinon Produit.
  final routeProduits = admin || role?.besoin == true ? '/besoin' : '/produit';

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      final date = DateFormat('dd/MM/yyyy');
      String montant(double v) => "${NumberFormatUtil.formatMontant(v)} ${l10n.currency}";

      void ouvrirModule(String route) {
        Navigator.of(dialogContext).pop();
        router.go(route);
      }

      return BaseDialog(
        width: 1100,
        height: 720,
        header: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 34, color: Appstyle.violet),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.alerts, style: Appstyle.textLB.copyWith(fontSize: 20)),
                    Text(l10n.alertsSubtitle, style: Appstyle.textSB),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    date.format(DateTime.now()),
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.violet.withOpacity(0.8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatsCard(
              items: [
                if (voirProduits) ...[
                  StatsItem(label: l10n.outOfStockProducts, value: alertes.produitsRupture.length, icon: Icons.remove_shopping_cart_outlined),
                  StatsItem(label: l10n.expiredProducts, value: alertes.produitsExpires.length, icon: Icons.event_busy_outlined),
                  StatsItem(
                    label: l10n.expiringSoonProducts(AlertesServices.joursAvantExpiration),
                    value: alertes.produitsBientotExpires.length,
                    icon: Icons.hourglass_bottom,
                  ),
                ],
                if (voirSessions)
                  StatsItem(label: l10n.unclosedSessions, value: alertes.sessionsNonCloturees.length, icon: Icons.lock_open_outlined),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (voirProduits) ...[
                _section(
                  l10n: l10n,
                  titre: l10n.outOfStockProducts,
                  icone: Icons.remove_shopping_cart_outlined,
                  couleur: Appstyle.crevete,
                  onOuvrir: () => ouvrirModule(routeProduits),
                  lignes: [
                    for (final r in alertes.produitsRupture)
                      _Ligne(r.produit.nom, r.produit.code, "${l10n.quantity} : ${NumberFormatUtil.formatMontant(r.quantite, decimales: 0)}"),
                  ],
                ),
                _section(
                  l10n: l10n,
                  titre: l10n.expiredProducts,
                  icone: Icons.event_busy_outlined,
                  couleur: Appstyle.red,
                  onOuvrir: () => ouvrirModule(routeProduits),
                  lignes: [
                    for (final p in alertes.produitsExpires)
                      _Ligne(p.nom, p.code, l10n.expiresOn(date.format(p.dateEmpreint!))),
                  ],
                ),
                _section(
                  l10n: l10n,
                  titre: l10n.expiringSoonProducts(AlertesServices.joursAvantExpiration),
                  icone: Icons.hourglass_bottom,
                  couleur: Appstyle.jaune,
                  onOuvrir: () => ouvrirModule('/produit'),
                  lignes: [
                    for (final p in alertes.produitsBientotExpires)
                      _Ligne(p.nom, p.code, l10n.expiresOn(date.format(p.dateEmpreint!))),
                  ],
                ),
              ],
              if (voirClients)
                _section(
                  l10n: l10n,
                  titre: l10n.topClientsCredit,
                  icone: Icons.person_outline,
                  couleur: Appstyle.indigo,
                  onOuvrir: () => ouvrirModule('/client'),
                  lignes: [
                    for (final c in alertes.clientsCredit) _Ligne(c.client.nom, c.client.code, "${l10n.credit} : ${montant(c.credit)}"),
                  ],
                ),
              if (voirFournisseurs)
                _section(
                  l10n: l10n,
                  titre: l10n.topSuppliersCredit,
                  icone: Icons.local_shipping_outlined,
                  couleur: Appstyle.blueF,
                  onOuvrir: () => ouvrirModule('/fournisseur'),
                  lignes: [
                    for (final f in alertes.fournisseursCredit)
                      _Ligne(f.fournisseur.nom, f.fournisseur.code, "${l10n.credit} : ${montant(f.credit)}"),
                  ],
                ),
              if (voirSessions)
                _section(
                  l10n: l10n,
                  titre: l10n.unclosedSessions,
                  icone: Icons.lock_open_outlined,
                  couleur: Appstyle.maron,
                  onOuvrir: () => ouvrirModule('/gestion_caisse'),
                  lignes: [
                    for (final s in alertes.sessionsNonCloturees)
                      _Ligne(s.nomCaisse, s.session.code, l10n.openedOn(date.format(s.session.dateOuverture))),
                  ],
                ),
            ],
          ),
        ),
        footer: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.close),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    },
  );
}

class _Ligne {
  final String titre;
  final String code;
  final String valeur;

  const _Ligne(this.titre, this.code, this.valeur);
}

Widget _section({
  required AppLocalizations l10n,
  required String titre,
  required IconData icone,
  required Color couleur,
  required List<_Ligne> lignes,
  required VoidCallback onOuvrir,
}) {
  final visibles = lignes.take(_maxLignesParSection).toList();
  final reste = lignes.length - visibles.length;

  return SectionDecoration(
    title: "$titre (${lignes.length})",
    icon: icone,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lignes.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Appstyle.green, size: 18),
                const SizedBox(width: 6),
                Text(l10n.noAlert, style: Appstyle.textSB.copyWith(color: Appstyle.green)),
              ],
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final l in visibles) _carteLigne(l, couleur)],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (reste > 0) Text(l10n.andMore(reste), style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
              const Spacer(),
              TextButton.icon(
                onPressed: onOuvrir,
                icon: Icon(Icons.open_in_new, size: 16, color: couleur),
                label: Text(l10n.openModule, style: Appstyle.textSB.copyWith(color: couleur)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _carteLigne(_Ligne l, Color couleur) {
  return Container(
    width: 245,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: couleur.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.titre, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(l.code, style: Appstyle.textXS.copyWith(color: Appstyle.gris)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(l.valeur, style: Appstyle.textXS.copyWith(color: couleur, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
