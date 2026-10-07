import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:collection/collection.dart';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/CaisseParam.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/data/models/caisse_session.dart';
import 'package:caisse_dz/core/dialog/caisse_session/caisse_fermee_dialog.dart';
import 'package:caisse_dz/core/dialog/caisse_session/ouverture_caisse.dart';
import 'package:caisse_dz/core/dialog/caisse_session/cloture_caisse_session.dart';
import 'package:caisse_dz/core/dialog/caisse_session/mouvement_manuel.dart';
import 'package:caisse_dz/Services/PaiementParam.dart';
import 'package:caisse_dz/data/models/paiementParam.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/Caisse/caisse_session_state.dart';

import 'package:caisse_dz/core/dialog/caisse/Enregistr%C3%A9_caisse.dart';
import 'package:caisse_dz/core/dialog/caisse/parametre_caisse.dart';
import 'package:caisse_dz/core/dialog/caisse/Encaisser_ticket.dart';
import 'package:caisse_dz/core/dialog/caisse/encaisser_blsc.dart';
import 'package:caisse_dz/core/dialog/caisse/modif_prix.dart';

import 'package:caisse_dz/core/dialog/client/client_nouveau.dart';

import 'package:caisse_dz/core/dialog/confirmation_dialog.dart';

import 'package:caisse_dz/core/dialog/insertion_client.dart';
import 'package:caisse_dz/core/dialog/insertion_remise.dart';

import 'package:caisse_dz/core/dialog/produit/produit_nouveau.dart';
import 'package:caisse_dz/core/dialog/produit/produit_detail.dart';
import 'package:caisse_dz/core/dialog/produit/produit_introuvable_dialog.dart';
import 'package:caisse_dz/core/utilis/barcode_scan_listener.dart';
import 'package:caisse_dz/core/utilis/keyboard_shortcut_listener.dart';
import 'package:flutter/services.dart';

import 'package:caisse_dz/core/tableau/caisse/tableau_produit_caisse.dart';
import 'package:caisse_dz/core/tableau/caisse/tableau_caisse.dart';


import 'package:caisse_dz/core/theme/app_style.dart';

import 'package:caisse_dz/core/utilis/constant.dart';

import 'package:caisse_dz/core/widget/afficheur/afficheur_caisse.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_produit.dart';

import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';

import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';

import 'package:caisse_dz/core/widget/calculatrice_small.dart';
import 'package:caisse_dz/core/widget/card/card_product.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/title/title_small.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/core/widget/calculatrice.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/data/models/caisseParam.dart';
import 'package:caisse_dz/data/models/categorie.dart';

import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';

import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_code_detail.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/caisse.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';

import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../Services/MagasinDetail.dart';
import '../Services/Pannier.dart';
import '../core/dialog/base_dialog.dart';
import '../core/dialog/caisse/afficher_produit_selectionner.dart';
import '../core/dialog/caisse/pannier_vendu.dart';
import '../core/dialog/caisse/recette_produit.dart';
import '../core/dialog/caisse/rechercher_produit.dart';
import '../core/dialog/entree/entree_nouveau.dart';
import '../core/dialog/information_dialog.dart';
import '../core/widget/title/titre_avec_ligne.dart';
import '../data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class CaisseScreen extends StatefulWidget {
  CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  // Ajouter ces variables avec les autres déclarations
  List<Pack> packsTest = [];
  List<ProduitPackDetail> packDetailsTest = [];
  Pack? selectedPack;

  late StockManager _stockManager;
  late BarcodeScanListener _barcodeScanListener;
  late KeyboardShortcutListener _keyboardShortcutListener;

  Key _tableauKey = const ValueKey('tableau');  // ✅ AJOUTEZ CETTE LIGNE
  List<ProduitMagasinDetail> produitMagasinDetails = [];
  bool isMagasinSystem = false;

  List<Produit>       produitsTest        = [];
  List<Client>        clientsTest         = [];
  List<Remise>        remisesTest         = [];
  List<SousCategorie> sousCategoriesTest  = [];
  List<Categorie>     categoriesTest      = [];
  List<CaisseGestion> CaisseTest          = [];
  CaisseParam?        Param;
  PaiementParam?      paiementParam;
  double              seuilMinimum        = 0;

  // ✅ Programme de bonus (Paramètres > Système) : n'affiche le mode de
  // paiement "Points" que si le programme est actif.
  bool                activeBonus         = false;
  double              bonusTaux           = 0;

  bool isLoading = true;

  List<String> CaisseList   = [];
  String CaisseAct   ="";

  // ✅ Architecture caisse (Ouverture -> Mouvements -> Clôture) : session
  // actuellement ouverte pour CaisseAct, ou null si la caisse est fermée.
  // Rafraîchie via _refreshSessionOuverte (chargement initial/reload, et
  // après chaque action ouverture/clôture/mouvement manuel).
  CaisseSession? sessionOuverteActuelle;

  String? get _caisseCodeActif =>
      CaisseTest.where((c) => c.nomCaisse == CaisseAct).firstOrNull?.code;

  Future<void> _refreshSessionOuverte() async {
    final code = _caisseCodeActif;
    final session = code != null ? await CaisseSessionServices.getSessionOuverte(code) : null;
    if (mounted) {
      setState(() => sessionOuverteActuelle = session);
    }
  }

  // ✅ Texte affiché pour la remise sélectionnée dans AfficheurCaisse : vide
  // si aucune remise n'est sélectionnée, sinon nom + taux quelle que soit
  // la période (le grisé/orange indique si elle est applicable ou non).
  String _remiseAfficheurText() {
    final info = caisseActive.remiseInfo;
    if (info == null) return "";
    final l10n = AppLocalizations.of(context)!;
    final tauxLabel = info.tauxType.toLowerCase() == "pourcentage"
        ? "${NumberFormatUtil.formatMontant(info.taux, decimales: 0)}%"
        : "${NumberFormatUtil.formatMontant(info.taux, decimales: 2)} ${l10n.currency}";
    return "${info.nom} ($tauxLabel)";
  }

  // ✅ Orange si la remise sélectionnée est dans sa période de validité,
  // gris si elle est sélectionnée mais hors délais.
  Color _remiseAfficheurColor() {
    if (caisseActive.remiseInfo == null) return Appstyle.Tblanc;
    return caisseActive.remiseHorsPeriode ? Appstyle.gris : Colors.orange;
  }

  // Ajoutez cette méthode dans _CaisseScreenState
  void updateRemiseCondition() {
    if (caisseActive.remiseInfo != null && caisseActive.remiseInfo!.montantCondition > 0) {
      final sousTotal = caisseActive.produits.fold<double>(
          0, (sum, p) => sum + (p.prix * p.qte)
      );

      final etaitActive = caisseActive.remiseActive;
      caisseActive.recalculerTotaux();

      // Si la remise vient de s'activer, afficher une notification
      if (!etaitActive && caisseActive.remiseActive) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.discountAppliedNamed(caisseActive.remiseInfo!.nom)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  Future<bool> verifierStockMagasin({
    required Produit produit,
    required double quantiteReelle,
    required String? colisType,
  }) async {
    // ✅ Un produit "service" n'a pas de stock physique suivi : toujours disponible.
    if (produit.service) return true;

    final db = await DbCreator.openDb();
    final pmdService = ProduitMagasinDetailServices(db);
    final l10n = AppLocalizations.of(context);

    // 1️⃣ Vérifier le stock global (calculé depuis le journal des mouvements)
    final quantiteGlobale = await MouvementsServices.quantiteProduit(produit.code);
    if (quantiteReelle > quantiteGlobale) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.product,
        message: l10n.stockGlobalInsuffisant(quantiteGlobale.toInt().toString(), quantiteReelle.toInt().toString()),
      );
      return false;
    }

    // 2️⃣ Récupérer le magasin sélectionné
    final magasinSelectionneCode = Param?.magasinCode;
    final magasinSelectionneNom = Param?.selectedMagasin;

    // 3️⃣ Vérifier le stock dans le magasin (calculé depuis le journal des
    // mouvements, filtré par magasin — remplace ProduitMagasinDetail.quantite).
    if (magasinSelectionneCode != null && magasinSelectionneCode.isNotEmpty) {
      final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
          produit.code,
          magasinSelectionneCode
      );

      if (magasinDetail != null) {
        final quantiteMagasin = await MouvementsServices.quantiteProduit(
          produit.code,
          magasinCode: magasinSelectionneCode,
        );
        if (quantiteMagasin >= quantiteReelle) {
          return true; // Stock suffisant
        }
        // Stock insuffisant - proposer de prendre ce qui est disponible
        final confirm = await ConfirmationDialog(
          context: context,
          kind: DialogKind.attention,
          titre: l10n.attention,
          message: l10n.stockInsuffisantMagasin(
              magasinSelectionneNom ?? '',
              quantiteMagasin.toInt().toString(),
              quantiteReelle.toInt().toString()),
          onConfirmer: () {},
        );
        return confirm == true;
      }
    }

    // caisse_dz est mono-magasin : aucun autre magasin où chercher du stock.
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      kind: DialogKind.refuser,
      titre_concerne: l10n.product,
      message: l10n.produitAucunMagasin,
    );
    return false;
  }
// Ajoutez cette méthode dans _CaisseScreenState
  Future<bool> appliquerRemise(Remise remise) async {
    final l10n = AppLocalizations.of(context)!;

    // Calculer le sous-total
    final sousTotal = caisseActive.produits.fold<double>(
        0, (sum, p) => sum + (p.prix * p.qte)
    );

    // Vérifier selon le type de remise
    if (remise.tauxType.toLowerCase() == "montant") {
      if (remise.taux > sousTotal) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          kind: DialogKind.refuser,
          titre_concerne: l10n.discount,
          message:l10n.discountAmountExceedsTotal(
              selectedRemise.taux.toString(),
              NumberFormatUtil.formatMontant(sousTotal, decimales: 2)
        ));
        return false;
      }
    }

    // Appliquer la remise
    setState(() {
      caisseActive.remisenom = remise.nom;
      caisseActive.remiseValeur = remise.taux;
      caisseActive.recalculerTotaux();
    });

    return true;
  }

  Future<void> _LoadAllData() async {
    final auth        = Provider.of<AuthState>(context, listen: false);
    final userCode    = auth.userCode;
    final db = await DbCreator.openDb();
    final service = await CaisseParamServices(db);
    final pmdService = ProduitMagasinDetailServices(db);

    produitMagasinDetails = await ProduitMagasinDetailServices.getAllProduitMagasinDetails();

    final souscate  = await SousCategoriesServices  .getAllSousCategorie();
    final categories = await CategorieServices      .getAllCategorie();
    final produits  = await ProduitServices         .getAllProduits();
    final clients   = await ClientServices          .getAllClients();
    final remisess  = await RemiseServices          .getAllRemise();
    final caiss     = await GCServices              .getAllCaisses();
    final caissParm = await service                 .getCaisseParamByUserCode(userCode!);
    final dernierPannier = await PannierServices.getLastPannierNumber();
    final param = await ParamServices.getParam();
    // ✅ Paramètres de paiement (modes actifs configurés dans l'écran Paramètres) :
    // chargés dès l'initialisation pour n'afficher que les modes visibles.
    final paiementParm = await PaiementParamServices.getPaiementParam();

    // ✅ Charger les packs et leurs détails
    final packs = await PackServices.getAllPacks();
    final packDetails = await ProduitPackDetailServices.getAllDetails();
    final codeDetails = await ProduitServices.getAllCodeDetails();
    // ✅ Quantités calculées depuis le journal des mouvements, scopées sur le
    // magasin de la caisse courante — remplace Produit.quantite.
    final quantitesStock = (await MouvementsServices.totauxParProduit(magasinCode: caissParm?.magasinCode)).quantites;

    if (mounted) {
      setState(() {
        sousCategoriesTest  = souscate;
        categoriesTest      = categories;
        produitsTest        = produits;
        remisesTest         = remisess;
        clientsTest         = clients.where((c) => c.etat).toList();
        CaisseTest          = caiss;
        Param               = caissParm;
        paiementParam       = paiementParm;
        seuilMinimum        = param.Minimum;
        activeBonus         = param.activeBonus;
        bonusTaux           = param.bonusTaux;

        // ✅ Initialiser les packs
        packsTest = packs.where((p) => p.etat == true).toList();
        packDetailsTest = packDetails;

        _buildCodeBarresSecondairesMap(codeDetails);

        dernierNumeroPannier = dernierPannier;
        nombrepannier = dernierPannier;

        CaisseList  = CaisseTest  .map((caisse) => caisse.nomCaisse).toList();
        // ✅ Un utilisateur non-Admin est verrouillé sur la caisse attachée à
        // son compte (Utilisateur.caisseCode) : elle le suit automatiquement
        // dans toutes les opérations, sans dépendre d'un choix manuel dans
        // Paramètres > Caisse (verrouillé pour ce rôle, cf. parametre_caisse.dart).
        final String? caisseAttachee = auth.role != "Admin" && auth.userCaisseCode != null
            ? CaisseTest.where((c) => c.code == auth.userCaisseCode).firstOrNull?.nomCaisse
            : null;
        CaisseAct   = caisseAttachee ?? (CaisseList.isNotEmpty ? CaisseList.first : "");

        if (caisses.isEmpty) {
          caisses = [CaisseState(nom: "Caisse 1", caisse: CaisseAct, modePaiement: _defaultModePaiement())];
        }

        if (produitsTest.isNotEmpty) {
          produitsFiltres       = produitsTest;
          produitsFiltrestable  = produitsTest;
          produitsSelectionnes  = produitsTest.first;
        }
        isLoading = false;
        _stockManager.initialiserStockReel(produitsTest, quantitesStock);
      });
      checkIfMagasinSystem();
      _refreshSessionOuverte();
    }
  }

// ✅ Vérifie si un pack est disponible (tous les produits ont assez de stock)
  Future<bool> verifierDisponibilitePack(Pack pack, {int quantitePack = 1}) async {
    final packDetails = packDetailsTest.where((d) => d.packCode == pack.code).toList();

    if (packDetails.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.pack,
        message: l10n.packSansProduit,
      );
      return false;
    }

    for (var detail in packDetails) {
      // ✅ Utiliser try-catch pour gérer le produit non trouvé
      Produit? produit;
      try {
        produit = produitsTest.firstWhere((p) => p.code == detail.produitCode);
      } catch (e) {
        produit = null;
      }

      if (produit == null) {
        final l10n = AppLocalizations.of(context)!;
        await InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          kind: DialogKind.refuser,
          titre_concerne: l10n.pack,
          message: l10n.produitInexistantBase(detail.produitCode),
        );
        return false;
      }

      final stockDisponible = getQuantiteDisponibleVirtuelle(produit);
      final quantiteNecessaire = detail.quantite.toDouble() * quantitePack;

      if (stockDisponible < quantiteNecessaire) {
        final l10n = AppLocalizations.of(context)!;
        await InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          kind: DialogKind.refuser,
          titre_concerne: l10n.pack,
          message: l10n.stockInsuffisantPourProduit(
              detail.produitCode,
              stockDisponible.toInt().toString(),
              quantiteNecessaire.toInt().toString()),
        );
        return false;
      }
    }

    return true;
  }

// ✅ Ajoute tous les produits d'un pack au panier
  // ✅ Ajoute tous les produits d'un pack au panier
  // ✅ Ajoute tous les produits d'un pack au panier
  Future<void> ajouterPackAuPanier(Pack pack, {int quantitePack = 1}) async {
    final l10n = AppLocalizations.of(context)!;

    // Vérifier la disponibilité
    final disponible = await verifierDisponibilitePack(pack, quantitePack: quantitePack);
    if (!disponible) return;

    final packDetails = packDetailsTest.where((d) => d.packCode == pack.code).toList();

    // Ajouter chaque produit du pack
    for (var detail in packDetails) {
      Produit? produit;
      try {
        produit = produitsTest.firstWhere((p) => p.code == detail.produitCode);
      } catch (e) {
        produit = null;
      }

      if (produit == null) {
        final l10n = AppLocalizations.of(context)!;
        await InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          kind: DialogKind.refuser,
          titre_concerne: l10n.pack,
          message: l10n.produitInexistant(detail.produitCode),
        );
        continue;
      }

      // ✅ Utiliser colisType = nom du pack pour regrouper les produits du pack
      await ajouterProduitAuPanier(
        produit,
        quantite: detail.quantite.toDouble() * quantitePack,  // ✅ Multiplier par la quantité de pack
        prixUnitaire: detail.prixUnitaire,
        colisType: pack.nom,           // ← Clé : regroupe les produits du pack
        packNom: pack.nom,             // ← Pour l'affichage
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.packAddedToCart(pack.nom, quantitePack > 1 ? ' x$quantitePack' : '')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ Dialogue pour sélectionner un pack
  Future<void> _ouvrirDialoguePack() async {
    final l10n = AppLocalizations.of(context)!;

    // Filtrer les packs actifs
    final packsActifs = packsTest.where((p) => p.etat == true).toList();

    if (packsActifs.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.pack,
        message: l10n.aucunPackDisponible,
      );
      return;
    }

    final Map<String, int> quantitesPack = {
      for (var p in packsActifs) p.code: 1,
    };

    showDialog(
      context: context,
      barrierColor: Appstyle.gris.withOpacity(0.4),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return BaseDialog(
              width: 600,
              height: 500,
              header: TitreAvecLigne(
                imagePath: 'assets/icons/cardwidget/pack_icon.png',
                text: l10n.pack,
              ),
              content: ListView.builder(
                itemCount: packsActifs.length,
                itemBuilder: (context, index) {
                  final pack = packsActifs[index];
                  final packDetails = packDetailsTest.where((d) => d.packCode == pack.code).toList();
                  final quantitePack = quantitesPack[pack.code] ?? 1;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Appstyle.violet.withOpacity(0.1),
                        child: const Icon(Icons.all_inbox, color: Appstyle.violet),
                      ),
                      title: Text(
                        pack.nom,
                        style: Appstyle.textMB.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${l10n.code}: ${pack.code}"),
                          const SizedBox(height: 4),
                          Text(
                            "${l10n.productsCount(packDetails.length)} | ${l10n.price}: ${NumberFormatUtil.formatMontant((pack.prixVente * quantitePack), decimales: 2)} ${l10n.currency}",
                            style: Appstyle.textS.copyWith(color: Appstyle.crevete),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            color: Appstyle.violet,
                            onPressed: () {
                              setStateDialog(() {
                                if (quantitePack > 1) {
                                  quantitesPack[pack.code] = quantitePack - 1;
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 24,
                            child: Text(
                              "$quantitePack",
                              textAlign: TextAlign.center,
                              style: Appstyle.textMB.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            color: Appstyle.violet,
                            onPressed: () {
                              setStateDialog(() {
                                quantitesPack[pack.code] = quantitePack + 1;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await ajouterPackAuPanier(pack, quantitePack: quantitePack);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appstyle.violet,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              l10n.add,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              footer: Align(
                alignment: Alignment.centerRight,
                child: MainButton(
                  text: l10n.close,
                  color: Appstyle.gris,
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            );
          },
        );
      },
    );
  }

  final TextEditingController _searchControllerPrTable  = TextEditingController();
  final TextEditingController _searchController         = TextEditingController();

  late  Remise selectedRemise;

  // ✅ Panier(s) en cours et client sélectionné : conservés dans
  // CaisseSessionState (singleton) pour survivre à la navigation vers un
  // autre module et retour sur /caisse (voir CaisseSessionState pour le détail).
  Client get clientselectione {
    return CaisseSessionState.instance.clientSelectione ??= clientsTest.isEmpty
        ? Client(
            id: 0, nom: "Comptoire", code: "", telephone: "", adresse: "",
            type: "", etat: true, dateCree: DateTime.now(), wilaya: "",
            creeParCode: "SYSTEM",
          )
        : clientsTest.first;
  }

  set clientselectione(Client value) => CaisseSessionState.instance.clientSelectione = value;

  // ✅ Mode de paiement initial d'une nouvelle caisse : premier mode visible
  // selon les paramètres (écran Paramètres). Évite d'initialiser sur "Espèces"
  // lorsque ce mode est désactivé — on prend alors le premier mode actif.
  String _defaultModePaiement() {
    final param = paiementParam;
    if (param != null) {
      final premierVisible = ListsConst.modePaiementList
          .firstWhereOrNull((mode) => param.isVisible(mode));
      if (premierVisible != null) return premierVisible;
    }
    return ListsConst.modePaiementList.first; // repli "Espèces"
  }

  CaisseState get caisseActive {
    if (caisses.isEmpty) {
      return CaisseState(nom: "Temp", caisse: CaisseAct, modePaiement: _defaultModePaiement());
    }
    if (selectedCaisse >= caisses.length) {
      selectedCaisse = caisses.length - 1;
    }
    return caisses[selectedCaisse];
  }

  ProduitPanier?  produitSelectionne;
  String          bufferQuantite = "";

  final ScrollController _produitsScrollController = ScrollController();

  bool AffichageCard = false;
  bool AffichageCalc = false;

  List<CaisseState> get caisses => CaisseSessionState.instance.caisses;
  set caisses(List<CaisseState> value) => CaisseSessionState.instance.caisses = value;

  Produit?          produitsSelectionnes;
  List<Produit>     produitsFiltres       = [];
  List<Produit>     produitsFiltrestable  = [];

  // ✅ Codes-barres secondaires (produit_code_detail), pour les produits à
  // plusieurs codes-barres : produitCode -> liste de codes-barres en minuscule.
  Map<String, List<String>> codeBarresSecondairesMap = {};

  void _buildCodeBarresSecondairesMap(List<ProduitCodeDetail> details) {
    codeBarresSecondairesMap = {};
    for (var d in details) {
      codeBarresSecondairesMap.putIfAbsent(d.produitCode, () => []).add(d.CodeBar.toLowerCase());
    }
  }

  int get selectedCaisse => CaisseSessionState.instance.selectedCaisse;
  set selectedCaisse(int value) => CaisseSessionState.instance.selectedCaisse = value;

  int nombreproduit   = 0;
  int nombrepannier   = 1;
  int dernierNumeroPannier = 0;

  bool showProduitPanel = false;

  // ✅ Filtre catégorie de la liste produit (chips à sélection unique, barre
  // horizontale au-dessus de la liste). Valeurs possibles :
  //   ""              -> "Tous" (aucun filtre catégorie)
  //   _kSansCodeBarre -> produits sans code-barre
  //   "<id>"          -> id de la catégorie sélectionnée (Categorie.id)
  // Le filtre est appliqué aux DEUX affichages (carte et tableau).
  static const String _kSansCodeBarre = "__SANS_CODE_BARRE__";
  String _categorieFiltre = "";

  // ✅ Prédicat de filtre catégorie commun aux affichages carte et tableau.
  bool _matchCategorieFiltre(Produit p) {
    if (_categorieFiltre.isEmpty) return true; // Tous
    if (_categorieFiltre == _kSansCodeBarre) {
      return p.codeBarre == null || p.codeBarre!.trim().isEmpty;
    }
    return p.categorieId.toString() == _categorieFiltre;
  }

  // ✅ Sélection d'une chip catégorie : met à jour le filtre et rafraîchit les
  // deux listes (carte + tableau) pour rester cohérent quel que soit
  // l'affichage courant.
  void _selectionnerCategorieFiltre(String value) {
    setState(() {
      _categorieFiltre = value;
      appliquefiltrePrtable();
      appliquerFiltreCarte();
    });
  }

  // ✅ Suivi du dialog produit ouvert par scan, pour pouvoir le refermer si un
  // nouveau scan arrive pendant qu'il est affiché (opération rapide/pratique).
  bool _produitDialogOuvert = false;
  int _produitDialogToken = 0;
  // ✅ Validation ("Ajouter") du dialog produit actuellement ouvert, pour
  // pouvoir la déclencher depuis un nouveau scan (cf. _onBarcodeScanned).
  Future<void> Function()? _confirmerAjoutDialogOuvert;

  @override
  void initState() {
    super.initState();
    _stockManager = StockManager();
    _stockManager.addListener(_onStockChanged); // ✅ Ajoutez cette ligne
    _barcodeScanListener = BarcodeScanListener(onScan: _onBarcodeScanned)..start();
    _keyboardShortcutListener = KeyboardShortcutListener(_buildKeyboardShortcuts())..start();
    _LoadAllData();
  }

  // ✅ Raccourcis clavier reprenant les actions déjà exposées par les boutons de la caisse.
  List<KeyboardShortcut> _buildKeyboardShortcuts() {
    return [
      KeyboardShortcut(character: '+', onTrigger: _incrementQte),
      KeyboardShortcut(character: '-', onTrigger: _decrementQte),
      KeyboardShortcut(key: LogicalKeyboardKey.keyN, onTrigger: _newProduct),
      KeyboardShortcut(key: LogicalKeyboardKey.keyC, onTrigger: _newClient),
      KeyboardShortcut(key: LogicalKeyboardKey.keyE, onTrigger: () => _openQuickEntry()),
      KeyboardShortcut(
        key: LogicalKeyboardKey.keyP,
        control: true,
        ignoreWhenTextFieldFocused: false,
        onTrigger: _ouvrirDialoguePack,
      ),
      KeyboardShortcut(
        key: LogicalKeyboardKey.keyR,
        control: true,
        ignoreWhenTextFieldFocused: false,
        onTrigger: () => _remiseclavier(),
      ),
      KeyboardShortcut(key: LogicalKeyboardKey.delete, onTrigger: () => _supprimerproduit()),
      KeyboardShortcut(key: LogicalKeyboardKey.backspace, onTrigger: () => _supprimerproduit()),
      KeyboardShortcut(
        key: LogicalKeyboardKey.f10,
        ignoreWhenTextFieldFocused: false,
        onTrigger: _viderPanier,
      ),
      KeyboardShortcut(
        key: LogicalKeyboardKey.f4,
        ignoreWhenTextFieldFocused: false,
        onTrigger: () => _encaissierTicket(),
      ),
      KeyboardShortcut(
        key: LogicalKeyboardKey.f5,
        ignoreWhenTextFieldFocused: false,
        onTrigger: () => _encaissierBLSC(),
      ),
      KeyboardShortcut(
        key: LogicalKeyboardKey.f6,
        ignoreWhenTextFieldFocused: false,
        onTrigger: () => _enregistreTicket(),
      ),
      KeyboardShortcut(key: LogicalKeyboardKey.keyR, onTrigger: () => _showCashReceipt()),
      KeyboardShortcut(key: LogicalKeyboardKey.keyP, onTrigger: () => _showProductRevenue()),
      KeyboardShortcut(
        key: LogicalKeyboardKey.f9,
        ignoreWhenTextFieldFocused: false,
        onTrigger: () => _supprimerCaisse(),
      ),
    ];
  }

  // ✅ Scan lecteur code-barres/QR : recherche le produit et l'ajoute au panier,
  // ou propose de le créer s'il n'existe pas.
  // Ignoré si un dialog est ouvert au-dessus de l'écran (route plus "current"),
  // pour que le scan profite au dialog ouvert et non à l'écran caisse en arrière-plan
  // — sauf la fiche produit ouverte par un scan précédent : un nouveau scan la
  // valide puis enchaîne sur le produit suivant (voir plus bas).
  Future<void> _onBarcodeScanned(String rawCode) async {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent && !_produitDialogOuvert) return;
    final code = rawCode.trim();
    if (code.isEmpty) return;

    Produit? produit = produitsTest.firstWhereOrNull(
      (p) => p.codeBarre == code || p.code == code,
    );

    if (produit == null) {
      final produitCode = await ProduitServices.getProduitCodeByBarcode(code);
      if (produitCode != null) {
        produit = produitsTest.firstWhereOrNull((p) => p.code == produitCode);
      }
    }

    if (!mounted) return;

    if (produit != null) {
      // Un scan pendant que la fiche d'un précédent produit scanné est
      // encore ouverte valide celle-ci (comme un clic sur "Ajouter") avant
      // d'enchaîner directement sur la nouvelle — opération rapide/pratique.
      if (_produitDialogOuvert && _confirmerAjoutDialogOuvert != null) {
        await _confirmerAjoutDialogOuvert!();
      }
      await ouvrirDialogProduit(produit);
      return;
    }

    await ProduitIntrouvableDialog(
      context: context,
      codeBarre: code,
      // ✅ Même enchaînement que le raccourci "Nouveau produit" (N) : une
      // fois le produit créé (avec son code-barre déjà pré-rempli), on
      // ouvre directement l'Entrée rapide dessus — un produit scanné qui
      // n'existait pas n'a encore aucun stock.
      onCreerNouveau: () => _newProduct(initialCodeBarre: code),
    );
  }

  void checkIfMagasinSystem() {
    final magasinSelectionne = Param?.selectedMagasin;
    isMagasinSystem = magasinSelectionne == "Magasin System" ||
        magasinSelectionne == "Magasin Système" ||
        magasinSelectionne == "Magasin system" ||
        magasinSelectionne == "System" ||
        magasinSelectionne == "Système";

    // ✅ Ajoutez ce print pour vérifier

  }
// ✅ Fonction appelée après succès d'encaissement/enregistrement
  void _onOperationSuccess() {

    if (caisses.length > 1) {
      // ✅ Plusieurs caisses ouvertes → Supprimer la caisse actuelle

      // Libérer toutes les réservations de cette caisse
      _stockManager.libererToutesReservationsCaisse(caisseActive.nom);

      setState(() {
        caisses.removeAt(selectedCaisse);
        if (selectedCaisse >= caisses.length) {
          selectedCaisse = caisses.length - 1;
        }
        if (selectedCaisse < 0 && caisses.isNotEmpty) {
          selectedCaisse = 0;
        }
      });

    } else if (caisses.length == 1) {
      // ✅ Une seule caisse → Vider le panier et réinitialiser

      // Libérer toutes les réservations
      for (var produit in caisseActive.produits) {
        final quantiteReelle = produit.qte * (produit.piecesParEmballage ?? 1);
        _stockManager.liberer(produit.code, caisseActive.nom, quantiteReelle);
      }

      setState(() {
        caisseActive.produits.clear();
        caisseActive.total = 0;
        caisseActive.remise = 0;
        caisseActive.remisenom = null;
        caisseActive.recalculerTotaux();
        produitSelectionne = null;

        // Incrémenter le numéro de panier
        nombrepannier++;

        // Rafraîchir l'affichage
        refreshProduitsDisplay();
      });

   }
  }
  // ✅ Filtre du TABLEAU produit : recherche (champ dédié tableau) + filtre
  // catégorie commun. Alimente `produitsFiltrestable`.
  void appliquefiltrePrtable() {
    final searchText = _searchControllerPrTable.text.toLowerCase();

    produitsFiltrestable = produitsTest.where((p) {
      final searchOk = searchText.isEmpty ||
          p.nom.toLowerCase().contains(searchText) ||
          p.marque.toLowerCase().contains(searchText) ||
          (p.description?.toLowerCase().contains(searchText) ?? false) ||
          p.prixVente.toString().contains(searchText) ||
          p.codeBarre.toString().contains(searchText) ||
          p.code.toLowerCase().contains(searchText) ||
          (codeBarresSecondairesMap[p.code]?.any((c) => c.contains(searchText)) ?? false);
      return _matchCategorieFiltre(p) && searchOk;
    }).toList();
  }

  // ✅ Filtre de l'affichage CARTE : recherche (champ dédié carte, séparé de
  // celui du tableau) + filtre catégorie commun. Alimente `produitsFiltres`.
  void appliquerFiltreCarte() {
    final searchText = _searchController.text.toLowerCase();

    produitsFiltres = produitsTest.where((p) {
      final rechercheOk = searchText.isEmpty || p.nom.toLowerCase().contains(searchText);
      return _matchCategorieFiltre(p) && rechercheOk;
    }).toList();
  }

  Map<String, dynamic> getClientInfo(String clientName) {
    try {
      final client = clientsTest.firstWhere((c) => c.nom == clientName);
      return {
        "type": client.type,
        "dernierAchat": client.dernierAchat ?? "--/--/----",
      };
    } catch (e) {

      return {
        "type": "Standard",
        "dernierAchat": "--/--/----",
      };
    }
  }

  @override
  void dispose() {
    _stockManager.removeListener(_onStockChanged); // ✅ Ajoutez cette ligne
    _barcodeScanListener.stop();
    _keyboardShortcutListener.stop();
    _produitsScrollController.dispose();
    _searchControllerPrTable.dispose();
    _searchController.dispose();
    super.dispose();
  }
  void _onStockChanged() {
    if (mounted) {
      setState(() {
        // Mettre à jour les listes : une nouvelle instance de liste suffit à
        // déclencher didUpdateWidget → updateCaisseProduit() côté
        // TableauProduitCaisseAdvanced, qui rafraîchit les quantités affichées
        // SANS perdre le tri par en-tête actif (contrairement à un changement
        // de _tableauKey, qui recrée le DataGridSource et donc son tri).
        produitsFiltres = List.from(produitsFiltres);
        produitsFiltrestable = List.from(produitsFiltrestable);
      });
    }
  }
  void _confirmerAction({
    required String titre,
    required String message,
    required VoidCallback onConfirmer,
    DialogKind kind = DialogKind.confirmer,
  }) {
    ConfirmationDialog(
      titre: titre,
      context: context,
      message: message,
      onConfirmer: onConfirmer,
      kind: kind,
    );
  }

  Future<void> _openQuickEntry() async {
    final l10n = AppLocalizations.of(context)!;

    if (Param == null || Param?.selectedMagasin == null) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.attention,
        kind: DialogKind.attention,
        titre_concerne: l10n.settings,
        message: l10n.noStoreSelected,
      );
      return;
    }

    // ✅ Passer le callback onSuccess
    await EntreeNouveau(
      context,
      onSuccess: () async {
        // Recharger toutes les données
        await _reloadAllData();

        // Mettre à jour le StockManager
        final produitsMisAJour = await ProduitServices.getAllProduits();
        final quantitesMisAJour = (await MouvementsServices.totauxParProduit(magasinCode: Param?.magasinCode)).quantites;
        _stockManager.initialiserStockReel(produitsMisAJour, quantitesMisAJour);

        // Mettre à jour les listes et l'affichage
        if (mounted) {
          setState(() {
            produitsTest = produitsMisAJour;
            // ✅ Réappliquer les filtres (catégorie + recherche) pour conserver
            // la sélection courante après rechargement.
            appliquerFiltreCarte();
            appliquefiltrePrtable();
          });
          refreshProduitsDisplay();
        }

       },
    );
  }

  Future<void> _showCashReceipt() async {
    final l10n = AppLocalizations.of(context)!;
    await DialogPannierVendu(
      context: context,
      caisseName: caisseActive.caisse,
    );
  }

  Future<void> _showProductRevenue() async {
    await DialogRecetteProduit(
      context: context,
      caisseName: caisseActive.caisse,
    );
  }
// ✅ Calcule la quantité disponible d'un produit (stock réel - quantité dans le panier)
  // ✅ Version corrigée de getQuantiteDisponibleVirtuelle
  double getQuantiteDisponibleVirtuelle(Produit produit) {
    // ✅ Un produit "service" n'a pas de stock physique suivi : toujours disponible.
    if (produit.service) return double.infinity;

    // Quantité déjà dans le panier de CETTE caisse en pièces
    double quantiteDansPanier = 0;

    // Calculer la quantité totale dans le panier en tenant compte du colisage
    for (var panierProduit in caisseActive.produits) {
      if (panierProduit.code == produit.code) {
        final piecesParEmballage = panierProduit.piecesParEmballage ?? 1;
        quantiteDansPanier += panierProduit.qte * piecesParEmballage;
      }
    }

    // ✅ Stock disponible GLOBAL depuis StockManager (stock réel - réservations AUTRES caisses)
    final stockDisponibleGlobal = _stockManager.getStockDisponible(produit.code, caisseActive.nom);

    // ✅ Pour cette caisse, le stock disponible = stockDisponibleGlobal - quantiteDansPanier
    // Pas besoin d'ajouter reservationCaisse car getStockDisponible retourne déjà stock réel - réservations autres caisses
    final disponible = stockDisponibleGlobal - quantiteDansPanier;


    return disponible > 0 ? disponible : 0;
  }
// ✅ Met à jour l'affichage des produits
  void refreshProduitsDisplay() {
    setState(() {
      // Une nouvelle instance de liste suffit à rafraîchir l'affichage (cf.
      // _onStockChanged ci-dessus) : ne pas changer _tableauKey ici, sous
      // peine de recréer le DataGridSource du tableau et de perdre le tri
      // par en-tête actif à chaque ajout/retrait/changement de quantité.
      produitsFiltres = List.from(produitsFiltres);
      produitsFiltrestable = List.from(produitsFiltrestable);
    });
  }

  // ✅ Bouton violet à icône de loupe affiché à gauche du champ de recherche
  // produit (mode carte et mode tableau) : ouvre le dialog de
  // recherche/insertion produit (filtres + recherche + tableau ou cartes),
  // qui insère directement le produit choisi dans le panier — il ne filtre
  // plus le tableau/wrap produit de cet écran.
  Widget _boutonFiltreProduitCaisse(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Appstyle.violet, width: 1.4),
        ),
        child: IconButton(
          icon: Icon(Icons.search, color: Appstyle.violet),
          onPressed: () async {
            await RechercherProduitDialog(
              context: context,
              categories: categoriesTest,
              sousCategories: sousCategoriesTest,
              produits: produitsTest,
              seuilMinimum: seuilMinimum,
              codeBarresSecondairesMap: codeBarresSecondairesMap,
              onProduitSelected: (p) => ouvrirDialogProduit(p),
            );
          },
        ),
      ),
    );
  }

  // ✅ Longueur du bouton pivoté "Afficher/Masquer produit" : approxime la
  // hauteur de la zone grille produit (Card/Tableau, adjustedHeight*0.555 +
  // ses en-têtes) et celle de la zone panier (tableau + récap, + calculatrice
  // si affichée) pour que le bouton ne dépasse ni ne s'arrête trop court par
  // rapport aux deux, quelle que soit la taille d'écran.
  double _hauteurBoutonAfficherProduit(double adjustedHeight) {
    final double hauteurZoneGrille = adjustedHeight * 0.555 + 96;
    final double hauteurZonePanier =
        adjustedHeight * (AffichageCalc ? 0.505 : 0.555) + 40 + (AffichageCalc ? 260 : 0);
    return hauteurZoneGrille > hauteurZonePanier ? hauteurZoneGrille : hauteurZonePanier;
  }

  // ✅ Chip individuelle de la barre de filtre catégorie (sélection unique).
  // `value` correspond à la valeur stockée dans `_categorieFiltre`.
  Widget _categorieFiltreChip({required String label, required String value}) {
    final bool isActive = _categorieFiltre == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _selectionnerCategorieFiltre(value),
        child: AnimatedContainer(
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Appstyle.violet : Appstyle.grisC,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [BoxShadow(color: Appstyle.violet.withOpacity(0.4), blurRadius: 12)]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Barre horizontale (une seule ligne, défilement horizontal) des filtres
  // catégorie affichée sous le titre "Catégorie" :
  //   "Tous" -> "Sans code-barre" -> une chip par catégorie existante.
  // Sélection unique, appliquée aux deux affichages (carte et tableau).
  Widget _barreCategoriesFiltre(AppLocalizations l10n) {
    final categoriesActives = categoriesTest.where((c) => c.etat).toList();
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _categorieFiltreChip(label: l10n.all, value: ""),
            const SizedBox(width: 8),
            _categorieFiltreChip(label: l10n.sansCodeBarre, value: _kSansCodeBarre),
            for (final cat in categoriesActives) ...[
              const SizedBox(width: 8),
              _categorieFiltreChip(label: cat.nom, value: cat.id.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _supprimerCaisse() async {
    final l10n = AppLocalizations.of(context)!;

    if (caisses.length == 1) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.caisse,
        message: l10n.cannotDeleteLastCaisse,
      );
      return;
    }

    await ConfirmationDialog(
      context: context,
      kind: DialogKind.danger,
      titre: l10n.modification,
      message: l10n.deleteCaisseMessage(caisses[selectedCaisse].nom),
      onConfirmer: () {
        // ✅ Libérer toutes les réservations de cette caisse
        _stockManager.libererToutesReservationsCaisse(caisses[selectedCaisse].nom);

        setState(() {
          caisses.removeAt(selectedCaisse);
          if (selectedCaisse >= caisses.length) {
            selectedCaisse = caisses.length - 1;
          }
        });
      },
    );
  }

  Future<void> _encaissierTicket() async {
    final l10n = AppLocalizations.of(context)!;
    if (caisseActive.produits.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.cart,
        message: l10n.emptyCartError,
      );
      return;
    }
    final clientInfo = getClientInfo(caisseActive.client);
    EncaissementTicketDialog(
      caisse: caisseActive,
      pannier: nombrepannier,
      context: context,
      clientInfo: clientInfo,
      client: clientselectione,
      selectedMagasinCode: Param?.magasinCode??"",
      onSuccess: _onOperationSuccess,
    );
  }

  Future<void> _encaissierBLSC() async {
    final l10n = AppLocalizations.of(context)!;
    if (caisseActive.produits.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.cart,
        message: l10n.emptyCartError,
      );
      return;
    }
    final clientInfo = getClientInfo(caisseActive.client);
    EncaissementBLSCDialog(
        client: clientselectione,
        caisse: caisseActive,
        context: context,
        clientInfo: clientInfo,
        selectedMagasinCode: Param?.magasinCode??"",
      onSuccess: _onOperationSuccess,
    );
  }

  Future<void> _enregistreTicket() async {
    final l10n = AppLocalizations.of(context)!;
    if (caisseActive.produits.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.cart,
        message: l10n.emptyCartError,
      );
      return;
    }
    final clientInfo = getClientInfo(caisseActive.client);
    EnregistrerTicketDialog(
        clientInfo: clientInfo,
        pannier: nombrepannier,
        context: context,
        caisse: caisseActive,
        client: clientselectione,
        selectedMagasinCode: Param?.magasinCode??"",
        onSuccess: _onOperationSuccess,
    );
  }

  void _newClient() async {
    await ClientNouveau(context);
    await Future.delayed(const Duration(milliseconds: 100));
    await _reloadAllData();
  }

  // ✅ Depuis la caisse (uniquement) : après la création d'un produit,
  // enchaîne directement sur l'Entrée rapide avec ce produit présélectionné
  // — pratique car un produit tout juste créé n'a encore aucun stock.
  void _newProduct({String? initialCodeBarre}) async {
    await ProduitNouveau(
      context,
      initialCodeBarre: initialCodeBarre,
      onCreated: (produit) async {
        await _reloadAllData();
        await EntreeNouveau(
          context,
          initialProduitCode: produit.code,
          onSuccess: () async {
            await _reloadAllData();
            final produitsMisAJour = await ProduitServices.getAllProduits();
            final quantitesMisAJour = (await MouvementsServices.totauxParProduit(magasinCode: Param?.magasinCode)).quantites;
            _stockManager.initialiserStockReel(produitsMisAJour, quantitesMisAJour);
            if (mounted) {
              setState(() {
                produitsTest = produitsMisAJour;
                // ✅ Réappliquer les filtres (catégorie + recherche).
                appliquerFiltreCarte();
                appliquefiltrePrtable();
              });
              refreshProduitsDisplay();
            }
          },
        );
      },
    );
    await Future.delayed(const Duration(milliseconds: 100));
    await _reloadAllData();
  }

  // ✅ Nouvelle fonction ajouterProduitAuPanier - SANS déstockage
  // ✅ Nouvelle fonction ajouterProduitAuPanier - Avec support des packs
  // ✅ Remise "Par Produit" assignée au produit (produit_remise.dart), applicable
  // uniquement si elle est active et que la date du jour est dans sa période.
  Remise? _remiseProduitApplicable(Produit p) {
    if (p.remiseId == null) return null;
    return remisesTest.firstWhereOrNull(
      (r) => r.id == p.remiseId && r.type == "Par Produit" && r.etat && remiseEstDansPeriode(r.debut, r.fin),
    );
  }

  double _prixApresRemiseProduit(double prixVente, Remise remise) {
    final prixReduit = remise.tauxType.toLowerCase() == "pourcentage"
        ? prixVente * (1 - remise.taux / 100)
        : prixVente - remise.taux;
    return prixReduit < 0 ? 0 : prixReduit;
  }

  Future<void> ajouterProduitAuPanier(
      Produit p, {
        double quantite = 1,
        String? colisType,
        double? prixUnitaire,
        String? packNom,   // ✅ Nouveau paramètre
        // Pièces par boîte/carton, transmis par la fiche produit. Avant, on
        // le déduisait en cherchant "Boîte"/"Carton" dans le libellé traduit
        // du colis ("Par boîte (6 pièce(s))", "Per Box"…) : ça ne
        // correspondait jamais, la ligne valait 1 pièce au lieu de 6 (Qte Pce,
        // contrôle et réservation de stock, sortie de stock à l'encaissement).
        int? piecesParEmballage,
      }) async {

    final double quantiteReelle = quantite * (piecesParEmballage ?? 1);

    // ✅ Vérifier le stock disponible pour CETTE caisse
    final stockDisponible = getQuantiteDisponibleVirtuelle(p);

    if (quantiteReelle > stockDisponible) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.product,
        message: l10n.stockInsuffisantDetail(stockDisponible.toInt().toString(), quantiteReelle.toInt().toString()),
      );
      return;
    }

    setState(() {
      final exist = caisseActive.produits.firstWhere(
            (x) => x.code == p.code && (colisType != null ? x.colis == colisType : x.colis.isEmpty),
        orElse: () => ProduitPanier(
          nom: "", prix: 0, qte: 0, code: '', prixachat: 0, colis: '',
          piecesParEmballage: null, packNom: null,
        ),
      );

      double prixAAjouter = prixUnitaire ?? p.prixVente;
      String colisAAjouter = colisType ?? '';

      // ✅ Remise par produit : appliquée seulement quand le prix n'est pas
      // déjà surchargé manuellement (pack, saisie de prix libre).
      final remiseProduit = prixUnitaire == null ? _remiseProduitApplicable(p) : null;
      final double? prixOriginalAAjouter = remiseProduit != null ? prixAAjouter : null;
      if (remiseProduit != null) {
        prixAAjouter = _prixApresRemiseProduit(prixAAjouter, remiseProduit);
      }

      if (exist.nom.isNotEmpty) {
        // ✅ Libérer l'ancienne réservation
        final ancienneQteReelle = exist.qte * (exist.piecesParEmballage ?? 1);
        _stockManager.liberer(p.code, caisseActive.nom, ancienneQteReelle);

        // ✅ Ajouter la nouvelle quantité
        exist.qte += quantite;
        if (colisType != null) exist.colis = colisType;
        if (piecesParEmballage != null) exist.piecesParEmballage = piecesParEmballage;

        // ✅ Mettre à jour l'info du pack (garder la première occurrence)
        if (packNom != null && exist.packNom == null) {
          exist.packNom = packNom;
        }

        // ✅ Faire la nouvelle réservation
        final nouvelleQteReelle = exist.qte * (exist.piecesParEmballage ?? 1);
        _stockManager.reserver(p.code, caisseActive.nom, nouvelleQteReelle);
      } else {
        // ✅ Nouveau produit, réserver directement
        final reserved = _stockManager.reserver(p.code, caisseActive.nom, quantiteReelle);
        if (!reserved) return;

        caisseActive.produits.add(
          ProduitPanier(
            nom: p.nom,
            prix: prixAAjouter,
            qte: quantite,
            code: p.code,
            prixachat: p.prixAchat,
            colis: colisAAjouter,
            nombreActif: p.nombreActif,
            piecesParEmballage: piecesParEmballage,
            packNom: packNom,    // ✅ Ajouter l'info du pack
            uniteMesure: p.uniteMesure,
            prixOriginal: prixOriginalAAjouter,
            remiseNom: remiseProduit?.nom,
          ),
        );
      }

      caisseActive.recalculerTotaux();
      caisseActive.produits = List.from(caisseActive.produits);
      refreshProduitsDisplay();
      updateRemiseCondition();
    });
  }
  // ✅ Fonction utilitaire
  double getQuantiteDejaDansPanier(String produitCode) {
    double quantite = 0;
    for (var p in caisseActive.produits) {
      if (p.code == produitCode) {
        quantite += p.qte * (p.piecesParEmballage ?? 1);
      }
    }
    return quantite;
  }

  // ✅ Cas 4: _supprimerproduit corrigé
  Future<void> _supprimerproduit() async {
    final l10n = AppLocalizations.of(context)!;
    if (produitSelectionne == null) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.product,
        message: l10n.noProduct,
      );
      return;
    }

    // ✅ Libérer la réservation
    final quantiteReelle = produitSelectionne!.qte * (produitSelectionne!.piecesParEmballage ?? 1);
    _stockManager.liberer(produitSelectionne!.code, caisseActive.nom, quantiteReelle);

    setState(() {
      caisseActive.produits.remove(produitSelectionne);
      produitSelectionne = null;
      caisseActive.recalculerTotaux();

      if (caisseActive.produits.isEmpty) {
        caisseActive.total = 0;
        caisseActive.remise = 0;
        caisseActive.remisenom = null;
      }

      caisseActive.produits = List.from(caisseActive.produits);
      refreshProduitsDisplay();

      updateRemiseCondition();
    });
  }
  Future<void> _remiseclavier() async {
    await showDialog(
      context: context,
      barrierColor: Appstyle.gris.withOpacity(0.25),
      builder: (_) => InsertionRemiseDialog(
        multiselection: false,
        remises: remisesTest.where((r) => r.type == "Par Montant" && r.etat).toList(),
        filtre: (r) => r.type == "Par Montant" && r.etat,
        onRemiseSelected: (remise) async {
          final sousTotal = caisseActive.produits.fold<double>(
              0, (sum, p) => sum + (p.prix * p.qte)
          );

          double montantCondition = remise.montant ?? 0;

          // ✅ Stocker la remise (pas de message)
          setState(() {
            caisseActive.remiseInfo = RemiseInfo(
              nom: remise.nom,
              taux: remise.taux,
              tauxType: remise.tauxType.toLowerCase(),
              montantCondition: montantCondition,
              debut: remise.debut,
              fin: remise.fin,
            );
            caisseActive.recalculerTotaux();
          });
        },
      ),
    );
  }




  // ✅ Cas 5: _viderPanier corrigé
  void _viderPanier() {
    final l10n = AppLocalizations.of(context)!;
    if (caisseActive.produits.isEmpty) return;

    _confirmerAction(
      titre: l10n.clearCartTitle,
      message: l10n.clearCartMessage,
      kind: DialogKind.danger,
      onConfirmer: () {
        // ✅ Libérer toutes les réservations
        for (var produit in caisseActive.produits) {
          final quantiteReelle = produit.qte * (produit.piecesParEmballage ?? 1);
          _stockManager.liberer(produit.code, caisseActive.nom, quantiteReelle);
        }

        setState(() {
          caisseActive.produits.clear();
          caisseActive.total = 0;
          caisseActive.remise = 0;
          caisseActive.recalculerTotaux();
          produitSelectionne = null;
          refreshProduitsDisplay();

          updateRemiseCondition();
        });
      },
    );
  }




  Future<void> ouvrirDialogProduit(Produit p) async {
    // ✅ Session de caisse obligatoire : impossible de commencer à composer
    // un panier (sélection de produit) tant que la caisse active n'a pas
    // été ouverte — plutôt que de laisser composer le panier et bloquer
    // seulement à l'encaissement final.
    if (sessionOuverteActuelle == null) {
      final caisseActuelle = CaisseTest.where((c) => c.nomCaisse == CaisseAct).firstOrNull;
      if (caisseActuelle != null) {
        await CaisseFermeeDialog(
          context: context,
          caisses: CaisseTest,
          caisseInitiale: caisseActuelle,
          onSessionOuverte: () async => await _refreshSessionOuverte(),
        );
      }
      return;
    }

    String? defaultColisType = Param?.selectedColis;

    final quantiteDisponibleVirtuelle = getQuantiteDisponibleVirtuelle(p);

    final int monToken = ++_produitDialogToken;
    _produitDialogOuvert = true;

    await afficherProduitSelectionneDialog(
      context: context,
      nom: p.nom,
      prix: p.prixVente,
      photoName: p.photo,
      sousCategorieId: p.sousCategorieId,
      emballage1: p.emballage1,
      emballageP1: p.emballageP1,
      emballage2: p.emballage2,
      emballageP2: p.emballageP2,
      uniteMesure: p.uniteMesure,
      defaultColisType: defaultColisType,
      quantiteDisponible: quantiteDisponibleVirtuelle,
      onControllerReady: (confirmerAjout) {
        _confirmerAjoutDialogOuvert = confirmerAjout;
      },
      onAjouter: (qte, {colisType, prixUnitaire, piecesParEmballage}) async {
        if (prixUnitaire != null) {
          await ajouterProduitAuPanier(
            p,
            quantite: qte,
            colisType: colisType,
            prixUnitaire: prixUnitaire,
            piecesParEmballage: (piecesParEmballage ?? 1) > 1 ? piecesParEmballage : null,
          );
        } else {
          await ajouterProduitAuPanier(p, quantite: qte);
        }
      },
    );

    // Ne réinitialiser que si aucun autre scan n'a ouvert un nouveau dialog
    // entre-temps (évite qu'une fermeture tardive n'efface l'état du suivant).
    if (_produitDialogToken == monToken) {
      _produitDialogOuvert = false;
      _confirmerAjoutDialogOuvert = null;
    }
  }

  Produit? _findProductByName(String name) {
    for (var produit in produitsTest) {
      if (produit.nom == name) {
        return produit;
      }
    }
    return null;
  }

  void _incrementQte() async {
    if (produitSelectionne == null) return;
    if (produitSelectionne!.isFromPack) return;

    final produitOriginal = _findProductByName(produitSelectionne!.nom);
    if (produitOriginal == null) return;

    final double nouvelleQte = produitSelectionne!.qte + 1;
    // ✅ Convertir int? en double
    final double quantiteSupplementReelle = (produitSelectionne!.piecesParEmballage ?? 1).toDouble();

    final disponibleVirtuel = getQuantiteDisponibleVirtuelle(produitOriginal);

    if (quantiteSupplementReelle > disponibleVirtuel) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.product,
        message: l10n.stockInsuffisantRestant(disponibleVirtuel.toInt().toString()),
      );
      return;
    }

    // ✅ Mettre à jour la réservation - Convertir int? en double
    final double ancienneQteReelle = produitSelectionne!.qte * (produitSelectionne!.piecesParEmballage ?? 1).toDouble();
    final double nouvelleQteReelle = nouvelleQte * (produitSelectionne!.piecesParEmballage ?? 1).toDouble();

    _stockManager.liberer(produitSelectionne!.code, caisseActive.nom, ancienneQteReelle);
    _stockManager.reserver(produitSelectionne!.code, caisseActive.nom, nouvelleQteReelle);

    setState(() {
      produitSelectionne!.qte = nouvelleQte;
      caisseActive.recalculerTotaux();
      refreshProduitsDisplay();
      updateRemiseCondition();
    });
  }

  void _decrementQte() {
    if (produitSelectionne == null) return;
    if (produitSelectionne!.isFromPack) return;

    // ✅ Mettre à jour la réservation - Convertir int? en double
    final double ancienneQteReelle = produitSelectionne!.qte * (produitSelectionne!.piecesParEmballage ?? 1).toDouble();
    final double nouvelleQte = produitSelectionne!.qte - 1;
    final double nouvelleQteReelle = nouvelleQte * (produitSelectionne!.piecesParEmballage ?? 1).toDouble();

    _stockManager.liberer(produitSelectionne!.code, caisseActive.nom, ancienneQteReelle);
    if (nouvelleQte > 0) {
      _stockManager.reserver(produitSelectionne!.code, caisseActive.nom, nouvelleQteReelle);
    }

    setState(() {
      if (produitSelectionne!.qte > 1) {
        produitSelectionne!.qte--;
        caisseActive.recalculerTotaux();
        refreshProduitsDisplay();
        updateRemiseCondition();
      }
    });
  }

  Future<void> _reloadAllData() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    final userCode = auth.userCode;
    final db = await DbCreator.openDb();
    final service = await CaisseParamServices(db);
    final pmdService = ProduitMagasinDetailServices(db);

    final souscate = await SousCategoriesServices.getAllSousCategorie();
    final categories = await CategorieServices.getAllCategorie();
    final produits = await ProduitServices.getAllProduits();
    final clients = await ClientServices.getAllClients();
    final remisess = await RemiseServices.getAllRemise();
    final caiss = await GCServices.getAllCaisses();
    final caissParm = await service.getCaisseParamByUserCode(userCode!);
    final paiementParm = await PaiementParamServices.getPaiementParam();
    final param = await ParamServices.getParam();
    final codeDetails = await ProduitServices.getAllCodeDetails();

    produitMagasinDetails = await ProduitMagasinDetailServices.getAllDetails();

    if (mounted) {
      setState(() {
        sousCategoriesTest = souscate;
        categoriesTest = categories;
        produitsTest = produits;
        remisesTest = remisess;
        clientsTest = clients.where((c) => c.etat).toList();
        CaisseTest = caiss;
        Param = caissParm;
        paiementParam = paiementParm;
        activeBonus = param.activeBonus;
        bonusTaux = param.bonusTaux;

        _buildCodeBarresSecondairesMap(codeDetails);

        // ✅ Réappliquer les filtres (catégorie + recherche) après rechargement.
        appliquerFiltreCarte();
        appliquefiltrePrtable();

        if (produitsSelectionnes != null) {
          final exists = produitsTest.any((p) => p.id == produitsSelectionnes!.id);
          if (!exists) {
            produitsSelectionnes = produitsTest.isNotEmpty ? produitsTest.first : null;
          }
        }

        if (clientselectione.id != 0 && clientsTest.isNotEmpty) {
          final exists = clientsTest.any((c) => c.id == clientselectione.id);
          if (exists) {
            clientselectione = clientsTest.firstWhere((c) => c.id == clientselectione.id);
          } else {
            clientselectione = clientsTest.first;
          }
          caisseActive.client = clientselectione.nom;
        }

        CaisseList = CaisseTest.map((caisse) => caisse.nomCaisse).toList();
        // ✅ Même verrouillage qu'à l'initialisation (cf. _LoadAllData) : un
        // rechargement ne doit pas faire revenir un utilisateur non-Admin
        // sur la première caisse de la liste.
        final String? caisseAttachee = auth.role != "Admin" && auth.userCaisseCode != null
            ? CaisseTest.where((c) => c.code == auth.userCaisseCode).firstOrNull?.nomCaisse
            : null;
        CaisseAct = caisseAttachee ?? (CaisseList.isNotEmpty ? CaisseList.first : "");
      });

      checkIfMagasinSystem();
      _refreshSessionOuverte();

    }
  }

  void _handleNumericInput(String value) async {
    if (produitSelectionne == null) return;
    if (produitSelectionne!.isFromPack) return;

    setState(() {
      if (value == "C") {
        if (bufferQuantite.isNotEmpty) {
          bufferQuantite = bufferQuantite.substring(0, bufferQuantite.length - 1);
        }
      } else if (value == "CL") {
        bufferQuantite = "";
      } else {
        bufferQuantite += value;
      }

      if (bufferQuantite.isNotEmpty) {
        final qte = double.tryParse(bufferQuantite);
        if (qte != null && qte > 0) {
          final produitOriginal = _findProductByName(produitSelectionne!.nom);
          if (produitOriginal != null) {
            final stockVirtuel = getQuantiteDisponibleVirtuelle(produitOriginal);
            final quantiteSupplement = qte - produitSelectionne!.qte;
            final quantiteSupplementReelle = quantiteSupplement * (produitSelectionne!.piecesParEmballage ?? 1);

            if (quantiteSupplement > 0 && quantiteSupplementReelle > stockVirtuel) {
              final l10n = AppLocalizations.of(context)!;
              InformationDialog(
                context: context,
                titre_type_message: l10n.error,
                kind: DialogKind.refuser,
                titre_concerne: l10n.product,
                message: l10n.stockInsuffisantSupplement(
                    stockVirtuel.toInt().toString(),
                    quantiteSupplementReelle.toInt().toString()),
              );
              bufferQuantite = produitSelectionne!.qte.toString();
              return;
            }

            // ✅ Mettre à jour la réservation
            final ancienneQteReelle = produitSelectionne!.qte * (produitSelectionne!.piecesParEmballage ?? 1);
            final nouvelleQteReelle = qte * (produitSelectionne!.piecesParEmballage ?? 1);

            _stockManager.liberer(produitSelectionne!.code, caisseActive.nom, ancienneQteReelle);
            _stockManager.reserver(produitSelectionne!.code, caisseActive.nom, nouvelleQteReelle);
          }

          produitSelectionne!.qte = qte;
          caisseActive.recalculerTotaux();
          refreshProduitsDisplay();
        }
      }
    });
  }


  Future<void> onValider({required CaisseParam Param}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      this.Param = Param;
      checkIfMagasinSystem();
      if (Param.caisseParDefaut && Param.selectedCaisse != null) {
        CaisseAct = Param.selectedCaisse!;
      }
    });
    _refreshSessionOuverte();

    await InformationDialog(
      context: context,
      titre_type_message: l10n.success,
      titre_concerne: l10n.settings,
      message: l10n.settingsSavedSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final clientInfo = getClientInfo(caisseActive.client);

    // ✅ La liste carte (produitsFiltres) et la liste tableau
    // (produitsFiltrestable) sont maintenues par appliquerFiltreCarte() /
    // appliquefiltrePrtable() : filtre catégorie commun + recherche propre à
    // chaque affichage. On ne recalcule donc plus rien ici.

    if (isLoading) {
      return Scaffold(
        backgroundColor: Appstyle.violetC,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight  = constraints.maxHeight  ;
          final screenWidth   = constraints.maxWidth   ;
          const minHeight     = Constant.minHeight;
          const minWidth      = Constant.minWidth ;

          final adjustedWidth = screenWidth < minWidth ? minWidth : screenWidth;
          final adjustedHeight = screenHeight < minHeight ? minHeight : screenHeight;

          final paddingV = adjustedHeight * 0.02;
          final paddingH = adjustedWidth * 0.02;

          // ✅ Hauteur de la zone panier (identique que le panier soit vide ou
          // rempli) : le message "panier vide" et le tableau du panier occupent
          // la même hauteur, pour que le panier ne rétrécisse pas dès l'ajout
          // d'un produit.
          final double panierZoneHeight = AffichageCalc ? adjustedHeight * 0.505 : adjustedHeight * 0.555;
          // Réserve ~fixe (en pixels) pour le bas du tableau panier (séparateur
          // + ligne du total). Contrairement à une compensation proportionnelle,
          // elle reste cohérente quelle que soit la hauteur de l'écran.
          const double panierRecapAllowance = 96;
          final double panierTableSize =
              (panierZoneHeight - panierRecapAllowance).clamp(120.0, double.infinity);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: minWidth, minHeight: minHeight),
              child: SizedBox(
                width: adjustedWidth,
                height: adjustedHeight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  HeaderModule(
                                    gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          "assets/icons/sidebar/caisse_icon.png",
                                          width: 40,
                                          color: Appstyle.violet,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.caisse,
                                          style: Appstyle.textXLB.copyWith(
                                            color: Appstyle.violet,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            const ConnectionStatusBar(),
                                            const SizedBox(width: 20),
                                            TimeDateWidget(
                                             iconHeure: "assets/icons/hour_icon.png",
                                              iconDate: "assets/icons/agenda_icon.png",
                                            ),
                                            const SizedBox(width: 20),
                                            AccountWidget(
                                              name: userName,
                                              imageUrl: "assets/images/support.png",
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: paddingV / 2),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      for (int i = 0; i < caisses.length; i++)
                                        HoverScale(
                                          onTap: () => setState(() => selectedCaisse = i),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: selectedCaisse == i ? Appstyle.indigo : Colors.grey[300],
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: selectedCaisse == i
                                                  ? [BoxShadow(color: Appstyle.indigo.withOpacity(0.4), blurRadius: 12)]
                                                  : [],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  caisses[i].nom,
                                                  style: TextStyle(color: selectedCaisse == i ? Colors.white : Colors.black),
                                                ),
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                  onTap: _supprimerCaisse,
                                                  child: Icon(Icons.close, size: 18, color: selectedCaisse == i ? Colors.white : Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      HoverScale(
                                        onTap: () async {
                                          if (caisses.length >= 10) {
                                            await InformationDialog(
                                              context: context,
                                              titre_type_message: l10n.attention,
                                              kind: DialogKind.attention,
                                              titre_concerne: l10n.caisse,
                                              message: l10n.maxCaissesReached,
                                            );
                                            return;
                                          }
                                          setState(() {
                                            final nextIndex = caisses.length;
                                            final caisseName = "${l10n.caisse} ${nextIndex + 1}";
                                            caisses.add(CaisseState(nom: caisseName, caisse: CaisseAct, modePaiement: _defaultModePaiement()));
                                            selectedCaisse = caisses.length - 1;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Appstyle.violet,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [BoxShadow(color: Appstyle.violet.withOpacity(0.4), blurRadius: 12)],
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: paddingV / 4),
                                  Container(
                                    padding: const EdgeInsets.all(0),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 84,
                                              child: Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: sectionDecoration(Appstyle.Tblanc),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        ChampAvecLabel(
                                                          label: l10n.client,
                                                          distance: 80,
                                                          buttonAjout: true,
                                                          onAjoutPressed: () async {
                                                            await showDialog(
                                                              context: context,
                                                              barrierColor: Appstyle.gris.withOpacity(0.25),
                                                              builder: (_) => InsertionClientDialog(
                                                                clients: clientsTest,
                                                                onClientSelected: (client) {
                                                                  setState(() {
                                                                    caisseActive.client = client.nom;
                                                                    clientselectione = client;
                                                                  });
                                                                },
                                                              ),
                                                            );
                                                          },
                                                          width: adjustedWidth / 5,
                                                          child: TextListe(
                                                            clearable: false,
                                                            value: caisseActive.client,
                                                            items: clientsTest.map((c) => c.nom).toList(),
                                                            onChanged: (v) {
                                                              setState(() {
                                                                caisseActive.client = v!;
                                                                clientselectione = clientsTest.firstWhere((e) => e.nom == v);
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        SizedBox(width: paddingV / 2),
                                                        ChampAvecLabel(
                                                          label: l10n.payment,
                                                          distance: 80,
                                                          width: adjustedWidth / 5,
                                                          child: TextListe(
                                                            clearable: false,
                                                            value: translator.translateModePaiement(caisseActive.modePaiement),
                                                            items: paiementParam != null
                                                                ? PaiementParamServices.visibleDisplayList(
                                                                    paiementParam!,
                                                                    translator,
                                                                    toujoursInclure: caisseActive.modePaiement,
                                                                    inclurePoints: activeBonus,
                                                                  )
                                                                : translator.modePaiementDisplayList,
                                                            onChanged: (v) {
                                                              setState(() {
                                                                caisseActive.modePaiement = translator.modePaiementToFrench(v!);
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: paddingV / 2),
                                                    if (produitsSelectionnes != null)
                                                      AfficheurProduit(
                                                        detail_but_icon: true,
                                                        afficheurBorder: true,
                                                        afficherprixachat: false,
                                                        afficherStatsAvancees: false,
                                                        produit: produitsSelectionnes!,
                                                        onDetails: () => ProduitDetail(context, produitsSelectionnes!),
                                                      )
                                                    else
                                                      Container(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: paddingH / 3),
                                            Expanded(
                                              flex: 79,
                                              child: Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: sectionDecoration(Appstyle.Tblanc),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    AfficheurCaisse(
                                                      total: caisseActive.total.toString(),
                                                      remise: _remiseAfficheurText(),
                                                      remiseColor: _remiseAfficheurColor(),
                                                      couleur: Appstyle.blueF,
                                                      npannier: nombrepannier.toString(),
                                                      nproduit: caisseActive.nombreProduits.toString(),
                                                    ),
                                                    SizedBox(height: 10),
                                                    // Dans le build de CaisseScreen, remplacez la partie de sélection de remise :

                                                    ChampAvecLabel(
                                                      label: l10n.remise,
                                                      distance: 200,
                                                      buttonAjout: true,
                                                      onAjoutPressed: () async {
                                                        await showDialog(
                                                          context: context,
                                                          barrierColor: Appstyle.gris.withOpacity(0.25),
                                                          builder: (_) => InsertionRemiseDialog(
                                                            multiselection: false,
                                                            remises: remisesTest.where((r) => r.type == "Par Montant" && r.etat).toList(),
                                                            filtre: (r) => r.type == "Par Montant" && r.etat,
                                                            onRemiseSelected: (remise) async {
                                                              final sousTotal = caisseActive.produits.fold<double>(
                                                                  0, (sum, p) => sum + (p.prix * p.qte)
                                                              );

                                                              // ✅ Vérifier si la condition de la remise est remplie
                                                              double montantCondition = remise.montant ?? 0;

                                                              if (montantCondition > 0 && sousTotal < montantCondition) {
                                                                // Condition non remplie - la remise sera stockée mais non active
                                                                final l10n = AppLocalizations.of(context)!;
                                                                await InformationDialog(
                                                                  context: context,
                                                                  titre_type_message: l10n.information,
                                                                  titre_concerne: l10n.discount,
                                                                  message: l10n.remiseConditionMessage(remise.nom, NumberFormatUtil.formatMontant(montantCondition, decimales: 2)),
                                                                );
                                                              }

                                                              // ✅ Stocker les informations de la remise
                                                              setState(() {
                                                                caisseActive.remiseInfo = RemiseInfo(
                                                                  nom: remise.nom,
                                                                  taux: remise.taux,
                                                                  tauxType: remise.tauxType.toLowerCase(),
                                                                  montantCondition: remise.montant ?? 0,
                                                                  debut: remise.debut,
                                                                  fin: remise.fin,
                                                                );
                                                                caisseActive.recalculerTotaux();
                                                              });
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      width: adjustedWidth / 2,
                                                      child: TextListe(
                                                        width: 600,
                                                        clearable: true,
                                                        value: (() {
                                                          if (caisseActive.remiseInfo == null) return null;
                                                          // ✅ Afficher toujours le nom de la remise, sans "(en attente)"
                                                          return translator.translateTypeRemise(caisseActive.remiseInfo!.nom);
                                                        })(),
                                                        items: remisesTest
                                                            .where((r) => r.type == "Par Montant" && r.etat)
                                                            .map((r) => translator.translateTypeRemise(r.nom))
                                                            .toList(),
                                                        onChanged: (v) async {
                                                          if (v == null) {
                                                            setState(() {
                                                              caisseActive.remiseInfo = null;
                                                              caisseActive.remiseActive = false;
                                                              caisseActive.recalculerTotaux();
                                                            });
                                                            return;
                                                          }

                                                          final frenchValue = translator.typeRemiseToFrench(v);
                                                          final selectedRemise = remisesTest.firstWhere(
                                                                (r) => r.nom == frenchValue && r.type == "Par Montant" && r.etat,
                                                            orElse: () => Remise(
                                                              nom: frenchValue,
                                                              taux: 0,
                                                              type: "Par Montant",
                                                              etat: true,
                                                              code: '',
                                                              tauxType: '',
                                                              debut: DateTime.now(),
                                                              id: 0,
                                                              fin: DateTime.now(),
                                                              creeParCode: '',
                                                              creeLe: DateTime.now(),
                                                            ),
                                                          );

                                                          final sousTotal = caisseActive.produits.fold<double>(
                                                              0, (sum, p) => sum + (p.prix * p.qte)
                                                          );

                                                          double montantCondition = selectedRemise.montant ?? 0;

                                                          // ✅ Optionnel : Afficher un message d'information seulement si vous voulez
                                                          if (montantCondition > 0 && sousTotal < montantCondition) {
                                                            final l10n = AppLocalizations.of(context)!;
                                                            await InformationDialog(
                                                              context: context,
                                                              titre_type_message: l10n.information,
                                                              titre_concerne: l10n.discount,
                                                              message: l10n.remiseConditionMessage(selectedRemise.nom, NumberFormatUtil.formatMontant(montantCondition, decimales: 2)),
                                                            );
                                                          }

                                                          setState(() {
                                                            caisseActive.remiseInfo = RemiseInfo(
                                                              nom: selectedRemise.nom,
                                                              taux: selectedRemise.taux,
                                                              tauxType: selectedRemise.tauxType.toLowerCase(),
                                                              montantCondition: montantCondition,
                                                              debut: selectedRemise.debut,
                                                              fin: selectedRemise.fin,
                                                            );
                                                            caisseActive.recalculerTotaux();
                                                          });
                                                        },
                                                      ),
                                                    ),

                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: paddingV / 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                MainIconButton(
                                                  color: Appstyle.violet,
                                                  imagePath: "assets/icons/sidebar/parametre_icon.png",
                                                  onPressed: () async {
                                                    if (Param == null) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.attention,
                                                        kind: DialogKind.attention,
                                                        titre_concerne: l10n.settings,
                                                        message: l10n.loadingParams,
                                                      );
                                                      return;
                                                    }
                                                    ParametreCaisseDialog(
                                                      context: context,
                                                      Param: Param!,
                                                      onValider: onValider,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                Tooltip(
                                                  message: sessionOuverteActuelle != null
                                                      ? l10n.cloturerCaisse
                                                      : l10n.ouvrirCaisse,
                                                  child: MainIconButton(
                                                    color: sessionOuverteActuelle != null
                                                        ? Colors.red
                                                        : Colors.green,
                                                    imagePath: "assets/icons/sidebar/caisse_icon.png",
                                                    onPressed: () async {
                                                      final caisseGestion = CaisseTest
                                                          .where((c) => c.nomCaisse == CaisseAct)
                                                          .firstOrNull;
                                                      if (caisseGestion == null) return;

                                                      if (sessionOuverteActuelle != null) {
                                                        await ClotureCaisseSessionDialog(
                                                          context: context,
                                                          session: sessionOuverteActuelle!,
                                                          onSuccess: _refreshSessionOuverte,
                                                        );
                                                      } else {
                                                        await OuvertureCaisseDialog(
                                                          context: context,
                                                          caisse: caisseGestion,
                                                          onSuccess: _refreshSessionOuverte,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                                if (sessionOuverteActuelle != null) ...[
                                                  const SizedBox(height: 8),
                                                  Tooltip(
                                                    message: l10n.mouvementManuel,
                                                    child: MainIconButton(
                                                      color: Appstyle.indigo,
                                                      imagePath: "assets/icons/sidebar/entree_icon.png",
                                                      onPressed: () async {
                                                        await MouvementManuelDialog(
                                                          context: context,
                                                          session: sessionOuverteActuelle!,
                                                          onSuccess: _refreshSessionOuverte,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 30, right: 5),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 300),
                                                    width: 50,
                                                    child: Center(
                                                      child: RotatedBox(
                                                        quarterTurns: -1,
                                                        child: MainButton(
                                                          noIcon: true,
                                                          // ✅ Longueur du bouton (verticale une fois pivoté) alignée sur
                                                          // la hauteur de la zone grille produit / tableau panier +
                                                          // calculatrice, au lieu d'une valeur fixe qui ne s'adaptait ni
                                                          // à la taille d'écran ni à l'affichage de la calculatrice.
                                                          width: _hauteurBoutonAfficherProduit(adjustedHeight)*0.75,
                                                          height: 40,
                                                          color: Appstyle.violet,
                                                          text: showProduitPanel ? l10n.hideProduct : l10n.showProduct,
                                                          onPressed: () => setState(() => showProduitPanel = !showProduitPanel),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (showProduitPanel)
                                              Expanded(
                                                flex: 50,
                                                child: Container(
                                                  padding: EdgeInsets.all(10),
                                                  decoration: sectionDecoration(Appstyle.Tblanc),
                                                  child: AnimatedSlide(
                                                    duration: const Duration(milliseconds: 300),
                                                    curve: Curves.easeOut,
                                                    offset: showProduitPanel ? Offset.zero : const Offset(-0.2, 0),
                                                    child: AnimatedOpacity(
                                                      duration: const Duration(milliseconds: 200),
                                                      opacity: showProduitPanel ? 1 : 0,
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Column(
                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [



                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  // Titre "Catégorie"
                                                                  TitleSmall(
                                                                    textsize: 20,
                                                                    imageSize: 16,
                                                                    text: l10n.categorie,
                                                                    couleur: Appstyle.indigo,
                                                                    imagePath: 'assets/icons/cardwidget/categorie_icon.png',
                                                                  ),
                                                                  // Barre de filtres - prend l'espace restant
                                                                  Expanded(
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.only(left: 16.0),
                                                                      child: _barreCategoriesFiltre(l10n),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),

                                                              SizedBox(height: paddingV / 2),

                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  TitleSmall(
                                                                    textsize: 20,
                                                                    imageSize: 16,
                                                                    text: l10n.produit,
                                                                    couleur: Appstyle.indigo,
                                                                    imagePath: 'assets/icons/sidebar/produit_icon.png',
                                                                  ),
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      SizedBox(width: paddingH / 2),
                                                                     ],
                                                                  ),


                                                                  Row(
                                                                    children: [

                                                                      SizedBox(
                                                                        width: adjustedWidth/6,
                                                                        // ✅ Recherche séparée par affichage : en mode carte
                                                                        // elle filtre la carte (_searchController), en mode
                                                                        // tableau elle filtre le tableau (_searchControllerPrTable).
                                                                        // La ValueKey force la reconstruction du champ (donc le
                                                                        // bon controller) au changement d'affichage.
                                                                        child: AffichageCard
                                                                            ? SearchField(
                                                                          key: const ValueKey('search_card'),
                                                                          controller: _searchController,
                                                                          onChanged: (_) => setState(() => appliquerFiltreCarte()),
                                                                        )
                                                                            : SearchField(
                                                                          key: const ValueKey('search_table'),
                                                                          controller: _searchControllerPrTable,
                                                                          onChanged: (_) => setState(() => appliquefiltrePrtable()),
                                                                        ),
                                                                      ),
                                                                      SizedBox(width: paddingH / 3),

                                                                      _boutonFiltreProduitCaisse(context),
                                                                      SizedBox(width: paddingH / 3),

                                                                      AnimatedSwitchButton(
                                                                        isCard: AffichageCard,
                                                                        onTap: () => setState(() => AffichageCard = !AffichageCard),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(height: paddingV / 4),

                                                            ],
                                                          ),
                                                          if (AffichageCard == true)
                                                            SizedBox(
                                                              height:  adjustedHeight * 0.555,
                                                              width: double.infinity,
                                                              child: Container(
                                                                padding: EdgeInsets.all(8),
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(18),
                                                                  gradient: LinearGradient(
                                                                    begin: Alignment.topLeft,
                                                                    end: Alignment.bottomRight,
                                                                    colors: [
                                                                      Appstyle.blueF.withOpacity(0.1),
                                                                      Appstyle.blueF.withOpacity(0.05),
                                                                    ],
                                                                  ),
                                                                ),
                                                                child: Scrollbar(
                                                                  controller: _produitsScrollController,
                                                                  thumbVisibility: true,
                                                                  trackVisibility: true,
                                                                  interactive: true,
                                                                  radius: const Radius.circular(8),
                                                                  thickness: 6,
                                                                  child: SingleChildScrollView(
                                                                    controller: _produitsScrollController,
                                                                    child: Wrap(
                                                                      spacing: 8,
                                                                      runSpacing: 8,
                                                                      children: produitsFiltres.map((p) {
                                                                        return CardProduct(
                                                                          seuil: seuilMinimum,
                                                                          text1: p.nom,
                                                                          text2: "${p.prixVente} DA",
                                                                          couleur: Appstyle.Tblanc,
                                                                          iconPath: 'assets/icons/sidebar/produit_icon.png',
                                                                          quantite: getQuantiteDisponibleVirtuelle(p), // ✅ Utiliser la quantité virtuelle
                                                                          photo: p.photo,
                                                                          sousCategorieId: p.sousCategorieId,
                                                                          actif: p.etat,
                                                                          selected: produitsSelectionnes?.id == p.id,
                                                                          onTap: !p.etat ? null : () => setState(() => produitsSelectionnes = p),
                                                                          onDoubleTap: !p.etat ? null : () {
                                                                            setState(() => produitsSelectionnes = p);
                                                                            ouvrirDialogProduit(p);
                                                                          },
                                                                          hasRemise: p.remiseId == 0 ? false : true,
                                                                        );
                                                                      }).toList(),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            SizedBox(
                                                              height:  adjustedHeight * 0.555,
                                                              child: TableauProduitCaisseAdvanced(
                                                                key: _tableauKey,  // ✅ Utilisez la clé ici
                                                                produits: produitsFiltrestable,
                                                                onDoubleTapProduit: (p) => ouvrirDialogProduit(p),
                                                                onSelectionChanged: (selection) => setState(() => produitsSelectionnes = selection),
                                                                getQuantiteVirtuelle: getQuantiteDisponibleVirtuelle,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            SizedBox(width: paddingH / 3),
                                            Expanded(
                                              flex: 50,
                                              child: Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: sectionDecoration(Appstyle.Tblanc),
                                                // ✅ minHeight (au lieu d'Expanded/IntrinsicHeight, qui
                                                // plantent ici car ce Row est dans une page scrollable à
                                                // hauteur non bornée) : le panier ne sera jamais plus
                                                // court que la liste produit, sans risque de layout.
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(minHeight: caisseActive.produits.isEmpty?adjustedHeight * 0.36:adjustedHeight * 0.4),
                                                  child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                     Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        TitleSmall(
                                                            textsize: 20,
                                                          imageSize: 16,
                                                          text: l10n.panier,
                                                          couleur: Appstyle.indigo,
                                                          imagePath: "assets/icons/sidebar/pannier_icon.png",
                                                        ),
                                                        AnimatedCalcSwitchButton(
                                                          isCalc: AffichageCalc,
                                                          onTap: () => setState(() => AffichageCalc = !AffichageCalc),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: paddingV / 2),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: caisseActive.produits.isEmpty
                                                          ? _panierVideWidget(
                                                        panierZoneHeight*0.78,
                                                        l10n,
                                                      )
                                                          :TableauCaisse(
                                                        caissenom: caisses[selectedCaisse].nom,
                                                        produits: caisseActive.produits,
                                                        size: panierTableSize*0.85,
                                                        showCode: !showProduitPanel,
                                                        afficherNombre: caisseActive.produits.any((cp) =>
                                                            produitsTest.firstWhereOrNull((p) => p.code == cp.code)?.nombreActif ?? false),
                                                        selectedProduit: produitSelectionne,
                                                        remiseInfo: caisseActive.remiseInfo,  // ✅ Ajouter
                                                        remiseActive: caisseActive.remiseActive,  // ✅ Ajouter
                                                        remiseValue: caisseActive.remise,  // ✅ Ajouter
                                                        onProduitSelected: (p) => setState(() => produitSelectionne = p),
                                                        onProduitDoubleClick: (p) {
                                                          ModifierPrixProduitDialog(
                                                            context: context,
                                                            produit: p,
                                                            onValider: (double nouveauPrix) {
                                                              setState(() {
                                                                p.prix = nouveauPrix;
                                                                caisseActive.recalculerTotaux();
                                                              });
                                                            },
                                                            // ✅ Portée "produit complet" : met à jour le prix de
                                                            // vente en base (via le Service) et le reflète en mémoire.
                                                            onValiderProduit: (double nouveauPrix) async {
                                                              final produitOriginal = produitsTest
                                                                  .firstWhereOrNull((x) => x.code == p.code);
                                                              if (produitOriginal == null) return;
                                                              produitOriginal.prixVente = nouveauPrix;
                                                              final db = await DbCreator.openDb();
                                                              await ProduitServices(db).updateProduit(produitOriginal);
                                                              if (mounted) {
                                                                setState(() {
                                                                  // Rafraîchir les listes pour refléter le nouveau prix.
                                                                  refreshProduitsDisplay();
                                                                });
                                                              }
                                                            },
                                                          );
                                                        },
                                                        onProduitDelete: (produit) {
                                                          final quantiteReelle = produit.qte * (produit.piecesParEmballage ?? 1);
                                                          _stockManager.liberer(produit.code, caisseActive.nom, quantiteReelle);
                                                          setState(() {
                                                            if (caisseActive.produits.isEmpty) {
                                                              caisseActive.total = 0;
                                                              caisseActive.remise = 0;
                                                              caisseActive.remisenom = null;
                                                              produitSelectionne = null;
                                                            } else {
                                                              caisseActive.recalculerTotaux();
                                                            }
                                                            refreshProduitsDisplay();
                                                          });
                                                        },
                                                        onTotalChanged: (total, remise) {
                                                          setState(() {
                                                            caisseActive.total = total;
                                                            caisseActive.remise = remise;
                                                          });
                                                        },
                                                        onVerifyStock: (produitPanier, nouvelleQte) async {
                                                          // Votre logique de vérification de stock
                                                          final produitOriginal = _findProductByName(produitPanier.nom);
                                                          if (produitOriginal == null) return false;

                                                          final double nouvelleQuantiteReelle = nouvelleQte * (produitPanier.piecesParEmballage ?? 1);
                                                          final double ancienneQuantiteReelle = produitPanier.qte * (produitPanier.piecesParEmballage ?? 1);
                                                          final double quantiteSupplementaire = nouvelleQuantiteReelle - ancienneQuantiteReelle;

                                                          if (quantiteSupplementaire <= 0) return true;

                                                          final stockVirtuel = getQuantiteDisponibleVirtuelle(produitOriginal);

                                                          if (quantiteSupplementaire > stockVirtuel) {
                                                            final l10n = AppLocalizations.of(context)!;
                                                            await InformationDialog(
                                                              context: context,
                                                              titre_type_message: l10n.error,
                                                              kind: DialogKind.refuser,
                                                              titre_concerne: l10n.product,
                                                              message: l10n.stockInsuffisantSupplement(
                                                                  stockVirtuel.toInt().toString(),
                                                                  quantiteSupplementaire.toInt().toString()),
                                                            );
                                                            return false;
                                                          }

                                                          _stockManager.liberer(produitPanier.code, caisseActive.nom, ancienneQuantiteReelle);
                                                          _stockManager.reserver(produitPanier.code, caisseActive.nom, nouvelleQuantiteReelle);

                                                          return true;
                                                        },
                                                      ),
                                                    ),
                                                    SizedBox(height: paddingV),
                                                    if (AffichageCalc)
                                                      CalculatriceWidget(
                                                        onButtonPressed: (value) {
                                                          switch (value) {
                                                            case "CLEAR": _supprimerproduit(); break;
                                                            case "REMISE":_remiseclavier(); break;
                                                            case "UP": _incrementQte(); break;
                                                            case "SUPPRIMER_CAISSE": _supprimerCaisse(); break;
                                                            case "DOWN": _decrementQte(); break;
                                                            case "CLEAR_PANIER": _viderPanier(); break;
                                                            case "ENCAISSEMENT_TICKET": _encaissierTicket(); break;
                                                            case "ENCAISSEMENT_BLSC": _encaissierBLSC(); break;
                                                            case "ENREGISTER_TICKET": _enregistreTicket(); break;
                                                            case "NEW_CLIENT": _newClient(); break;
                                                            case "NEW_PRODUCT": _newProduct(); break;
                                                            case "QUICK_ENTRY": _openQuickEntry(); break;
                                                            case "CASH_RECEIPT": _showCashReceipt(); break;
                                                            case "CASH_RECEIPT_PRODUIT": _showProductRevenue(); break;
                                                            case "PACK":_ouvrirDialoguePack();
                                                              break;
                                                            default: _handleNumericInput(value);
                                                          }
                                                        },
                                                      )
                                                    else
                                                      CalculatriceSmallWidget(
                                                        onButtonPressed: (valeur) {
                                                          switch (valeur) {
                                                            case "SUPPRIMER_CAISSE": _supprimerCaisse(); break;
                                                            case "ENCAISSEMENT_TICKET": _encaissierTicket(); break;
                                                            case "ENCAISSEMENT_BLSC": _encaissierBLSC(); break;
                                                            case "ENREGISTER_TICKET": _enregistreTicket(); break;
                                                            case "CLEAR_PANIER": _viderPanier(); break;
                                                            case "NEW_CLIENT": _newClient(); break;
                                                            case "NEW_PRODUCT": _newProduct(); break;
                                                            case "QUICK_ENTRY": _openQuickEntry(); break;
                                                            case "CASH_RECEIPT": _showCashReceipt(); break;
                                                            case "CASH_RECEIPT_PRODUIT": _showProductRevenue(); break;
                                                            case "REMISE": _remiseclavier(); break;
                                                            case "PACK":_ouvrirDialoguePack();
                                                              break;
                                                            default: _handleNumericInput(valeur);
                                                          }
                                                        },
                                                      ),
                                                  ],
                                                ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),

              ),
          );
        },
      ),
    );
  }
}

Widget _panierVideWidget(double height, AppLocalizations l10n) {
  return SizedBox(
    height: height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset("assets/icons/sidebar/pannier_icon.png",
          width: 72,
          height: 72,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.emptyCart,
          style: Appstyle.textM.copyWith(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.addProductsToStart,
          style: Appstyle.textS.copyWith(
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}

class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HoverScale({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: isHover ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class AnimatedSwitchButton extends StatefulWidget {
  final bool isCard;
  final VoidCallback onTap;

  const AnimatedSwitchButton({
    super.key,
    required this.isCard,
    required this.onTap,
  });

  @override
  State<AnimatedSwitchButton> createState() => _AnimatedSwitchButtonState();
}

class _AnimatedSwitchButtonState extends State<AnimatedSwitchButton> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Appstyle.violet,
            borderRadius: BorderRadius.circular(10),
            boxShadow: hover
                ? [
              BoxShadow(
                color: Appstyle.violet.withOpacity(0.6),
                blurRadius: 16,
              )
            ]
                : [],
          ),
          child: Center(
            child: AnimatedRotation(
              turns: widget.isCard ? 0 : 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedScale(
                scale: hover ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isCard ? Icons.view_list : Icons.grid_view,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration sectionDecoration(Color color) {
  return BoxDecoration(
    color: color.withOpacity(0.8),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: color.withOpacity(0.25),
      width: 0.2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        offset: Offset(0, 2),
        blurRadius: 6,
      ),
    ],
  );
}

class AnimatedCalcSwitchButton extends StatefulWidget {
  final bool isCalc;
  final VoidCallback onTap;

  const AnimatedCalcSwitchButton({
    super.key,
    required this.isCalc,
    required this.onTap,
  });

  @override
  State<AnimatedCalcSwitchButton> createState() =>
      _AnimatedCalcSwitchButtonState();
}

class _AnimatedCalcSwitchButtonState extends State<AnimatedCalcSwitchButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Appstyle.violet,
            borderRadius: BorderRadius.circular(10),
            boxShadow: hover
                ? [
              BoxShadow(
                color: Appstyle.violet.withOpacity(0.6),
                blurRadius: 16,
              )
            ]
                : [],
          ),
          child: Center(
            child: AnimatedRotation(
              turns: widget.isCalc ? 0 : 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedScale(
                scale: hover ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isCalc ? Icons.panorama_fish_eye_sharp : Icons.remove_red_eye,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class StockManager extends ChangeNotifier {
  Map<String, Map<String, double>> _reservations = {};
  Map<String, double> _stockReel = {};

  void initialiserStockReel(List<Produit> produits, Map<String, double> quantites) {
    for (var produit in produits) {
      _stockReel[produit.code] = quantites[produit.code] ?? 0;
    }
    notifyListeners();
  }

  // ✅ Met à jour le stock réel après encaissement
  void confirmerVente(String produitCode, double quantiteVendue) {
    if (_stockReel.containsKey(produitCode)) {
      _stockReel[produitCode] = _stockReel[produitCode]! - quantiteVendue;
      notifyListeners();
    }
  }

  // ✅ Annuler une réservation (pour vider panier, supprimer produit, etc.)
  void annulerReservation(String produitCode, String caisseNom, double quantite) {
    liberer(produitCode, caisseNom, quantite);
  }

  bool reserver(String produitCode, String caisseNom, double quantiteAPrelever) {
    final stockDisponible = getStockDisponible(produitCode, caisseNom);


    if (quantiteAPrelever <= stockDisponible) {
      if (!_reservations.containsKey(produitCode)) {
        _reservations[produitCode] = {};
      }

      final reservationActuelle = _reservations[produitCode]![caisseNom] ?? 0;
      _reservations[produitCode]![caisseNom] = reservationActuelle + quantiteAPrelever;

      notifyListeners();
      return true;
    }

    return false;
  }

  void liberer(String produitCode, String caisseNom, double quantite) {
    if (_reservations.containsKey(produitCode) &&
        _reservations[produitCode]!.containsKey(caisseNom)) {

      final nouvelleQte = (_reservations[produitCode]![caisseNom] ?? 0) - quantite;


      if (nouvelleQte <= 0) {
        _reservations[produitCode]!.remove(caisseNom);
        if (_reservations[produitCode]!.isEmpty) {
          _reservations.remove(produitCode);
        }
      } else {
        _reservations[produitCode]![caisseNom] = nouvelleQte;
      }

      notifyListeners();
    }
  }

  void libererToutesReservationsCaisse(String caisseNom) {

    List<String> produitsASupprimer = [];

    for (var entry in _reservations.entries) {
      if (entry.value.containsKey(caisseNom)) {
        entry.value.remove(caisseNom);
        if (entry.value.isEmpty) {
          produitsASupprimer.add(entry.key);
        }
      }
    }

    for (var produitCode in produitsASupprimer) {
      _reservations.remove(produitCode);
    }

    notifyListeners();
  }

  double getStockDisponible(String produitCode, String caisseNom) {
    final stock = _stockReel[produitCode] ?? 0;

    double reservationsAutresCaisses = 0;

    if (_reservations.containsKey(produitCode)) {
      for (var entry in _reservations[produitCode]!.entries) {
        if (entry.key != caisseNom) {
          reservationsAutresCaisses += entry.value;
        }
      }
    }

    final disponible = stock - reservationsAutresCaisses;
    return disponible > 0 ? disponible : 0;
  }

  double getReservationParCaisse(String produitCode, String caisseNom) {
    return _reservations[produitCode]?[caisseNom] ?? 0;
  }

  void updateStockReel(String produitCode, double nouvelleQuantite) {
    _stockReel[produitCode] = nouvelleQuantite;
    notifyListeners();
  }
}