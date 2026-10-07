import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Zakat.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/zakat.dart';
import '../../../data/models/produit.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
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

final TextEditingController stockControllerZ = TextEditingController();
final TextEditingController liquiditesControllerZ = TextEditingController();
final TextEditingController creancesControllerZ = TextEditingController();
final TextEditingController dettesControllerZ = TextEditingController();
final TextEditingController nissabControllerZ = TextEditingController();
final TextEditingController tauxControllerZ = TextEditingController();
final TextEditingController observationControllerZ = TextEditingController();
List<Produit> produitsTest = [];
// Quantité par produit calculée depuis le journal des mouvements — voir
// produit_screen.dart pour le même mécanisme. Remplace Produit.quantite.
Map<String, double> quantitesTest = {};
bool calculauto = false;

double calculStockAuto() {
  double total = 0;
  for (final p in produitsTest) {
    total += p.prixVente * (quantitesTest[p.code] ?? 0);
  }
  return total;
}

void updateStockAuto() {
  if (calculauto) {
    stockControllerZ.text = calculStockAuto().toStringAsFixed(2);
  }
}

double _toDouble(TextEditingController c) {
  return double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;
}

double calculCapitalTotal() {
  return _toDouble(stockControllerZ) +
      _toDouble(liquiditesControllerZ) +
      _toDouble(creancesControllerZ) -
      _toDouble(dettesControllerZ);
}

double calculMontantZakat() {
  final capital = calculCapitalTotal();
  final nissab = _toDouble(nissabControllerZ);
  final taux = _toDouble(tauxControllerZ) / 100;

  if (capital < nissab) return 0.0;
  return capital * taux;
}

bool zakatObligatoire() {
  final nissab = _toDouble(nissabControllerZ);
  if (nissab <= 0) return false;
  return calculCapitalTotal() >= nissab;
}

bool nissabInvalide() {
  return _toDouble(nissabControllerZ) <= 0;
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveData({
  required Zakat zakat,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = await ZakatServices(db);
  final serviceh = await HistoriqueServices(db);

  final response = await services.updateZakat(zakat);

  final int idH = await _GetNextHistoriqueId();

  final Historique histo = Historique(
      id: idH,
      code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "l'utilisateur $userName a modifer les information de Zakat de l'annee ${zakat.annee}",
      oper: ListsConst.typeHisto[1],
      type: "zakat",
      dateCree: DateTime.now(),
      creeParCode: userCode
  );
  await serviceh.addHistorique(histo);
  return response;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> ZakatModif(BuildContext context, Zakat zakat) async {
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
      message: l10n.loginRequiredModify,
    );
    return;
  }

  // Charger les produits pour le calcul automatique (n'était jamais fait
  // ici — calculStockAuto() retournait donc toujours 0 avant ce correctif).
  try {
    produitsTest = await ProduitServices.getAllProduits();
    quantitesTest = (await MouvementsServices.totauxParProduit()).quantites;
  } catch (e) {
    print('⚠️ Erreur chargement produits: $e');
    produitsTest = [];
    quantitesTest = {};
  }

  final translatorInit = ListsConstTranslator(l10n);
  String selectedStatutZ = translatorInit.translateStatutZakat(zakat.statut);

  stockControllerZ.text = zakat.stock.toStringAsFixed(2);
  liquiditesControllerZ.text = zakat.liquidites.toStringAsFixed(2);
  creancesControllerZ.text = zakat.creances.toStringAsFixed(2);
  dettesControllerZ.text = zakat.dettes.toStringAsFixed(2);
  nissabControllerZ.text = zakat.nissab.toStringAsFixed(2);
  tauxControllerZ.text = zakat.taux.toStringAsFixed(2);
  observationControllerZ.text = zakat.observation ?? "";

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
                  text: l10n.modifyZakat,
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
                                            controller: TextEditingController(text: zakat.code),
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
                                                updateStockAuto();
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
                                            controller: stockControllerZ,
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
                                            controller: liquiditesControllerZ,
                                            hint: l10n.cashBank,
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.receivables,
                                          obligatoire: true,
                                          child: TextChampL(
                                            controller: creancesControllerZ,
                                            obligatoire: true,
                                            hint: l10n.moneyToReceive,
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          obligatoire: true,
                                          label: l10n.debts,
                                          child: TextChampL(
                                            controller: dettesControllerZ,
                                            hint: l10n.shortTermDebts,
                                            obligatoire: true,
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
                                            controller: nissabControllerZ,
                                            obligatoire: true,
                                            hint: l10n.nissabThreshold,
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          obligatoire: true,
                                          label: l10n.ratePercent,
                                          child: TextChampL(
                                            controller: tauxControllerZ,
                                            obligatoire: true,
                                            hint: "2.5",
                                            numeric: true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.status,
                                          obligatoire: true,
                                          child: TextListe(
                                            obligatoire: true,
                                            clearable: false,
                                            value: selectedStatutZ,
                                            items: [l10n.unpaid, l10n.paid],
                                            onChanged: (v) => setState(() => selectedStatutZ = v!),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ChampAvecLabel(
                                          label: l10n.observation,
                                          child: TextChampL(
                                            controller: observationControllerZ,
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
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.zakat,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.zakat,
                          message: l10n.confirmModifyZakat,
                          onConfirmer: () async {
                            zakat.liquidites = double.tryParse(liquiditesControllerZ.text) ?? zakat.liquidites;
                            zakat.creances = double.tryParse(creancesControllerZ.text) ?? zakat.creances;
                            zakat.dettes = double.tryParse(dettesControllerZ.text) ?? zakat.dettes;
                            zakat.nissab = double.tryParse(nissabControllerZ.text) ?? zakat.nissab;
                            zakat.stock = double.tryParse(stockControllerZ.text) ?? zakat.stock;
                            zakat.taux = double.tryParse(tauxControllerZ.text) ?? zakat.taux;
                            zakat.statut = translator.statutZakatToFrench(selectedStatutZ);
                            zakat.observation = observationControllerZ.text;
                            zakat.dateModif = DateTime.now();
                            zakat.modifParCode = userCode;

                            final response = await _SaveData(
                              zakat: zakat,
                              userName: userName,
                              userCode: userCode,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                kind: DialogKind.refuser,
                                titre_concerne: l10n.zakat,
                                message: response.message ?? l10n.errorOccurred,
                              );
                              return;
                            }

                            await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.zakat,
                                message: response.message ?? l10n.zakatModifiedSuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                }
                            );
                          },
                        );
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