import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Sortie.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SousCategories.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dialog//confirmation_dialog.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

/// Modification d'une sortie déjà enregistrée : le contenu (produit,
/// quantité, type, prix, montant) est verrouillé dès l'enregistrement —
/// même principe que Pannier/SmartScan/Retour. Seules la date et
/// l'observation restent modifiables ; une correction du contenu passe par
/// une annulation.
List<Produit> produitsTest = [];
List<Categorie> categoriesTestSM = [];
List<SousCategorie> sousCategoriesTestSM = [];

// Sortie n'a pas besoin de l'heure précise, seulement du jour — même
// convention date-only que sortie_nouveau.dart, pour ne pas perdre
// silencieusement une heure existante en réassignant `sortie.date`
// directement depuis le sélecteur.
String _formatDateOnlySM(DateTime d) =>
    "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

Future<void> _LoadAllData() async {
  produitsTest = await ProduitServices.getAllProduits();
  categoriesTestSM = await CategorieServices.getAllCategorie();
  sousCategoriesTestSM = await SousCategoriesServices.getAllSousCategorie();
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _UpdateR({
  required String userName,
  required String userCode,
  required Sortie sortie,
}) async {
  final db = await DbCreator.openDb();
  final services = SortieServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);

  final produits = await ProduitServices.getAllProduits();
  final response = await services.updateSortie(sortie);
  if (!response.success) {
    return response;
  }

  // Répercuter la date sur le mouvement de stock lié — le contenu ne change
  // plus, seule la date peut être corrigée.
  final mouvement = await MouvementsServices.getAllMouvementsByCodeOper(sortie.code);
  if (mouvement.isNotEmpty) {
    final m = mouvement.first;
    m.date = sortie.date;
    m.dateModif = DateTime.now();
    m.modifParCode = userCode;
    await serviceM.updateMouvement(m);
  }

  final prod = produits.where((e) => e.code == sortie.produitCode).firstOrNull;

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "sortie",
      desc: "L'utilisateur $userName a modifié la date/observation de la Sortie ${sortie.code}"
          "${prod != null ? ' de Produit ${prod.nom}' : ''}",
      oper: ListsConst.typeHisto[1],
      dateCree: DateTime.now(),
      creeParCode: userCode
  );

  await serviceh.addHistorique(histo);
  return response;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> SortieModif(BuildContext context, Sortie sortie) async {
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

  TextEditingController codeControllerS = TextEditingController();
  TextEditingController prixControllerS = TextEditingController();
  TextEditingController montantControllerS = TextEditingController();
  TextEditingController quantiteControllerS = TextEditingController();
  TextEditingController nombreControllerS = TextEditingController();
  TextEditingController observationControllerS = TextEditingController();
  TextEditingController dateControllerS = TextEditingController();

  codeControllerS.text = sortie.code;
  prixControllerS.text = sortie.prix.toStringAsFixed(2);
  montantControllerS.text = sortie.montant.toStringAsFixed(2);
  quantiteControllerS.text = QuantiteFormat.format(sortie.quantite);
  nombreControllerS.text = sortie.nombre != null ? QuantiteFormat.format(sortie.nombre!) : '';
  observationControllerS.text = sortie.observation ?? "";
  dateControllerS.text = _formatDateOnlySM(sortie.date);

  final Produit? prods = produitsTest.where((e) => e.code == sortie.produitCode).firstOrNull;
  final String nomProduit = prods?.nom ?? sortie.produitCode;
  final bool afficheNombreS = prods?.nombreActif ?? false;

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          final String typeAffiche = translator.translateTypeSortie(sortie.type);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                height: 420,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/sortie_icon.png',
                  text: l10n.modifyExit,
                ),

                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChampAvecLabel(
                                label: l10n.code,
                                child: TextChampL(
                                  controller: codeControllerS,
                                  enabled: false,
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.product,
                                child: TextChampL(
                                  controller: TextEditingController(text: nomProduit),
                                  enabled: false,
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.exitType,
                                child: TextListe(
                                  value: typeAffiche,
                                  clearable: false,
                                  items: translator.typeSortieDisplayList,
                                  enabled: false,
                                  onChanged: (v) {},
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.date,
                                obligatoire: true,
                                child: TextDate(
                                  obligatoire: true,
                                  hint: '',
                                  controller: dateControllerS,
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: sortie.date,
                                    );
                                    if (d != null) {
                                      setState(() {
                                        sortie.date = d;
                                        dateControllerS.text = _formatDateOnlySM(d);
                                      });
                                    }
                                  },
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
                                label: l10n.quantity,
                                child: TextChampL(
                                  controller: quantiteControllerS,
                                  enabled: false,
                                  numeric: true,
                                  isQuantite: true,
                                  uniteMesure: prods?.uniteMesure,
                                  hint: '',
                                ),
                              ),
                              if (afficheNombreS) ...[
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.numberField,
                                  child: TextChampL(
                                    controller: nombreControllerS,
                                    enabled: false,
                                    numeric: true,
                                    isQuantite: true,
                                    uniteMesure: QuantiteFormat.unitePiece,
                                    hint: '',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.price,
                                child: TextChampL(
                                  controller: prixControllerS,
                                  enabled: false,
                                  numeric: true,
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.amount,
                                child: TextChampL(
                                  controller: montantControllerS,
                                  enabled: false,
                                  numeric: true,
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationControllerS,
                                  hint: l10n.observationHint,
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
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.exit,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modification,
                          message: l10n.confirmModifyExit,
                          onConfirmer: () async {
                            sortie.modifParCode = userCode;
                            sortie.dateModif = DateTime.now();
                            sortie.observation = observationControllerS.text;

                            final response = await _UpdateR(
                                userName: userName,
                                userCode: userCode,
                                sortie: sortie,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                kind: DialogKind.refuser,
                                titre_concerne: l10n.exit,
                                message: response.message ?? l10n.errorOccurred,
                              );
                              return;
                            }

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.exit,
                              message: response.message ?? l10n.exitModifiedSuccess,
                              onTerminer: () {
                                Navigator.pop(context);
                              },
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
