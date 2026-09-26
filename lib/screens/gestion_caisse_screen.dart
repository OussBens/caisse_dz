import 'package:caisse_dz/core/dialog/gestion_caisse/gestion_caisse_nouveau.dart';
import 'package:caisse_dz/core/dialog/gestion_caisse/gestion_caisse_detail.dart';
import 'package:caisse_dz/core/dialog/gestion_caisse/gestion_caisse_modif.dart';
import 'package:caisse_dz/core/dialog/gestion_caisse/gestion_caisse_actif.dart';

import 'package:caisse_dz/core/dialog/transfert/transfert_nouveau.dart';
import 'package:caisse_dz/core/dialog/transfert/transfert_detail.dart';
import 'package:caisse_dz/core/dialog/transfert/transfert_actif.dart';
import 'package:caisse_dz/core/dialog/transfert/transfert_modif.dart';

import 'package:caisse_dz/core/dialog/cloture_caisse/cloture_caisse_detail.dart';
import 'package:caisse_dz/core/dialog/cloture_caisse/cloture_caisse_nouveau.dart';
import 'package:caisse_dz/core/dialog/cloture_caisse/export_fiscal_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_session.dart';

import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/TransfertCaisse.dart';
import 'package:caisse_dz/Services/ClotureCaisse.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:collection/collection.dart';

import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/tableau/gestion_caisse/tableau_gestion_caisse.dart';
import 'package:caisse_dz/core/tableau/transfert/tableau_transfert.dart';
import 'package:caisse_dz/core/tableau/cloture_caisse/tableau_cloture_caisse.dart';
import 'package:caisse_dz/core/tableau/caisse_session/tableau_caisse_session.dart';
import 'package:caisse_dz/core/tableau/mouvement_caisse/tableau_mouvement_caisse.dart';
import 'package:caisse_dz/core/tableau/mouvement_caisse/mouvement_caisse_source.dart';
import 'package:caisse_dz/data/models/cloture_caisse.dart';
import 'package:caisse_dz/data/models/caisse_session.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_gestion_caisse.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_gestion_caisse_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_transfert.dart';

import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';

import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';
import 'package:caisse_dz/core/widget/account.dart';

import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/transfert.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';

import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../core/dialog/information_dialog.dart';
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/date_champ.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/fourchette._widget.dart';
import '../core/widget/search_bar.dart';
import '../core/widget/section_decoration_filtre.dart';
import '../data/constant.dart';

class GestionCaisseScreen extends StatefulWidget {
  const GestionCaisseScreen({super.key});

  @override
  State<GestionCaisseScreen> createState() => _GestionCaisseScreenState();
}

class _GestionCaisseScreenState extends State<GestionCaisseScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_CAISSE = 0;
  static const int TAB_TRANSFERT = 1;
  static const int TAB_CLOTURE = 2;
  static const int TAB_MOUVEMENT = 3;
  static const int TAB_SESSION = 4;

  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();

  DateTime? dateDebut;
  DateTime? dateFin;

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  int nombretransfert = 4;

  double? montantMin;
  double? montantMax;
  bool filtresActifs = false;

  String? selectedEtatFilter;
  String? periodeRapide;

  String? selectedCaisseSourceFilter;
  String? selectedCaisseDestinaFilter;

  List<CaisseGestion> caisses = [];
  List<CaisseGestion> caissesSelectionnees = [];
  List<CaisseGestion> Caissesfiltre = [];

  List<TransfertCaisse> transferts = [];
  List<TransfertCaisse> transfertsSelectionnees = [];
  List<TransfertCaisse> transfertsfiltre = [];
  List<Utilisateur> utilisateursTest = [];

  List<ClotureCaisse> clotures = [];
  List<ClotureCaisse> cloturesSelectionnees = [];

  List<CaisseSession> sessions = [];
  List<CaisseSession> sessionsSelectionnees = [];
  List<CaisseMouvement> mouvementsCaisse = [];
  List<Client> clientsTest = [];
  List<Fournisseur> fournisseursTest = [];
  String? selectedSessionFiltreCode;

  final TextEditingController _searchControllerCaisse = TextEditingController();
  final TextEditingController _searchControllertransfert = TextEditingController();

  Future<void> _loadAllData() async {
    final loadedCaisses = await GCServices.getAllCaisses();
    final loadedTransferts = await TransfertcaisseServices.getAllTransfertcaisse();
    final loadedUtilisateurs = await UtilisateurServices.getAllUtilisateurs();
    final loadedClotures = await ClotureCaisseServices.getAllClotures();
    final loadedSessions = await CaisseSessionServices.getAllSessions();
    final loadedMouvements = await CaisseSessionServices.getAllMouvements();
    final loadedClients = await ClientServices.getAllClients();
    final loadedFournisseurs = await FournisseurServices.getAllFournisseurs();

    setState(() {
      caisses = loadedCaisses;
      transferts = loadedTransferts;
      utilisateursTest = loadedUtilisateurs;
      clotures = loadedClotures;
      sessions = loadedSessions;
      mouvementsCaisse = loadedMouvements;
      clientsTest = loadedClients;
      fournisseursTest = loadedFournisseurs;
      nombretransfert = loadedTransferts.length;
      Caissesfiltre = loadedCaisses;
      transfertsfiltre = loadedTransferts;
      caissesSelectionnees.clear();
      transfertsSelectionnees.clear();
      cloturesSelectionnees.clear();
      sessionsSelectionnees.clear();
    });
  }

  void viderliste() {
    transfertsSelectionnees.clear();
    caissesSelectionnees.clear();
    cloturesSelectionnees.clear();
    sessionsSelectionnees.clear();
  }

  void appliquefiltreCaisse() {
    final searchText = _searchControllerCaisse.text.toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        Caissesfiltre = List.from(caisses);
      } else {
        Caissesfiltre = caisses.where((c) {
          return c.searchableText.contains(searchText);
        }).toList();
      }
    });
  }

  void appliquerFiltre() {
    final searchText = _searchControllertransfert.text.toLowerCase();

    setState(() {
      transfertsfiltre = transferts.where((p) {
        final caissesource = selectedCaisseSourceFilter == null ||
            selectedCaisseSourceFilter!.isEmpty ||
            caisses.any((c) => c.code == p.caisseExpCode && c.nomCaisse == selectedCaisseSourceFilter);

        final caissedestina = selectedCaisseDestinaFilter == null ||
            selectedCaisseDestinaFilter!.isEmpty ||
            caisses.any((c) => c.code == p.caisseDestCode && c.nomCaisse == selectedCaisseDestinaFilter);

        final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);

        final montantOk = (montantMin == null || p.montant >= montantMin!) &&
            (montantMax == null || p.montant <= montantMax!);

        final etatOk = selectedEtatFilter == null ||
            selectedEtatFilter == "" ||
            (selectedEtatFilter == "Actif" && p.etat) ||
            (selectedEtatFilter == "Inactif" && !p.etat);

        final dateOk = () {
          if (dateDebut == null && dateFin == null) return true;
          if (p.dateTransfert == null) return false;

          final d = p.dateTransfert;

          final debut = dateDebut != null
              ? DateTime(dateDebut!.year, dateDebut!.month, dateDebut!.day)
              : null;

          final fin = dateFin != null
              ? DateTime(dateFin!.year, dateFin!.month, dateFin!.day, 23, 59, 59)
              : null;

          if (debut != null && d.isBefore(debut)) return false;
          if (fin != null && d.isAfter(fin)) return false;

          return true;
        }();

        return caissesource && caissedestina && montantOk && etatOk && searchOk && dateOk;
      }).toList();

      if (selectedCaisseSourceFilter == null &&
          selectedCaisseDestinaFilter == null &&
          montantMin == null &&
          montantMax == null &&
          selectedEtatFilter == null &&
          dateDebut == null &&
          dateFin == null &&
          searchText.isEmpty) {
        transfertsfiltre = List.from(transferts);
      }
    });
  }

  Future<void> _pickDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFin ?? dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFin = picked;

        if (dateDebut != null && picked.isBefore(dateDebut!)) {
          dateFin = dateDebut;
        }

        _dateFinCtrl.text = _formatDate(dateFin!);
        periodeRapide = null;
        appliquerFiltre();
      });
    }
  }

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebut = picked;
        _dateDebutCtrl.text = _formatDate(picked);
        periodeRapide = null;
        appliquerFiltre();
      });
    }
  }

  void _appliquerPeriodeRapide(String p, AppLocalizations l10n) {
    final periode = calculerPeriodeRapide(p);
    dateDebut = periode.debut;
    dateFin = periode.fin;

    _dateDebutCtrl.text = _formatDate(dateDebut!);
    _dateFinCtrl.text = _formatDate(dateFin!);

    appliquerFiltre();
  }

  void supprimerFilter() {
    selectedCaisseDestinaFilter = null;
    selectedCaisseSourceFilter = null;
    montantMax = null;
    montantMin = null;
    selectedEtatFilter = null;
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
    _searchControllertransfert.clear();
  }

  // ✅ Vrai si au moins un champ de filtre transfert est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresTransfertActifs =>
      selectedCaisseSourceFilter != null ||
      selectedCaisseDestinaFilter != null ||
      montantMin != null ||
      montantMax != null ||
      selectedEtatFilter != null ||
      dateDebut != null ||
      dateFin != null ||
      periodeRapide != null ||
      _searchControllertransfert.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          viderliste();
        });
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  // ---------------- STATISTIQUES ----------------
  int getTotalCaisses() => caisses.length;
  int getCaissesActives() => caisses.where((c) => c.etat).length;
  int getCaissesInactives() => caisses.where((c) => !c.etat).length;

  int getTotalTransferts() => transferts.length;

  double getTotalMontantTransferts() =>
      transferts.where((t) => t.etat).fold(0.0, (s, t) => s + t.montant);

  TransfertCaisse? _grandTransfert() {
    final actifs = transferts.where((t) => t.etat).toList();
    if (actifs.isEmpty) return null;
    return actifs.reduce((a, b) => a.montant >= b.montant ? a : b);
  }

  double getMontantGrandTransfert() => _grandTransfert()?.montant ?? 0;
  String? getCodeGrandTransfert() => _grandTransfert()?.code;

  // Lignes affichables pour l'onglet "Mouvements" : mouvements actifs,
  // filtrés par session si une est choisie (via le filtre ou le drill-down
  // depuis l'onglet Sessions), triés par date.
  List<LigneMouvementCaisse> _lignesMouvementCaisse() {
    final filtres = mouvementsCaisse.where((m) {
      if (!m.etat) return false;
      if (selectedSessionFiltreCode != null && m.sessionCode != selectedSessionFiltreCode) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return List.generate(filtres.length, (i) {
      final m = filtres[i];
      final entrant = m.sens.toLowerCase() == 'entrée';
      return LigneMouvementCaisse(
        numero: i + 1,
        date: m.date,
        codeVersement: m.code,
        type: ListsConst.labelTypeMouvementCaisse(m.type),
        codeOperation: m.codeOperation ?? '-',
        nomClient: m.clientCode != null
            ? (clientsTest.firstWhereOrNull((c) => c.code == m.clientCode)?.nom ?? m.clientCode!)
            : '-',
        nomFournisseur: m.fournisseurCode != null
            ? (fournisseursTest.firstWhereOrNull((f) => f.code == m.fournisseurCode)?.nom ?? m.fournisseurCode!)
            : '-',
        montantEntree: entrant ? m.montant : 0,
        montantSortie: entrant ? 0 : m.montant,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final userCode = auth.userCode ?? '';

    // Check if RTL (Arabic)
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;

    // ✅ Couleurs des tabs
    final tabColors = [
      Appstyle.violet,
      Appstyle.indigo,
      Appstyle.crevete,
      Appstyle.blueC,
      Appstyle.green,
    ];
    final Color headerColor = tabColors[currentTab];

    // ✅ Noms des tabs
    final tabNames = [
      l10n.gestionCaisse,
      l10n.transfert,
      l10n.cashRegisterClosures,
      l10n.cashMovementsTab,
      l10n.cashSessionsTab,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/caisse_icon.png',
      'assets/icons/cardwidget/transfert_icon.png',
      'assets/icons/sidebar/caisse_icon.png',
      'assets/icons/sidebar/caisse_icon.png',
      'assets/icons/sidebar/caisse_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      getTotalCaisses().toString(),
      nombretransfert.toString(),
      clotures.length.toString(),
      mouvementsCaisse.length.toString(),
      sessions.length.toString(),
    ];

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: Directionality(
        textDirection: textDirection,
        child: LayoutBuilder(
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: minWidth,
                  minHeight: minHeight,
                ),
                child: SizedBox(
                  width: adjustedWidth,
                  height: adjustedHeight,
                    child: Row(
                      textDirection: textDirection,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------------------- SIDEBAR -------------------
                        SideBarWidget(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                /// HEADER
                                HeaderModule(
                                  gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                  child: Row(
                                    textDirection: textDirection,
                                    children: [
                                      /// -------- LEFT (Icon + Title)
                                      Row(
                                        textDirection: textDirection,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            "assets/icons/sidebar/caisse_icon.png",
                                            width: 40,
                                            color: headerColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              Text(
                                                l10n.gestionCaisse,
                                                style: Appstyle.textXLB.copyWith(
                                                  color: headerColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 15),
                                              Text(
                                                "(${tabNames[currentTab]})",
                                                style: Appstyle.textXLB.copyWith(
                                                  color: headerColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      /// -------- RIGHT (Time + Account)
                                      Row(
                                        textDirection: textDirection,
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

                                /// ✅ TAB BAR (remplace les CardWidget)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
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
                                      color: headerColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Appstyle.gris,
                                    dividerColor: Colors.transparent,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    padding: const EdgeInsets.all(6),
                                    labelStyle: Appstyle.textXS.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    unselectedLabelStyle: Appstyle.textXS.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    tabs: List.generate(5, (index) {
                                      final isSelected = currentTab == index;
                                      return Tab(
                                        icon: Container(
                                          width: 24,
                                          height: 24,
                                          child: Image.asset(
                                            tabIcons[index],
                                            width: 20,
                                            height: 20,
                                            color: isSelected ? Colors.white : Appstyle.gris,
                                          ),
                                        ),
                                        text: "${tabNames[index]} (${tabCounts[index]})",
                                      );
                                    }),
                                  ),
                                ),

                                SizedBox(height: paddingV / 2),

                                // ═══════════════════════════════════════════════════════════════════════════════
                                // SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
                                // ═══════════════════════════════════════════════════════════════════════════════

                                // ──────────────────────────────────────────────────────────────
                                // 1. CAS CAISSE (currentTab == TAB_CAISSE)
                                // ──────────────────────────────────────────────────────────────
                                if (currentTab == TAB_CAISSE)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (caissesSelectionnees.length == 1)
                                        AfficheurCaisseGestion(
                                          caisse: caissesSelectionnees.first,
                                          onDetails: () {
                                            CaisseGestionDetail(context, caissesSelectionnees.first);
                                          },
                                        )
                                      else
                                        AfficheurGestionCaisseGlobalWidget(
                                          nombreCaisses: getTotalCaisses(),
                                          nombreTransferts: getTotalTransferts(),
                                          totalTransferts: getTotalMontantTransferts(),
                                          montantGrandTransfert: getMontantGrandTransfert(),
                                          codeGrandTransfert: getCodeGrandTransfert(),
                                        ),

                                      SizedBox(height: paddingV / 2),

                                      // Actions - Style FournisseurScreen
                                      Row(
                                        textDirection: textDirection,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          filtreCaisse(setState, l10n, isRTL),
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              MainIconButton(
                                                imagePath: "assets/icons/action/detail_icon.png",
                                                color: Appstyle.violet,
                                                onPressed: () async {
                                                  if (caissesSelectionnees.length == 1) {
                                                    CaisseGestionDetail(context, caissesSelectionnees.first);
                                                  } else if (caissesSelectionnees.isEmpty) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.caisse,
                                                      message: l10n.noCashRegisterSelected ?? "Aucune caisse sélectionnée !",
                                                    );
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.caisse,
                                                      message: l10n.selectSingleCashRegisterForDetail ?? "Veuillez sélectionner une seule caisse pour afficher le détail !",
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainIconButton(
                                                imagePath: "assets/icons/action/supprimer_icon.png",
                                                color: Appstyle.gris,
                                                onPressed: () async {
                                                  if (caissesSelectionnees.isNotEmpty) {
                                                    bool contientNonSupprimable = caissesSelectionnees.any(
                                                          (caisse) => ListsConst.nonSupprimablePacks.any(
                                                            (p) => p.nom == "Caisse" && p.code == caisse.code,
                                                      ),
                                                    );

                                                    if (contientNonSupprimable) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.caisse,
                                                        message: l10n.cannotDeleteSystemCashRegister ?? "Impossible de supprimer cette caisse (système) !",
                                                      );
                                                    } else {
                                                      await AnnulerCaisseGestion(context, caissesSelectionnees);
                                                      await _loadAllData();
                                                    }
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.caisse,
                                                      message: l10n.noCashRegisterSelected ?? "Aucune caisse sélectionnée !",
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainIconButton(
                                                imagePath: "assets/icons/action/edit_icon.png",
                                                color: Appstyle.blueC,
                                                onPressed: () async {
                                                  if (caissesSelectionnees.length == 1) {
                                                    bool contientNonSupprimable = caissesSelectionnees.any(
                                                          (caisse) => ListsConst.nonSupprimablePacks.any(
                                                            (p) => p.nom == "Caisse" && p.code == caisse.code,
                                                      ),
                                                    );

                                                    if (contientNonSupprimable) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.caisse,
                                                        message: l10n.cannotModifySystemCashRegister ?? "Impossible de modifier cette caisse (système) !",
                                                      );
                                                    } else {
                                                      await CaisseGestionModif(context, caissesSelectionnees.first);
                                                      await _loadAllData();
                                                    }
                                                  } else if (caissesSelectionnees.isEmpty) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.caisse,
                                                      message: l10n.noCashRegisterSelected ?? "Aucune caisse sélectionnée !",
                                                    );
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.caisse,
                                                      message: l10n.selectSingleCashRegisterToModify ?? "Veuillez sélectionner une seule caisse pour modifier !",
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainButton(
                                                text: l10n.newCashRegister ?? "Nouvelle Caisse",
                                                color: Appstyle.crevete,
                                                onPressed: () async {
                                                  await CaisseGestionNouveau(context);
                                                  await _loadAllData();
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: paddingV / 4),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.7,
                                        child: TableauCaisseGestionAdvanced(
                                          caisses: Caissesfiltre,
                                          key: ValueKey(Caissesfiltre),
                                          utilisateurs: utilisateursTest,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              caissesSelectionnees = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 2. CAS TRANSFERT (currentTab == TAB_TRANSFERT)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_TRANSFERT)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (transfertsSelectionnees.length == 1)
                                        AfficheurTransfert(
                                          transfert: transfertsSelectionnees.first,
                                          onDetails: () {
                                            TransfertCaisseDetail(context, transfertsSelectionnees.first);
                                          },
                                        )
                                      else
                                        AfficheurGestionCaisseGlobalWidget(
                                          nombreCaisses: getTotalCaisses(),
                                          nombreTransferts: getTotalTransferts(),
                                          totalTransferts: getTotalMontantTransferts(),
                                          montantGrandTransfert: getMontantGrandTransfert(),
                                          codeGrandTransfert: getCodeGrandTransfert(),
                                        ),

                                      SizedBox(height: paddingV / 2),

                                      // Filtres & Actions - Style FournisseurScreen
                                      Row(
                                        textDirection: textDirection,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Button afficher et masquer les filtres
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              MainButton(
                                                text: l10n.filter,
                                                textColor: Appstyle.violet,
                                                color: Appstyle.Tblanc,
                                                icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                iconColor: Appstyle.violet,
                                                showBadge: _filtresTransfertActifs,
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
                                              if (filtresActifs)
                                                SizedBox(width: paddingH / 4),
                                              MainButton(
                                                text: l10n.extract,
                                                textColor: Colors.green,
                                                iconColor: Colors.green,
                                                color: Appstyle.Tblanc,
                                                icon: Icons.download,
                                                onPressed: () async {
                                                  // await _exportCurrentModuleToExcel();
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainIconButton(
                                                imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                color: Colors.orange,
                                                onPressed: () async {
                                                  // await _exportSelectedToExcel();
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              MainIconButton(
                                                imagePath: "assets/icons/action/detail_icon.png",
                                                color: Appstyle.violet,
                                                onPressed: () async {
                                                  if (transfertsSelectionnees.length == 1) {
                                                    TransfertCaisseDetail(context, transfertsSelectionnees.first);
                                                  } else if (transfertsSelectionnees.isEmpty) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.transfert,
                                                      message: l10n.noTransferSelected ?? "Aucun transfert sélectionné !",
                                                    );
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.transfert,
                                                      message: l10n.selectSingleTransferForDetail ?? "Veuillez sélectionner un seul transfert pour afficher le détail !",
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainIconButton(
                                                imagePath: "assets/icons/action/supprimer_icon.png",
                                                color: Appstyle.gris,
                                                onPressed: () async {
                                                  if (transfertsSelectionnees.isNotEmpty) {
                                                    await AnnulerTransfertCaisse(context, transfertsSelectionnees);
                                                    await _loadAllData();
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.transfert,
                                                      message: l10n.noTransferSelected ?? "Aucun transfert sélectionné !",
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainIconButton(
                                                imagePath: "assets/icons/action/edit_icon.png",
                                                color: Appstyle.blueC,
                                                onPressed: () async {
                                                  if (transfertsSelectionnees.length == 1) {
                                                    await TransfertCaisseModif(context, transfertsSelectionnees.first);
                                                    await _loadAllData();
                                                  } else if (transfertsSelectionnees.isEmpty) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.transfert,
                                                      message: l10n.noTransferSelected ?? "Aucun transfert sélectionné !",
                                                    );
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.transfert,
                                                      message: l10n.selectSingleTransferToModify ?? "Veuillez sélectionner un seul transfert pour modifier !",
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainButton(
                                                text: l10n.newTransfer ?? "Nouveau Transfert",
                                                color: Appstyle.crevete,
                                                onPressed: () async {
                                                  await TransfertCaisseNouveau(context);
                                                  await _loadAllData();
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Filtres
                                      if (filtresActifs)
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: paddingV / 2),
                                          child: filtreTransfert(setState, adjustedWidth, l10n, translator, isRTL),
                                        ),

                                      SizedBox(height: paddingV),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.7,
                                        child: TableauTransfertCaisseAdvanced(
                                          transferts: transfertsfiltre,
                                          caisses: caisses,
                                          key: ValueKey(transfertsfiltre),
                                          utilisateurs: utilisateursTest,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              transfertsSelectionnees = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 3. CAS CLOTURE (currentTab == TAB_CLOTURE)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_CLOTURE)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                        child: Row(
                                          textDirection: textDirection,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            MainIconButton(
                                              imagePath: "assets/icons/action/detail_icon.png",
                                              color: Appstyle.violet,
                                              onPressed: () async {
                                                if (cloturesSelectionnees.length == 1) {
                                                  ClotureCaisseDetail(
                                                    context,
                                                    cloturesSelectionnees.first,
                                                    caisses: caisses,
                                                    utilisateurs: utilisateursTest,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.cashRegisterClosures,
                                                    message: l10n.selectSingleCartForDetail,
                                                  );
                                                }
                                              },
                                            ),
                                            Row(
                                              textDirection: textDirection,
                                              children: [
                                                MainButton(
                                                  text: l10n.fiscalControlExport,
                                                  icon: Icons.verified_outlined,
                                                  color: Appstyle.indigo,
                                                  onPressed: () => ExportFiscalDialog(context),
                                                ),
                                                const SizedBox(width: 10),
                                                MainButton(
                                                  text: l10n.newClosure,
                                                  icon: Icons.lock_outline,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await ClotureCaisseNouveau(context);
                                                    await _loadAllData();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: paddingV / 2),
                                      clotures.isEmpty
                                          ? Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(32),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(l10n.noClosuresYet, style: Appstyle.textSB),
                                              ),
                                            )
                                          : SizedBox(
                                              height: adjustedHeight * 0.7,
                                              child: TableauClotureCaisseAdvanced(
                                                key: ValueKey(clotures),
                                                clotures: clotures,
                                                caisses: caisses,
                                                utilisateurs: utilisateursTest,
                                                onSelectionChanged: (selection) {
                                                  setState(() {
                                                    cloturesSelectionnees = selection;
                                                  });
                                                },
                                              ),
                                            ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 4. CAS MOUVEMENTS (currentTab == TAB_MOUVEMENT)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_MOUVEMENT)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        textDirection: textDirection,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: 450,
                                            child: ChampAvecLabel(
                                              label: l10n.cashSessionsTab,
                                              buttonAjout: true,
                                              onAjoutPressed: () async {
                                                await showDialog(
                                                  context: context,
                                                  barrierColor: Appstyle.gris.withOpacity(0.25),
                                                  builder: (_) {
                                                    return InsertionSessionDialog(
                                                      sessions: sessions,
                                                      caisses: caisses,
                                                      onSessionSelected: (session) {
                                                        setState(() {
                                                          selectedSessionFiltreCode = session.code;
                                                        });
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                              child: TextListe(
                                                value: selectedSessionFiltreCode,
                                                items: sessions.map((s) => s.code).toList(),
                                                clearable: true,
                                                hint: l10n.all,
                                                onChanged: (v) => setState(() {
                                                  selectedSessionFiltreCode = (v == null || v.isEmpty) ? null : v;
                                                }),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: paddingV / 2),
                                      SizedBox(
                                        height: adjustedHeight * 0.7,
                                        child: TableauMouvementCaisse(
                                          key: ValueKey('$selectedSessionFiltreCode-${mouvementsCaisse.length}'),
                                          lignes: _lignesMouvementCaisse(),
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 5. CAS SESSIONS (currentTab == TAB_SESSION)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_SESSION)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                        child: MainButton(
                                          text: l10n.viewMovements,
                                          icon: Icons.receipt_long,
                                          color: Appstyle.indigo,
                                          onPressed: () async {
                                            if (sessionsSelectionnees.length == 1) {
                                              setState(() {
                                                selectedSessionFiltreCode = sessionsSelectionnees.first.code;
                                                _tabController.index = TAB_MOUVEMENT;
                                              });
                                            } else if (sessionsSelectionnees.isEmpty) {
                                              await InformationDialog(
                                                context: context,
                                                titre_type_message: l10n.information,
                                                titre_concerne: l10n.cashSessionsTab,
                                                message: l10n.noSessionSelected,
                                              );
                                            } else {
                                              await InformationDialog(
                                                context: context,
                                                titre_type_message: l10n.information,
                                                titre_concerne: l10n.cashSessionsTab,
                                                message: l10n.selectSingleSessionForMovements,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(height: paddingV / 2),
                                      sessions.isEmpty
                                          ? Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(32),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(l10n.noSessionsYet, style: Appstyle.textSB),
                                              ),
                                            )
                                          : SizedBox(
                                              height: adjustedHeight * 0.7,
                                              child: TableauCaisseSessionAdvanced(
                                                key: ValueKey(sessions),
                                                sessions: sessions,
                                                caisses: caisses,
                                                utilisateurs: utilisateursTest,
                                                onSelectionChanged: (selection) {
                                                  setState(() {
                                                    sessionsSelectionnees = selection;
                                                  });
                                                },
                                                onVoirMouvements: (session) {
                                                  setState(() {
                                                    selectedSessionFiltreCode = session.code;
                                                    _tabController.index = TAB_MOUVEMENT;
                                                  });
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
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
      ),
    );
  }

  Widget filtreTransfert(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Ligne caisse source / caisse dest / montant
          Row(
            textDirection: textDirection,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.sourceCashRegister ?? "Caisse Src",
                  child: TextListe(
                    value: selectedCaisseSourceFilter,
                    items: caisses.map((sc) => sc.nomCaisse).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedCaisseSourceFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.destinationCashRegister ?? "Caisse Dest",
                  child: TextListe(
                    value: selectedCaisseDestinaFilter,
                    items: caisses.map((sc) => sc.nomCaisse).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedCaisseDestinaFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.amount,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: montantMin,
                    maxValue: montantMax,
                    onChanged: (min, max) {
                      setState(() {
                        montantMin = min;
                        montantMax = max;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Date row
          Row(
            textDirection: textDirection,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutCtrl,
                    onTap: _pickDateDebut,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebut != null,
                    controller: _dateFinCtrl,
                    onTap: _pickDateFin,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: width * 0.7,
                child: ChampAvecLabel(
                  label: l10n.quickPeriod,
                  child: DropdownButtonFormField<String>(
                    value: periodeRapide,
                    decoration: InputDecoration(
                      hintText: l10n.choosePeriod,
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: periodesRapidesLabels(l10n).entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          periodeRapide = v;
                          _appliquerPeriodeRapide(v, l10n);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            textDirection: textDirection,
            children: [
              SizedBox(
                width: width * 0.7,
                child: Row(
                  textDirection: textDirection,
                  children: [
                    Expanded(
                      child: ChampAvecLabel(
                        label: l10n.search,
                        child: SearchField(
                          controller: _searchControllertransfert,
                          onChanged: (v) {
                            setState(() {
                              appliquerFiltre();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.etat,
                  child: TextListe(
                    value: selectedEtatFilter != null ? translator.translateEtat(selectedEtatFilter!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilter = translator.etatToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(width: width * 0.28),
            ],
          ),
        ],
      ),
    );
  }

  Widget filtreCaisse(void Function(VoidCallback fn) setState, AppLocalizations l10n, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 430,
          child: Row(
            textDirection: textDirection,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerCaisse,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltreCaisse();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}