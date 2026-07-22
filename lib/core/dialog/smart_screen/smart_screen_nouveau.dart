import 'dart:math';
import 'package:caisse_dz/core/dialog/confirmation_dialog.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/button/ajouter_manuel.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/step_widget.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

Future<ApiResponse<int>> SaveSS({
  required String userName,
  required String userCode,
  required SmartScan SmartScan,
  required List<SmartScanProduit> Produits,
  required List<Mouvement> mouvments,
})
async {
  final db = await DbCreator.openDb();
  final services = await SmartScanServices(db);
  final serviceh = await HistoriqueServices(db);
  final serviceS = await SmartScanProduitServices(db);
  final serviceM = await MouvementsServices(db);
  final serviceP = await ProduitServices(db);
  final serviceFournisseur = FournisseurServices(db);

  final response = await services.addSmartScan(SmartScan);
  final Produites = await ProduitServices.getAllProduits();

  // ✅ Récupérer le fournisseur
  final fournisseur = fournisseursTest.firstWhere(
        (f) => f.nom == SmartScan.fournisseur,
    orElse: () => throw Exception("Fournisseur introuvable"),
  );

  try {
    await serviceFournisseur.ajouterAchat(
      fournisseur.id,
      SmartScan.montant,
    );
    print("✅ Fournisseur mis à jour: ${fournisseur.nom}");
  } catch (e) {
    print("⚠️ Erreur lors de la mise à jour du fournisseur: $e");
  }

  final int idH = await _GetNextHistoriqueId();
  final Historique histo = Historique(
      id: idH,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idH,
      ),
      desc: "l'utilisateur $userName a ajoutee un nouveau Smart Scan de Fournisseur de ${SmartScan.fournisseur}",
      oper: ListsConst.typeHisto[0],
      type: "SmartScan",
      dateCree: DateTime.now(),
      creeParCode: userCode
  );
  await serviceh.addHistorique(histo);

  for (var produit in Produits) {
    Produit prod = Produites.where((e) => e.nom == produit.nomProduit).first;

    // ✅ Mettre à jour les champs du produit
    prod.quantite = (produit.quantite + prod.quantite).toDouble();
    prod.prixAchat = produit.prix;
    prod.prixVente = produit.prixVente; // ✅ Mettre à jour le prix de vente
    prod.dateModif = DateTime.now();
    prod.modifPar = userName;



    await serviceP.updateProduit(prod);

    produit.id = await _GetNextSmartScanProduitId();
    produit.codeSmartScan = SmartScan.code;

    await serviceS.addSmartScanProduit(produit);

    int idp = await _GetNextHistoriqueId();

    final Historique histoProduit = Historique(
        id: idp,
        code: CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: idp,
        ),
        desc: "l'utilisateur $userName a ajoutee un nouveau Smart Scan Produit de Produit de ${produit.nomProduit} de Smart Scan ${SmartScan.code}",
        oper: ListsConst.typeHisto[0],
        type: "SmartScanProduit",
        dateCree: DateTime.now(),
        creeParCode: userCode
    );

    await serviceh.addHistorique(histoProduit);
  }

  for (var mouvemnt in mouvments) {
    int idm = await _GetNextMouvementId();
    mouvemnt.id = idm;
    mouvemnt.creeParCode = userCode;
    mouvemnt.code = CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.mouvement,
      id: idm,
    );
    mouvemnt.fournisseur = SmartScan.fournisseur;
    mouvemnt.date = SmartScan.date;
    mouvemnt.codeOperation = SmartScan.code;
    await serviceM.addMouvement(mouvemnt);
  }
  return response;
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextMouvementId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MouvementsServices.getNextMouvementId(txn);
  });
  return id;
}

Future<int> _GetNextSmartScanProduitId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SmartScanProduitServices.getNextSmartScanProduitId(txn);
  });
  return id;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SmartScanServices.getNextSmartScanId(txn);
  });
  return id;
}

Future<void> pickDate(
    BuildContext context,
    TextEditingController controller, {
      DateTime? minDate,
    }) async {
  DateTime initialDate = DateTime.now();

  if (controller.text.isNotEmpty) {
    try {
      initialDate = DateTime.parse(controller.text);
    } catch (_) {}
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate.isBefore(minDate ?? initialDate)
        ? (minDate ?? initialDate)
        : initialDate,
    firstDate: minDate ?? DateTime(2000),
    lastDate: DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Appstyle.violet,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    controller.text =
    "${picked.year.toString().padLeft(4, '0')}-"
        "${picked.month.toString().padLeft(2, '0')}-"
        "${picked.day.toString().padLeft(2, '0')}";
  }
}

final TextEditingController codeController = TextEditingController();
final TextEditingController fournisseurController = TextEditingController();
final TextEditingController nombreController = TextEditingController();
final TextEditingController observationController = TextEditingController();
final TextEditingController montantController = TextEditingController();
final TextEditingController payeController = TextEditingController();
final TextEditingController quantiteController = TextEditingController();
final TextEditingController dateController = TextEditingController();
DateTime? selectedDate;

List<Produit> produitsTest = [];
List<Fournisseur> fournisseursTest = [];

Future<void> _LoadAllData() async {
  produitsTest = await ProduitServices.getAllProduits();
  fournisseursTest = await FournisseurServices.getAllFournisseurs();
}

class SmartScanDialog extends StatefulWidget {
  const SmartScanDialog({super.key});

  static void open(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SmartScanDialog(),
    );
  }

  @override
  State<SmartScanDialog> createState() => _SmartScanDialogState();
}

class _SmartScanDialogState extends State<SmartScanDialog> {
  void resetForm() {
    step = 1;
    isAutoScan = true;
    actif = true;
    etat = true;
    slected = false;

    codeController.clear();
    fournisseurController.clear();
    nombreController.clear();
    observationController.clear();
    montantController.clear();
    payeController.clear();
    quantiteController.clear();
    dateController.clear();

    fournisseur = null;
    quantite = 0;
    article = 0;
    montant = 0;
    date = null;
    code = null;

    selectedFournisseur = '';

    produits.clear();
    mouvments.clear();

    selectedDate = null;

    setState(() {});
  }

  bool slected = false;
  int step = 1;
  bool isAutoScan = true;

  DateTime? date;
  String? fournisseur;

  int quantite = 0;
  double article = 0;
  double montant = 0;
  double paye = 0;
  double reste = 0;

  int quantiteCalcul = 0;
  double articleCalcul = 0;
  double montantCalcul = 0;
  bool ecart = false;

  String? code;
  bool etat = true;
  String selectedFournisseur = '';

  List<SmartScanProduit> produits = [];
  List<Mouvement> mouvments = [];

  bool actif = true;

  @override
  void initState() {
    super.initState();
    _LoadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseDialog(
      width: 1200, // Augmenté pour accueillir le nouveau champ
      header: _buildHeader(l10n),
      content: _buildContent(l10n),
      footer: _buildFooter(l10n),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitreAvecLigne(
          imagePath: 'assets/icons/cardwidget/scan_icon.png',
          text: l10n.newSmartScan,
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 80),
          child: StepIndicator(activeStep: step),
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    switch (step) {
      case 1:
        return _stepFournisseur(l10n);
      case 2:
        return _stepProduits(l10n);
      case 3:
        return _stepRecap(l10n);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (step > 1)
          MainButton(
            onPressed: () => setState(() => step--),
            color: Appstyle.gris,
            text: l10n.back,
            icon: Icons.chevron_left,
            iconOnRight: false,
          )
        else
          MainButton(
            text: l10n.cancel,
            icon: Icons.close,
            color: Appstyle.gris,
            onPressed: () {
              resetForm();
              Navigator.pop(context);
            },
          ),

        MainButton(
          onPressed: _onNext,
          text: step == 3 ? l10n.validate : l10n.next,
          color: step == 3 ? Appstyle.violet : Appstyle.crevete,
          icon: step == 3 ? Icons.save : Icons.chevron_right,
        ),
      ],
    );
  }

  bool _validerStep(AppLocalizations l10n) {
    if (step == 1) {
      if (codeController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.supplierCodeRequired,
        );
        return false;
      }

      if (fournisseurController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.supplierNameRequired,
        );
        return false;
      }

      if (dateController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.dateRequired,
        );
        return false;
      }

      if (montantController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.amountRequired,
        );
        return false;
      } if (payeController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.amountRequired,
        );
        return false;
      }

      if (nombreController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.productCountRequired,
        );
        return false;
      }

      if (quantiteController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.totalQuantityRequired,
        );
        return false;
      }

      return true;
    }

    if (step == 2) {
      if (produits.isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.atLeastOneProduct,
        );
        return false;
      }

      // ✅ Vérifier que le prix de vente est supérieur au prix d'achat pour chaque produit
      for (var produit in produits) {
        if (produit.prixVente <= produit.prix) {
          InformationDialog(
            context: context,
            titre_type_message: l10n.error,
            titre_concerne: produit.nomProduit,
            message: "Le prix de vente doit être supérieur au prix d'achat pour ${produit.nomProduit}",
          );
          return false;
        }
      }

      return true;
    }

    return true;
  }

  void _onNext() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_validerStep(l10n)) return;

    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final userCode = auth.userCode!;

    if (step < 3) {
      setState(() {
        step++;
        if (step == 3) {
          _prepareCalculs();
        }
      });
      return;
    }

    if (_hasEcart()) {
      bool? continuer = await _confirmEcartDialog(l10n);
      if (continuer != true) return;
    }

    await _validerSmartScan(userName: userName, userCode: userCode, l10n: l10n);
  }

  int _calculNombreProduits() {
    return produits.length;
  }

  double _calculTotalQuantiteArticles() {
    return produits.fold(0.0, (sum, p) => sum + p.quantite);
  }

  double _calculTotalMontant() {
    return produits.fold(0.0, (sum, p) => sum + (p.prix * p.quantite));
  }

  double _calculReste() {
    return double.parse(payeController.text)-double.parse(montantController.text);
  }

  bool _hasEcart() {
    return quantite != quantiteCalcul ||
        article != articleCalcul ||
        montant != montantCalcul;
  }

  void _prepareCalculs() {
    quantiteCalcul = _calculTotalQuantiteArticles().toInt();
    articleCalcul = _calculNombreProduits().toDouble();
    montantCalcul = _calculTotalMontant();
    paye=double.tryParse(payeController.text) ?? 0;
    reste=_calculReste();
    quantite = int.tryParse(quantiteController.text) ?? 0;
    article = double.tryParse(nombreController.text) ?? 0;
    montant = double.tryParse(montantController.text) ?? 0;
  }

  Future<bool> _confirmEcartDialog(AppLocalizations l10n) async {
    bool? result = await ConfirmationDialog(
      context: context,
      titre: l10n.confirmation,
      message: l10n.gapDetectedMessage,
    );
    return result ?? false;
  }

  Future<void> _validerSmartScan({
    required String userName,
    required String userCode,
    required AppLocalizations l10n
  }) async {
    DateTime date = DateTime.tryParse(dateController.text) ?? DateTime.now();

    final id = await _GetNextId();

    final code = CodeGenerator.generateCode(
      prefix: CodePrefix.smartscan,
      id: id,
      digitCount: 6,
    );

    SmartScan smartscan = SmartScan(
      id: id,
      code: code,
      date: date,
      etat: etat,
      ecart: ecart,
      dateCree: DateTime.now(),
      activity: ListsConst.typeactivitySmartScan[1],
      fournisseur: fournisseurController.text,
      creeParCode: userCode,
      fournisseurCode: codeController.text,
      nbrProduit: int.parse(nombreController.text),
      quantiteArticle: double.parse(quantiteController.text),
      montant: double.parse(montantController.text),
      nbrProduitCalcul: _calculNombreProduits(),
      quantiteArticleCalcul: _calculTotalQuantiteArticles(),
      montantCalcul: _calculTotalMontant(),
      paye: paye,
      reste: reste,
    );

    final response = await SaveSS(
      userName: userName,
      userCode: userCode,
      SmartScan: smartscan,
      Produits: produits,
      mouvments: mouvments,
    );

    if (response.success) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.success,
        titre_concerne: l10n.smartScan,
        message: l10n.smartScanSavedSuccess,
        onTerminer: () {
          resetForm();
          Navigator.pop(context);
        },
      );
    }

    if (!response.success) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.smartScan,
        message: response.message,
        onTerminer: () {
          resetForm();
          Navigator.pop(context);
        },
      );
    }
  }

  Widget _stepFournisseur(AppLocalizations l10n) {
    final translator = ListsConstTranslator(l10n);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChampAvecLabel(
                    label: l10n.supplier,
                    buttonAjout: true,
                    onAjoutPressed: () async {
                      await showDialog(
                        context: context,
                        barrierColor: Appstyle.gris.withOpacity(0.25),
                        builder: (_) {
                          return InsertionFournisseurDialog(
                            fournisseurs: fournisseursTest,
                            onFournisseurSelected: (fournisseur) {
                              setState(() {
                                slected = true;
                                selectedFournisseur = fournisseur.nom;
                                codeController.text = fournisseur.code;
                                fournisseurController.text = fournisseur.nom;
                              });
                            },
                          );
                        },
                      );
                    },
                    child: TextListe(
                      value: selectedFournisseur,
                      clearable: false,
                      items: fournisseursTest.map((c) => c.nom).toList(),
                      onChanged: (v) {
                        setState(() {
                          slected = true;
                          selectedFournisseur = v!;
                          fournisseurController.text = v;
                          codeController.text = fournisseursTest.where((t) => t.nom == v).first.code;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.code,
                    child: TextChampL(
                      obligatoire: true,
                      enabled: !isAutoScan && !slected,
                      controller: codeController,
                      hint: l10n.supplierCodeHint,
                      onChanged: (v) => code = v,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.supplier,
                    child: TextChampL(
                      obligatoire: true,
                      controller: fournisseurController,
                      enabled: !isAutoScan && !slected,
                      hint: l10n.supplierNameHint,
                      onChanged: (v) => fournisseur = v,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.date,
                    child: TextDate(
                        obligatoire: true,
                        hint: "15 nov 2025",
                        enabled: !isAutoScan,
                        controller: dateController,
                        onTap: () => pickDate(context, dateController)
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChampAvecLabel(
                    label: l10n.amount,
                    obligatoire: true,
                    child: TextChampL(
                      obligatoire: true,
                      enabled: !isAutoScan,
                      controller: montantController,
                      hint: "0.00",
                      numeric: true,
                      onChanged: (v) => montant = double.tryParse(v)!,
                    ),
                  ),

                  const SizedBox(height: 15),
                  ChampAvecLabel(
                    label: l10n.paye,
                    obligatoire: true,
                    child: TextChampL(
                      obligatoire: true,
                      enabled: !isAutoScan,
                      controller: payeController,
                      hint: "0.00",
                      numeric: true,
                      onChanged: (v) => paye = double.tryParse(v)!,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ChampAvecLabel(
                      obligatoire: true,
                      label: l10n.productCount,
                      child: TextChampL(
                        obligatoire: true,
                        enabled: !isAutoScan,
                        controller: nombreController,
                        hint: '',
                      )
                  ),

                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.totalQuantity,
                    child: TextChampL(
                      obligatoire: true,
                      enabled: !isAutoScan,
                      hint: '',
                      controller: quantiteController,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    label: l10n.observation,
                    child: TextChampL(
                      enabled: !isAutoScan,
                      hint: '',
                      controller: observationController,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        Center(
          child: Column(
            children: [
              if (isAutoScan) ...[
                const Icon(Icons.qr_code, size: 90),
                const SizedBox(height: 10),
                Text(l10n.scanGlobalQRCode),
              ] else ...[
                const Icon(Icons.edit, size: 60),
                const SizedBox(height: 10),
                Text(
                  l10n.enterRequiredInformation,
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.manual, style: Appstyle.textSB),
                  const SizedBox(width: 20),
                  Switch(
                    value: isAutoScan,
                    activeColor: Appstyle.violet,
                    onChanged: (v) {
                      setState(() => isAutoScan = v);
                    },
                  ),
                  const SizedBox(width: 20),
                  Text(l10n.auto, style: Appstyle.textSB),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepProduits(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: _produitsTable(l10n),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _ouvrirInsertionProduitDialog,
          child: const AddManualWidget(),
        ),
      ],
    );
  }

  Widget _stepRecap(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.summary,
          style: Appstyle.textL.copyWith(
            color: Appstyle.violet,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${l10n.supplier}: ${fournisseurController.text}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
                Text("${l10n.date}: ${dateController.text}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${l10n.productCount}: ${articleCalcul.toString()}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
                Text("${l10n.totalQuantity}: ${quantiteCalcul.toStringAsFixed(0)}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
                Text("${l10n.totalAmount}: ${montantCalcul.toStringAsFixed(2)} ${l10n.currency}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),

        const Divider(height: 30, color: Colors.grey),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Appstyle.violetC.withOpacity(0.2),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(l10n.code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text(l10n.product,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.quantity,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.purchasePrice,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.salePrice,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.amount,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        const Divider(height: 0, color: Colors.grey),

        Expanded(
          child: ListView.separated(
            itemCount: produits.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.grey),
            itemBuilder: (_, i) {
              final p = produits[i];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                color: i % 2 == 0 ? Colors.white : Appstyle.grisC.withOpacity(0.05),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(p.codeProduit,
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 3, child: Text(p.nomProduit,
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 2, child: Text(p.quantite.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 2, child: Text(p.prix.toStringAsFixed(2),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 2, child: Text(p.prixVente.toStringAsFixed(2),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB.copyWith(color: Appstyle.crevete))),
                    Expanded(flex: 2, child: Text((p.quantite * p.prix).toStringAsFixed(2),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB.copyWith(color: Appstyle.violet))),
                  ],
                ),
              );
            },
          ),
        ),

        const Divider(color: Colors.grey),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          color: Appstyle.violetC.withOpacity(0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total,
                  style: Appstyle.textMB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold)),
              Text("${montantCalcul.toStringAsFixed(2)} ${l10n.currency}",
                  style: Appstyle.textMB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(height: 15),
      ],
    );
  }

  Widget _produitsTable(AppLocalizations l10n) {
    if (produits.isEmpty) {
      return Center(child: Text(l10n.noProductsAdded));
    }

    return ListView.builder(
      itemCount: produits.length,
      itemBuilder: (_, i) {
        final p = produits[i];

        final quantiteController = TextEditingController(text: p.quantite.toString());
        final prixAchatController = TextEditingController(text: p.prix.toString());
        final prixVenteController = TextEditingController(text: p.prixVente.toString());
        final totalController = TextEditingController(text: (p.quantite * p.prix).toStringAsFixed(2));

        void _updateTotal() {
          final q = double.tryParse(quantiteController.text) ?? 0;
          final prix = double.tryParse(prixAchatController.text) ?? 0;
          final prixVente = double.tryParse(prixVenteController.text) ?? 0;

          setState(() {
            p.quantite = q;
            p.prix = prix;
            p.prixVente = prixVente;
            p.total = q * prix;
            totalController.text = p.total.toStringAsFixed(2);
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text("${p.codeProduit}-${p.nomProduit}",
                    style: Appstyle.textSB),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.quantity,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (_) => _updateTotal(),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: prixAchatController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.purchasePrice,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (_) => _updateTotal(),
                ),
              ),

              const SizedBox(width: 10),

              // ✅ NOUVEAU CHAMP PRIX VENTE
              Expanded(
                flex: 2,
                child: TextField(
                  controller: prixVenteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.salePrice,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (v) {
                    // ✅ Vérifier que prix vente > prix achat
                    final prixAchat = double.tryParse(prixAchatController.text) ?? 0;
                    final prixVente = double.tryParse(v) ?? 0;
                    if (prixVente <= prixAchat && prixVente > 0) {
                      // Afficher un warning mais ne pas bloquer
                      print("⚠️ Prix de vente doit être supérieur au prix d'achat pour ${p.nomProduit}");
                    }
                    _updateTotal();
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: totalController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.total,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => produits.removeAt(i)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ouvrirInsertionProduitDialog() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final userCode = auth.userCode!;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => InsertionProduitDialog(
        multiselection: true,
        produits: produitsTest,
        onProduitSelected: (produit) async {
          final existe = produits.any(
                (p) => p.codeProduit == produit.code,
          );

          if (existe) {
            InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.productAlreadyAdded(produit.nom),
              message: l10n.productExistsInSmartScan,
            );
            return;
          }

          setState(() {
            Mouvement mouv = Mouvement(
              id: 0,
              code: CodeGenerator.generateCodeWithTimestamp(
                prefix: CodePrefix.mouvement,
                id: 0,
              ),
              date: DateTime.now(),
              nomProduit: produit.nom,
              codeProduit: produit.code,
              quantite: produit.quantite,
              prixAchat: produit.prixAchat,
              prixVente: produit.prixVente,
              type: ListsConst.typeMouvement[1],
              codeOperation: 'd',
              etat: true,
              dateCree: DateTime.now(),
              creeParCode: userCode,
            );

            mouvments.add(mouv);

            final smartScanProduit = SmartScanProduit(
              codeSmartScan: "SMC-PRD",
              codeProduit: produit.code,
              creeParCode: userCode,
              nomProduit: produit.nom,
              quantite: produit.quantite.toDouble(),
              creeLe: DateTime.now(),
              total: produit.quantite.toDouble() * produit.prixAchat.toDouble(),
              prix: produit.prixAchat.toDouble(),
              prixVente: produit.prixVente.toDouble(), // ✅ Ajout du prix de vente
              etat: true,
              id: 0,
            );

            produits.add(smartScanProduit);
          });
        },
      ),
    );
  }
}