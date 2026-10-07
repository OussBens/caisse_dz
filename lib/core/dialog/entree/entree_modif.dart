import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Verssement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseSession.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

/// Modification d'une entrée rapide (SmartScan à 1 produit) : le contenu
/// (produit/quantité/prix/fournisseur/date) est verrouillé dès
/// l'enregistrement, même principe que smart_screen_modif.dart — seul le
/// montant versé reste modifiable, ce qui permet désormais de convertir une
/// entrée rapide (réglée intégralement à la création) en paiement partiel.
String? selectedProduitE;
String? selectedFournisseurE;
String? selectedCaisseE;

List<Produit> produitsTestE = [];
List<Fournisseur> fournisseursTestE = [];
List<CaisseGestion> caissesTestE = [];

Future<void> _LoadAllData() async {
  produitsTestE = await ProduitServices.getAllProduits();
  fournisseursTestE = await FournisseurServices.getAllFournisseurs();
  caissesTestE = await GCServices.getAllCaisses();
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _UpdateEntreeRapide({
  required SmartScan smartScan,
  required String userName,
  required String userCode,
  required double ancienVerse,
  required double nouveauVerse,
  required String caisseCode,
}) async {
  final db = await DbCreator.openDb();
  final serviceSS = SmartScanServices(db);
  final serviceH = HistoriqueServices(db);
  final serviceV = VerssementServices(db);
  final caisseSessionService = CaisseSessionServices(db);

  final response = await serviceSS.updateSmartScan(smartScan);
  if (!response.success) {
    return response;
  }

  // Répercuter le nouveau montant versé sur le versement fournisseur lié
  // (le montant versé/reste n'est plus stocké sur le smart scan).
  final diffVerse = nouveauVerse - ancienVerse;
  if (diffVerse != 0) {
    final versementsScan = await serviceV.getVerssementsByCodeOperation(smartScan.code);
    final versementFournisseur = versementsScan
        .where((v) => v.typebeneficiare == 'Fournisseur' && v.etat)
        .firstOrNull;

    if (versementFournisseur != null) {
      versementFournisseur.montant = nouveauVerse;
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
        beneficiareCode: smartScan.fournisseurCode,
        montant: nouveauVerse,
        etat: true,
        mode_paiement: "Espèces",
        sense: 'Sortie',
        type: "Paiement",
        dateCree: DateTime.now(),
        creeParCode: userCode,
        caisse: caissesTestE.where((c) => c.code == caisseCode).firstOrNull?.nomCaisse ?? '',
        codeOperation: smartScan.code,
      );
      await serviceV.addverssement(nouveauVersement);
    }

    // Répercuter le même changement sur le mouvement de caisse (grand-livre)
    // lié à cet achat : mise à jour en place s'il existe déjà, création
    // sinon (seulement si un montant est versé et qu'une session est ouverte).
    final mouvementsExistants = await CaisseSessionServices.getMouvementsByCodeOperation(
      smartScan.code,
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
          codeOperation: smartScan.code,
          fournisseurCode: smartScan.fournisseurCode,
          date: DateTime.now(),
          etat: true,
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await caisseSessionService.ajouterMouvement(mouvementCaisse);
      }
    }
  }

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id: idh,
    code: "HE$idh${DateTime.now().millisecondsSinceEpoch}",
    type: "SmartScan",
    desc: "L'utilisateur $userName a modifié le montant versé de l'entrée rapide ${smartScan.code}: $ancienVerse->$nouveauVerse",
    oper: ListsConst.typeHisto[1],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceH.addHistorique(histo);

  return response;
}

final GlobalKey<FormState> entreeFormKey = GlobalKey<FormState>();
final TextEditingController verseControllerE = TextEditingController();
final TextEditingController resteControllerE = TextEditingController();

Future<void> EntreeModif(BuildContext context, SmartScan scan) async {
  await _LoadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  final lignes = await SmartScanProduitServices.getSmartScanProduitByCode(scan.code);
  if (lignes.isEmpty) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      kind: DialogKind.refuser,
      titre_concerne: l10n.entry,
      message: l10n.errorOccurred,
    );
    return;
  }
  final ligne = lignes.first;

  TextEditingController codeControllerE = TextEditingController();
  TextEditingController prixControllerE = TextEditingController();
  TextEditingController produitCodeControllerE = TextEditingController();
  TextEditingController montantControllerE = TextEditingController();
  TextEditingController quantiteControllerE = TextEditingController();
  TextEditingController observationControllerE = TextEditingController();
  TextEditingController dateControllerE = TextEditingController();
  TextEditingController nombreControllerE = TextEditingController();
  Produit? prod = produitsTestE.where((p) => p.code == ligne.codeProduit).cast<Produit?>().firstWhere((p) => true, orElse: () => null);

  selectedProduitE = prod?.nom;
  selectedFournisseurE = fournisseursTestE.where((f) => f.code == scan.fournisseurCode).firstOrNull?.nom;

  final db = await DbCreator.openDb();
  final versementsScanExistants = await VerssementServices(db).getVerssementsByCodeOperation(scan.code);
  final versementFournisseurExistant = versementsScanExistants
      .where((v) => v.typebeneficiare == 'Fournisseur')
      .firstOrNull;

  // ✅ Montant versé = somme des versements fournisseur actifs liés à cette
  // entrée (calcul dynamique, comme pour le SmartScan multi-produits).
  final double ancienVerse = versementsScanExistants
      .where((v) => v.typebeneficiare == 'Fournisseur' && v.etat)
      .fold(0.0, (s, v) => s + v.montant);

  // ✅ Caisse par défaut : celle du versement fournisseur déjà lié à cet
  // achat (si connue), sinon la première caisse disponible.
  selectedCaisseE = caissesTestE
          .where((c) => c.nomCaisse == versementFournisseurExistant?.caisse)
          .firstOrNull
          ?.nomCaisse ??
      (caissesTestE.isNotEmpty ? caissesTestE.first.nomCaisse : null);

  codeControllerE.text = scan.code;
  produitCodeControllerE.text = prod!.code;
  quantiteControllerE.text = QuantiteFormat.format(ligne.quantite);
  nombreControllerE.text = ligne.nombre != null ? QuantiteFormat.format(ligne.nombre!) : '';
  prixControllerE.text = ligne.prix.toStringAsFixed(2);
  montantControllerE.text = scan.montant.toStringAsFixed(2);
  dateControllerE.text = "${scan.date}";
  observationControllerE.text = scan.observation ?? "";
  verseControllerE.text = ancienVerse.toStringAsFixed(2);
  resteControllerE.text = (scan.montant - ancienVerse).toStringAsFixed(2);

  showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: BaseDialog(
              width: 900,
              height: 480,
              header: TitreAvecLigne(
                imagePath: 'assets/icons/cardwidget/entree_rapide_icon.png',
                text: l10n.modifyEntry,
              ),
              content: Form(
                key: entreeFormKey,
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ────────── Contenu de l'entrée : lecture seule ──────────
                      // Verrouillé dès l'enregistrement (même principe que le
                      // Pannier/SmartScan) : une correction du contenu passe
                      // par une annulation, jamais par cette modification.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChampAvecLabel(
                              label: l10n.code,
                              child: TextChampL(
                                controller: codeControllerE,
                                enabled: false,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.productCode,
                              child: TextChampL(
                                controller: produitCodeControllerE,
                                enabled: false,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.product,
                              child: TextChampL(
                                controller: TextEditingController(text: selectedProduitE ?? ''),
                                enabled: false,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.date,
                              child: TextChampL(
                                controller: dateControllerE,
                                enabled: false,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.supplier,
                              child: TextChampL(
                                controller: TextEditingController(text: selectedFournisseurE ?? ''),
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
                              label: l10n.quantity,
                              child: TextChampL(
                                controller: quantiteControllerE,
                                enabled: false,
                                hint: '',
                              ),
                            ),
                            if (prod?.nombreActif ?? false) ...[
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.numberField,
                                child: TextChampL(
                                  controller: nombreControllerE,
                                  enabled: false,
                                  hint: '',
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.price,
                              child: TextChampL(
                                controller: prixControllerE,
                                enabled: false,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.amount,
                              child: TextChampL(
                                controller: montantControllerE,
                                enabled: false,
                                numeric: true,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.paye,
                              obligatoire: true,
                              child: TextChampL(
                                obligatoire: true,
                                controller: verseControllerE,
                                numeric: true,
                                hint: '0.00',
                                onChanged: (_) => setState(() {
                                  final verse = double.tryParse(verseControllerE.text) ?? 0;
                                  resteControllerE.text = (scan.montant - verse).toStringAsFixed(2);
                                }),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.reste,
                              child: TextChampL(
                                controller: resteControllerE,
                                enabled: false,
                                hint: '',
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
                                      caisses: caissesTestE,
                                      onCaisseSelected: (c) {
                                        setState(() => selectedCaisseE = c.nomCaisse);
                                      },
                                    );
                                  },
                                );
                              },
                              child: TextListe(
                                obligatoire: true,
                                clearable: false,
                                value: selectedCaisseE,
                                items: caissesTestE.map((c) => c.nomCaisse).toSet().toList(),
                                onChanged: (v) => setState(() => selectedCaisseE = v),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.observation,
                              child: TextChampL(
                                controller: observationControllerE,
                                enabled: false,
                                hint: '',
                              ),
                            ),
                          ],
                        ),
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
                    icon: Icons.cancel,
                    color: Appstyle.gris,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.modify,
                    icon: Icons.save,
                    color: Appstyle.violet,
                    onPressed: () async {
                      if (!entreeFormKey.currentState!.validate()) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.fillRequiredFields,
                        );
                        return;
                      }

                      if (selectedCaisseE == null || selectedCaisseE!.isEmpty) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.cashRegisterRequired,
                        );
                        return;
                      }

                      final nouveauVerse = double.tryParse(verseControllerE.text) ?? 0;
                      if (nouveauVerse < 0 || nouveauVerse > scan.montant) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.fillRequiredFields,
                        );
                        return;
                      }

                      final caisseChoisieE = caissesTestE.firstWhere((c) => c.nomCaisse == selectedCaisseE);

                      // ✅ Session de caisse obligatoire uniquement quand le
                      // montant versé change réellement (un nouveau mouvement
                      // de caisse va être journalisé).
                      if (nouveauVerse != ancienVerse) {
                        final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseChoisieE.code);
                        if (sessionOuverte == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.attention,
                            kind: DialogKind.attention,
                            titre_concerne: l10n.entry,
                            message: l10n.aucuneSessionOuverte(caisseChoisieE.nomCaisse),
                          );
                          return;
                        }
                      }

                      scan.modifParCode = userCode;
                      scan.dateModif = DateTime.now();

                      final response = await _UpdateEntreeRapide(
                        smartScan: scan,
                        userName: userName,
                        userCode: userCode,
                        ancienVerse: ancienVerse,
                        nouveauVerse: nouveauVerse,
                        caisseCode: caisseChoisieE.code,
                      );

                      if (!response.success) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: response.message ?? l10n.errorOccurred,
                        );
                        return;
                      }

                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.success,
                        titre_concerne: l10n.entry,
                        message: response.message ?? l10n.entryModifiedSuccess,
                        onTerminer: () => Navigator.pop(context),
                      );
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
}
