import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/ParamZakat.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Zakat.dart'; // ✅ Correction: utiliser Zakat.dart (pas ZAKATServices)
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/paramZakat.dart';
import 'package:caisse_dz/data/models/zakat.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import '../../../Services/Produits.dart';
import '../../../data/models/produit.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/radio_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

final TextEditingController stockController = TextEditingController();
final TextEditingController liquiditesController = TextEditingController();
final TextEditingController creancesController = TextEditingController();
final TextEditingController dettesController = TextEditingController();
final TextEditingController nissabController = TextEditingController();
final TextEditingController tauxController = TextEditingController(text: "2.5");
final TextEditingController observationController = TextEditingController();
List<Produit> produitsTest = [];
// Quantité par produit calculée depuis le journal des mouvements — voir
// produit_screen.dart pour le même mécanisme. Remplace Produit.quantite.
Map<String, double> quantitesTest = {};

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

// ✅ Correction: Utiliser ZakatServices au lieu de ZAKATServices
Future<ApiResponse<int>> _SaveZakat({
  required Zakat zakat,
  required String userName,
  required String userCode
}) async {
  try {
    final db = await DbCreator.openDb();
    final services = ZakatServices(db); // ✅ Correction: ZakatServices
    final serviceh = await HistoriqueServices(db);

    final response = await services.addZakat(zakat);

    if (response.success) {
      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
          id: idH,
          code: CodeGenerator.generateCodeWithTimestamp(
            prefix: CodePrefix.historique,
            id: idH,
          ),
          desc: "L'utilisateur $userName a ajouté un nouveau Zakat de l'année ${zakat.annee}",
          oper: ListsConst.typeHisto[0],
          type: "zakat",
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await serviceh.addHistorique(histo);
    }

    return response;
  } catch (e) {
    print('❌ Erreur _SaveZakat: $e');
    return ApiResponse(
      success: false,
      message: "Erreur lors de l'enregistrement: $e",
    );
  }
}

bool calculauto = false;
String? selectedStatut = "";
String? zakatStatus = "";

void resetZakatForm() {
  stockController.text = "0.0";
  liquiditesController.text = "0.0";
  creancesController.text = "0.0";
  dettesController.text = "0.0";
  nissabController.text = "0.0";
  tauxController.text = "2.5";
  observationController.clear();
  selectedStatut = "";
  calculauto = false;
}

double calculStockAuto() {
  double total = 0;
  for (final p in produitsTest) {
    total += p.prixVente * (quantitesTest[p.code] ?? 0);
  }
  return total;
}

void updateStockAuto() {
  if (calculauto) {
    stockController.text = calculStockAuto().toStringAsFixed(2);
  }
}

double _toDouble(TextEditingController c) {
  return double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;
}

double calculCapitalTotal() {
  return _toDouble(stockController) +
      _toDouble(liquiditesController) +
      _toDouble(creancesController) -
      _toDouble(dettesController);
}

double calculMontantZakat() {
  final capital = calculCapitalTotal();
  final nissab = _toDouble(nissabController);
  final taux = _toDouble(tauxController) / 100;

  if (capital < nissab || nissab <= 0) return 0.0;
  return capital * taux;
}

bool zakatObligatoire() {
  final nissab = _toDouble(nissabController);
  if (nissab <= 0) return false;
  return calculCapitalTotal() >= nissab;
}

bool nissabInvalide() {
  return _toDouble(nissabController) <= 0;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ZakatServices.getNextZakatId(txn); // ✅ Correction
  });
  return id;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> ZakatNouveau(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  // Charger les produits pour le calcul automatique
  try {
    produitsTest = await ProduitServices.getAllProduits();
    quantitesTest = (await MouvementsServices.totauxParProduit()).quantites;
  } catch (e) {
    print('⚠️ Erreur chargement produits: $e');
    produitsTest = [];
    quantitesTest = {};
  }

  int id = await _GetNextId();

  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.zakat,
    id: id,
    digitCount: 6,
  );

  // Charger les paramètres
  try {
    ParamZakat param = await ParamZAKATServices.getParamZakat();
    nissabController.text = param.Nissab.toString();
    tauxController.text = param.Taux.toString();
  } catch (e) {
    print('⚠️ Erreur chargement paramètres: $e');
    nissabController.text = "0.0";
    tauxController.text = "2.5";
  }

  // Réinitialiser les contrôles
  stockController.text = "0.0";
  liquiditesController.text = "0.0";
  creancesController.text = "0.0";
  dettesController.text = "0.0";
  observationController.clear();

  final translator = ListsConstTranslator(l10n);
  zakatStatus = translator.statutZakatDisplayList.first;
  selectedStatut = translator.statutZakatToFrench(zakatStatus!);

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 850,
                height: 750,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/zakat_icon.png',
                  text: l10n.newZakat,
                ),
                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _section(
                                    title: l10n.financialData,
                                    icon: "assets/icons/info_icon.png",
                                    child: Column(
                                      children: [
                                        ChampAvecLabel(
                                          label: l10n.code,
                                          child: TextChampL(
                                            enabled: false,
                                            controller: TextEditingController(text: code),
                                            hint: "",
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.autoCalculate,
                                          alignmentStart: true,
                                          child: TextRadio(
                                            value: calculauto,
                                            onChanged: (v) {
                                              setState(() {
                                                calculauto = v ?? false;
                                                if (calculauto) {
                                                  updateStockAuto();
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.stock,
                                          obligatoire: true,
                                          child: TextChampL(
                                            obligatoire: true,
                                            controller: stockController,
                                            hint: calculauto
                                                ? l10n.autoCalculateFromProducts
                                                : l10n.stockValue,
                                            numeric: true,
                                            enabled: !calculauto,
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.liquidities,
                                          obligatoire: true,
                                          child: TextChampL(
                                            obligatoire: true,
                                            controller: liquiditesController,
                                            hint: l10n.cashBank,
                                            onChanged: (_) => setState(() {}),
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          obligatoire: true,
                                          label: l10n.receivables,
                                          child: TextChampL(
                                            obligatoire: true,
                                            controller: creancesController,
                                            hint: l10n.moneyToReceive,
                                            onChanged: (_) => setState(() {}),
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          obligatoire: true,
                                          label: l10n.debts,
                                          child: TextChampL(
                                            obligatoire: true,
                                            controller: dettesController,
                                            hint: l10n.shortTermDebts,
                                            onChanged: (_) => setState(() {}),
                                            numeric: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _section(
                                    title: l10n.rulesStatus,
                                    icon: "assets/icons/info_icon.png",
                                    child: Column(
                                      children: [
                                        ChampAvecLabel(
                                          label: l10n.nissab,
                                          obligatoire: true,
                                          child: TextChampL(
                                            obligatoire: true,
                                            controller: nissabController,
                                            hint: nissabController.text,
                                            onChanged: (_) => setState(() {}),
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          obligatoire: true,
                                          label: l10n.ratePercent,
                                          child: TextChampL(
                                            obligatoire: true,
                                            controller: tauxController,
                                            hint: "2.5",
                                            onChanged: (_) => setState(() {}),
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.status,
                                          obligatoire: true,
                                          child: TextListe(
                                              value: zakatStatus,
                                              items: translator.statutZakatDisplayList,
                                              onChanged: (v) {
                                                setState(() {
                                                  zakatStatus = v!;
                                                  selectedStatut = translator.statutZakatToFrench(v!);
                                                });
                                              }
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.observation,
                                          child: TextChampL(
                                            controller: observationController,
                                            maxLines: 2,
                                            hint: l10n.observationHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Appstyle.violet.withOpacity(0.15),
                                Appstyle.violet.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: nissabInvalide()
                                  ? Colors.red
                                  : zakatObligatoire()
                                  ? Colors.green.withOpacity(0.6)
                                  : Colors.orange.withOpacity(0.6),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _resumeItem(
                                    title: l10n.totalCapital,
                                    value: "${NumberFormatUtil.formatMontant(calculCapitalTotal(), decimales: 2)} ${l10n.currency}",
                                    icon: Icons.account_balance_wallet,
                                    color: Appstyle.blueF,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        nissabInvalide()
                                            ? Icons.error
                                            : zakatObligatoire()
                                            ? Icons.check_circle
                                            : Icons.info,
                                        color: nissabInvalide()
                                            ? Colors.red
                                            : zakatObligatoire()
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        nissabInvalide()
                                            ? l10n.nissabNotDefined
                                            : zakatObligatoire()
                                            ? l10n.zakatMandatory
                                            : l10n.zakatNotMandatory,
                                        style: Appstyle.textSB.copyWith(
                                          color: nissabInvalide()
                                              ? Colors.red
                                              : zakatObligatoire()
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _resumeItem(
                                    title: l10n.zakatAmount,
                                    value: "${NumberFormatUtil.formatMontant(calculMontantZakat(), decimales: 2)} ${l10n.currency}",
                                    icon: Icons.monetization_on,
                                    color: calculMontantZakat() > 0
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
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
                      onPressed: () {
                        resetZakatForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.zakat,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Vérifier que les champs obligatoires sont remplis
                        if (selectedStatut == null || selectedStatut!.isEmpty) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.zakat,
                            message: l10n.selectStatus,
                          );
                          return;
                        }

                        try {
                          final capitalTotal = calculCapitalTotal();
                          final montantZakat = calculMontantZakat();

                          Zakat zakat = Zakat(
                            id: id,
                            code: code,
                            annee: DateTime.now().year,
                            stock: _toDouble(stockController),
                            liquidites: _toDouble(liquiditesController),
                            creances: _toDouble(creancesController),
                            dettes: _toDouble(dettesController),
                            capitalTotal: capitalTotal,
                            nissab: _toDouble(nissabController),
                            taux: _toDouble(tauxController),
                            montantZakat: montantZakat,
                            obligatoire: zakatObligatoire(),
                            statut: selectedStatut!,
                            etat: true,
                            dateDebutHawl: DateTime.now(),
                            dateZakatDue: DateTime.now(),
                            creeParCode: userCode,
                            dateCree: DateTime.now(),
                            observation: observationController.text,
                          );

                          final response = await _SaveZakat(
                              zakat: zakat,
                              userName: userName,
                              userCode: userCode
                          );

                          if (!response.success) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.zakat,
                              message: response.message ?? l10n.errorOccurred,
                            );
                            return;
                          }

                          await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.zakat,
                              message: response.message ?? l10n.zakatSavedSuccess,
                              onTerminer: () {
                                resetZakatForm();
                                Navigator.pop(context);
                              }
                          );
                        } catch (e) {
                          print('❌ Erreur lors de la sauvegarde: $e');
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.zakat,
                            message: "${l10n.errorOccurred}: $e",
                          );
                        }
                      },
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

Widget _section({
  required String title,
  required String icon,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    decoration: BoxDecoration(
      color: Appstyle.Tblanc,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Appstyle.grisC, width: 1.5),
    ),
    child: Column(
      children: [
        TitleSmall(
          imageSize: 22,
          imagePath: icon,
          text: title,
          couleur: Appstyle.Tblue,
          opacity: 0.85,
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}

Widget _resumeItem({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Column(
    children: [
      Icon(icon, size: 28, color: color),
      const SizedBox(height: 6),
      Text(
        title,
        style: Appstyle.textSB.copyWith(color: color),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: Appstyle.textLB.copyWith(color: color),
      ),
    ],
  );
}