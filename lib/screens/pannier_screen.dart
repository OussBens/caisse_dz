import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_actif.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_detail.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_modif.dart';
import 'package:caisse_dz/core/tableau/pannier/tableau_pannier.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_pannier.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_pannier_global.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dialog/information_dialog.dart';
import '../core/widget/section_decoration_filtre.dart';

// Valeurs sélectionnées dans le filtre
String? selectedEtatFilter;
String? selectedClientFilter;
String? modepaiementFilter;
String? typepannierFilter;

class PannierScreen extends StatefulWidget {
  const PannierScreen({super.key});

  @override
  State<PannierScreen> createState() => _PannierScreenState();
}

class _PannierScreenState extends State<PannierScreen> {

  Future<void> _refreshData() async {
    await _LoadAllData();
    if (mounted) {
      setState(() {});
    }
  }
  void _modifierPannier(Pannier p) {
    PannierModif(
      context,
      p,
      onSuccess: _refreshData, // ✅ Callback après modification
    );
  }
  void _annulerPannier(List<Pannier> selection) {
    AnnulerPannier(
      context,
      selection,
      onSuccess: _refreshData, // ✅ Callback après annulation
    );
  }
  // Period keys for translation lookup
  final List<String> periodeKeys = [
    "today",
    "yesterday",
    "week",
    "lastWeek",
    "month",
    "lastMonth",
    "last7days",
    "last30days",
    "year",
    "lastYear",
  ];

  List<Pannier> paniersTest = [];
  List<Client> clientsTest = [];
  List<PannierProduit> pannierProduitsTest = [];
  List<Verssement> versementsTest = [];
  List<Utilisateur> utilisateursTest = [];
  Map<String, double> verseParPannier = {};
  Map<String, int> nbrVersementParPannier = {};
  Set<String> panniersAvecRetour = {};

  Future<void> _LoadAllData() async {
    supprimerFilter();
    final db = await DbCreator.openDb();
    paniersTest = await PannierServices.getAllPanniers();
    clientsTest = await ClientServices.getAllClients();
    pannierProduitsTest = await PPServices.getAllPP();
    versementsTest = await VerssementServices.getAllverssement();
    utilisateursTest = await UtilisateurServices.getAllUtilisateurs();
    verseParPannier = PannierServices.verseParPannier(versementsTest);
    nbrVersementParPannier = PannierServices.nbrVersementParPannier(versementsTest);

    final retoursTest = await RetourServices.getAllRetour();
    panniersAvecRetour = retoursTest
        .where((r) => r.etat && r.type == "Client" && r.retourCorrespondDe != null)
        .map((r) => r.retourCorrespondDe!)
        .toSet();

    setState(() {
      paniers = paniersTest;
      pannierFiltres = paniersTest;
    });
  }

  double _resteDe(Pannier p) => p.montant - (verseParPannier[p.code] ?? 0);

  DateTime? dateDebut;
  DateTime? dateFin;

  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();

  String? periodeRapide;

  late List<String> clientFilterOptions = [];
  late List<String> modepaiementFilterOptions = [];
  late List<String> modepannierFilterOptions = [];

  List<Pannier> paniers = [];
  List<Pannier> pannierFiltres = [];
  List<Pannier> paniersSelectionnes = [];

  bool filtresActifs = false;
  bool? filtreetat;

  final TextEditingController _searchController = TextEditingController();

  double? montantMin;
  double? montantMax;
  double? resteMin;
  double? resteMax;

  Map<String, double> calculerVentesProduits(List<PannierProduit> lignes) {
    final Map<String, double> ventes = {};

    for (final l in lignes) {
      if (l.etat != "actif") continue;

      final code = l.codeProduit;
      final qte = l.quantite;

      ventes[code] = (ventes[code] ?? 0) + qte;
    }

    return ventes;
  }

  String getProduitStarGlobal(List<PannierProduit> lignes) {
    final ventes = calculerVentesProduits(lignes);

    if (ventes.isEmpty) return "—";

    String star = ventes.keys.first;

    ventes.forEach((produit, qte) {
      if (qte > ventes[star]!) {
        star = produit;
      }
    });

    return star;
  }

  double getQuantiteStarGlobal(List<PannierProduit> lignes) {
    final ventes = calculerVentesProduits(lignes);
    if (ventes.isEmpty) return 0;
    double max = 0;
    for (final qte in ventes.values) {
      if (qte > max) max = qte;
    }
    return max;
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  @override
  void initState() {
    super.initState();
    _LoadAllData();
  }

  // ✅ Vrai si au moins un champ de filtre panier est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresPannierActifs =>
      (selectedClientFilter != null && selectedClientFilter!.isNotEmpty) ||
      (modepaiementFilter != null && modepaiementFilter!.isNotEmpty) ||
      (selectedEtatFilter != null && selectedEtatFilter!.isNotEmpty) ||
      (typepannierFilter != null && typepannierFilter!.isNotEmpty) ||
      montantMin != null ||
      montantMax != null ||
      resteMin != null ||
      resteMax != null ||
      dateDebut != null ||
      dateFin != null ||
      _searchController.text.isNotEmpty;

  void appliquerFiltre() {
    pannierFiltres = paniersTest.where((p) {
      final searchText = _searchController.text.toLowerCase();
      final clientOk = selectedClientFilter == null ||
          selectedClientFilter!.isEmpty ||
          clientsTest.any((c) => c.code == p.client_code && c.nom == selectedClientFilter);
      final modeOk = modepaiementFilter == null ||
          modepaiementFilter!.isEmpty ||
          p.modePaiement == modepaiementFilter;
      final typeOk = typepannierFilter == null ||
          typepannierFilter!.isEmpty ||
          p.typepannier == typepannierFilter;
      final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);

      final montantOk = (montantMin == null || p.montant >= montantMin!) &&
          (montantMax == null || p.montant <= montantMax!);

      final reste = _resteDe(p);
      final resteOk = (resteMin == null || reste >= resteMin!) &&
          (resteMax == null || reste <= resteMax!);

      final etatOk = selectedEtatFilter == null ||
          selectedEtatFilter == "" ||
          (selectedEtatFilter == "Actif" && p.etat) ||
          (selectedEtatFilter == "Inactif" && !p.etat);

      final dateOk = () {
        if (dateDebut == null && dateFin == null) return true;

        final d = p.date;

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

      return clientOk && modeOk && montantOk && resteOk && etatOk &&
          searchOk && typeOk && dateOk;
    }).toList();

    if ((selectedClientFilter == null || selectedClientFilter!.isEmpty) &&
        (modepaiementFilter == null || modepaiementFilter!.isEmpty) &&
        (selectedEtatFilter == null || selectedEtatFilter!.isEmpty) &&
        (typepannierFilter == null || typepannierFilter!.isEmpty) &&
        montantMin == null && montantMax == null &&
        resteMax == null && resteMin == null &&
        dateDebut == null && dateFin == null &&
        _searchController.text.isEmpty) {
      pannierFiltres = paniersTest;
    }

    setState(() {});
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

  String _getPeriodeDisplayName(String key, AppLocalizations l10n) {
    switch (key) {
      case "today": return l10n.today;
      case "yesterday": return l10n.yesterday;
      case "week": return l10n.thisWeek;
      case "lastWeek": return l10n.lastWeek;
      case "month": return l10n.thisMonth;
      case "lastMonth": return l10n.lastMonth;
      case "last7days": return l10n.last7Days;
      case "last30days": return l10n.last30Days;
      case "year": return l10n.thisYear;
      case "lastYear": return l10n.lastYear;
      default: return key;
    }
  }

  void _appliquerPeriodeRapide(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebut = DateTime(now.year, now.month, now.day);
        dateFin = dateDebut;
        break;

      case "yesterday":
        dateDebut = DateTime(now.year, now.month, now.day - 1);
        dateFin = dateDebut;
        break;

      case "week":
        dateDebut = now.subtract(Duration(days: now.weekday - 1));
        dateFin = dateDebut!.add(const Duration(days: 6));
        break;

      case "lastWeek":
        dateDebut = now.subtract(Duration(days: now.weekday + 6));
        dateFin = dateDebut!.add(const Duration(days: 6));
        break;

      case "month":
        dateDebut = DateTime(now.year, now.month, 1);
        dateFin = DateTime(now.year, now.month + 1, 0);
        break;

      case "lastMonth":
        dateDebut = DateTime(now.year, now.month - 1, 1);
        dateFin = DateTime(now.year, now.month, 0);
        break;

      case "last7days":
        dateDebut = now.subtract(const Duration(days: 6));
        dateFin = now;
        break;

      case "last30days":
        dateDebut = now.subtract(const Duration(days: 29));
        dateFin = now;
        break;

      case "year":
        dateDebut = DateTime(now.year, 1, 1);
        dateFin = DateTime(now.year, 12, 31);
        break;

      case "lastYear":
        dateDebut = DateTime(now.year - 1, 1, 1);
        dateFin = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrl.text = _formatDate(dateDebut!);
    _dateFinCtrl.text = _formatDate(dateFin!);

    appliquerFiltre();
  }

  void supprimerFilter() {
    selectedEtatFilter = null;
    selectedClientFilter = null;
    modepaiementFilter = null;
    typepannierFilter = null;
    periodeRapide = null;
    montantMax = null;
    montantMin = null;
    filtreetat = null;
    dateDebut = null;
    resteMax = null;
    resteMin = null;
    dateFin = null;

    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
    _searchController.clear();
  }

  // Excel Export Methods
  Future<void> _exportToExcel() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      // Use filtered panniers if filters are active, otherwise use all
      final panniersToExport = filtresActifs ? pannierFiltres : paniersTest;

      if (panniersToExport.isEmpty) {
        Navigator.pop(context);
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.panier,
          message: l10n.noDataToExport,
        );
        return;
      }

      final excelFile = await ExcelGenerator.generatePanniersExcel(
        panniers: panniersToExport,
        versements: versementsTest,
        l10n: l10n,
        translator: translator,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Panniers'];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      if (sheet != null) {
        List<List<dynamic>> data = [];
        List<String> headers = [];

        // Extract headers
        for (int col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          if (cell.value != null && cell.value.toString().isNotEmpty) {
            headers.add(cell.value.toString());
          }
        }

        // Extract data rows
        for (int row = 1; row < sheet.maxRows; row++) {
          List<dynamic> rowData = [];
          bool hasData = false;

          for (int col = 0; col < sheet.maxColumns; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null && cell.value.toString().isNotEmpty) {
              rowData.add(cell.value);
              hasData = true;
            } else {
              rowData.add('-');
            }
          }

          if (hasData) {
            data.add(rowData);
          }
        }

        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No data found in Excel file'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExcelPreviewDialog(
            data: data,
            headers: headers,
            title: l10n.panier,
            l10n: l10n,
            excelFile: excelFile,
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.exportSuccess),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onShare: () {
              Navigator.pop(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find data sheet in Excel file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export selected panniers only
  Future<void> _exportSelectedToExcel() async {
    if (paniersSelectionnes.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.panier,
        message: l10n.noCartSelected,
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      final excelFile = await ExcelGenerator.generatePanniersExcel(
        panniers: paniersSelectionnes,
        versements: versementsTest,
        l10n: l10n,
        translator: translator,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Panniers'];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      if (sheet != null) {
        List<List<dynamic>> data = [];
        List<String> headers = [];

        // Extract headers
        for (int col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          if (cell.value != null && cell.value.toString().isNotEmpty) {
            headers.add(cell.value.toString());
          }
        }

        // Extract data rows
        for (int row = 1; row < sheet.maxRows; row++) {
          List<dynamic> rowData = [];
          bool hasData = false;

          for (int col = 0; col < sheet.maxColumns; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null && cell.value.toString().isNotEmpty) {
              rowData.add(cell.value);
              hasData = true;
            } else {
              rowData.add('-');
            }
          }

          if (hasData) {
            data.add(rowData);
          }
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExcelPreviewDialog(
            data: data,
            headers: headers,
            title: "${l10n.panier} (${l10n.selected})",
            l10n: l10n,
            excelFile: excelFile,
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.exportSuccess),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onShare: () {
              Navigator.pop(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find data sheet in Excel file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final userCode = auth.userCode ?? '';

    // Initialize filter options with translated values
    clientFilterOptions = clientsTest.map((c) => c.nom).toSet().toList();
    modepaiementFilterOptions = translator.modePaiementDisplayList;
    modepannierFilterOptions = translator.typePannierDisplayList;

    final produitStar = getProduitStarGlobal(pannierProduitsTest);
    final quantiteStar = getQuantiteStarGlobal(pannierProduitsTest);
    final double total = paniers.fold(0.0, (s, c) => s + c.montant);

    final int nb = paniersSelectionnes.isEmpty ? paniers.length : paniers.length;
    final double moyenne = nb == 0 ? 0 : total / nb;

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: minWidth,
                minHeight: minHeight,
              ),
              child: SizedBox(
                width: adjustedWidth,
                    height: adjustedHeight,
                    child: Row(
                       children: [
                        SideBarWidget(),

                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// HEADER
                                HeaderModule(
                                  gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                  child: Row(
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            "assets/icons/sidebar/pannier_icon.png",
                                            width: 40,
                                            color: Appstyle.violet,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            l10n.panier,
                                            style: Appstyle.textXLB.copyWith(
                                              color: Appstyle.violet,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
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

                                if (paniersSelectionnes.length == 1)
                                  AfficheurPanier(
                                    pannier: paniersSelectionnes.first,
                                    verse: verseParPannier[paniersSelectionnes.first.code] ?? 0,
                                    reste: _resteDe(paniersSelectionnes.first),
                                    nbrVersement: nbrVersementParPannier[paniersSelectionnes.first.code] ?? 0,
                                    hasRetour: panniersAvecRetour.contains(paniersSelectionnes.first.code),
                                    onDetails: () {
                                      PannierDetail(context, paniersSelectionnes.first);
                                    },
                                  )
                                else
                                  AfficheurPaniersGlobalWidget(
                                    totalPanier: total,
                                    produitStar: produitStar,
                                    nombrePaniers: paniers.length,
                                    moyenneParPanier: moyenne,
                                    produitStarQuantite: quantiteStar,
                                  ),

                                SizedBox(height: paddingV),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        MainButton(
                                          text: l10n.filter,
                                          textColor: Appstyle.violet,
                                          color: Appstyle.Tblanc,
                                          showBadge: _filtresPannierActifs,
                                          icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                          iconColor:Appstyle.violet ,
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

                                        // EXTRACT ALL Button
                                        MainButton(
                                          text: l10n.extract,
                                          textColor:Colors.green ,
                                          iconColor: Colors.green,
                                          color: Appstyle.Tblanc,
                                          icon: Icons.download,
                                          onPressed: () async {
                                            await _exportToExcel();
                                          },
                                        ),
                                        SizedBox(width: paddingH / 4),
                                        // EXTRACT SELECTED Button
                                        MainIconButton(
                                          imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                          color: Colors.orange,
                                          onPressed: () async {
                                            await _exportSelectedToExcel();
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
                                            if (paniersSelectionnes.length == 1) {
                                              PannierDetail(context, paniersSelectionnes.first);
                                            } else if (paniersSelectionnes.isEmpty) {
                                              await InformationDialog(
                                                context: context,
                                                titre_type_message: l10n.information,
                                                titre_concerne: l10n.panier,
                                                message: l10n.noCartSelected,
                                              );
                                            } else {
                                              await InformationDialog(
                                                context: context,
                                                titre_type_message: l10n.information,
                                                titre_concerne: l10n.panier,
                                                message: l10n.selectSingleCartForDetail,
                                              );
                                            }
                                          },
                                        ),
                                        SizedBox(width: paddingH / 4),
                                        MainIconButton(
                                          imagePath: "assets/icons/action/annuler_icon.png",
                                          color: Appstyle.gris,
                                          onPressed: () async {
                                            if (paniersSelectionnes.isNotEmpty) {
                                              _annulerPannier(paniersSelectionnes);
                                              // ❌ Supprimer cette ligne car le callback le fait
                                              // await _LoadAllData();
                                            } else {
                                              await InformationDialog(
                                                context: context,
                                                titre_type_message: l10n.information,
                                                titre_concerne: l10n.panier,
                                                message: l10n.noCartSelected,
                                              );
                                            }
                                          },
                                        ),
                                        SizedBox(width: paddingH / 4),
                              MainIconButton(
                                imagePath: "assets/icons/action/edit_icon.png",
                                color: Appstyle.lavande,
                                onPressed: () async {
                                  if (paniersSelectionnes.length == 1) {
                                    _modifierPannier(paniersSelectionnes.first);
                                    // ❌ Supprimer cette ligne car le callback le fait
                                    // await _LoadAllData();
                                  } else if (paniersSelectionnes.isEmpty) {
                                    await InformationDialog(
                                      context: context,
                                      titre_type_message: l10n.information,
                                      titre_concerne: l10n.panier,
                                      message: l10n.noCartSelected,
                                    );
                                  } else {
                                    await InformationDialog(
                                      context: context,
                                      titre_type_message: l10n.information,
                                      titre_concerne: l10n.panier,
                                      message: l10n.selectSingleCartToModify,
                                    );
                                  }
                                },
                              ),
                                 ],
                                    ),
                                  ],
                                ),
                                if (filtresActifs)
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: paddingV),
                                      child: Column(
                                        children: [
                                          filtreproduit(setState, adjustedWidth / 3, l10n, translator),
                                        ],
                                      ),
                                    ),
                                  ),
                                SizedBox(height: paddingV / 2),
                                SizedBox(
                                  height: adjustedHeight * 0.65,
                                  child: TableauPannierAdvanced(
                                    key: ValueKey(pannierFiltres),
                                    panniers: pannierFiltres,
                                    clients: clientsTest,
                                    verseParPannier: verseParPannier,
                                    nbrVersementParPannier: nbrVersementParPannier,
                                    utilisateurs: utilisateursTest,
                                    onSelectionChanged: (selection) {
                                      setState(() {
                                        paniersSelectionnes = selection;
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
                  ),

              ),
          );
        },
      ),
    );
  }

  Widget filtreproduit(void Function(VoidCallback fn) setState, double width,
      AppLocalizations l10n, ListsConstTranslator translator) {
    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.client,
                  child: TextListe(
                    value: selectedClientFilter ?? "",
                    items: clientFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedClientFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.payment,
                  child: TextListe(
                    // Translate French value to display value
                    value: modepaiementFilter != null
                        ? translator.translateModePaiement(modepaiementFilter!)
                        : null,
                    items: modepaiementFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        // Convert display value back to French for storage
                        modepaiementFilter = translator.modePaiementToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.typePannier,
                  child: TextListe(
                    // Translate French value to display value
                    value: typepannierFilter != null
                        ? translator.translateTypePannier(typepannierFilter!)
                        : null,
                    items: modepannierFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        // Convert display value back to French for storage
                        typepannierFilter = translator.typePannierToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
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
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.remaining,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: resteMin,
                    maxValue: resteMax,
                    onChanged: (min, max) {
                      setState(() {
                        resteMin = min;
                        resteMax = max;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.etat,
                  child: TextListe(
                    // Translate French value to display value
                    value: selectedEtatFilter != null
                        ? translator.translateEtat(selectedEtatFilter!)
                        : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        // Convert display value back to French for storage
                        selectedEtatFilter = translator.etatToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
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
                width: width * 0.75,
                child: ChampAvecLabel(
                  label: l10n.quickPeriod,
                  child: DropdownButtonFormField<String>(
                    value: periodeRapide,
                    decoration: InputDecoration(
                      hintText: l10n.choosePeriod,
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: periodeKeys.map((key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(_getPeriodeDisplayName(key, l10n)),
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
          SizedBox(
            width: width * 0.75,
            child: Row(
              children: [
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.search,
                    child: SearchField(
                      controller: _searchController,
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
        ],
      ),
    );
  }
}