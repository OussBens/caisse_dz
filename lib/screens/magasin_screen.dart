import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/TransfertMagasin.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/transfert_magasin.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/stats_card.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/dialog/magasin/magasin_actif.dart';
import '../core/dialog/magasin/magasin_detail.dart';
import '../core/dialog/magasin/magasin_modif.dart';
import '../core/dialog/magasin/magasin_nouveau.dart';
import '../core/dialog/magasin/transfert_magasin_actif.dart';
import '../core/dialog/magasin/transfert_magasin_detail.dart';
import '../core/dialog/magasin/transfert_magasin_nouveau.dart';
import '../core/dialog/information_dialog.dart';
import '../core/tableau/magasin/tableau_magasin.dart';
import '../core/tableau/magasin/tableau_transfert_magasin.dart';
import '../core/widget/afficheur/afficheur_magasin.dart';
import '../core/widget/afficheur/afficheur_magasin_global.dart';
import '../core/widget/afficheur/afficheur_transfert_magasin.dart';
import '../core/theme/app_style.dart';
import '../core/utilis/constant.dart';
import '../core/widget/button/main_button.dart';
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/header_module.dart';
import '../core/widget/search_bar.dart';
import '../core/widget/time_date_widget.dart';
import '../core/widget/connection_status_bar.dart';
import '../core/widget/account.dart';
import '../data/constant.dart';
import '../data/models/magasin.dart';

class MagasinScreen extends StatefulWidget {
  const MagasinScreen({super.key});

  @override
  State<MagasinScreen> createState() => _MagasinScreenState();
}

class _MagasinScreenState extends State<MagasinScreen> with SingleTickerProviderStateMixin {
  static const int TAB_MAGASINS = 0;
  static const int TAB_TRANSFERTS = 1;

  late TabController _tabController;
  int currentTab = TAB_MAGASINS;

  String? selectedEtatFilter;
  bool filtresActifs = false;
  final TextEditingController _searchController = TextEditingController();

  List<Magasin> magasins = [];
  List<Magasin> magasinsFiltres = [];
  List<Magasin> magasinsSelectionnes = [];
  List<Utilisateur> utilisateursTest = [];

  List<TransfertMagasin> transfertsTest = [];
  List<TransfertMagasin> transfertsFiltres = [];
  List<TransfertMagasin> transfertsSelectionnes = [];
  List<Produit> produitsTest = [];

  // Filtres de l'onglet Transferts (indépendants de ceux de l'onglet Magasins).
  bool filtresActifsTransfert = false;
  String? selectedProduitFilterTransfert;
  String? selectedMagasinSourceFilter;
  String? selectedMagasinDestFilter;
  DateTime? dateDebutTransfert;
  DateTime? dateFinTransfert;
  String? periodeRapideTransfert;
  final TextEditingController _dateDebutCtrlTransfert = TextEditingController();
  final TextEditingController _dateFinCtrlTransfert = TextEditingController();
  bool _exportEnCours = false;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => currentTab = _tabController.index);
    });
    loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _dateDebutCtrlTransfert.dispose();
    _dateFinCtrlTransfert.dispose();
    super.dispose();
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);

    final magasin = await MagasinServices.getAllMagasins();
    final utilisateurs = await UtilisateurServices.getAllUtilisateurs();
    final transferts = await TransfertMagasinServices.getAllTransferts();
    final produits = await ProduitServices.getAllProduits();

    if (!mounted) return;

    setState(() {
      utilisateursTest = utilisateurs;
      magasins = List.from(magasin);
      transfertsTest = List.from(transferts);
      produitsTest = List.from(produits);
      if (filtresActifs) {
        appliquerFiltre();
      } else {
        magasinsFiltres = List.from(magasin);
      }
      appliquerFiltreTransfert();
      isLoading = false;
      magasinsSelectionnes.clear();
      transfertsSelectionnes.clear();
    });
  }

  bool get _filtresMagasinActifs =>
      (selectedEtatFilter != null && selectedEtatFilter!.isNotEmpty) ||
      _searchController.text.isNotEmpty;

  void appliquerFiltre() {
    final search = _searchController.text.toLowerCase();

    magasinsFiltres = magasins.where((m) {
      final etatOk = selectedEtatFilter == null ||
          selectedEtatFilter == "" ||
          (selectedEtatFilter == "Actif" && m.etat) ||
          (selectedEtatFilter == "Inactif" && !m.etat);
      final searchOk = search.isEmpty || m.searchableText.contains(search);

      return etatOk && searchOk;
    }).toList();

    setState(() {});
  }

  void supprimerFilter() {
    selectedEtatFilter = null;
    _searchController.clear();
  }

  // ──────────────────────────────────────────
  // Filtres de l'onglet Transferts
  // ──────────────────────────────────────────

  bool get _filtresTransfertActifs =>
      selectedProduitFilterTransfert != null ||
      selectedMagasinSourceFilter != null ||
      selectedMagasinDestFilter != null ||
      dateDebutTransfert != null ||
      dateFinTransfert != null ||
      periodeRapideTransfert != null;

  String? _codeMagasin(String? nom) =>
      nom == null || nom.isEmpty ? null : magasins.firstWhereOrNull((m) => m.nom == nom)?.code;

  /// Ne fait pas de setState : appelé depuis des blocs setState existants.
  void appliquerFiltreTransfert() {
    final produitCode = selectedProduitFilterTransfert == null || selectedProduitFilterTransfert!.isEmpty
        ? null
        : produitsTest.firstWhereOrNull((p) => p.nom == selectedProduitFilterTransfert)?.code;
    final sourceCode = _codeMagasin(selectedMagasinSourceFilter);
    final destCode = _codeMagasin(selectedMagasinDestFilter);
    final debut = dateDebutTransfert != null
        ? DateTime(dateDebutTransfert!.year, dateDebutTransfert!.month, dateDebutTransfert!.day)
        : null;
    final fin = dateFinTransfert != null
        ? DateTime(dateFinTransfert!.year, dateFinTransfert!.month, dateFinTransfert!.day, 23, 59, 59)
        : null;

    transfertsFiltres = transfertsTest.where((t) {
      if (produitCode != null && t.produitCode != produitCode) return false;
      if (sourceCode != null && t.magasinSourceCode != sourceCode) return false;
      if (destCode != null && t.magasinDestCode != destCode) return false;
      if (debut != null && t.date.isBefore(debut)) return false;
      if (fin != null && t.date.isAfter(fin)) return false;
      return true;
    }).toList();
  }

  void supprimerFilterTransfert() {
    selectedProduitFilterTransfert = null;
    selectedMagasinSourceFilter = null;
    selectedMagasinDestFilter = null;
    dateDebutTransfert = null;
    dateFinTransfert = null;
    periodeRapideTransfert = null;
    _dateDebutCtrlTransfert.clear();
    _dateFinCtrlTransfert.clear();
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  Future<void> _pickDateDebutTransfert() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutTransfert ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateDebutTransfert = picked;
        _dateDebutCtrlTransfert.text = _formatDate(picked);
        periodeRapideTransfert = null;
        appliquerFiltreTransfert();
      });
    }
  }

  Future<void> _pickDateFinTransfert() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinTransfert ?? dateDebutTransfert ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateFinTransfert = (dateDebutTransfert != null && picked.isBefore(dateDebutTransfert!))
            ? dateDebutTransfert
            : picked;
        _dateFinCtrlTransfert.text = _formatDate(dateFinTransfert!);
        periodeRapideTransfert = null;
        appliquerFiltreTransfert();
      });
    }
  }

  void _appliquerPeriodeRapideTransfert(String key) {
    final periode = calculerPeriodeRapide(key);
    periodeRapideTransfert = key;
    dateDebutTransfert = periode.debut;
    dateFinTransfert = periode.fin;
    _dateDebutCtrlTransfert.text = _formatDate(periode.debut);
    _dateFinCtrlTransfert.text = _formatDate(periode.fin);
    appliquerFiltreTransfert();
  }

  /// Extract : la liste affichée (filtrée si les filtres sont ouverts).
  /// Extract filtre : uniquement les lignes sélectionnées dans le tableau.
  Future<void> _exportTransfertsToExcel({required bool selectionSeulement, bool enPdf = false}) async {
    if (_exportEnCours) return;
    final l10n = AppLocalizations.of(context)!;

    final transferts = selectionSeulement
        ? transfertsSelectionnes
        : (filtresActifsTransfert ? transfertsFiltres : transfertsTest);

    if (transferts.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.transfer,
        message: selectionSeulement ? l10n.noTransferSelected : l10n.noDataToExport,
      );
      return;
    }

    setState(() => _exportEnCours = true);
    try {
      final fichier = await executerAvecSpinner(
        context,
        () => ExcelGenerator.generateTransfertsMagasinExcel(
          transferts: transferts,
          produits: produitsTest,
          magasins: magasins,
          utilisateurs: utilisateursTest,
          l10n: l10n,
        ),
      );
      if (!mounted) return;
      if (enPdf) {
        await ouvrirApercuPdfDepuisExcel(context, fichier: fichier, titre: l10n.storeTransferTab, nomFeuille: 'TransfertsMagasin');
        return;
      }
      await ouvrirApercuExcel(
        context,
        fichier: fichier,
        nomFeuille: 'TransfertsMagasin',
        titre: selectionSeulement ? "${l10n.storeTransferTab} (${l10n.selected})" : l10n.storeTransferTab,
        l10n: l10n,
      );
    } catch (e) {
      debugPrint('Excel export error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          const minHeight = Constant.minHeight;
          const minWidth = Constant.minWidth;

          final adjustedWidth = screenWidth < minWidth ? minWidth : screenWidth;
          final adjustedHeight = screenHeight < minHeight ? minHeight : screenHeight;

          final paddingV = adjustedHeight * 0.02;
          final paddingH = adjustedWidth * 0.02;

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
                                    "assets/icons/sidebar/magasin_icon.png",
                                    width: 40,
                                    color: Appstyle.violet,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.magasin,
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


                            SizedBox(height: paddingV),

                            // ✅ TAB BAR — "Magasins" / "Transferts" (le
                            // transfert de marchandise entre magasins vit ici,
                            // pas dans un module séparé de la sidebar).
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: false,
                                indicator: BoxDecoration(
                                  color: currentTab == TAB_MAGASINS ? Appstyle.violet : Appstyle.indigo,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Appstyle.gris,
                                dividerColor: Colors.transparent,
                                indicatorSize: TabBarIndicatorSize.tab,
                                padding: const EdgeInsets.all(6),
                                labelStyle: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600),
                                unselectedLabelStyle: Appstyle.textSB.copyWith(fontWeight: FontWeight.w500),
                                tabs: [
                                  Tab(
                                    icon: Image.asset(
                                      "assets/icons/sidebar/magasin_icon.png",
                                      width: 20,
                                      height: 20,
                                      color: currentTab == TAB_MAGASINS ? Colors.white : Appstyle.gris,
                                    ),
                                    text: l10n.stores,
                                  ),
                                  Tab(
                                    icon: Image.asset(
                                      "assets/icons/cardwidget/transfert_icon.png",
                                      width: 20,
                                      height: 20,
                                      color: currentTab == TAB_TRANSFERTS ? Colors.white : Appstyle.gris,
                                    ),
                                    text: l10n.storeTransferTab,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: paddingV / 2),

                            if (currentTab == TAB_MAGASINS) ...[
                            // Afficheur
                            if (magasinsSelectionnes.length == 1)
                              AfficheurMagasin(
                                magasin: magasinsSelectionnes.first,
                                transferts: transfertsTest,
                                onDetails: () {
                                  MagasinDetail(context, magasinsSelectionnes.first);
                                },
                              )
                            else
                              AfficheurMagasinGlobalWidget(
                                nombreMagasins: magasins.length,
                                nombreMagasinsActifs: magasins.where((m) => m.etat).length,
                                nombreTransferts: transfertsTest.where((t) => t.etat).length,
                                quantiteTotaleTransferee: transfertsTest.where((t) => t.etat).fold(0.0, (s, t) => s + t.quantite),
                              ),

                            SizedBox(height: paddingV / 2),

                            // Filtres & Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    MainButton(
                                      text: l10n.filter,
                                      textColor: Appstyle.violet,
                                      color: Appstyle.Tblanc,
                                      showBadge: _filtresMagasinActifs,
                                      icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                      iconColor: Appstyle.violet,
                                      onPressed: () {
                                        setState(() {
                                          filtresActifs = !filtresActifs;
                                          if (!filtresActifs) {
                                            supprimerFilter();
                                            appliquerFiltre();
                                          }
                                        });
                                      },
                                    ),
                                    SizedBox(width: paddingH / 4),
                                    if (filtresActifs)
                                      MainIconButton(
                                        color: Colors.grey.shade400,
                                        imagePath: 'assets/icons/action/supprimer_icon.png',
                                        onPressed: () {
                                          setState(() {
                                            supprimerFilter();
                                            appliquerFiltre();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    MainIconButton(
                                      imagePath: "assets/icons/action/detail_icon.png",
                                      color: Appstyle.violet,
                                      onPressed: () async {
                                        if (magasinsSelectionnes.length == 1) {
                                          MagasinDetail(context, magasinsSelectionnes.first);
                                        } else if (magasinsSelectionnes.isEmpty) {
                                          await InformationDialog(
                                            context: context,
                                            titre_type_message: l10n.information,
                                            titre_concerne: l10n.magasin,
                                            message: l10n.noStoreSelected,
                                          );
                                        } else {
                                          await InformationDialog(
                                            context: context,
                                            titre_type_message: l10n.information,
                                            titre_concerne: l10n.magasin,
                                            message: l10n.selectSingleStoreForDetail,
                                          );
                                        }
                                      },
                                    ),
                                    SizedBox(width: paddingH / 4),
                                    MainIconButton(
                                      imagePath: "assets/icons/action/supprimer_icon.png",
                                      color: Appstyle.gris,
                                      onPressed: () async {
                                        if (magasinsSelectionnes.isEmpty) {
                                          await InformationDialog(
                                            context: context,
                                            titre_type_message: l10n.information,
                                            titre_concerne: l10n.magasin,
                                            message: l10n.noStoreSelected,
                                          );
                                          return;
                                        }

                                        final contientSysteme = magasinsSelectionnes.any(
                                          (m) => ListsConst.nonSupprimablePacks.any(
                                            (p) => p.nom == "Magasin" && p.code == m.code,
                                          ),
                                        );

                                        if (contientSysteme) {
                                          await InformationDialog(
                                            context: context,
                                            titre_type_message: l10n.information,
                                            titre_concerne: l10n.magasin,
                                            message: l10n.cannotDeleteSystemStore,
                                          );
                                        } else {
                                          await AnnulerMagasin(context, magasinsSelectionnes);
                                          await loadAllData();
                                        }
                                      },
                                    ),
                                    SizedBox(width: paddingH / 4),
                                    MainIconButton(
                                      imagePath: "assets/icons/action/edit_icon.png",
                                      color: Appstyle.blueC,
                                      onPressed: () async {
                                        if (magasinsSelectionnes.length == 1) {
                                          final m = magasinsSelectionnes.first;
                                          final estSysteme = ListsConst.nonSupprimablePacks.any(
                                            (p) => p.nom == "Magasin" && p.code == m.code,
                                          );

                                          if (estSysteme) {
                                            await InformationDialog(
                                              context: context,
                                              titre_type_message: l10n.information,
                                              titre_concerne: l10n.magasin,
                                              message: l10n.cannotModifySystemStore,
                                            );
                                          } else {
                                            await MagasinModif(context, m);
                                            await loadAllData();
                                          }
                                        } else if (magasinsSelectionnes.isEmpty) {
                                          await InformationDialog(
                                            context: context,
                                            titre_type_message: l10n.information,
                                            titre_concerne: l10n.magasin,
                                            message: l10n.noStoreSelected,
                                          );
                                        } else {
                                          await InformationDialog(
                                            context: context,
                                            titre_type_message: l10n.information,
                                            titre_concerne: l10n.magasin,
                                            message: l10n.selectSingleStoreToModify,
                                          );
                                        }
                                      },
                                    ),
                                    SizedBox(width: paddingH / 4),
                                    MainButton(
                                      text: l10n.newWord,
                                      color: Appstyle.crevete,
                                      onPressed: () async {
                                        await MagasinNouveau(context);
                                        await loadAllData();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (filtresActifs)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: paddingV),
                                child: _filtreMagasin(setState, adjustedWidth, l10n),
                              ),

                            if (!filtresActifs) SizedBox(height: paddingV / 2),

                            SizedBox(
                              height: adjustedHeight * 0.68,
                              child: TableauMagasinAdvanced(
                                key: const ValueKey('magasin-table'),
                                magasins: magasinsFiltres,
                                utilisateurs: utilisateursTest,
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    magasinsSelectionnes = selection;
                                  });
                                },
                              ),
                            ),
                            ] else ...[
                              // ──────────────────────────────────────────
                              // Onglet Transferts (marchandise entre magasins)
                              // ──────────────────────────────────────────
                              // Afficheur
                              if (transfertsSelectionnes.length == 1)
                                AfficheurTransfertMagasin(
                                  transfert: transfertsSelectionnes.first,
                                  produits: produitsTest,
                                  magasins: magasins,
                                  onDetails: () {
                                    TransfertMagasinDetail(
                                      context,
                                      transfertsSelectionnes.first,
                                      produits: produitsTest,
                                      magasins: magasins,
                                    );
                                  },
                                )
                              else
                                AfficheurMagasinGlobalWidget(
                                  nombreMagasins: magasins.length,
                                  nombreMagasinsActifs: magasins.where((m) => m.etat).length,
                                  nombreTransferts: transfertsTest.where((t) => t.etat).length,
                                  quantiteTotaleTransferee: transfertsTest.where((t) => t.etat).fold(0.0, (s, t) => s + t.quantite),
                                ),

                              SizedBox(height: paddingV / 2),

                              // Filtres & Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      MainButton(
                                        text: l10n.filter,
                                        textColor: Appstyle.violet,
                                        color: Appstyle.Tblanc,
                                        showBadge: _filtresTransfertActifs,
                                        icon: filtresActifsTransfert ? Icons.visibility_off : Icons.visibility,
                                        iconColor: Appstyle.violet,
                                        onPressed: () {
                                          setState(() {
                                            filtresActifsTransfert = !filtresActifsTransfert;
                                            if (!filtresActifsTransfert) {
                                              supprimerFilterTransfert();
                                              appliquerFiltreTransfert();
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(width: paddingH / 4),
                                      if (filtresActifsTransfert)
                                        MainIconButton(
                                          color: Colors.grey.shade400,
                                          imagePath: 'assets/icons/action/supprimer_icon.png',
                                          onPressed: () {
                                            setState(() {
                                              supprimerFilterTransfert();
                                              appliquerFiltreTransfert();
                                            });
                                          },
                                        ),
                                      if (filtresActifsTransfert)
                                        SizedBox(width: paddingH / 4),
                                      MainButton(
                                        text: l10n.extract,
                                        textColor: Colors.green,
                                        iconColor: Colors.green,
                                        color: Appstyle.Tblanc,
                                        icon: Icons.download,
                                        loading: _exportEnCours,
                                        onPressed: () async {
                                          await _exportTransfertsToExcel(selectionSeulement: false);
                                        },
                                      ),
                                      SizedBox(width: paddingH / 4),
                                      MainButton(
                                        text: l10n.extractPdf,
                                        textColor: Colors.red,
                                        iconColor: Colors.red,
                                        color: Appstyle.Tblanc,
                                        icon: Icons.picture_as_pdf,
                                        onPressed: () async {
                                          await _exportTransfertsToExcel(selectionSeulement: false, enPdf: true);
                                        },
                                      ),
                                      SizedBox(width: paddingH / 4),
                                      MainIconButton(
                                        imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                        color: Colors.orange,
                                        onPressed: () async {
                                          await _exportTransfertsToExcel(selectionSeulement: true);
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                  MainIconButton(
                                    imagePath: "assets/icons/action/detail_icon.png",
                                    color: Appstyle.violet,
                                    onPressed: () async {
                                      if (transfertsSelectionnes.length == 1) {
                                        TransfertMagasinDetail(
                                          context,
                                          transfertsSelectionnes.first,
                                          produits: produitsTest,
                                          magasins: magasins,
                                        );
                                      } else if (transfertsSelectionnes.isEmpty) {
                                        await InformationDialog(
                                          context: context,
                                          titre_type_message: l10n.information,
                                          titre_concerne: l10n.transfer,
                                          message: l10n.noTransferSelected,
                                        );
                                      } else {
                                        await InformationDialog(
                                          context: context,
                                          titre_type_message: l10n.information,
                                          titre_concerne: l10n.transfer,
                                          message: l10n.selectSingleTransferForDetail,
                                        );
                                      }
                                    },
                                  ),
                                  SizedBox(width: paddingH / 4),
                                  MainIconButton(
                                    imagePath: "assets/icons/action/supprimer_icon.png",
                                    color: Appstyle.gris,
                                    onPressed: () async {
                                      if (transfertsSelectionnes.isEmpty) {
                                        await InformationDialog(
                                          context: context,
                                          titre_type_message: l10n.information,
                                          titre_concerne: l10n.transfer,
                                          message: l10n.noTransferSelected,
                                        );
                                        return;
                                      }
                                      await AnnulerTransfertMagasin(
                                        context,
                                        transfertsSelectionnes,
                                        produits: produitsTest,
                                      );
                                      await loadAllData();
                                    },
                                  ),
                                  SizedBox(width: paddingH / 4),
                                  MainIconButton(
                                    imagePath: "assets/icons/action/edit_icon.png",
                                    color: Appstyle.blueC,
                                    onPressed: () async {
                                      if (transfertsSelectionnes.length == 1) {
                                        await TransfertMagasinModif(context, transfertsSelectionnes.first);
                                        await loadAllData();
                                      } else {
                                        await InformationDialog(
                                          context: context,
                                          titre_type_message: l10n.information,
                                          titre_concerne: l10n.transfer,
                                          message: transfertsSelectionnes.isEmpty
                                              ? l10n.noTransferSelected
                                              : l10n.selectSingleTransferToModify,
                                        );
                                      }
                                    },
                                  ),
                                  SizedBox(width: paddingH / 4),
                                  MainButton(
                                    text: l10n.newWord,
                                    color: Appstyle.crevete,
                                    onPressed: () async {
                                      await TransfertMagasinNouveau(context);
                                      await loadAllData();
                                    },
                                  ),
                                    ],
                                  ),
                                ],
                              ),

                              if (filtresActifsTransfert)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: paddingV),
                                  child: _filtreTransfert(setState, adjustedWidth / 3, l10n),
                                ),

                              if (!filtresActifsTransfert) SizedBox(height: paddingV / 2),

                              SizedBox(
                                height: adjustedHeight * 0.68,
                                child: TableauTransfertMagasinAdvanced(
                                  key: const ValueKey('transfert-magasin-table'),
                                  transferts: transfertsFiltres,
                                  produits: produitsTest,
                                  magasins: magasins,
                                  utilisateurs: utilisateursTest,
                                  onSelectionChanged: (selection) {
                                    setState(() {
                                      transfertsSelectionnes = selection;
                                    });
                                  },
                                ),
                              ),
                            ],
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

  Widget _filtreMagasin(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n) {
    return SectionDecorationFiltre(
      padding: const EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: LigneFiltreTiers(
        children: [
          ChampAvecLabel(
            label: l10n.etat,
            child: TextListe(
              value: selectedEtatFilter,
              items: [l10n.active, l10n.inactive],
              onChanged: (v) {
                setState(() {
                  selectedEtatFilter = v == l10n.active ? "Actif" : (v == l10n.inactive ? "Inactif" : null);
                  appliquerFiltre();
                });
              },
            ),
          ),
          ChampAvecLabel(
            label: l10n.search,
            child: SearchField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {
                  appliquerFiltre();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// [width] = tiers de la largeur écran, comme les autres filtres à période
  /// rapide (Retour, Transfert caisse…).
  Widget _filtreTransfert(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n) {
    final nomsMagasins = magasins.map((m) => m.nom).toList();

    return SectionDecorationFiltre(
      padding: const EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Produit / magasin source / magasin destination
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.produit,
                  child: TextListe(
                    value: selectedProduitFilterTransfert,
                    items: produitsTest.map((p) => p.nom).toSet().toList(),
                    clearable: true,
                    onChanged: (v) {
                      setState(() {
                        selectedProduitFilterTransfert = (v == null || v.isEmpty) ? null : v;
                        appliquerFiltreTransfert();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.source,
                  child: TextListe(
                    value: selectedMagasinSourceFilter,
                    items: nomsMagasins,
                    clearable: true,
                    onChanged: (v) {
                      setState(() {
                        selectedMagasinSourceFilter = (v == null || v.isEmpty) ? null : v;
                        appliquerFiltreTransfert();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.destination,
                  child: TextListe(
                    value: selectedMagasinDestFilter,
                    items: nomsMagasins,
                    clearable: true,
                    onChanged: (v) {
                      setState(() {
                        selectedMagasinDestFilter = (v == null || v.isEmpty) ? null : v;
                        appliquerFiltreTransfert();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Du / au / période rapide
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
                label: l10n.from,
                child: TextDate(
                  hint: l10n.startDate,
                  controller: _dateDebutCtrlTransfert,
                  onTap: _pickDateDebutTransfert,
                ),
              ),
              ChampAvecLabel(
                label: l10n.to,
                child: TextDate(
                  hint: l10n.endDate,
                  enabled: dateDebutTransfert != null,
                  controller: _dateFinCtrlTransfert,
                  onTap: _pickDateFinTransfert,
                ),
              ),
              ChampPeriodeRapide(
                l10n: l10n,
                value: periodeRapideTransfert,
                onSelected: (v) {
                  setState(() => _appliquerPeriodeRapideTransfert(v));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
