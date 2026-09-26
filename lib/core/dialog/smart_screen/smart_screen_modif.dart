import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Verssement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseSession.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import '../../utilis/api_response.dart';
import '../../utilis/quantite_format.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

final TextEditingController observationController = TextEditingController();
final TextEditingController smartDateController = TextEditingController();
final TextEditingController montantController = TextEditingController();
final TextEditingController verseController = TextEditingController();
final TextEditingController resteController = TextEditingController();

List<SmartScanProduit> smartscanProduitsTest = [];
List<Fournisseur> fournisseursTest = [];
List<CaisseGestion> caissesTest = [];
List<Mouvement> Mouvments = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

/// Modifie uniquement le montant versé (paiement fournisseur) d'un achat
/// déjà enregistré — le contenu (produits/quantités/prix/fournisseur/date)
/// est verrouillé dès l'enregistrement (voir SmartScanServices.updateSmartScan)
/// et ne se corrige plus que par une annulation, même principe que
/// pannier_modif.dart pour les ventes.
Future<ApiResponse<int>> UpdateSS({
  required String userName,
  required String userCode,
  required SmartScan smartscan,
  required double ancienVerse,
  required double nouveauVerse,
  required String caisseCode,
}) async {
  final db = await DbCreator.openDb();
  final services = SmartScanServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceV = VerssementServices(db);
  final caisseSessionService = CaisseSessionServices(db);

  final response = await services.updateSmartScan(smartscan);
  if (!response.success) {
    return response;
  }

  // Répercuter le nouveau montant versé sur le versement fournisseur lié à
  // ce smart scan (montant versé/reste ne sont plus stockés sur le smart
  // scan, uniquement dérivés des versements).
  final diffVerse = nouveauVerse - ancienVerse;
  if (diffVerse != 0) {
    final versementsScan = await serviceV.getVerssementsByCodeOperation(smartscan.code);
    final versementFournisseur = versementsScan
        .where((v) => v.typebeneficiare == 'Fournisseur')
        .firstOrNull;

    if (versementFournisseur != null) {
      versementFournisseur.montant = nouveauVerse;
      versementFournisseur.etat = nouveauVerse > 0;
      versementFournisseur.dateModif = DateTime.now();
      versementFournisseur.modifParCode = userCode;
      await serviceV.updateVerssement(versementFournisseur);
    } else if (nouveauVerse > 0) {
      final nextVerssementId = await VerssementServices.getNextVerssementId(db);
      final nouveauVersement = Verssement(
        id: nextVerssementId,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.verssement,
          id: nextVerssementId,
          digitCount: 6,
        ),
        date: DateTime.now(),
        typebeneficiare: "Fournisseur",
        beneficiareCode: smartscan.fournisseurCode,
        montant: nouveauVerse,
        etat: true,
        mode_paiement: "Espèces",
        sense: 'Sortie',
        type: "Paiement",
        dateCree: DateTime.now(),
        creeParCode: userCode,
        caisse: caissesTest.where((c) => c.code == caisseCode).firstOrNull?.nomCaisse ?? '',
        codeOperation: smartscan.code,
      );
      await serviceV.addverssement(nouveauVersement);
    }

    // Répercuter le même changement sur le mouvement de caisse (grand-livre)
    // lié à cet achat : mise à jour en place s'il existe déjà, création
    // sinon (seulement si un nouveau montant est versé et qu'une session est
    // ouverte pour la caisse choisie).
    final mouvementsExistants = await CaisseSessionServices.getMouvementsByCodeOperation(
      smartscan.code,
      type: 'decaissement_achat',
    );
    final mouvementExistant = mouvementsExistants.firstOrNull;

    if (mouvementExistant != null) {
      await caisseSessionService.updateMontantMouvement(
        code: mouvementExistant.code,
        montant: nouveauVerse,
        userCode: userCode,
      );
    } else if (nouveauVerse > 0) {
      final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseCode);
      if (sessionOuverte != null) {
        final nextMouvementId = await CaisseSessionServices.getNextMouvementId(db);
        final mouvementCaisse = CaisseMouvement(
          id: nextMouvementId,
          code: CodeGenerator.generateCode(
            prefix: CodePrefix.caisseMouvement,
            id: nextMouvementId,
            digitCount: 8,
          ),
          sessionCode: sessionOuverte.code,
          caisseCode: caisseCode,
          type: 'decaissement_achat',
          sens: 'Sortie',
          montant: nouveauVerse,
          modePaiement: "Espèces",
          codeOperation: smartscan.code,
          fournisseurCode: smartscan.fournisseurCode,
          date: DateTime.now(),
          etat: true,
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await caisseSessionService.ajouterMouvement(mouvementCaisse);
      }
    }

    int idhV = await _GetNextHistoriqueId();
    await serviceh.addHistorique(
      Historique(
        id: idhV,
        code: 'HS$idhV${DateTime.now().millisecondsSinceEpoch}',
        type: 'Versement',
        desc: "l'utilisateur $userName a modifié le montant versé du smart scan ${smartscan.code}: $ancienVerse->$nouveauVerse",
        oper: ListsConst.typeHisto[1],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      ),
    );
  }

  return response;
}

List<Produit> produitsCatalogue = [];

String _nomProduitCatalogue(String code) =>
    produitsCatalogue.where((p) => p.code == code).firstOrNull?.nom ?? code;

bool _nombreActifCatalogueSS(String code) =>
    produitsCatalogue.where((p) => p.code == code).firstOrNull?.nombreActif ?? false;

Future<void> _LoadAllData({required SmartScan smartscan}) async {
  smartscanProduitsTest = await SmartScanProduitServices.getSmartScanProduitByCode(smartscan.code);
  fournisseursTest = await FournisseurServices.getAllFournisseurs();
  caissesTest = await GCServices.getAllCaisses();
  Mouvments = await MouvementsServices.getAllMouvementsByCodeOper(smartscan.code);
  produitsCatalogue = await ProduitServices.getAllProduits();
}

String? selectedCaisseSS;

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> SmartScanModif(
    BuildContext context,
    SmartScan scan,
    ) async {
  await _LoadAllData(smartscan: scan);
  final List<SmartScanProduit> produitsDuScan = smartscanProduitsTest
      .where((p) => p.codeSmartScan == scan.code)
      .toList();

  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  final db = await DbCreator.openDb();
  final serviceV = VerssementServices(db);
  final versementsScan = await serviceV.getVerssementsByCodeOperation(scan.code);
  // Montant versé = somme des versements fournisseur actifs liés à ce smart
  // scan (calcul dynamique, la colonne paye/reste n'existe plus sur le scan).
  final double ancienVerse = versementsScan
      .where((v) => v.etat)
      .fold(0.0, (s, v) => s + v.montant);

  // ✅ Caisse par défaut : celle du versement fournisseur déjà lié à cet
  // achat (si connue), sinon la première caisse disponible.
  final versementFournisseurExistant = versementsScan
      .where((v) => v.typebeneficiare == 'Fournisseur')
      .firstOrNull;
  selectedCaisseSS = caissesTest
          .where((c) => c.nomCaisse == versementFournisseurExistant?.caisse)
          .firstOrNull
          ?.nomCaisse ??
      (caissesTest.isNotEmpty ? caissesTest.first.nomCaisse : null);

  smartDateController.text = "${scan.date}";
  montantController.text = scan.montant.toStringAsFixed(2);
  verseController.text = ancienVerse.toStringAsFixed(2);
  resteController.text = (scan.montant - ancienVerse).toStringAsFixed(2);
  observationController.text = scan.observation ?? "";

  final String nomFournisseur =
      fournisseursTest.where((f) => f.code == scan.fournisseurCode).firstOrNull?.nom ?? scan.fournisseurCode;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/scan_icon.png',
                  text: l10n.modifySmartScan,
                ),

                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ────────── Contenu de l'achat : lecture seule ──────────
                            // Verrouillé dès l'enregistrement (même principe que le
                            // Pannier) : une correction du contenu passe par une
                            // annulation, jamais par cette modification.
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ChampAvecLabel(
                                    label: l10n.code,
                                    child: TextChampL(
                                      controller: TextEditingController(text: scan.code),
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.date,
                                    child: TextChampL(
                                      controller: smartDateController,
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.supplier,
                                    child: TextChampL(
                                      controller: TextEditingController(text: nomFournisseur),
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.productCount,
                                    child: TextChampL(
                                      controller: TextEditingController(text: scan.nbrProduit.toString()),
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.observation,
                                    child: TextChampL(
                                      controller: observationController,
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // ────────── Paiement : seul champ modifiable ──────────
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ChampAvecLabel(
                                    label: l10n.amount,
                                    child: TextChampL(
                                      numeric: true,
                                      enabled: false,
                                      controller: montantController,
                                      hint: "0.00",
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.paye,
                                    obligatoire: true,
                                    child: TextChampL(
                                      obligatoire: true,
                                      hint: "0.00",
                                      numeric: true,
                                      controller: verseController,
                                      onChanged: (_) => setState(() {
                                        final verse = double.tryParse(verseController.text) ?? 0;
                                        resteController.text =
                                            (scan.montant - verse).toStringAsFixed(2);
                                      }),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.reste,
                                    child: TextChampL(
                                      hint: '',
                                      enabled: false,
                                      controller: resteController,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.cashRegister,
                                    obligatoire: true,
                                    buttonAjout: true,
                                    onAjoutPressed: () async {
                                      await showDialog(
                                        context: context,
                                        barrierColor: Appstyle.gris.withOpacity(0.25),
                                        builder: (_) {
                                          return InsertionCaisseDialog(
                                            caisses: caissesTest,
                                            onCaisseSelected: (c) {
                                              setState(() => selectedCaisseSS = c.nomCaisse);
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: TextListe(
                                      obligatoire: true,
                                      clearable: false,
                                      value: selectedCaisseSS,
                                      items: caissesTest.map((c) => c.nomCaisse).toSet().toList(),
                                      onChanged: (v) => setState(() => selectedCaisseSS = v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          l10n.smartScanProductsList,
                          style: Appstyle.textLB.copyWith(color: Appstyle.Tnoir),
                        ),
                        const SizedBox(height: 10),

                        // ────────── Lignes produit : affichage seul ──────────
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  columns: [
                                    DataColumn(label: Text(l10n.productCode)),
                                    DataColumn(label: Text(l10n.productName)),
                                    DataColumn(label: Text(l10n.quantity)),
                                    DataColumn(label: Text(l10n.numberField)),
                                    DataColumn(label: Text(l10n.price)),
                                    DataColumn(label: Text(l10n.total)),
                                  ],
                                  rows: produitsDuScan.map((p) {
                                    final afficheNombre = _nombreActifCatalogueSS(p.codeProduit);
                                    return DataRow(cells: [
                                      DataCell(Text(p.codeProduit)),
                                      DataCell(Text(_nomProduitCatalogue(p.codeProduit))),
                                      DataCell(Text(QuantiteFormat.format(p.quantite))),
                                      DataCell(Text(afficheNombre && p.nombre != null ? QuantiteFormat.format(p.nombre!) : '-')),
                                      DataCell(Text(p.prix.toStringAsFixed(2))),
                                      DataCell(Text(NumberFormatUtil.formatMontant(p.total, decimales: 2))),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                        text: l10n.modify,
                        color: Appstyle.violet,
                        icon: Icons.save,
                        onPressed: () async {
                          if (!produitFormKey.currentState!.validate()) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.smartScan,
                              message: l10n.fillRequiredFields,
                            );
                            return;
                          }

                          if (selectedCaisseSS == null || selectedCaisseSS!.isEmpty) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.smartScan,
                              message: l10n.cashRegisterRequired,
                            );
                            return;
                          }
                          final caisseChoisieSS = caissesTest.where((c) => c.nomCaisse == selectedCaisseSS).first;

                          final nouveauVerse = double.tryParse(verseController.text) ?? 0;
                          if (nouveauVerse > scan.montant) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.smartScan,
                              message: l10n.fillRequiredFields,
                            );
                            return;
                          }

                          // ✅ Session de caisse obligatoire uniquement quand le
                          // montant versé change réellement (un nouveau
                          // mouvement de caisse va être journalisé).
                          if (nouveauVerse != ancienVerse) {
                            final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseChoisieSS.code);
                            if (sessionOuverte == null) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.attention,
                                titre_concerne: l10n.smartScan,
                                message: l10n.aucuneSessionOuverte(caisseChoisieSS.nomCaisse),
                              );
                              return;
                            }
                          }

                          scan.dateModif = DateTime.now();
                          scan.modifParCode = userCode;

                          final response = await UpdateSS(
                            userName: userName,
                            userCode: userCode,
                            smartscan: scan,
                            ancienVerse: ancienVerse,
                            nouveauVerse: nouveauVerse,
                            caisseCode: caisseChoisieSS.code,
                          );

                          if (!response.success) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.smartScan,
                              message: response.message,
                            );
                            return;
                          }

                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.success,
                            titre_concerne: l10n.smartScan,
                            message: l10n.smartScanModifiedSuccess,
                            onTerminer: () {
                              Navigator.pop(context);
                            },
                          );
                        }
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
