import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:collection/collection.dart';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/CaisseParam.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/core/Auth/auth_state.dart';

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
import 'package:caisse_dz/core/widget/calculatrice.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/data/models/caisseParam.dart';

import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/magasin.dart';

import 'package:caisse_dz/data/models/produit.dart';
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
import '../core/dialog/caisse/selection_magasin.dart';
import '../core/dialog/entree/entree_nouveau.dart';
import '../core/dialog/information_dialog.dart';
import '../core/widget/title/titre_avec_ligne.dart';
import '../data/models/produit_magasin_detail.dart';

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

  Key _tableauKey = const ValueKey('tableau');  // ✅ AJOUTEZ CETTE LIGNE
  List<ProduitMagasinDetail> produitMagasinDetails = [];
  bool isMagasinSystem = false;

  List<Produit>       produitsTest        = [];
  List<Client>        clientsTest         = [];
  List<Remise>        remisesTest         = [];
  List<SousCategorie> sousCategoriesTest  = [];
  List<CaisseGestion> CaisseTest          = [];
  List<Magasin>       MagasinTest         = [];
  CaisseParam?        Param;

  bool isLoading = true;

  List<String> CaisseList   = [];
  List<String> MagasinList  = [];
  String CaisseAct   ="";

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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Remise '${caisseActive.remiseInfo!.nom}' appliquée !"),
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
    final db = await DbCreator.openDb();
    final pmdService = ProduitMagasinDetailServices(db);
    final l10n = AppLocalizations.of(context);

    // 1️⃣ Vérifier le stock global
    if (quantiteReelle > produit.quantite) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.product,
        message: "Stock global insuffisant !\nDisponible: ${produit.quantite.toInt()} pièce(s)\nDemandé: ${quantiteReelle.toInt()} pièce(s)",
      );
      return false;
    }

    // 2️⃣ Récupérer le magasin sélectionné
    final magasinSelectionneCode = Param?.magasinCode;
    final magasinSelectionneNom = Param?.selectedMagasin;

    // 3️⃣ Vérifier le stock dans le magasin
    if (magasinSelectionneCode != null && magasinSelectionneCode.isNotEmpty) {
      final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
          produit.code,
          magasinSelectionneCode
      );

      if (magasinDetail != null && magasinDetail.quantite >= quantiteReelle) {
        return true; // Stock suffisant
      } else if (magasinDetail != null && magasinDetail.quantite < quantiteReelle) {
        // Stock insuffisant - proposer de prendre ce qui est disponible
        final confirm = await ConfirmationDialog(
          context: context,
          titre: l10n.attention,
          message: "Stock insuffisant dans le magasin '$magasinSelectionneNom' !\n"
              "Disponible: ${magasinDetail.quantite.toInt()} pièce(s)\n"
              "Demandé: ${quantiteReelle.toInt()} pièce(s)\n\n"
              "Voulez-vous prendre uniquement la quantité disponible ?",
          onConfirmer: () {},
        );
        return confirm == true;
      }
    }

    // 4️⃣ Chercher d'autres magasins
    final magasinsDisponibles = await pmdService.getByProduitCode(produit.code);
    final magasinsAvecStock = magasinsDisponibles.where((m) => m.quantite > 0).toList();

    if (magasinsAvecStock.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.product,
        message: "Ce produit n'est disponible dans aucun magasin !",
      );
      return false;
    }

    // Afficher la sélection de magasin
    final magasinChoisi = await showMagasinSelectionDialogWithQuantity(
      context: context,
      magasinsDisponibles: magasinsAvecStock,
      magasins: MagasinTest,
      produitNom: produit.nom,
      quantiteDemandee: quantiteReelle,
    );

    if (magasinChoisi == null) return false;

    if (magasinChoisi.quantite >= quantiteReelle) {
      return true;
    } else {
      final magasinChoisiNom = MagasinTest
              .firstWhereOrNull((m) => m.code == magasinChoisi.magasinCode)
              ?.nom ??
          magasinChoisi.magasinCode;
      final confirm = await ConfirmationDialog(
        context: context,
        titre: l10n.attention,
        message: "Stock insuffisant dans le magasin '$magasinChoisiNom' !\n"
            "Disponible: ${magasinChoisi.quantite.toInt()} pièce(s)\n"
            "Demandé: ${quantiteReelle.toInt()} pièce(s)\n\n"
            "Voulez-vous prendre uniquement la quantité disponible ?",
        onConfirmer: () {},
      );
      return confirm == true;
    }
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
          titre_concerne: l10n.discount,
          message:l10n.discountAmountExceedsTotal(
              selectedRemise.taux.toString(),
              sousTotal.toStringAsFixed(2)
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
    final maga      = await MagasinServices         .getAllMagasins();
    final produits  = await ProduitServices         .getAllProduits();
    final clients   = await ClientServices          .getAllClients();
    final remisess  = await RemiseServices          .getAllRemise();
    final caiss     = await GCServices              .getAllCaisses();
    final caissParm = await service                 .getCaisseParamByUserCode(userCode!);
    final dernierPannier = await PannierServices.getLastPannierNumber();

    // ✅ Charger les packs et leurs détails
    final packs = await PackServices.getAllPacks();
    final packDetails = await ProduitPackDetailServices.getAllDetails();

    if (mounted) {
      setState(() {
        sousCategoriesTest  = souscate;
        produitsTest        = produits;
        remisesTest         = remisess;
        clientsTest         = clients;
        MagasinTest         = maga;
        CaisseTest          = caiss;
        Param               = caissParm;

        // ✅ Initialiser les packs
        packsTest = packs.where((p) => p.etat == true).toList();
        packDetailsTest = packDetails;

        dernierNumeroPannier = dernierPannier;
        nombrepannier = dernierPannier;

        CaisseList  = CaisseTest  .map((caisse) => caisse.nomCaisse).toList();
        MagasinList = MagasinTest .map((maga)   => maga.nom)        .toList();
        CaisseAct   = CaisseList.isNotEmpty ? CaisseList.first : "";

        if (caisses.isEmpty) {
          caisses = [CaisseState(nom: "Caisse 1", caisse: CaisseAct)];
        }

        if (produitsTest.isNotEmpty) {
          produitsFiltres       = produitsTest;
          produitsFiltrestable  = produitsTest;
          produitsSelectionnes  = produitsTest.first;
        }
        isLoading = false;
        _stockManager.initialiserStockReel(produitsTest);
      });
      checkIfMagasinSystem();
    }
  }

// ✅ Vérifie si un pack est disponible (tous les produits ont assez de stock)
  Future<bool> verifierDisponibilitePack(Pack pack) async {
    final packDetails = packDetailsTest.where((d) => d.packCode == pack.code).toList();

    if (packDetails.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.pack,
        message: "Ce pack ne contient aucun produit",
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
          titre_concerne: l10n.pack,
          message: "Le produit '${detail.produitNom}' n'existe pas dans la base de données",
        );
        return false;
      }

      final stockDisponible = getQuantiteDisponibleVirtuelle(produit);
      final quantiteNecessaire = detail.quantite.toDouble();

      if (stockDisponible < quantiteNecessaire) {
        final l10n = AppLocalizations.of(context)!;
        await InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.pack,
          message: "Stock insuffisant pour le produit '${detail.produitNom}'\n"
              "Disponible: ${stockDisponible.toInt()} pièce(s)\n"
              "Nécessaire: ${quantiteNecessaire.toInt()} pièce(s)",
        );
        return false;
      }
    }

    return true;
  }

// ✅ Ajoute tous les produits d'un pack au panier
  // ✅ Ajoute tous les produits d'un pack au panier
  // ✅ Ajoute tous les produits d'un pack au panier
  Future<void> ajouterPackAuPanier(Pack pack) async {
    final l10n = AppLocalizations.of(context)!;

    // Vérifier la disponibilité
    final disponible = await verifierDisponibilitePack(pack);
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
          titre_concerne: l10n.pack,
          message: "Le produit '${detail.produitNom}' n'existe pas",
        );
        continue;
      }

      // ✅ Utiliser colisType = nom du pack pour regrouper les produits du pack
      await ajouterProduitAuPanier(
        produit,
        quantite: detail.quantite.toDouble(),
        prixUnitaire: detail.prixUnitaire,
        colisType: pack.nom,           // ← Clé : regroupe les produits du pack
        packNom: pack.nom,             // ← Pour l'affichage
        packCode: pack.code,           // ← Pour l'affichage
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Pack '${pack.nom}' ajouté au panier"),
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
        message: "Aucun pack disponible",
      );
      return;
    }

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
                          Text("Code: ${pack.code}"),
                          const SizedBox(height: 4),
                          Text(
                            "${packDetails.length} produit(s) | Prix: ${pack.prixVente.toStringAsFixed(2)} ${l10n.currency}",
                            style: Appstyle.textS.copyWith(color: Appstyle.crevete),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ajouterPackAuPanier(pack);
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
  late Client  clientselectione = clientsTest.isEmpty ? Client(
    id: 0, nom: "Comptoire", code: "", telephone: "", adresse: "",
    type: "", etat: true, dateCree: DateTime.now(),
    creePar: "", creeParCode: "", dernierAchat: null, wilaya: '',
  ) : clientsTest.first;

  CaisseState get caisseActive {
    if (caisses.isEmpty) {
      return CaisseState(nom: "Temp", caisse: CaisseAct);
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

  List<CaisseState> caisses = [];

  Produit?          produitsSelectionnes;
  List<Produit>     produitsFiltres       = [];
  List<Produit>     produitsFiltrestable  = [];

  int selectedCaisse  = 0;
  int nombreproduit   = 0;
  int nombrepannier   = 1;
  int dernierNumeroPannier = 0;

  String activeSousCategorie    = "";
  String selectedSousCategorie  = "";

  List<String> sousCategoriesSelectionnees = [];
  bool showProduitPanel = true;

  @override
  void initState() {
    super.initState();
    _stockManager = StockManager();
    _stockManager.addListener(_onStockChanged); // ✅ Ajoutez cette ligne
    _LoadAllData();
  }

  void checkIfMagasinSystem() {
    final magasinSelectionne = Param?.selectedMagasin;
    isMagasinSystem = magasinSelectionne == "Magasin System" ||
        magasinSelectionne == "Magasin Système" ||
        magasinSelectionne == "Magasin system" ||
        magasinSelectionne == "System" ||
        magasinSelectionne == "Système";

    // ✅ Ajoutez ce print pour vérifier
    print("=== checkIfMagasinSystem ===");
    print("magasinSelectionne: $magasinSelectionne");
    print("isMagasinSystem: $isMagasinSystem");

  }
// ✅ Fonction appelée après succès d'encaissement/enregistrement
  void _onOperationSuccess() {
    print("🎉 Opération réussie! Nettoyage de la caisse...");

    if (caisses.length > 1) {
      // ✅ Plusieurs caisses ouvertes → Supprimer la caisse actuelle
      print("🗑️ Plusieurs caisses: suppression de la caisse ${caisseActive.nom}");

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
      print("🧹 Une seule caisse: vidage du panier");

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

      print("✅ Panier vidé, nouveau numéro de panier: $nombrepannier");
    }
  }
  void appliquefiltrePrtable() {
    final l10n = AppLocalizations.of(context)!;
    final searchText = _searchControllerPrTable.text.toLowerCase();

    if (searchText.isEmpty) {
      produitsFiltrestable = produitsTest;
      return;
    }
    if (searchText.isNotEmpty) {
      produitsFiltrestable = produitsTest.where((p) {
        return
          p.nom.toLowerCase().contains(searchText) ||
              p.marque.toLowerCase().contains(searchText) ||
              (p.description?.toLowerCase().contains(searchText) ?? false) ||
              p.prixVente.toString().contains(searchText) ||
              p.code.toLowerCase().contains(searchText);
      }).toList();
    }
  }

  Map<String, dynamic> getClientInfo(String clientName) {
    try {
      final client = clientsTest.firstWhere((c) => c.nom == clientName);
      return {
        "type": client.type,
        "dernierAchat": client.dernierAchat ?? "--/--/----",
      };
    } catch (e) {
      debugPrint('⚠️ Client non trouvé: $clientName, utilisation du client par défaut');
      return {
        "type": "Standard",
        "dernierAchat": "--/--/----",
      };
    }
  }

  @override
  void dispose() {
    _stockManager.removeListener(_onStockChanged); // ✅ Ajoutez cette ligne
    _produitsScrollController.dispose();
    _searchControllerPrTable.dispose();
    _searchController.dispose();
    super.dispose();
  }
  void _onStockChanged() {
    if (mounted) {
      print("🔄 Stock changed, refreshing display...");
      setState(() {
        // Mettre à jour les listes
        produitsFiltres = List.from(produitsFiltres);
        produitsFiltrestable = List.from(produitsFiltrestable);

        // ✅ Changer la clé pour forcer le rebuild complet
        _tableauKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
      });
    }
  }
  void _confirmerAction({required String titre, required String message, required VoidCallback onConfirmer}) {
    ConfirmationDialog(
      titre: titre,
      context: context,
      message: message,
      onConfirmer: onConfirmer,
    );
  }

  Future<void> _openQuickEntry() async {
    final l10n = AppLocalizations.of(context)!;

    if (Param == null || Param?.selectedMagasin == null) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.attention,
        titre_concerne: l10n.settings,
        message: l10n.noStoreSelected,
      );
      return;
    }

    // ✅ Passer le callback onSuccess
    await EntreeNouveau(
      context,
      onSuccess: () async {
        print("✅ Entrée réussie, mise à jour des données...");

        // Recharger toutes les données
        await _reloadAllData();

        // Mettre à jour le StockManager
        final produitsMisAJour = await ProduitServices.getAllProduits();
        _stockManager.initialiserStockReel(produitsMisAJour);

        // Mettre à jour les listes et l'affichage
        if (mounted) {
          setState(() {
            produitsTest = produitsMisAJour;
            produitsFiltres = produitsMisAJour;
            produitsFiltrestable = produitsMisAJour;
          });
          refreshProduitsDisplay();
        }

        print("✅ Mise à jour terminée");
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
// ✅ Calcule la quantité disponible d'un produit (stock réel - quantité dans le panier)
  // ✅ Version corrigée de getQuantiteDisponibleVirtuelle
  double getQuantiteDisponibleVirtuelle(Produit produit) {
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

    print("📊 ${produit.nom}: stockGlobal=$stockDisponibleGlobal, dansPanier=$quantiteDansPanier, disponible=$disponible");

    return disponible > 0 ? disponible : 0;
  }
// ✅ Met à jour l'affichage des produits
  void refreshProduitsDisplay() {
    setState(() {
      produitsFiltres = List.from(produitsFiltres);
      produitsFiltrestable = List.from(produitsFiltrestable);
      _tableauKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }
  Future<void> _supprimerCaisse() async {
    final l10n = AppLocalizations.of(context)!;

    if (caisses.length == 1) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.caisse,
        message: l10n.cannotDeleteLastCaisse,
      );
      return;
    }

    await ConfirmationDialog(
      context: context,
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

  void _newProduct() async {
    await ProduitNouveau(context);
    await Future.delayed(const Duration(milliseconds: 100));
    await _reloadAllData();
  }

  // ✅ Nouvelle fonction ajouterProduitAuPanier - SANS déstockage
  // ✅ Nouvelle fonction ajouterProduitAuPanier - Avec support des packs
  Future<void> ajouterProduitAuPanier(
      Produit p, {
        double quantite = 1,
        String? colisType,
        double? prixUnitaire,
        String? packNom,    // ✅ Nouveau paramètre
        String? packCode,   // ✅ Nouveau paramètre
      }) async {
    int? piecesParEmballage;
    if (colisType != null) {
      if (colisType.contains("Boîte") && p.emballage1 != null) {
        piecesParEmballage = p.emballage1?.toInt();
      } else if (colisType.contains("Carton") && p.emballage2 != null) {
        piecesParEmballage = p.emballage2?.toInt();
      }
    }

    final double quantiteReelle = quantite * (piecesParEmballage ?? 1);

    // ✅ Vérifier le stock disponible pour CETTE caisse
    final stockDisponible = getQuantiteDisponibleVirtuelle(p);

    if (quantiteReelle > stockDisponible) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.product,
        message: "Stock insuffisant !\nDisponible: ${stockDisponible.toInt()} pièce(s)\nDemandé: ${quantiteReelle.toInt()} pièce(s)",
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
            piecesParEmballage: piecesParEmballage,
            packNom: packNom,    // ✅ Ajouter l'info du pack
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
        remises: remisesTest.where((r) => r.type == "Par Montant").toList(),
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
    String? defaultColisType = Param?.selectedColis;

    final quantiteDisponibleVirtuelle = getQuantiteDisponibleVirtuelle(p);

    await afficherProduitSelectionneDialog(
      context: context,
      nom: p.nom,
      prix: p.prixVente,
      photoName: p.photo,
      emballage1: p.emballage1,
      emballageP1: p.emballageP1,
      emballage2: p.emballage2,
      emballageP2: p.emballageP2,
      defaultColisType: defaultColisType,
      quantiteDisponible: quantiteDisponibleVirtuelle,
      onAjouter: (qte, {colisType, prixUnitaire}) async {
        if (prixUnitaire != null) {
          await ajouterProduitAuPanier(p, quantite: qte, colisType: colisType, prixUnitaire: prixUnitaire);
        } else {
          await ajouterProduitAuPanier(p, quantite: qte);
        }
      },
    );
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
        titre_concerne: l10n.product,
        message: "Stock insuffisant !\nPlus que ${disponibleVirtuel.toInt()} pièce(s) disponible(s)",
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
    final maga = await MagasinServices.getAllMagasins();
    final produits = await ProduitServices.getAllProduits();
    final clients = await ClientServices.getAllClients();
    final remisess = await RemiseServices.getAllRemise();
    final caiss = await GCServices.getAllCaisses();
    final caissParm = await service.getCaisseParamByUserCode(userCode!);

    produitMagasinDetails = await ProduitMagasinDetailServices.getAllDetails();

    if (mounted) {
      setState(() {
        sousCategoriesTest = souscate;
        produitsTest = produits;
        remisesTest = remisess;
        clientsTest = clients;
        MagasinTest = maga;
        CaisseTest = caiss;
        Param = caissParm;

        produitsFiltres = produitsTest;
        produitsFiltrestable = produitsTest;

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
        MagasinList = MagasinTest.map((maga) => maga.nom).toList();
        CaisseAct = CaisseList.isNotEmpty ? CaisseList.first : "";
      });

      checkIfMagasinSystem();

    }
  }

  void _handleNumericInput(String value) async {
    if (produitSelectionne == null) return;

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
                titre_concerne: l10n.product,
                message: "Stock insuffisant !\n"
                    "Disponible: ${stockVirtuel.toInt()} pièce(s)\n"
                    "Demandé supplément: ${quantiteSupplementReelle.toInt()} pièce(s)",
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

    final searchText = _searchController.text.toLowerCase();
    final produitsFiltres = produitsTest.where((p) {
      final bool sousCategorieOk = activeSousCategorie.isEmpty
          ? true
          : p.sousCategorie == activeSousCategorie;
      final bool rechercheOk = searchText.isEmpty
          ? true
          : p.nom.toLowerCase().contains(searchText);
      return sousCategorieOk && rechercheOk;
    }).toList();

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

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: minWidth, minHeight: minHeight),
                   child: SizedBox(
                    width: adjustedWidth,
                    height: adjustedHeight ,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SideBarWidget(),
                         Expanded(
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
                                            TimeDateWidget(
                                              heure: "18:00",
                                              date: "25 Nov 2025",
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
                                              titre_concerne: l10n.caisse,
                                              message: l10n.maxCaissesReached,
                                            );
                                            return;
                                          }
                                          setState(() {
                                            final nextIndex = caisses.length;
                                            final caisseName = "${l10n.caisse} ${nextIndex + 1}";
                                            caisses.add(CaisseState(nom: caisseName, caisse: CaisseAct));
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
                                              flex: 5,
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
                                                            items: translator.modePaiementDisplayList,
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
                                                        afficheurBorder: true,
                                                        afficherprixachat: false,
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
                                              flex: 3,
                                              child: Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: sectionDecoration(Appstyle.Tblanc),
                                                child: Column(
                                                  children: [
                                                    AfficheurCaisse(
                                                      total: caisseActive.total.toString(),
                                                      remise: "(${caisseActive.remise.toString()}) ${caisseActive.remisenom.toString()}",
                                                      couleur: Appstyle.blueF,
                                                      npannier: nombrepannier.toString(),
                                                      nproduit: caisseActive.nombreProduits.toString(),
                                                    ),
                                                    SizedBox(height: 10),
                                                    // Dans le build de CaisseScreen, remplacez la partie de sélection de remise :

                                                    ChampAvecLabel(
                                                      label: l10n.remise,
                                                      buttonAjout: true,
                                                      distance: 260,
                                                      onAjoutPressed: () async {
                                                        await showDialog(
                                                          context: context,
                                                          barrierColor: Appstyle.gris.withOpacity(0.25),
                                                          builder: (_) => InsertionRemiseDialog(
                                                            multiselection: false,
                                                            remises: remisesTest.where((r) => r.type == "Par Montant").toList(),
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
                                                                  message: "La remise '${remise.nom}' sera appliquée automatiquement lorsque le total atteindra ${montantCondition.toStringAsFixed(2)} DA.",
                                                                );
                                                              }

                                                              // ✅ Stocker les informations de la remise
                                                              setState(() {
                                                                caisseActive.remiseInfo = RemiseInfo(
                                                                  nom: remise.nom,
                                                                  taux: remise.taux,
                                                                  tauxType: remise.tauxType.toLowerCase(),
                                                                  montantCondition: remise.montant ?? 0,
                                                                );
                                                                caisseActive.recalculerTotaux();
                                                              });
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      width: adjustedWidth / 3,
                                                      child: TextListe(
                                                        clearable: true,
                                                        value: (() {
                                                          if (caisseActive.remiseInfo == null) return null;
                                                          // ✅ Afficher toujours le nom de la remise, sans "(en attente)"
                                                          return translator.translateTypeRemise(caisseActive.remiseInfo!.nom);
                                                        })(),
                                                        items: remisesTest
                                                            .where((r) => r.type == "Par Montant")
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
                                                                (r) => r.nom == frenchValue && r.type == "Par Montant",
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
                                                              creePar: '',
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
                                                              message: "La remise '${selectedRemise.nom}' sera appliquée automatiquement lorsque le total atteindra ${montantCondition.toStringAsFixed(2)} DA.",
                                                            );
                                                          }

                                                          setState(() {
                                                            caisseActive.remiseInfo = RemiseInfo(
                                                              nom: selectedRemise.nom,
                                                              taux: selectedRemise.taux,
                                                              tauxType: selectedRemise.tauxType.toLowerCase(),
                                                              montantCondition: montantCondition,
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
                                                          width: 600,
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
                                                flex: 79,
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
                                                                  TitleSmall(
                                                                    text: l10n.produit,
                                                                    couleur: Appstyle.indigo,
                                                                    imagePath: 'assets/icons/sidebar/produit_icon.png',
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      AnimatedSwitchButton(
                                                                        isCard: AffichageCard,
                                                                        onTap: () => setState(() => AffichageCard = !AffichageCard),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(height: paddingV / 4),
                                                              if (AffichageCard == true)
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    SizedBox(
                                                                      width: 300,
                                                                      child: SearchField(
                                                                        controller: _searchController,
                                                                        onChanged: (_) => setState(() {}),
                                                                      ),
                                                                    ),
                                                                    SizedBox(width: paddingH),
                                                                    ChampAvecLabel(
                                                                      width: adjustedWidth * 11 / 47,
                                                                      label: l10n.sousCategorie,
                                                                      child: TextListe(
                                                                        width: adjustedWidth / 7,
                                                                        value: selectedSousCategorie,
                                                                        items: sousCategoriesTest.map((sc) => sc.nom).toList(),
                                                                        onChanged: (v) {
                                                                          setState(() {
                                                                            selectedSousCategorie = v!;
                                                                            if (!sousCategoriesSelectionnees.contains(v)) {
                                                                              sousCategoriesSelectionnees.add(v);
                                                                            }
                                                                          });
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              if (AffichageCard == false)
                                                                SizedBox(
                                                                  width: 300,
                                                                  child: SearchField(
                                                                    controller: _searchControllerPrTable,
                                                                    onChanged: (_) => setState(() => appliquefiltrePrtable()),
                                                                  ),
                                                                ),
                                                              SizedBox(height: 10),
                                                              if (AffichageCard == true)
                                                                Wrap(
                                                                  spacing: 8,
                                                                  runSpacing: 8,
                                                                  children: List.from(sousCategoriesSelectionnees).map((cat) {
                                                                    final bool isActive = activeSousCategorie == cat;
                                                                    return MouseRegion(
                                                                      cursor: SystemMouseCursors.click,
                                                                      child: GestureDetector(
                                                                        onTap: () => setState(() => activeSousCategorie = isActive ? "" : cat),
                                                                        child: AnimatedContainer(
                                                                          curve: Curves.easeOut,
                                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                          duration: const Duration(milliseconds: 180),
                                                                          decoration: BoxDecoration(
                                                                            color: isActive ? Appstyle.violet : Appstyle.grisC,
                                                                            borderRadius: BorderRadius.circular(20),
                                                                            boxShadow: isActive ? [BoxShadow(color: Appstyle.violet.withOpacity(0.4), blurRadius: 12)] : [],
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                              Text(cat,
                                                                                style: TextStyle(
                                                                                  color: isActive ? Colors.white : Colors.black,
                                                                                  fontWeight: FontWeight.w500,
                                                                                ),
                                                                              ),
                                                                              const SizedBox(width: 6),
                                                                              MouseRegion(
                                                                                cursor: SystemMouseCursors.click,
                                                                                child: GestureDetector(
                                                                                  onTap: () {
                                                                                    setState(() {
                                                                                      if (activeSousCategorie == cat) activeSousCategorie = "";
                                                                                      sousCategoriesSelectionnees.remove(cat);
                                                                                      caisseActive.recalculerTotaux();
                                                                                    });
                                                                                  },
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.only(left: 4, right: 2),
                                                                                    child: Icon(Icons.close, size: 16, color: isActive ? Colors.white : Colors.black),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                              if (AffichageCard == true && sousCategoriesSelectionnees.isNotEmpty)
                                                                const SizedBox(height: 10),
                                                            ],
                                                          ),
                                                          if (AffichageCard == true)
                                                            SizedBox(
                                                              height: AffichageCalc? adjustedHeight * 0.68: adjustedHeight  *0.728,
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
                                                                      spacing: 12,
                                                                      runSpacing: 12,
                                                                      children: produitsFiltres.map((p) {
                                                                        return CardProduct(
                                                                          seuil: p.seuilMin,
                                                                          text1: p.nom,
                                                                          text2: "${p.prixAchat} DA",
                                                                          couleur: Appstyle.Tblanc,
                                                                          iconPath: 'assets/icons/sidebar/produit_icon.png',
                                                                          quantite: getQuantiteDisponibleVirtuelle(p), // ✅ Utiliser la quantité virtuelle
                                                                          photo: p.photo,
                                                                          selected: produitsSelectionnes?.id == p.id,
                                                                          onTap: () => setState(() => produitsSelectionnes = p),
                                                                          onDoubleTap: () {
                                                                            setState(() => produitsSelectionnes = p);
                                                                            ouvrirDialogProduit(p);
                                                                          },
                                                                          remise: p.remise,
                                                                        );
                                                                      }).toList(),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            SizedBox(
                                                              height: AffichageCalc? adjustedHeight * 0.68: adjustedHeight  *0.728,
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
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: paddingV / 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        TitleSmall(
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
                                                        AffichageCalc ? adjustedHeight * 0.456 : adjustedHeight * 0.51,
                                                        l10n,
                                                      )
                                                          :TableauCaisse(
                                                        caissenom: caisses[selectedCaisse].nom,
                                                        produits: caisseActive.produits,
                                                        size: AffichageCalc ? adjustedHeight * 0.365 : adjustedHeight * 0.43,
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
                                                              titre_concerne: l10n.product,
                                                              message: "Stock insuffisant !\n"
                                                                  "Disponible: ${stockVirtuel.toInt()} pièce(s)\n"
                                                                  "Demandé supplément: ${quantiteSupplementaire.toInt()} pièce(s)",
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
                                                            case "NEW_CLIENT": _newClient(); break;
                                                            case "NEW_PRODUCT": _newProduct(); break;
                                                            case "QUICK_ENTRY": _openQuickEntry(); break;
                                                            case "CASH_RECEIPT": _showCashReceipt(); break;
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
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Appstyle.indigo,
            borderRadius: BorderRadius.circular(10),
            boxShadow: hover
                ? [
              BoxShadow(
                color: Appstyle.indigo.withOpacity(0.6),
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
                  size: 22,
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Appstyle.indigo,
            borderRadius: BorderRadius.circular(10),
            boxShadow: hover
                ? [
              BoxShadow(
                color: Appstyle.indigo.withOpacity(0.6),
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
                  size: 22,
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

  void initialiserStockReel(List<Produit> produits) {
    for (var produit in produits) {
      _stockReel[produit.code] = produit.quantite;
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

    print("📝 Réservation: $produitCode, Caisse: $caisseNom, Qté: $quantiteAPrelever, StockDispo: $stockDisponible");

    if (quantiteAPrelever <= stockDisponible) {
      if (!_reservations.containsKey(produitCode)) {
        _reservations[produitCode] = {};
      }

      final reservationActuelle = _reservations[produitCode]![caisseNom] ?? 0;
      _reservations[produitCode]![caisseNom] = reservationActuelle + quantiteAPrelever;

      print("✅ Réservation OK - Total réservé: ${_reservations[produitCode]![caisseNom]}");
      notifyListeners();
      return true;
    }

    print("❌ Réservation échouée - Stock insuffisant");
    return false;
  }

  void liberer(String produitCode, String caisseNom, double quantite) {
    if (_reservations.containsKey(produitCode) &&
        _reservations[produitCode]!.containsKey(caisseNom)) {

      final nouvelleQte = (_reservations[produitCode]![caisseNom] ?? 0) - quantite;

      print("🔓 Libération: $produitCode, Caisse: $caisseNom, Qté: $quantite, Nouveau total: $nouvelleQte");

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
    print("🗑️ Libération de toutes les réservations pour la caisse: $caisseNom");

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