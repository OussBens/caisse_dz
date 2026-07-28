import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
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
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

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

double totalCreditPeriode(List<Pannier> list, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;
  return list
      .where((p) => !p.date.isBefore(s) && !p.date.isAfter(e))
      .fold(0, (s, p) => s + p.reste);
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

List<Map<String, String>> getProduitsRupture(List<Produit> produits) {
  final filtered = produits.where((p) => p.quantite < p.seuilMin).toList();
  filtered.sort((a, b) => a.quantite.compareTo(b.quantite));
  return filtered.take(10).map((p) => {
    "name": p.nom,
    "value": p.quantite.toStringAsFixed(0),
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
double totalAchatC(List<SmartScan> list, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;
  return list
      .where((ss) => !ss.date.isBefore(s) && !ss.date.isAfter(e))
      .fold(0.0, (s, p) => s + p.reste);
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
double totalCreditC(List<Pannier> list, DateTime start, DateTime end) {
  final s = start.startOfDay;
  final e = end.endOfDay;

  return list
      .where((p) =>
  !p.date.isBefore(s) &&
      !p.date.isAfter(e))
      .fold(0.0, (sum, p) => sum + p.reste);
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

double totalStockValue(List<Produit> produits, {bool usePrixVente = true}) {
  return produits.fold(0.0, (s, p) {
    final prix = usePrixVente ? p.prixVente : p.prixAchat;
    return s + p.quantite * prix;
  });
}

class _DashScreenState extends State<DashScreen> {

  bool _isLoading = true;
  bool _dataLoaded = false;
  List<PannierProduit>  pannierProduitsTest = [];
  List<Fournisseur>     fournisseursTest    = [];
  List<SmartScan>       smartScansTest      = [];
  List<Produit>         produitsTest        = [];
  List<Pannier>         paniersTest         = [];
  List<Client>          clientsTest         = [];
  void initState() {
    super.initState();
    _initDashboard();
  }
  Future<void> _initDashboard() async {
    await _LoadAllData();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _dataLoaded = true;
      });
    }
  }
  Future<void> _LoadAllData() async {
    final db = await DbCreator.openDb();
    pannierProduitsTest = await PPServices.getAllPP();
    fournisseursTest    = await FournisseurServices.getAllFournisseurs();
    smartScansTest      = await SmartScanServices.getAllSmartScans();
    produitsTest        = await ProduitServices.getAllProduits();
    paniersTest         = await PannierServices.getAllPanniers();
    clientsTest         = await ClientServices.getAllClients();
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
    final credit = totalCreditC(paniersTest, dateDebut!, dateFin!);
    final creditPrev = totalCreditC(paniersTest, previous.start, previous.end);
    final creditF = totalAchatC(smartScansTest, dateDebut!, dateFin!);
    final creditFPrev = totalAchatC(smartScansTest, previous.start, previous.end);

    final ventesStat = ventesStats(paniersTest, dateDebut!, dateFin!);
    final ventesStatPrev = ventesStats(paniersTest, previous.start, previous.end);
    final stockVente = totalStockValue(produitsTest, usePrixVente: true);
    final stockAchat = totalStockValue(produitsTest, usePrixVente: false);

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
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
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
                            /// SIDEBAR - Reordered for RTL
                            SideBarWidget(),
                            /// MAIN CONTENT
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [

                                    /// HEADER
                                    HeaderModule(
                                      gradientColors: [
                                        Appstyle.green2.withOpacity(0.95),
                                        Appstyle.green2.withOpacity(0.6),
                                      ],
                                      child: Row(
                                        children: [
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/icons/sidebar/dash_icon.png",
                                                width: 40,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                l10n.dashboard,
                                                style: Appstyle.textXLB.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
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
                                              borderRadius: BorderRadius.circular(16),
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
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: DashboardCAPieChart(
                                              l10n: l10n,
                                              panniers: paniersTest,
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
                                              borderRadius: BorderRadius.circular(16),
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
                                              borderRadius: BorderRadius.circular(16),
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
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: DashboardProduitBarChart(
                                              l10n: l10n,
                                              dateDebut: dateDebut,
                                              dateFin: dateFin,
                                              produits: pannierProduitsTest,
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
                                            items: getProduitsRupture(produitsTest),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),

                          ],
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

  const DashboardKpiAdvancedCard({
    super.key,
    required this.title,
    required this.today,
    required this.yesterday,
    this.suffix = "",
    this.showPercent = true,
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
        color: Appstyle.violet.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            "${today.toStringAsFixed(0)} $suffix",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (showPercent)
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  "${percent.toStringAsFixed(1)} %",
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
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
        ),
        DashboardKpiAdvancedCard(
          title: l10n.salesprevious,
          today: venteYesterday,
          yesterday: venteYesterday,
          suffix: "DA",
          showPercent: false,
        ),
        DashboardKpiAdvancedCard(
          title: l10n.purchaseToday,
          today: achatToday,
          yesterday: achatYesterday,
          suffix: "DA",
        ),
        DashboardKpiAdvancedCard(
          title: l10n.netToday,
          today: netToday,
          yesterday: netYesterday,
          suffix: "DA",
        ),
        DashboardKpiAdvancedCard(
          title: l10n.supplierDebt,
          today: creditFournisseur,
          yesterday: creditFournisseurYesterday,
          suffix: "DA",
        ),
        DashboardKpiAdvancedCard(
          title: l10n.clientCredit,
          today: creditClient,
          yesterday: creditClientYesterday,
          suffix: "DA",
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
                        color: Colors.grey[200],
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
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const DashboardProduitBarChart({
    super.key,
    required this.l10n,
    required this.produits,
    this.dateDebut,
    this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    if (produits.isEmpty) return Center(child: Text(l10n.noData));

    final Map<String, double> totals = {};
    for (var p in produits) {
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
                            color: Colors.grey[200],
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

    final colors = [
      Appstyle.green2,
      Appstyle.violet,
      Colors.orange,
      Colors.blue,
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
                        title: "${((value / displayTotal) * 100).toStringAsFixed(0)}%",
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
              text: mode,
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
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const DashboardCAPieChart({
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

    final totalMontant = totalMontantPeriode(panniers, dateDebut!, dateFin!);
    final totalCredit = totalCreditPeriode(panniers, dateDebut!, dateFin!);
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
                        title: "${((encaisse / total) * 100).toStringAsFixed(0)}%",
                      ),
                      _section(
                        value: totalCredit,
                        color: Colors.redAccent,
                        title: "${((totalCredit / total) * 100).toStringAsFixed(0)}%",
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
            _Legend(color: Colors.redAccent, text: l10n.credit),
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
          color: Colors.redAccent,
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
              "${value.toStringAsFixed(0)} DA",
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

  Map<String, String> _getPeriodesRapides(AppLocalizations l10n) {
    return {
      "today": l10n.today,
      "yesterday": l10n.yesterday,
      "week": l10n.thisWeek,
      "lastWeek": l10n.lastWeek,
      "month": l10n.thisMonth,
      "lastMonth": l10n.lastMonth,
      "last7days": l10n.last7Days,
      "last30days": l10n.last30Days,
      "year": l10n.thisYear,
      "lastYear": l10n.lastYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final periodesRapides = _getPeriodesRapides(l10n);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Appstyle.violet.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: periodeRapide,
        underline: const SizedBox(),
        hint: Text(l10n.quickPeriod),
        isExpanded: true,
        items: periodesRapides.entries.map((e) {
          return DropdownMenuItem<String>(value: e.key, child: Text(e.value));
        }).toList(),
        onChanged: onPeriodeChanged,
      ),
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
        borderRadius: BorderRadius.circular(12),
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

  const _PaymentResume({required this.totals, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(ListsConst.modePaiementList.length, (index) {
        final mode = ListsConst.modePaiementList[index];
        final value = totals[mode]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode, style: const TextStyle(fontSize: 12)),
                  Text("${value.toStringAsFixed(0)} DA",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      }),
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
        borderRadius: BorderRadius.circular(16),
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