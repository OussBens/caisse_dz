import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/TransfertMagasin.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/transfert_magasin.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
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
import '../core/theme/app_style.dart';
import '../core/utilis/constant.dart';
import '../core/widget/button/main_button.dart';
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/header_module.dart';
import '../core/widget/search_bar.dart';
import '../core/widget/side_bar.dart';
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
  List<TransfertMagasin> transfertsSelectionnes = [];
  List<Produit> produitsTest = [];

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

                            StatsCard(
                              items: [
                                StatsItem(label: l10n.stores, value: magasins.length),
                                StatsItem(
                                  label: l10n.active,
                                  value: magasins.where((m) => m.etat).length,
                                ),
                                StatsItem(
                                  label: l10n.inactive,
                                  value: magasins.where((m) => !m.etat).length,
                                ),
                              ],
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
                                  color: Appstyle.violet,
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
                                  Tab(text: l10n.stores),
                                  Tab(text: l10n.transfers),
                                ],
                              ),
                            ),

                            SizedBox(height: paddingV / 2),

                            if (currentTab == TAB_MAGASINS) ...[
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
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

                              SizedBox(height: paddingV / 2),

                              SizedBox(
                                height: adjustedHeight * 0.68,
                                child: TableauTransfertMagasinAdvanced(
                                  key: const ValueKey('transfert-magasin-table'),
                                  transferts: transfertsTest,
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
                  ],
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
      child: Row(
        children: [
          Expanded(
            child: ChampAvecLabel(
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
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ChampAvecLabel(
              width: width * 0.75,
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
          ),
        ],
      ),
    );
  }
}
