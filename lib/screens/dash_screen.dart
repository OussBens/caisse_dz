import 'package:caisse_dz/core/widget/situation/cout_produit_tab.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/dash/periode_dashboard_dialog.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/situation/mouvement_caisse_tab.dart';
import 'package:caisse_dz/core/widget/situation/mouvement_produit_tab.dart';
import 'package:caisse_dz/core/widget/situation/recette_caisse_pannier_tab.dart';
import 'package:caisse_dz/core/widget/situation/recette_caisse_produit_tab.dart';
import 'package:caisse_dz/core/widget/situation/marge_pannier_tab.dart';
import 'package:caisse_dz/core/widget/situation/marge_periode_tab.dart';
import 'package:caisse_dz/core/widget/situation/inventaire_tab.dart';
import 'package:caisse_dz/core/widget/situation/client_situation_tab.dart';
import 'package:caisse_dz/core/widget/situation/fournisseur_situation_tab.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:caisse_dz/core/utilis/number_format.dart';

class DashScreen extends StatefulWidget {
  const DashScreen({Key? key}) : super(key: key);

  @override
  State<DashScreen> createState() => _DashScreenState();
}



// Enum and helper functions remain the same...
enum ChartGranularity { hourly, daily, weekly }
extension DateOnly on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);
}

double _calcYInterval(Map<int, double> data) {
  if (data.isEmpty) return 1;
  final max = data.values.reduce((a, b) => a > b ? a : b);
  return (max / 4).ceilToDouble();
}
Map<int, double> caParHeure(List<Pannier> list, DateTime day) {
  final Map<int, double> data = {};
  for (var p in list) {
    final d = p.date;
    if (d.year == day.year && d.month == day.month && d.day == day.day) {
      final h = d.hour;
      data[h] = (data[h] ?? 0) + p.montant;
    }
  }
  return data;
}
Map<int, double> caParJour(List<Pannier> list, DateTime start, DateTime end,) {
  final s = start.startOfDay;
  final e = end.endOfDay;

  final Map<int, double> data = {};

  for (var p in list) {
    final d = p.date;

    if (!d.isBefore(s) && !d.isAfter(e)) {

      /// ✅ index relatif à la période
      final key = d.difference(s).inDays + 1;

      data[key] = (data[key] ?? 0) + p.montant;
    }
  }

  return data;
}
Map<int, double> caParSemaine(List<Pannier> list, DateTime start, DateTime end,) {
  final s = start.startOfDay;
  final e = end.endOfDay;

  final Map<int, double> data = {};

  for (var p in list) {
    final d = p.date;

    if (!d.isBefore(s) && !d.isAfter(e)) {

      final diffDays = d.difference(s).inDays;

      /// semaine relative
      final week = (diffDays / 7).floor() + 1;

      data[week] = (data[week] ?? 0) + p.montant;
    }
  }

  return data;
}
// ✅ FIXED: Added BuildContext parameter
Map<String, double> totalParMode(List<Pannier> panniers, DateTime start, DateTime end, BuildContext context) {
  final s = start.startOfDay;
  final e = end.endOfDay;
  final l10n = AppLocalizations.of(context)!;
  final modeList = ListsConst.modePaiementList;

  final Map<String, double> totals = {
    for (var mode in modeList) mode: 0,
  };

  for (var p in panniers) {
    if (p.date.isBefore(s) || p.date.isAfter(e)) continue;
    if (totals.containsKey(p.modePaiement)) {
      totals[p.modePaiement!] = totals[p.modePaiement]! + p.montant;
    }
  }
  return totals;
}

double totalMontantPeriode(List<Pannier> list, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;

  return list
      .where((p) => !p.date.isBefore(s) && !p.date.isAfter(e))
      .fold(0, (s, p) => s + p.montant);
}

double totalCreditPeriode(List<Pannier> list, List<Verssement> versements, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;
  return list
      .where((p) => !p.date.isBefore(s) && !p.date.isAfter(e))
      .fold(0, (s, p) => s + PannierServices.calculerReste(p, versements));
}

Map<String, double> caParCaissier(List<Pannier> list, DateTime start, DateTime end) {

  final s = start.startOfDay;
  final e = end.endOfDay;
  final Map<String, double> data = {};
  for (var p in list) {
    if (!p.date.isBefore(s) && !p.date.isAfter(e)) {
      final caissier = p.caissier_code;
      data[caissier] = (data[caissier] ?? 0) + p.montant;
    }
  }
  return data;
}

List<Map<String, String>> getProduitsRupture(
  List<Produit> produits,
  double seuilMin,
  Map<String, double> quantites,
) {
  double qte(Produit p) => quantites[p.code] ?? 0;
  final filtered = produits.where((p) => qte(p) <= seuilMin).toList();
  filtered.sort((a, b) => qte(a).compareTo(qte(b)));
  return filtered.take(10).map((p) => {
    "name": p.nom,
    "value": NumberFormatUtil.formatMontant(qte(p), decimales: 0),
  }).toList();
}

DateTimeRange getPreviousPeriod(DateTime start, DateTime end) {
  final diff = end.difference(start).inDays + 1;
  final previousEnd = start.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(Duration(days: diff - 1));
  return DateTimeRange(start: previousStart, end: previousEnd);
}
double totalVente(List<Pannier> list, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;

  return list
      .where((p) =>
  !p.date.isBefore(s) &&
      !p.date.isAfter(e))
      .fold(0.0, (sum, p) => sum + p.montant);
}
double totalAchat(List<SmartScan> list, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;
  return list
      .where((ss) => !ss.date.isBefore(s) && !ss.date.isAfter(e))
      .fold(0.0, (s, p) => s + p.montant);
}
double totalAchatC(List<SmartScan> list, List<Verssement> versements, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;
  return list
      .where((ss) => !ss.date.isBefore(s) && !ss.date.isAfter(e))
      .fold(0.0, (s, p) => s + SmartScanServices.calculerReste(p, versements));
}
double totalNet(List<Pannier> list, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;

  return list
      .where((p) =>
  !p.date.isBefore(s) &&
      !p.date.isAfter(e))
      .fold(0.0, (sum, p) => sum + p.marge);
}
double totalCreditC(List<Pannier> list, List<Verssement> versements, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;

  return list
      .where((p) =>
  !p.date.isBefore(s) &&
      !p.date.isAfter(e))
      .fold(0.0, (sum, p) => sum + PannierServices.calculerReste(p, versements));
}


Map<String, dynamic> ventesStats(List<Pannier> panniers, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;
  final filtered = panniers.where((p) => !p.date.isBefore(s) && !p.date.isAfter(e)).toList();
  final totalVenteValue = filtered.fold(0.0, (s, p) => s + p.montant);
  final nombre = filtered.length.toDouble();
  final moyenne = nombre == 0 ? 0 : totalVenteValue / nombre;
  return {
    "nombre": nombre,
    "moyenne": moyenne.toDouble(),
  };
}

double totalStockValue(
  List<Produit> produits,
  Map<String, double> quantites, {
  bool usePrixVente = true,
}) {
  return produits.fold(0.0, (s, p) {
    final prix = usePrixVente ? p.prixVente : p.prixAchat;
    return s + (quantites[p.code] ?? 0) * prix;
  });
}

class _DashScreenState extends State<DashScreen> with SingleTickerProviderStateMixin {

  bool _isLoading = true;
  bool _dataLoaded = false;
  List<PannierProduit>  pannierProduitsTest = [];
  List<Fournisseur>     fournisseursTest    = [];
  List<SmartScan>       smartScansTest      = [];
  List<Produit>         produitsTest        = [];
  // Quantité par produit calculée depuis le journal des mouvements, sommée
  // sur les magasins CONSULTABLES par l'utilisateur (AuthState
  // .magasinsConsultation) — même mécanisme que produit_screen.dart /
  // stock_screen.dart, pour que valeur du stock et ruptures concordent.
  Map<String, double>   quantitesTest       = {};
  List<Pannier>         paniersTest         = [];
  List<Verssement>      versementsTest      = [];
  List<Client>          clientsTest         = [];
  double                seuilMinimum        = 0;

  late TabController _mainTabController;
  int? _selectedSituationIndex;

  bool _datesInitialized = false; // ✅ Flag pour éviter la double initialisation

  // ✅ Capture du contenu du dashboard (KPI + graphiques) pour l'export PDF.
  final GlobalKey _dashboardCaptureKey = GlobalKey();
  bool _exportEnCours = false;

  // ✅ Découpe l'image capturée en tranches horizontales de pleine largeur,
  // une par page — évite qu'une page unique au ratio hauteur/largeur
  // extrême (dashboard très haut) ne soit réduite pour tenir sur une
  // feuille standard, ce qui laissait des marges vides sur les côtés.
  Future<List<Uint8List>> _decouperImageEnPages(ui.Image image, double ratioPage) async {
    final int hauteurTranchePx = (image.width / ratioPage).round().clamp(1, image.height);
    final int nombrePages = (image.height / hauteurTranchePx).ceil();
    final List<Uint8List> tranches = [];

    for (int i = 0; i < nombrePages; i++) {
      final int haut = i * hauteurTranchePx;
      final int hauteur = (i == nombrePages - 1) ? image.height - haut : hauteurTranchePx;
      if (hauteur <= 0) continue;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final srcRect = Rect.fromLTWH(0, haut.toDouble(), image.width.toDouble(), hauteur.toDouble());
      final dstRect = Rect.fromLTWH(0, 0, image.width.toDouble(), hauteur.toDouble());
      canvas.drawImageRect(image, srcRect, dstRect, Paint());

      final trancheImage = await recorder.endRecording().toImage(image.width, hauteur);
      final byteData = await trancheImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) tranches.add(byteData.buffer.asUint8List());
    }

    return tranches;
  }

  Future<void> _exporterDashboardPDF() async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    try {
      final boundary = _dashboardCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);

      const pageFormat = PdfPageFormat.a4;
      final pageLandscape = pageFormat.landscape;
      final ratioPage = pageLandscape.width / pageLandscape.height;

      final tranches = await _decouperImageEnPages(image, ratioPage);

      final pdf = pw.Document();
      for (final tranche in tranches) {
        pdf.addPage(
          pw.Page(
            pageFormat: pageLandscape,
            margin: pw.EdgeInsets.zero,
            build: (context) => pw.Image(
              pw.MemoryImage(tranche),
              fit: pw.BoxFit.fill,
              width: pageLandscape.width,
              height: pageLandscape.height,
            ),
          ),
        );
      }

      await Printing.layoutPdf(
        name: 'dashboard.pdf',
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint("Erreur export PDF dashboard: $e");
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.exportError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedSituationIndex = null;
        });
      }
    });
   _initDashboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_datesInitialized) {
      _datesInitialized = true;
      _initializeDates();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPeriodDialog());
    }
  }

  Future<void> _showPeriodDialog() async {
    if (!mounted) return;

    // ✅ Vérifier que l'utilisateur est sur l'onglet Dashboard (index 1)
    if (_mainTabController.index != 1) return;

    await PeriodeDashboardDialog(
      context: context,
      initialDateDebut: dateDebut ?? DateTime.now(),
      initialDateFin: dateFin ?? DateTime.now(),
      formatDate: formatDate,
      onConfirmer: (debut, fin) {
        setState(() {
          dateDebut = debut;
          dateFin = fin;
          dateDebutCtrl.text = formatDate(debut);
          dateFinCtrl.text = formatDate(fin);
          periodeRapide = null;
        });
      },
    );
  }

  void _initializeDates() {
    final now = DateTime.now();
    dateDebut = DateTime(now.year, now.month, now.day);
    dateFin = dateDebut;
    dateDebutCtrl.text = formatDate(dateDebut!);
    dateFinCtrl.text = formatDate(dateFin!);
  }
  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }
  Future<void> _initDashboard() async {
    await _LoadAllData();

    // ✅ Vérifier si les dates sont déjà initialisées
    if (dateDebut == null || dateFin == null) {
      _initializeDates();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _dataLoaded = true;
      });
    }
  }
  Future<void> _LoadAllData() async {
    final magasinsConsultation = Provider.of<AuthState>(context, listen: false).magasinsConsultation;
    final db = await DbCreator.openDb();
    pannierProduitsTest = await PPServices.getAllPP();
    fournisseursTest    = await FournisseurServices.getAllFournisseurs();
    // Les tickets/achats annulés (etat=false) ne doivent pas gonfler les
    // totaux du tableau de bord — voir ClotureCaisse.dart pour le même filtre.
    smartScansTest      = (await SmartScanServices.getAllSmartScans()).where((s) => s.etat).toList();
    produitsTest        = await ProduitServices.getAllProduits();
    quantitesTest       = await MouvementsServices.quantitesConsultables(magasinsConsultation);
    paniersTest         = (await PannierServices.getAllPanniers()).where((p) => p.etat).toList();
    versementsTest      = await VerssementServices.getAllverssement();
    clientsTest         = await ClientServices.getAllClients();
    seuilMinimum        = (await ParamServices.getParam()).Minimum;
    // ✅ Initialiser les dates avec la date du jour APRÈS le chargement
    final now = DateTime.now();
    dateDebut = DateTime(now.year, now.month, now.day);
    dateFin = dateDebut;
    dateDebutCtrl.text = formatDate(dateDebut!);
    dateFinCtrl.text = formatDate(dateFin!);
    periodeRapide = "today";

  }

  DateTime? dateDebut;
  DateTime? dateFin;
  final TextEditingController dateDebutCtrl = TextEditingController();
  final TextEditingController dateFinCtrl = TextEditingController();
  String? periodeRapide;

  Map<String, dynamic> calculateKpis() {
    if (dateDebut == null || dateFin == null) return {};
    final previous = getPreviousPeriod(dateDebut!, dateFin!);
    final vente = totalVente(paniersTest, dateDebut!, dateFin!);
    final ventePrev = totalVente(paniersTest, previous.start, previous.end);
    final achat = totalAchat(smartScansTest, dateDebut!, dateFin!);
    final achatPrev = totalAchat(smartScansTest, previous.start, previous.end);
    final net = totalNet(paniersTest, dateDebut!, dateFin!);
    final netPrev = totalNet(paniersTest, previous.start, previous.end);
    final credit = totalCreditC(paniersTest, versementsTest, dateDebut!, dateFin!);
    final creditPrev = totalCreditC(paniersTest, versementsTest, previous.start, previous.end);
    final creditF = totalAchatC(smartScansTest, versementsTest, dateDebut!, dateFin!);
    final creditFPrev = totalAchatC(smartScansTest, versementsTest, previous.start, previous.end);

    final ventesStat = ventesStats(paniersTest, dateDebut!, dateFin!);
    final ventesStatPrev = ventesStats(paniersTest, previous.start, previous.end);
    final stockVente = totalStockValue(produitsTest, quantitesTest, usePrixVente: true);
    final stockAchat = totalStockValue(produitsTest, quantitesTest, usePrixVente: false);

    return {
      "vente": vente,
      "ventePrev": ventePrev,
      "achat": achat,
      "achatPrev": achatPrev,
      "net": net,
      "netPrev": netPrev,
      "credit": credit,
      "creditPrev": creditPrev,
      "creditfournisseur": creditF,
      "creditfournisseurPrev": creditFPrev,
      "nombreVente": ventesStat["nombre"],
      "nombreVentePrev": ventesStatPrev["nombre"],
      "moyenneVente": ventesStat["moyenne"],
      "moyenneVentePrev": ventesStatPrev["moyenne"],
      "stockVente": stockVente,
      "stockAchat": stockAchat,
    };
  }

  ChartGranularity getGranularity() {
    if (dateDebut == null || dateFin == null) return ChartGranularity.weekly;
    final diff = dateFin!.difference(dateDebut!).inDays;
    if (diff == 0) return ChartGranularity.hourly;
    if (diff <= 7) return ChartGranularity.daily;
    return ChartGranularity.weekly;
  }

  // ✅ FIXED: Added l10n parameter instead of using context at top level
  void appliquerPeriodeRapide(String p, AppLocalizations l10n) {
    final periode = calculerPeriodeRapide(p);
    dateDebut = periode.debut;
    dateFin = periode.fin;
    dateDebutCtrl.text = formatDate(dateDebut!);
    dateFinCtrl.text = formatDate(dateFin!);
  }


  String formatDate(DateTime d) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return "${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}";
    }
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }
  Future<void> pickDateDebut() async {
    final picked = await showDatePicker(
      initialDate : dateDebut ?? DateTime.now(),
      firstDate   : DateTime(2000),
      lastDate    : DateTime(2100),
      context     : context,
    );
    if (picked != null) {
      setState(() {
        dateDebutCtrl.text  = formatDate(picked);
        periodeRapide       = null;
        dateDebut           = picked;
      });
    }
  }
  Future<void> pickDateFin() async {
    final picked = await showDatePicker(
      initialDate : dateFin ?? dateDebut ?? DateTime.now(),
      firstDate   : dateDebut ?? DateTime(2000),
      lastDate    : DateTime(2100),
      context     : context,
    );
    if (picked != null) {
      setState(() {
        dateFin = picked;
        dateFinCtrl.text = formatDate(picked);
        periodeRapide = null;
      });
    }
  }
  List<Map<String, dynamic>> _situationItems(AppLocalizations l10n) => [
    {"id": "pannier", "label": l10n.revenueByCart, "icon": Icons.receipt_long, "color": Appstyle.blueC},
    {"id": "produit", "label": l10n.revenueByProductCard, "icon": Icons.inventory_2, "color": Appstyle.violet},
    {"id": "mouvement", "label": l10n.cashRegisterMovement, "icon": Icons.swap_horiz, "color": Appstyle.indigo},
    {"id": "mouvementProduit", "label": l10n.productMovementSituation, "icon": Icons.sync_alt, "color": Appstyle.warningInk},
    {"id": "margePannier", "label": l10n.dailyProfitByCart, "icon": Icons.trending_up, "color": Appstyle.crevete},
    {"id": "margePeriode", "label": l10n.profitByPeriod, "icon": Icons.stacked_line_chart, "color": Appstyle.blueF},
    {"id": "inventaire", "label": l10n.inventory, "icon": Icons.warehouse, "color": Appstyle.successInk},
    {"id": "coutProduit", "label": l10n.productCostSituation, "icon": Icons.price_change, "color": Appstyle.primary},
    {"id": "situationClient", "label": l10n.clientSituationLabel, "icon": Icons.person, "color": Appstyle.info},
    {"id": "situationFournisseur", "label": l10n.supplierSituationLabel, "icon": Icons.local_shipping, "color": Appstyle.warning},
  ];

  Widget _buildMainTabBar(AppLocalizations l10n) {
    final mainTabs = [
      {'icon': 'assets/icons/sidebar/reporting_icon.png', 'label': l10n.situation},
      {'icon': 'assets/icons/sidebar/dash_icon.png', 'label': l10n.dashboard},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Appstyle.shadowTint.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _mainTabController,
        isScrollable: false,
        indicator: BoxDecoration(
          color: Appstyle.violet,
          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Appstyle.gris,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(6),
        labelStyle: Appstyle.textXS.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Appstyle.textXS.copyWith(fontWeight: FontWeight.w500),
        tabs: List.generate(mainTabs.length, (index) {
          final isSelected = _mainTabController.index == index;
          return Tab(
            icon: Container(
              width: 24,
              height: 24,
              child: Image.asset(
                mainTabs[index]['icon']!,
                width: 20,
                height: 20,
                color: isSelected ? Colors.white : Appstyle.gris,
              ),
            ),
            text: mainTabs[index]['label']!,
          );
        }),
      ),
    );
  }  Widget _buildSituationTab(double paddingV, AppLocalizations l10n) {
    final items = _situationItems(l10n);
    if (_selectedSituationIndex == null) {
      return _buildSituationGrid(items);
    }
    final item = items[_selectedSituationIndex!];
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildSituationMiniTabs(items),
          SizedBox(height: paddingV / 2),
          if (item["id"] == "mouvement")
            const MouvementCaisseTab()
          else if (item["id"] == "mouvementProduit")
            const MouvementProduitTab()
          else if (item["id"] == "pannier")
            const RecetteCaissePannierTab()
          else if (item["id"] == "produit")
            const RecetteCaisseProduitTab()
          else if (item["id"] == "margePannier")
            const MargeParPannierTab()
          else if (item["id"] == "margePeriode")
            const MargeParPeriodeTab()
          else if (item["id"] == "inventaire")
            const InventaireTab()
          else if (item["id"] == "coutProduit")
            const CoutProduitTab()
          else if (item["id"] == "situationClient")
            const ClientSituationTab()
          else if (item["id"] == "situationFournisseur")
            const FournisseurSituationTab()
          else
            _buildSituationPlaceholder(item["label"] as String),
        ],
      ),
    );
  }

  Widget _buildSituationGrid(List<Map<String, dynamic>> items) {
    return Align(
      alignment: Alignment.topLeft,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.7,
        children: List.generate(items.length, (i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedSituationIndex = i),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: item["color"] as Color,
                borderRadius: BorderRadius.circular(Appstyle.radiusCard),
                boxShadow: [
                  BoxShadow(
                    color: Appstyle.shadowTint.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item["icon"] as IconData, color: Colors.white, size: 46),
                  const SizedBox(height: 14),
                  Text(
                    item["label"] as String,
                    textAlign: TextAlign.center,
                    style: Appstyle.textLB.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSituationMiniTabs(List<Map<String, dynamic>> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isSelected = _selectedSituationIndex == i;
        final color = item["color"] as Color;
        return GestureDetector(
          onTap: () => setState(() => _selectedSituationIndex = i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item["icon"] as IconData, color: isSelected ? Colors.white : color, size: 18),
                const SizedBox(width: 8),
                Text(
                  item["label"] as String,
                  style: Appstyle.textXS.copyWith(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSituationPlaceholder(String label) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
      ),
      child: Center(
        child: Text(
          label,
          style: Appstyle.textXLB.copyWith(color: Appstyle.gris, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!; // ✅ Use non-null assertion
    final kpis = calculateKpis();
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final userCode = auth.userCode ?? '';
    bool isRTL = false;
    final local = context.watch<LocaleProvider>();
    isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
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

            return Directionality(
              textDirection: textDirection,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: minWidth,
                    minHeight: minHeight,
                  ),
                  child: SizedBox(
                    width: adjustedWidth,
                        height: adjustedHeight,
                        child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: RepaintBoundary(
                                  key: _dashboardCaptureKey,
                                  child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [

                                    /// HEADER
                                    HeaderModule(
                                      gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],

                                      child: Row(
                                        children: [
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/icons/sidebar/dash_icon.png",
                                                width: 40,
                                                color: Appstyle.violet,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                l10n.dashboard,
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

                                    _buildMainTabBar(l10n),

                                    SizedBox(height: paddingV / 2),

                                    if (_mainTabController.index == 0)
                                      _buildSituationTab(paddingV, l10n)
                                    else ...[
                                      /// FILTERS
                                      DashboardFiltersWidget(
                                        l10n: l10n,
                                        dateFinCtrl: dateFinCtrl,
                                        dateDebutCtrl: dateDebutCtrl,
                                        periodeRapide: periodeRapide,
                                        onPickDateFin: pickDateFin,
                                        onPickDateDebut: pickDateDebut,
                                        onPeriodeChanged: (v) {
                                          if (v != null) {
                                            setState(() {
                                              periodeRapide = v;
                                              appliquerPeriodeRapide(v, l10n);
                                            });
                                          }
                                        },
                                        onExport: _exportEnCours ? null : _exporterDashboardPDF,
                                      ),

                                      SizedBox(height: paddingV * 2 / 3),

                                      /// KPI ROW
                                      DashboardKpiRow(
                                        l10n: l10n,
                                        netToday: kpis["net"] ?? 0,
                                        venteToday: kpis["vente"] ?? 0,
                                        achatToday: kpis["achat"] ?? 0,
                                        netYesterday: kpis["netPrev"] ?? 0,
                                        creditClient: kpis["credit"] ?? 0,
                                        creditClientYesterday: kpis["creditPrev"] ?? 0,
                                        venteYesterday: kpis["ventePrev"] ?? 0,
                                        achatYesterday: kpis["achatPrev"] ?? 0,
                                        creditFournisseur: kpis["creditfournisseur"] ?? 0,
                                        creditFournisseurYesterday:kpis["creditfournisseurPrev"] ?? 0,
                                      ),

                                      SizedBox(height: paddingV * 2 / 3),

                                      /// GRAPH ROW
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 260,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(Appstyle.radiusLG),
                                              ),
                                              child: DashboardDynamicSalesChart(
                                                l10n: l10n,
                                                panniers: paniersTest,
                                                dateDebut: dateDebut,
                                                dateFin: dateFin,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Container(
                                              height: 260,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(Appstyle.radiusLG),
                                              ),
                                              child: DashboardCAPieChart(
                                                l10n: l10n,
                                                panniers: paniersTest,
                                                versements: versementsTest,
                                                dateDebut: dateDebut,
                                                dateFin: dateFin,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: paddingV * 2 / 3),

                                      /// BAR + STOCK
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 310,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(Appstyle.radiusLG),
                                              ),
                                              child: DashboardBarCaissierChart(
                                                l10n: l10n,
                                                panniers: paniersTest,
                                                dateDebut: dateDebut,
                                                dateFin: dateFin,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: paddingH / 2),
                                          Expanded(
                                            child: Container(
                                              height: 310,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(Appstyle.radiusLG),
                                              ),
                                              child: DashboardPaymentPieChart(
                                                l10n: l10n,
                                                panniers: paniersTest,
                                                dateDebut: dateDebut,
                                                dateFin: dateFin,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: paddingH / 2),
                                          Expanded(
                                            child: Container(
                                              height: 310,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(Appstyle.radiusLG),
                                              ),
                                              child: DashboardProduitBarChart(
                                                l10n: l10n,
                                                dateDebut: dateDebut,
                                                dateFin: dateFin,
                                                produits: pannierProduitsTest,
                                                panniers: paniersTest,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      /// LIST ROW
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DashboardListCard(
                                              title: l10n.outOfStockProducts,
                                              items: getProduitsRupture(produitsTest, seuilMinimum, quantitesTest),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                ),
                              ),
                      ),

                  ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// KPI Classes with Localization
class DashboardKpiAdvancedCard extends StatelessWidget {
  final String title;
  final double today;
  final double yesterday;
  final String suffix;
  final bool showPercent;
  // Couleur/icône par nature de métrique (vente, achat, profit, dette...) —
  // avant, toutes les cartes KPI partageaient le même violet, ce qui rendait
  // le tableau de bord difficile à scanner d'un coup d'œil.
  final Color color;
  final IconData icon;

  const DashboardKpiAdvancedCard({
    super.key,
    required this.title,
    required this.today,
    required this.yesterday,
    this.suffix = "",
    this.showPercent = true,
    this.color = Appstyle.violet,
    this.icon = Icons.bar_chart,
  });

  @override
  Widget build(BuildContext context) {
    final diff = today - yesterday;

    // ✅ Calcul du pourcentage selon tous les cas
    double percent;
    if (yesterday == 0) {
      if (today > 0) {
        percent = 100; // hier = 0, aujourd'hui > 0
      } else {
        percent = 0; // hier = 0, aujourd'hui = 0
      }
    } else {
      percent = (diff / yesterday) * 100; // cas normal
    }

    final isPositive = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Appstyle.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${NumberFormatUtil.formatMontant(today, decimales: 0)} $suffix",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          if (showPercent)
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? Appstyle.success : Appstyle.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  "${NumberFormatUtil.formatMontant(percent, decimales: 1)} %",
                  style: TextStyle(
                    color: isPositive ? Appstyle.success : Appstyle.danger,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
class DashboardKpiRow extends StatelessWidget {
  final AppLocalizations l10n;
  final double venteToday;
  final double venteYesterday;
  final double achatToday;
  final double achatYesterday;
  final double netToday;
  final double netYesterday;
  final double creditFournisseur;
  final double creditFournisseurYesterday;
  final double creditClient;
  final double creditClientYesterday;

  const DashboardKpiRow({
    super.key,
    required this.l10n,
    required this.venteToday,
    required this.venteYesterday,
    required this.achatToday,
    required this.achatYesterday,
    required this.netToday,
    required this.netYesterday,
    required this.creditFournisseur,
    required this.creditFournisseurYesterday,
    required this.creditClient,
    required this.creditClientYesterday,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        DashboardKpiAdvancedCard(
          title: l10n.sales,
          today: venteToday,
          yesterday: venteYesterday,
          suffix: "DA",
          color: Appstyle.primary,
          icon: Icons.point_of_sale,
        ),
        DashboardKpiAdvancedCard(
          title: l10n.salesprevious,
          today: venteYesterday,
          yesterday: venteYesterday,
          suffix: "DA",
          showPercent: false,
          color: Appstyle.textMuted,
          icon: Icons.history,
        ),
        DashboardKpiAdvancedCard(
          title: l10n.purchaseToday,
          today: achatToday,
          yesterday: achatYesterday,
          suffix: "DA",
          color: Appstyle.info,
          icon: Icons.shopping_cart_outlined,
        ),
        DashboardKpiAdvancedCard(
          title: l10n.netToday,
          today: netToday,
          yesterday: netYesterday,
          suffix: "DA",
          color: Appstyle.success,
          icon: Icons.trending_up,
        ),
        DashboardKpiAdvancedCard(
          title: l10n.supplierDebt,
          today: creditFournisseur,
          yesterday: creditFournisseurYesterday,
          suffix: "DA",
          color: Appstyle.warning,
          icon: Icons.warning_amber_rounded,
        ),
        DashboardKpiAdvancedCard(
          title: l10n.clientCredit,
          today: creditClient,
          yesterday: creditClientYesterday,
          suffix: "DA",
          color: Appstyle.danger,
          icon: Icons.person_outline,
        ),
      ],
    );
  }
}

// Chart Classes with Localization
class DashboardDynamicSalesChart extends StatelessWidget {
  final AppLocalizations l10n;
  final List<Pannier> panniers;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const DashboardDynamicSalesChart({
    super.key,
    required this.l10n,
    required this.panniers,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    if (dateDebut == null || dateFin == null) {
      return Center(child: Text(l10n.selectPeriod));
    }

    final granularity = _granularity();
    late Map<int, double> data;
    late int count;
    late String title;

    switch (granularity) {
      case ChartGranularity.hourly:
        data = caParHeure(panniers, dateDebut!);
        count = 24;
        title = l10n.salesByHour;
        break;
      case ChartGranularity.daily:
        data = caParJour(panniers, dateDebut!, dateFin!);
        count = dateFin!.difference(dateDebut!).inDays + 1;
        title = l10n.salesByDay;
        break;
      case ChartGranularity.weekly:
        data = caParSemaine(panniers, dateDebut!, dateFin!);
        count = ((dateFin!.difference(dateDebut!).inDays) / 7).ceil();
        title = l10n.salesByWeek;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: LineChart(
            _chartData(data, count),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
          ),
        ),
      ],
    );
  }

  ChartGranularity _granularity() {
    final diff = dateFin!.difference(dateDebut!).inDays;
    if (diff == 0) return ChartGranularity.hourly;
    if (diff <= 7) return ChartGranularity.daily;
    return ChartGranularity.weekly;
  }

  LineChartData _chartData(Map<int, double> data, int count) {
    return LineChartData(
      minY: 0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: 1,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _calcYInterval(data),
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final v = value.toInt();
              if (v < 1 || v > count) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(v.toString(), style: const TextStyle(fontSize: 11)),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: Appstyle.violet,
          barWidth: 4,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Appstyle.violet.withOpacity(0.2),
          ),
          spots: List.generate(count, (i) {
            final x = i + 1;
            return FlSpot(x.toDouble(), data[x] ?? 0);
          }),
        ),
      ],
    );
  }
}

class DashboardBarCaissierChart extends StatelessWidget {
  final AppLocalizations l10n;
  final List<Pannier> panniers;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const DashboardBarCaissierChart({
    super.key,
    required this.l10n,
    required this.panniers,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    if (dateDebut == null || dateFin == null) {
      return Center(child: Text(l10n.selectPeriod));
    }

    final data = caParCaissier(panniers, dateDebut!, dateFin!);
    if (data.isEmpty) return Center(child: Text(l10n.noData));

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.revenueByCashier,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxValue * 1.2,
              barGroups: data.entries
                  .map(
                    (e) => BarChartGroupData(
                  x: data.keys.toList().indexOf(e.key),
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: Appstyle.green2,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxValue * 1.2,
                        color: Appstyle.neutral150,
                      ),
                    ),
                  ],
                ),
              )
                  .toList(),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) =>
                        Text("${value.toInt()} DA", style: const TextStyle(fontSize: 11)),
                    interval: (maxValue / 5).ceilToDouble(),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox();
                      final caissier = data.keys.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(caissier, style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawHorizontalLine: true),
              borderData: FlBorderData(show: false),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeOut,
          ),
        ),
      ],
    );
  }
}

class DashboardProduitBarChart extends StatelessWidget {
  final AppLocalizations l10n;
  final List<PannierProduit> produits;
  final List<Pannier> panniers;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const DashboardProduitBarChart({
    super.key,
    required this.l10n,
    required this.produits,
    required this.panniers,
    this.dateDebut,
    this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    // panniers est déjà filtré par etat (annulés exclus) au chargement du
    // dashboard ; on restreint ici les lignes produit à la période choisie
    // en passant par les codes panier de cette période.
    List<PannierProduit> produitsFiltres = produits;
    if (dateDebut != null && dateFin != null) {
      final s = dateDebut!.startOfDay;
      final e = dateFin!.endOfDay;
      final codesPeriode = panniers
          .where((p) => !p.date.isBefore(s) && !p.date.isAfter(e))
          .map((p) => p.code)
          .toSet();
      produitsFiltres = produits.where((p) => codesPeriode.contains(p.codePannier)).toList();
    }

    if (produitsFiltres.isEmpty) return Center(child: Text(l10n.noData));

    final Map<String, double> totals = {};
    for (var p in produitsFiltres) {
      totals[p.codeProduit] = (totals[p.codeProduit] ?? 0) + p.total;
    }

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = sortedEntries.isEmpty ? 0.0 : sortedEntries.first.value;
    const double barWidth = 40;
    final double chartWidth = sortedEntries.length * (barWidth + 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.salesByProduct,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.2,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(sortedEntries.length, (index) {
                    final entry = sortedEntries[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Appstyle.green2,
                          width: barWidth,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxValue * 1.2,
                            color: Appstyle.neutral150,
                          ),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: (maxValue / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) => Text(
                          "${value.toInt()} DA",
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedEntries.length) return const SizedBox();
                          final produit = sortedEntries[index].key;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 60,
                              child: Text(
                                produit,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawHorizontalLine: true),
                  borderData: FlBorderData(show: false),
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeOut,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Pie Charts with Localization
class DashboardPaymentPieChart extends StatelessWidget {
  final AppLocalizations l10n;
  final List<Pannier> panniers;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const DashboardPaymentPieChart({
    super.key,
    required this.l10n,
    required this.panniers,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    if (dateDebut == null || dateFin == null) {
      return Center(child: Text(l10n.selectPeriod));
    }

    // ✅ FIXED: Pass context to totalParMode
    final totals = totalParMode(panniers, dateDebut!, dateFin!, context);
    final total = totals.values.fold(0.0, (sum, v) => sum + v);
    final displayTotal = total == 0 ? 1 : total;
    final translator = ListsConstTranslator(l10n);

    final colors = [
      Appstyle.success,
      Appstyle.primary,
      Appstyle.warning,
      Appstyle.info,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.salesByPaymentMethod,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: List.generate(ListsConst.modePaiementList.length, (index) {
                      final mode = ListsConst.modePaiementList[index];
                      final value = totals[mode]!;
                      return PieChartSectionData(
                        value: value <= 0 ? 0.01 : value,
                        color: colors[index % colors.length],
                        radius: 60,
                        title: "${NumberFormatUtil.formatMontant(((value / displayTotal) * 100), decimales: 0)}%",
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    }),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeOut,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _PaymentResume(
                  totals: totals,
                  colors: colors,
                  translator: translator,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(ListsConst.modePaiementList.length, (index) {
            final mode = ListsConst.modePaiementList[index];
            return _Legend(
              color: colors[index % colors.length],
              text: translator.translateModePaiement(mode),
            );
          }),
        ),
      ],
    );
  }
}

class DashboardCAPieChart extends StatelessWidget {
  final AppLocalizations l10n;
  final List<Pannier> panniers;
  final List<Verssement> versements;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const DashboardCAPieChart({
    super.key,
    required this.l10n,
    required this.panniers,
    required this.versements,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    if (dateDebut == null || dateFin == null) {
      return Center(child: Text(l10n.selectPeriod));
    }

    final totalMontant = totalMontantPeriode(panniers, dateDebut!, dateFin!);
    final totalCredit = totalCreditPeriode(panniers, versements, dateDebut!, dateFin!);
    final encaisse = totalMontant - totalCredit;
    final total = totalMontant == 0 ? 1 : totalMontant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.revenueDistribution,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: [
                      _section(
                        value: encaisse,
                        color: Appstyle.green2,
                        title: "${NumberFormatUtil.formatMontant(((encaisse / total) * 100), decimales: 0)}%",
                      ),
                      _section(
                        value: totalCredit,
                        color: Appstyle.danger,
                        title: "${NumberFormatUtil.formatMontant(((totalCredit / total) * 100), decimales: 0)}%",
                      ),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeOut,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _MontantResume(
                  l10n: l10n,
                  encaisse: encaisse,
                  credit: totalCredit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 50),
            _Legend(color: Appstyle.green2, text: l10n.collected),
            _Legend(color: Appstyle.danger, text: l10n.credit),
          ],
        ),
      ],
    );
  }

  PieChartSectionData _section({
    required double value,
    required Color color,
    required String title,
  }) {
    return PieChartSectionData(
      value: value <= 0 ? 0.01 : value,
      color: color,
      radius: 60,
      title: title,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}

class _MontantResume extends StatelessWidget {
  final AppLocalizations l10n;
  final double encaisse;
  final double credit;

  const _MontantResume({
    required this.l10n,
    required this.encaisse,
    required this.credit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _item(
          color: Appstyle.green2,
          label: l10n.collected,
          value: encaisse,
        ),
        const SizedBox(height: 16),
        _item(
          color: Appstyle.danger,
          label: l10n.credit,
          value: credit,
        ),
      ],
    );
  }

  Widget _item({
    required Color color,
    required String label,
    required double value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              "${NumberFormatUtil.formatMontant(value, decimales: 0)} DA",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Filter Classes with Localization
class DashboardFiltersWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController dateDebutCtrl;
  final TextEditingController dateFinCtrl;
  final String? periodeRapide;
  final VoidCallback onPickDateDebut;
  final VoidCallback onPickDateFin;
  final ValueChanged<String?> onPeriodeChanged;
  final VoidCallback? onExport;

  const DashboardFiltersWidget({
    super.key,
    required this.l10n,
    required this.dateDebutCtrl,
    required this.dateFinCtrl,
    required this.periodeRapide,
    required this.onPickDateDebut,
    required this.onPickDateFin,
    required this.onPeriodeChanged,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final periodesRapides = periodesRapidesLabels(l10n);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Appstyle.violet.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
      ),
      child: Row(
        children: [
          PeriodeDateFilter(
            l10n: l10n,
            dateDebutCtrl: dateDebutCtrl,
            dateFinCtrl: dateFinCtrl,
            periodeRapide: periodeRapide,
            periodesRapides: periodesRapides,
            onPickDateDebut: onPickDateDebut,
            onPickDateFin: onPickDateFin,
            onPeriodeChanged: onPeriodeChanged,
          ),
          const Spacer(),
          _exportButton(l10n),
        ],
      ),
    );
  }

  Widget _exportButton(AppLocalizations l10n) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.download, size: 18),
      label: Text(l10n.export),
      style: ElevatedButton.styleFrom(
        backgroundColor: Appstyle.violet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
      ),
      onPressed: onExport ?? () {},
    );
  }
}

class PeriodeDateFilter extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController dateDebutCtrl;
  final TextEditingController dateFinCtrl;
  final String? periodeRapide;
  final Map<String, String> periodesRapides;
  final VoidCallback onPickDateDebut;
  final VoidCallback onPickDateFin;
  final ValueChanged<String?> onPeriodeChanged;

  const PeriodeDateFilter({
    super.key,
    required this.l10n,
    required this.dateDebutCtrl,
    required this.dateFinCtrl,
    required this.periodeRapide,
    required this.periodesRapides,
    required this.onPickDateDebut,
    required this.onPickDateFin,
    required this.onPeriodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dateField(l10n.from, dateDebutCtrl, onPickDateDebut),
        const SizedBox(width: 12),
        _dateField(l10n.to, dateFinCtrl, onPickDateFin),
        const SizedBox(width: 12),
        _periodeDropdown(),
      ],
    );
  }

  Widget _periodeDropdown() {
    return PeriodeRapideDropdown(
      l10n: l10n,
      value: periodeRapide,
      onSelected: onPeriodeChanged,
      width: 154,
    );
  }

  Widget _dateField(
      String label,
      TextEditingController controller,
      VoidCallback onTap,
      ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      ),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(hintText: label, border: InputBorder.none),
      ),
    );
  }
}

// Supporting Widgets
class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _PaymentResume extends StatelessWidget {
  final Map<String, double> totals;
  final List<Color> colors;
  final ListsConstTranslator translator;

  const _PaymentResume({
    required this.totals,
    required this.colors,
    required this.translator,
  });

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView : les libellés de mode de paiement sont traduits
    // (fr/ar/en) et de longueur variable — un Column figé débordait déjà
    // verticalement avec certaines traductions plus longues.
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(ListsConst.modePaiementList.length, (index) {
          final mode = ListsConst.modePaiementList[index];
          final value = totals[mode]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translator.translateModePaiement(mode),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${NumberFormatUtil.formatMontant(value, decimales: 0)} DA",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class DashboardListCard extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;

  const DashboardListCard({
    required this.title,
    this.items = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  dense     : true,
                  title     : Text(item["name"] ?? ""),
                  trailing  : Text(item["value"] ?? ""),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
