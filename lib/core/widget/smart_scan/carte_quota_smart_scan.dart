import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/smart_scan_quota.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Carte « quota Smart Scan » du module Smart Scan : forfait, scans utilisés
/// / limite, barre de progression, restants et date de renouvellement (ou
/// d'expiration de l'offre payante). Affiche uniquement ce que renvoie le
/// serveur — [quota] null + [chargement] faux = serveur injoignable.
class CarteQuotaSmartScan extends StatelessWidget {
  final SmartScanQuota? quota;
  final bool chargement;
  final VoidCallback? onRafraichir;

  const CarteQuotaSmartScan({
    super.key,
    required this.quota,
    this.chargement = false,
    this.onRafraichir,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final q = quota;
    final Color couleur = q == null
        ? Appstyle.gris
        : q.epuise
            ? Appstyle.red
            : q.progression >= 0.8
                ? Appstyle.warning
                : Appstyle.violet;

    return Container(
      width: 440,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        border: Border.all(color: couleur.withOpacity(0.25), width: 1.5),
        boxShadow: [BoxShadow(color: couleur.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: chargement
          ? const SizedBox(height: 70, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          : q == null
              ? Row(
                  children: [
                    Icon(Icons.cloud_off, color: couleur),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l10n.smartScanQuotaUnavailable, style: Appstyle.textSB.copyWith(color: couleur))),
                    if (onRafraichir != null) IconButton(icon: const Icon(Icons.refresh), onPressed: onRafraichir),
                  ],
                )
              : _contenu(l10n, q, couleur),
    );
  }

  Widget _contenu(AppLocalizations l10n, SmartScanQuota q, Color couleur) {
    final date = DateFormat('dd/MM/yyyy');
    final ligneDate = q.offreActive && q.finOffre != null
        ? l10n.smartScanOfferUntil(date.format(q.finOffre!))
        : q.renouvellement != null
            ? l10n.smartScanRenewal(date.format(q.renouvellement!))
            : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
              child: Icon(Icons.document_scanner_outlined, color: couleur, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(q.planNom, style: Appstyle.textSB.copyWith(color: couleur, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            if (onRafraichir != null)
              InkWell(
                borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                onTap: onRafraichir,
                child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.refresh, size: 18, color: Appstyle.gris)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l10n.smartScanUsed, style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
            const Spacer(),
            Text(
              '${q.utilises} / ${q.limiteMensuelle}',
              style: Appstyle.textSB.copyWith(color: couleur, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: q.progression,
            minHeight: 9,
            backgroundColor: couleur.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(couleur),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              l10n.smartScanRemaining(q.restants),
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600, color: couleur),
            ),
            const Spacer(),
            Text(ligneDate, style: Appstyle.textXS.copyWith(color: Appstyle.gris)),
          ],
        ),
      ],
    );
  }
}
