import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SousCategories.dart' hide ApiResponse;
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/categorie.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

// Controllers
final TextEditingController nomCategorieController = TextEditingController();
final TextEditingController onbservCategorieController = TextEditingController();
String? selectedEtatR;

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

// ✅ Correction : Mettre à jour aussi les sous-catégories et produits
Future<ApiResponse<int>> _saveCategorie({
  required Categorie categorie,
  required String oldNom,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = CategorieServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceS = SousCategoriesServices(db);
  final serviceP = ProduitServices(db);

  // 1. Mettre à jour la catégorie
  final response = await service.updateCategorie(categorie);

  // 2. Mettre à jour les sous-catégories si le nom a changé
  if (oldNom != categorie.nom) {
    try {
      // Récupérer toutes les sous-catégories de cette catégorie
      final sousCate = await serviceS.getSousCategorieByCategorie(oldNom);

      for (var sous in sousCate) {
        // Mettre à jour le nom de la catégorie dans la sous-catégorie
        final sousUpdate = SousCategorie(
          id: sous.id,
          nom: sous.nom,
          code: sous.code,
          etat: sous.etat,
          categorieId: sous.categorieId,
          categorieNom: categorie.nom, // ✅ Nouveau nom
          creePar: sous.creePar,
          creeParCode: sous.creeParCode,
          dateCree: sous.dateCree,
          observation: sous.observation,
          modifPar: userName,
          dateModif: DateTime.now(),
        );

        await serviceS.updateSousCategorie(sousUpdate);

        // Historique
        final int idS = await _GetNextHistoriqueId();
        final Historique histo = Historique(
          id: idS,
          code: "HS$idS ${DateTime.now().microsecondsSinceEpoch}",
          desc: "L'utilisateur $userName a modifié la catégorie de la sous-catégorie ${sous.nom} de '$oldNom' vers '${categorie.nom}'",
          type: "SousCategorie",
          oper: ListsConst.typeHisto[1],
          creePar: userName,
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await serviceh.addHistorique(histo);
      }
    } catch (e) {
      print('⚠️ Erreur mise à jour sous-catégories: $e');
    }

    // 3. Mettre à jour les produits
    try {
      final produits = await serviceP.getProduitsByCategorie(oldNom);

      for (var produit in produits) {
        // Mettre à jour le nom de la catégorie dans le produit
        final produitUpdate = Produit(
          id: produit.id,
          nom: produit.nom,
          code: produit.code,
          marque: produit.marque,
          description: produit.description,
          codeBarre: produit.codeBarre,
          numeroSerie: produit.numeroSerie,
          fournisseur: produit.fournisseur,
          categorieId: produit.categorieId,
          sousCategorieId: produit.sousCategorieId,
          remiseId: produit.remiseId,
          categorie: categorie.nom, // ✅ Nouveau nom
          sousCategorie: produit.sousCategorie,
          remise: produit.remise,
          multicodebar: produit.multicodebar,
          prixAchat: produit.prixAchat,
          prixVente: produit.prixVente,
          margeBool: produit.margeBool,
          margeTaux: produit.margeTaux,
          margeTauxPrct: produit.margeTauxPrct,
          tva: produit.tva,
          photo: produit.photo,
          seuilBool: produit.seuilBool,
          quantite: produit.quantite,
          seuilMin: produit.seuilMin,
          seuilMax: produit.seuilMax,
          uniteMesure: produit.uniteMesure,
          observation: produit.observation,
          dateEmpreint: produit.dateEmpreint,
          emballage1: produit.emballage1,
          emballageP1: produit.emballageP1,
          emballageP2: produit.emballageP2,
          emballage2: produit.emballage2,
          creeParcode: produit.creeParcode,
          dateCree: produit.dateCree,
          creePar: produit.creePar,
          etat: produit.etat,
          dateModif: DateTime.now(),
          modifPar: userName,
          annulerPar: produit.annulerPar,
          annulerLe: produit.annulerLe,
          motifAnnul: produit.motifAnnul,
          service: produit.service,
          taille: produit.taille,
          couleur: produit.couleur,
        );

        await serviceP.updateProduit(produitUpdate);

        // Historique
        final int idP = await _GetNextHistoriqueId();
        final Historique histo = Historique(
          id: idP,
          code: "HS$idP ${DateTime.now().microsecondsSinceEpoch}",
          desc: "L'utilisateur $userName a modifié la catégorie du produit ${produit.nom} de '$oldNom' vers '${categorie.nom}'",
          type: "Produit",
          oper: ListsConst.typeHisto[1],
          creePar: userName,
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await serviceh.addHistorique(histo);
      }
    } catch (e) {
      print('⚠️ Erreur mise à jour produits: $e');
    }
  }

  // 4. Historique principal de la catégorie
  final int idH = await _GetNextHistoriqueId();
  final Historique histo = Historique(
    id: idH,
    code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
    desc: "L'utilisateur $userName a modifié la catégorie ${categorie.nom}",
    type: "Categorie",
    oper: ListsConst.typeHisto[1],
    creePar: userName,
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceh.addHistorique(histo);

  return response;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> CategorieModif(BuildContext context, Categorie categorie) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username;
  final userCode = auth.userCode;

  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  // Initialisation
  int id = categorie.id;
  nomCategorieController.text = categorie.nom;
  String oldNom = categorie.nom; // ✅ Sauvegarder l'ancien nom
  onbservCategorieController.text = categorie.observation ?? '';
  selectedEtatR = categorie.etat ? l10n.active : l10n.inactive;
  String code = categorie.code;

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
                width: 700,
                height: 700,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/categorie_icon.png',
                  text: l10n.modifyCategory,
                ),
                content: Form(
                  key: produitFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChampAvecLabel(
                        label: l10n.status,
                        child: TextListe(
                          clearable: false,
                          value: selectedEtatR,
                          items: [l10n.active, l10n.inactive],
                          onChanged: (v) => setState(() {
                            selectedEtatR = v;
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: l10n.name,
                        obligatoire: true,
                        child: TextChampL(
                          controller: nomCategorieController,
                          obligatoire: true,
                          hint: l10n.categoryNameHint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: l10n.observation,
                        child: TextChampL(
                          controller: onbservCategorieController,
                          hint: l10n.categoryObservationHint,
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
                        /// ✅ Validation formulaire
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.modifyCategory,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        /// ✅ Dialog confirmation
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modifyCategory,
                          message: oldNom != nomCategorieController.text.trim()
                              ? "Êtes-vous sûr de vouloir modifier le nom de la catégorie '$oldNom' en '${nomCategorieController.text.trim()}' ?\n\n⚠️ Cela mettra à jour automatiquement toutes les sous-catégories et produits associés."
                              : "Êtes-vous sûr de vouloir modifier cette catégorie ?",
                          onConfirmer: () async {
                            try {
                              final categorieU = Categorie(
                                id: categorie.id,
                                code: categorie.code,
                                nom: nomCategorieController.text.trim(),
                                observation: onbservCategorieController.text.trim(),
                                etat: selectedEtatR == l10n.active,
                                creePar: categorie.creePar,
                                creeParCode: categorie.creeParCode,
                                dateCree: categorie.dateCree,
                                dateModif: DateTime.now(),
                                modifPar: userName,
                              );

                              final response = await _saveCategorie(
                                categorie: categorieU,
                                oldNom: oldNom, // ✅ Passer l'ancien nom
                                userCode: userCode!,
                                userName: userName!,
                              );

                              /// ❌ ERREUR
                              if (!response.success) {
                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.error,
                                  titre_concerne: l10n.modifyCategory,
                                  message: response.message ??
                                      "Une erreur est survenue lors de la modification.",
                                );
                                return;
                              }

                              /// ✅ SUCCÈS
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.modifyCategory,
                                message: oldNom != nomCategorieController.text.trim()
                                    ? "Catégorie modifiée avec succès.\n\nToutes les sous-catégories et produits ont été mis à jour."
                                    : l10n.modifySuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.modifyCategory,
                                message: "Erreur lors de la modification : $e",
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