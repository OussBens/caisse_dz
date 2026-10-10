import 'package:caisse_dz/Services/SmartScanQuota.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/data/models/smart_scan_quota.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../base_dialog.dart';

/// « Quota Smart Scan atteint » : rappelle la limite du forfait actuel et
/// propose l'offre supérieure renvoyée par le serveur (nom, prix, quota —
/// rien n'est codé dans l'application). « Demander l'offre » enregistre la
/// demande côté BENS (activée ensuite depuis l'administration) ; le résultat
/// s'affiche dans ce même dialog, sans en ouvrir un second.
Future<void> QuotaSmartScanAtteintDialog(BuildContext context, SmartScanQuota quota) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _QuotaSmartScanAtteint(quota: quota),
  );
}

class _QuotaSmartScanAtteint extends StatefulWidget {
  final SmartScanQuota quota;

  const _QuotaSmartScanAtteint({required this.quota});

  @override
  State<_QuotaSmartScanAtteint> createState() => _QuotaSmartScanAtteintState();
}

class _QuotaSmartScanAtteintState extends State<_QuotaSmartScanAtteint> {
  bool _envoiEnCours = false;
  String? _resultat;
  bool _resultatOk = false;
  String _contact = '';

  SmartScanOffre? get _offre => widget.quota.offres.isEmpty ? null : widget.quota.offres.first;

  Future<void> _demander(AppLocalizations l10n) async {
    final offre = _offre;
    if (offre == null || _envoiEnCours) return;
    setState(() => _envoiEnCours = true);
    final r = await SmartScanQuotaServices.demanderOffre(offre.code);
    if (!mounted) return;
    setState(() {
      _envoiEnCours = false;
      _resultatOk = r.succes;
      _contact = r.contact.isNotEmpty ? r.contact : widget.quota.contact;
      _resultat = !r.succes
          ? l10n.smartScanRequestFailed
          : r.dejaDemandee
              ? l10n.smartScanRequestAlreadySent
              : l10n.smartScanRequestSent;
    });
  }

  String _prix(AppLocalizations l10n, SmartScanOffre o) {
    final montant = NumberFormat.decimalPattern('fr').format(o.prixDa);
    return o.dureeMois == 12 ? l10n.smartScanPricePerYear(montant) : l10n.smartScanPricePerMonths(montant, o.dureeMois);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offre = _offre;
    final q = widget.quota;

    return BaseDialog(
      width: 560,
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Appstyle.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
            child: const Icon(Icons.document_scanner_outlined, color: Appstyle.warning, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.smartScanQuotaReachedTitle, style: Appstyle.textLB.copyWith(fontSize: 19))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.smartScanQuotaReachedMessage(q.limiteMensuelle), style: Appstyle.textSB),
          const SizedBox(height: 14),
          if (offre != null) ...[
            Text(l10n.smartScanUpgradeMessage(offre.nom, offre.quotaMensuel), style: Appstyle.textSB),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Appstyle.violetC,
                borderRadius: BorderRadius.circular(Appstyle.radiusButton),
                border: Border.all(color: Appstyle.violet.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined, color: Appstyle.violet, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(offre.nom, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.w700, color: Appstyle.violet, fontSize: 16)),
                        Text(l10n.smartScanScansPerMonth(offre.quotaMensuel), style: Appstyle.textXS.copyWith(color: Appstyle.gris)),
                      ],
                    ),
                  ),
                  Text(_prix(l10n, offre), style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.violet, fontSize: 17)),
                ],
              ),
            ),
          ] else if (q.renouvellement != null)
            Text(l10n.smartScanNoUpgrade(DateFormat('dd/MM/yyyy').format(q.renouvellement!)), style: Appstyle.textSB),
          if (_resultat != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(_resultatOk ? Icons.check_circle : Icons.error_outline, color: _resultatOk ? Appstyle.green : Appstyle.red),
                const SizedBox(width: 8),
                Expanded(child: Text(_resultat!, style: Appstyle.textSB)),
              ],
            ),
            if (_contact.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(l10n.smartScanContact(_contact), style: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600)),
            ],
          ],
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MainButton(
            text: l10n.close,
            color: Appstyle.gris,
            icon: Icons.close,
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (offre != null && !_resultatOk) ...[
            const SizedBox(width: 10),
            MainButton(
              text: l10n.smartScanRequestOffer,
              color: Appstyle.violet,
              icon: Icons.send_outlined,
              loading: _envoiEnCours,
              onPressed: () => _demander(l10n),
            ),
          ],
        ],
      ),
    );
  }
}
