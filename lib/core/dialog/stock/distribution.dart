import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/RepartitionStock.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Distribution d'un produit entre les magasins de l'utilisateur (Admin :
/// tous les magasins) : on choisit les magasins et la quantité de chacun.
/// Le total ne change jamais — c'est un déplacement de stock, enregistré en
/// mouvements « Distribution » (sortie des magasins qui perdent, entrée dans
/// ceux qui gagnent), sous un même code d'opération. Voir RepartitionStock.
Future<bool> DistributionProduit(BuildContext context, Produit produit) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final l10n = AppLocalizations.of(context)!;
  final userCode = auth.userCode;
  if (!auth.isAuthenticated || userCode == null) return false;

  final ordre = auth.magasins;
  final tousMagasins = await MagasinServices.getAllMagasins();
  final magasins = [
    for (final code in ordre)
      tousMagasins.where((m) => m.code == code).firstOrNull ??
          Magasin(id: 0, code: code, nom: code, etat: true, dateCree: DateTime.now(), creeParCode: ''),
  ];
  final actuel = await MouvementsServices.quantitesParMagasin(produit.code, magasins: ordre);
  final total = ordre.fold<double>(0, (s, m) => s + (actuel[m] ?? 0));

  if (!context.mounted) return false;
  if (total <= 0) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.information,
      titre_concerne: l10n.productDistribution,
      message: l10n.distributionNothing,
    );
    return false;
  }

  // Magasins cochés : ceux qui ont du stock, au moins le principal.
  final coches = <String>{
    for (final m in ordre)
      if ((actuel[m] ?? 0) != 0) m,
  };
  if (coches.isEmpty) coches.add(ordre.first);
  final controllers = {
    for (final m in ordre)
      m: TextEditingController(text: QuantiteFormat.formatPour((actuel[m] ?? 0).clamp(0, double.infinity), produit.uniteMesure)),
  };

  Map<String, double> cibles() => {
        for (final m in ordre)
          m: coches.contains(m) ? (double.tryParse(controllers[m]!.text.replaceAll(',', '.')) ?? 0) : 0,
      };

  final resultat = await showDialog<bool>(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final reparti = cibles().values.fold<double>(0, (a, b) => a + b);
        final reste = total - reparti;
        final valide = RepartitionStock.distributionValide(total, cibles());
        String q(double v) => QuantiteFormat.formatPour(v, produit.uniteMesure);

        Widget compteur(String label, String valeur, Color couleur) => Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: couleur.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    Text(label, style: Appstyle.textXS.copyWith(color: couleur)),
                    const SizedBox(height: 4),
                    Text(valeur, style: Appstyle.textSB.copyWith(color: couleur, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            );

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: BaseDialog(
              width: 700,
              header: TitreAvecLigne(
                imagePath: 'assets/icons/action/distribution_icon.png',
                text: '${l10n.productDistribution} — ${produit.nom}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.distributionHelp, style: Appstyle.textXS.copyWith(color: Appstyle.gris)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        compteur(l10n.distributionTotal, q(total), Appstyle.violet),
                        const SizedBox(width: 10),
                        compteur(l10n.distributionDistributed, q(reparti), Appstyle.green),
                        const SizedBox(width: 10),
                        compteur(l10n.remaining, q(reste), reste.abs() < 1e-6 ? Appstyle.gris : Appstyle.red),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final m in magasins)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: coches.contains(m.code) ? Colors.white : Appstyle.grischamp,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: coches.contains(m.code) ? Appstyle.violet.withOpacity(0.35) : Appstyle.grisC),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: coches.contains(m.code),
                              activeColor: Appstyle.violet,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  coches.add(m.code);
                                } else if (coches.length > 1) {
                                  coches.remove(m.code);
                                }
                              }),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.nom, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600)),
                                  Text('${l10n.inStock} ${q(actuel[m.code] ?? 0)}', style: Appstyle.textXS.copyWith(color: Appstyle.gris)),
                                ],
                              ),
                            ),
                            if (m.code == ordre.first)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(l10n.mainStore, style: Appstyle.textXS.copyWith(color: Appstyle.violet, fontWeight: FontWeight.w600)),
                              ),
                            SizedBox(
                              width: 130,
                              child: TextField(
                                controller: controllers[m.code],
                                enabled: coches.contains(m.code),
                                textAlign: TextAlign.end,
                                inputFormatters: QuantiteFormat.inputFormattersPour(produit.uniteMesure),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  isDense: true,
                                  suffixText: produit.uniteMesure,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MainButton(
                    text: l10n.cancel,
                    icon: Icons.close,
                    color: Appstyle.gris,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.save,
                    icon: Icons.save,
                    color: valide ? Appstyle.violet : Appstyle.grisC,
                    onPressed: () async {
                      if (!RepartitionStock.distributionValide(total, cibles())) {
                        await InformationDialog(
                          context: dialogContext,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.productDistribution,
                          message: l10n.distributionInvalid(q(total)),
                        );
                        return;
                      }
                      await _enregistrerDistribution(
                        produit: produit,
                        deltas: RepartitionStock.deltasDistribution(actuel, cibles()),
                        userCode: userCode,
                        userName: auth.username ?? userCode,
                      );
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  for (final c in controllers.values) {
    c.dispose();
  }
  return resultat ?? false;
}

/// Un mouvement « Distribution » par magasin dont la quantité change
/// (Sortie si elle baisse, Entrée si elle monte), sous un même code
/// d'opération, plus une ligne d'historique.
Future<void> _enregistrerDistribution({
  required Produit produit,
  required Map<String, double> deltas,
  required String userCode,
  required String userName,
}) async {
  if (deltas.isEmpty) return;
  final db = await DbCreator.openDb();
  final serviceM = MouvementsServices(db);
  final codeOperation = CodeGenerator.generateCodeWithTimestamp(prefix: CodePrefix.transfert, id: produit.id);

  for (final e in deltas.entries) {
    final id = await MouvementsServices.getNextMouvementId(db);
    await serviceM.addMouvement(Mouvement(
      id: id,
      code: CodeGenerator.generateCode(prefix: CodePrefix.mouvement, id: id, digitCount: 8),
      date: DateTime.now(),
      codeProduit: produit.code,
      quantite: e.value.abs(),
      prixAchat: produit.prixAchat,
      prixVente: produit.prixVente,
      type: 'Distribution',
      sousType: e.value > 0 ? 'Entrée' : 'Sortie',
      magasinCode: e.key,
      etat: true,
      codeOperation: codeOperation,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    ));
  }

  final idh = await HistoriqueServices.getNextHistoriqueId(db);
  await HistoriqueServices(db).addHistorique(Historique(
    id: idh,
    code: CodeGenerator.generateCodeWithTimestamp(prefix: CodePrefix.historique, id: idh),
    type: 'Distribution',
    desc: "L'utilisateur $userName a réparti le produit ${produit.nom} entre les magasins "
        "(${deltas.entries.map((e) => '${e.key} ${e.value > 0 ? '+' : ''}${e.value}').join(', ')})",
    oper: ListsConst.typeHisto[1],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  ));
}
