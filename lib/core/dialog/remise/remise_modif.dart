import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../dialog//confirmation_dialog.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/ajouter_manuel.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/affichage_champ.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/date_champ.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../../../../data/models/remise.dart';
import '../information_dialog.dart';

final TextEditingController nomRemiseController = TextEditingController();
final TextEditingController observRemiseController = TextEditingController();
final TextEditingController tauxController = TextEditingController();
final TextEditingController montantRemiseController = TextEditingController();
final TextEditingController debutController = TextEditingController();
final TextEditingController finController = TextEditingController();
List<Produit> produitsTest = [];
List<Produit> produitsRemise = [];
String? selectedTypeCalcul;

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _LoadData({required int remiseId}) async {
  produitsTest = await ProduitServices.getAllProduits();
  produitsRemise = produitsTest.where((e) => e.remiseId == remiseId).toList();
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

  final DateTime safeMinDate = minDate ?? DateTime(2000);

  if (initialDate.isBefore(safeMinDate)) {
    initialDate = safeMinDate;
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: safeMinDate,
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



Future<ApiResponse<int>> _saveRemise({
  required Remise remised,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = RemiseServices(db);
  final service = ProduitServices(db);
  final serviceh = HistoriqueServices(db);

  try {
    final existingRemise = await db.query(
      'remises',
      where: 'nom = ? AND id != ?',
      whereArgs: [remised.nom, remised.id],
    );
    if (existingRemise.isNotEmpty) {
      return ApiResponse(
        success: false,
        message: "Une remise avec ce nom existe déjà.",
      );
    }

    final anciensProduits = await service.getProduitsByRemiseId(remised.id);

    for (var p in anciensProduits) {
      if (!produitsRemise.any((pr) => pr.id == p.id)) {
        p.remiseId = null;
        p.dateModif = DateTime.now();
        p.modifParCode = userCode;
        await service.updateProduit(p);

        final int idN = await _GetNextHistoriqueId();
        final Historique histoProduit = Historique(
          id: idN,
          code: "HS$idN ${DateTime.now().microsecondsSinceEpoch}",
          desc: "L'utilisateur $userName a retiré la remise ${remised.nom} du produit ${p.nom}",
          oper: ListsConst.typeHisto[1],
          type: "Produit",
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await serviceh.addHistorique(histoProduit);
      }
    }

    for (var p in produitsRemise) {
      if (p.remiseId != remised.id) {
        p.remiseId = remised.id;
        p.dateModif = DateTime.now();
        p.modifParCode = userCode;
        await service.updateProduit(p);

        final int idN = await _GetNextHistoriqueId();
        final Historique histoProduit = Historique(
          id: idN,
          code: "HS$idN ${DateTime.now().microsecondsSinceEpoch}",
          desc: "L'utilisateur $userName a appliqué la remise ${remised.nom} au produit ${p.nom}",
          oper: ListsConst.typeHisto[1],
          type: "Produit",
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await serviceh.addHistorique(histoProduit);
      }
    }

    final response = await services.updateRemise(remised);

    final int idH = await _GetNextHistoriqueId();
    final Historique histoRemise = Historique(
      id: idH,
      code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "L'utilisateur $userName a modifié la remise ${remised.nom}",
      type: "Remise",
      oper: ListsConst.typeHisto[1],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histoRemise);

    return ApiResponse(
      success: true,
      message: "Remise modifiée avec succès.",
      data: response,
    );
  } catch (e) {
    return ApiResponse(
      success: false,
      message: "Erreur lors de la modification : $e",
    );
  }
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> RemiseModif(BuildContext context, Remise remise) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredModify,
    );
    return;
  }

  nomRemiseController.text = remise.nom;
  observRemiseController.text = remise.observation ?? '';
  tauxController.text = remise.taux.toString();
  montantRemiseController.text = remise.taux.toString();
  debutController.text = "${remise.debut}";
  finController.text = remise.fin != null ? "${remise.fin}" : '';

  selectedTypeCalcul = remise.tauxType;

  await _LoadData(remiseId: remise.id);

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
                width: 900,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/remise_icon.png',
                  text: l10n.modifyDiscount,
                ),
                content: Form(
                  key: produitFormKey,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: remise.type == "Par Produit"
                              ? _buildRemiseParProduitModif(setState, context, remise, l10n, translator)
                              : _buildRemiseParMontantModif(setState, context, remise, l10n, translator),
                        ),
                      ),
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
                      icon: Icons.save,
                      color: Appstyle.violet,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.discount,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modification,
                          message: l10n.confirmModifyDiscount,
                          onConfirmer: () async {
                            try {
                              final remised = Remise(
                                id: remise.id,
                                code: remise.code,
                                nom: nomRemiseController.text.trim(),
                                observation: observRemiseController.text.trim(),
                                debut: DateTime.parse(debutController.text),
                                fin: DateTime.parse(finController.text),
                                type: remise.type,
                                taux: double.parse(tauxController.text),
                                tauxType: selectedTypeCalcul!,
                                montant: double.tryParse(montantRemiseController.text),
                                modifLe: DateTime.now(),
                                modifParCode: userCode,
                                creeLe: remise.creeLe,
                                creeParCode: remise.creeParCode,
                                etat: true,
                              );

                              final response = await _saveRemise(
                                remised: remised,
                                userName: userName,
                                userCode: userCode,
                              );

                              if (!response.success) {
                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.error,
                                  titre_concerne: l10n.discount,
                                  message: response.message ?? l10n.errorOccurred,
                                );
                                return;
                              }

                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.discount,
                                message: response.message ?? l10n.discountModifiedSuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.discount,
                                message: "${l10n.errorOccurred}: $e",
                              );
                            }
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

Widget _buildRemiseParProduitModif(
    void Function(VoidCallback fn) setState,
    BuildContext context,
    Remise remise,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChampAvecLabel(
                    label: l10n.reference,
                    child: AffichageChamp(text: remise.code),
                  ),
                  const SizedBox(height: 20),
                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.name,
                    child: TextChampL(
                      controller: nomRemiseController,
                      hint: '',
                      obligatoire: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.start,
                    child: TextDate(
                      obligatoire: true,
                      controller: debutController,
                      onTap: () => pickDate(context, debutController),
                      hint: '',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.end,
                    child: TextDate(
                      obligatoire: true,
                      controller: finController,
                      onTap: () {
                        if (debutController.text.isEmpty) return;
                        final debut = DateTime.parse(debutController.text);
                        pickDate(context, finController, minDate: debut);
                      },
                      hint: '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.rateType,
                    child: TextListe(
                      obligatoire: true,
                      clearable: false,
                      value: selectedTypeCalcul,
                      items: translator.typeCalculDisplayList,
                      onChanged: (v) {
                        setState(() {
                          tauxController.clear();
                          selectedTypeCalcul = translator.typeCalculToFrench(v!);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChampAvecLabel(
                          obligatoire: true,
                          label: l10n.amountRate,
                          child: TextChampL(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.requiredField;
                              }
                              final double? taux = double.tryParse(value);
                              if (taux == null) {
                                return l10n.invalidNumber;
                              }
                              if (selectedTypeCalcul == "Pourcentage" && taux > 100) {
                                return l10n.percentageExceeds100;
                              }
                              if (taux < 0) {
                                return l10n.valueMustBePositive;
                              }
                              return null;
                            },
                            maxValue: selectedTypeCalcul == 'Pourcentage' ? 100 : null,
                            numeric: true,
                            controller: tauxController,
                            hint: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        selectedTypeCalcul == 'Pourcentage' ? "%" : l10n.currency,
                        style: Appstyle.textMB.copyWith(
                          color: Appstyle.violet,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ChampAvecLabel(
                    label: l10n.observation,
                    child: TextChampL(
                      controller: observRemiseController,
                      hint: '',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      TitleSmall(
        imagePath: 'assets/icons/sidebar/produit_icon.png',
        text: l10n.productsConcerned,
        couleur: Appstyle.violet,
      ),
      const SizedBox(height: 10),
      _headerTableProduitsRemise(l10n),
      const SizedBox(height: 6),
      Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: _tableProduitsRemise(setState, l10n, remise),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => _ouvrirInsertionProduitRemise(context, setState, l10n),
        child: const AddManualWidget(),
      ),
    ],
  );
}

Widget _buildRemiseParMontantModif(
    void Function(VoidCallback fn) setState,
    BuildContext context,
    Remise remise,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChampAvecLabel(
                label: l10n.reference,
                child: AffichageChamp(text: remise.code),
              ),
              const SizedBox(height: 20),
              ChampAvecLabel(
                obligatoire: true,
                label: l10n.name,
                child: TextChampL(
                  obligatoire: true,
                  controller: nomRemiseController,
                  hint: '',
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                obligatoire: true,
                label: l10n.start,
                child: TextDate(
                  obligatoire: true,
                  controller: debutController,
                  onTap: () => pickDate(context, debutController),
                  hint: '',
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                obligatoire: true,
                label: l10n.end,
                child: TextDate(
                  obligatoire: true,
                  controller: finController,
                  onTap: () {
                    if (debutController.text.isEmpty) return;
                    final debut = DateTime.parse(debutController.text);
                    pickDate(context, finController, minDate: debut);
                  },
                  hint: '',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChampAvecLabel(
                obligatoire: true,
                label: l10n.rateType,
                child: TextListe(
                  obligatoire: true,
                  clearable: false,
                  value: selectedTypeCalcul,
                  items: translator.typeCalculDisplayList,
                  onChanged: (v) {
                    setState(() {
                      selectedTypeCalcul = translator.typeCalculToFrench(v!);
                      tauxController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChampAvecLabel(
                      obligatoire: true,
                      label: l10n.amountRate,
                      child: TextChampL(
                        obligatoire: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.requiredField;
                          }
                          final double? taux = double.tryParse(value);
                          if (taux == null) {
                            return l10n.invalidNumber;
                          }
                          if (selectedTypeCalcul == "Pourcentage" && taux > 100) {
                            return l10n.percentageExceeds100;
                          }
                          if (taux < 0) {
                            return l10n.valueMustBePositive;
                          }
                          return null;
                        },
                        maxValue: selectedTypeCalcul == 'Pourcentage' ? 100 : null,
                        numeric: true,
                        controller: tauxController,
                        hint: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedTypeCalcul == 'Pourcentage' ? "%" : l10n.currency,
                    style: Appstyle.textMB.copyWith(
                      color: Appstyle.violet,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.observation,
                child: TextChampL(
                  controller: observRemiseController,
                  hint: '',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _headerTableProduitsRemise(AppLocalizations l10n) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    decoration: BoxDecoration(
      color: Appstyle.gris.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            l10n.code,
            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            l10n.product,
            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            l10n.currentDiscount,
            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}

Widget _tableProduitsRemise(
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n,
    Remise remise) {
  if (produitsRemise.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        l10n.noProductsAdded,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: produitsRemise.length,
    itemBuilder: (context, index) {
      final p = produitsRemise[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                p.code ?? "-",
                style: Appstyle.textSB,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                p.nom ?? "-",
                style: Appstyle.textSB,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                p.remiseId == remise.id ? remise.nom : "-",
                style: Appstyle.textSB,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    produitsRemise.removeAt(index);
                  });
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _ouvrirInsertionProduitRemise(
    BuildContext context,
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n) {
  showDialog(
    context: context,
    builder: (_) => InsertionProduitDialog(
      multiselection: false,
      produits: produitsTest,
      onProduitSelected: (Produit produit) {
        setState(() {
          if (!produitsRemise.any((p) => p.id == produit.id)) {
            produitsRemise.add(produit);
          }
        });
      },
    ),
  );
}