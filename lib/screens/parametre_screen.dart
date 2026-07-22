import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_style.dart';
import '../core/utilis/constant.dart';
import '../core/widget/side_bar.dart';
import '../l10n/app_localizations.dart';
import '../core/locale/locale_provider.dart';

// 👇 IMPORT SAME WIDGETS AS DIALOG
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/text_champ_l.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/time_date_widget.dart';
import '../core/widget/header_module.dart';
import '../core/widget/account.dart';
import '../core/widget/button/main_button.dart';

class ParametreScreen extends StatefulWidget {
  const ParametreScreen({super.key});

  @override
  State<ParametreScreen> createState() => _ParametreScreenState();
}

class _ParametreScreenState extends State<ParametreScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController appIdController = TextEditingController();

  String? selectedLanguage = "fr";
  String? selectedCurrency = "DZD";
  String? selectedMagasin = "";
  String? selectedMagasinId = "";

  bool _isLoading = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Available options
  final List<String> availableLanguages = const ["fr", "en", "ar"];
  final List<String> availableCurrencies = const ["DZD", "EUR", "USD"];

  // For demo - these should come from a magasin service
  final List<Map<String, String>> availableMagasins = const [
    {"id": "MAG001", "name": "Main Store"},
    {"id": "MAG002", "name": "Branch Store"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserParameters();
  }

  @override
  void dispose() {
    usernameController.dispose();
    shopNameController.dispose();
    appIdController.dispose();
    super.dispose();
  }

  Future<void> _loadUserParameters() async {
    final auth = Provider.of<AuthState>(context, listen: false);

    // Load user info
    usernameController.text = auth.username ?? "";

    // Load user parameters from AuthState
    final userParam = auth.userParam;
    if (userParam != null) {
      setState(() {
        selectedLanguage = userParam.language ?? "fr";
        selectedCurrency = userParam.currency ?? "DZD";
        selectedMagasin = userParam.magasin;
        selectedMagasinId = userParam.magasinid;
        shopNameController.text = userParam.magasin ?? "";
        appIdController.text = userParam.magasinid ?? "";
      });
    } else {
      // Set defaults
      setState(() {
        selectedLanguage = auth.currentLanguage ?? "fr";
        selectedCurrency = auth.currentCurrency ?? "DZD";
        selectedMagasin = auth.currentMagasin;
        selectedMagasinId = auth.currentMagasinId;
        shopNameController.text = auth.currentMagasin ?? "";
        appIdController.text = auth.currentMagasinId ?? "";
      });
    }
  }

  Future<void> saveParameters() async {
    if (!formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthState>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    // Check if user is logged in
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseLoginFirst)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update user parameters in database
      final success = await auth.updateUserParameters(
        language: selectedLanguage!,
        currency: selectedCurrency!,
        magasin: shopNameController.text,
        magasinId: appIdController.text,
        modifiedBy: auth.username!,
        modifiedByCode: auth.userCode!,
        reason: "Parameter update from settings screen",
      );

      if (success) {
        // Change app language if needed
        if (selectedLanguage != auth.currentLanguage) {
          await localeProvider.setLocale(selectedLanguage!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSaved),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSavingSettings),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorSavingSettings}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void resetParameters() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthState>(context, listen: false);

    setState(() {
      usernameController.text = auth.username ?? "";
      selectedLanguage = auth.currentLanguage ?? "fr";
      selectedCurrency = auth.currentCurrency ?? "DZD";
      selectedMagasin = auth.currentMagasin;
      selectedMagasinId = auth.currentMagasinId;
      shopNameController.text = auth.currentMagasin ?? "";
      appIdController.text = auth.currentMagasinId ?? "";
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsReset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

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

            final halfScreenWidth = adjustedWidth * 0.5;

            return SingleChildScrollView(
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
                        textDirection: textDirection,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Sidebar
                          SideBarWidget(),

                          /// Content
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
                                        /// LEFT: Icon + Title
                                        Row(
                                          textDirection: textDirection,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              "assets/icons/sidebar/parametre_icon.png",
                                              width: 40,
                                              color: Appstyle.blueC.withOpacity(0.7),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              l10n.parametre,
                                              style: Appstyle.textXLB.copyWith(
                                                color: Appstyle.blueC.withOpacity(0.7),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),

                                        /// RIGHT: Time + Account
                                        Row(
                                          textDirection: textDirection,
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

                                  SizedBox(height: paddingV),

                                  /// Settings Form
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: paddingH),
                                    child: Form(
                                      key: formKey,
                                      child: Column(
                                        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          /// User Information Section
                                          _section(
                                            title: l10n.userInformation,
                                            icon: "assets/icons/info_icon.png",
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: halfScreenWidth,
                                                  child: ChampAvecLabel(
                                                    label: l10n.username,
                                                    obligatoire: true,
                                                    child: TextChampL(
                                                      controller: usernameController,
                                                      obligatoire: true,
                                                      hint: l10n.enterUsername,
                                                      enabled: false, // Username can't be changed
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(height: paddingV),

                                          /// Shop Information Section
                                          _section(
                                            title: l10n.shopInformation,
                                            icon: "assets/icons/sidebar/magasin_icon.png",
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: halfScreenWidth,
                                                  child: ChampAvecLabel(
                                                    label: l10n.shopName,
                                                    obligatoire: true,
                                                    child: TextChampL(
                                                      controller: shopNameController,
                                                      obligatoire: true,
                                                      hint: l10n.enterShopName,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                SizedBox(
                                                  width: halfScreenWidth,
                                                  child: ChampAvecLabel(
                                                    label: l10n.appId,
                                                    obligatoire: true,
                                                    child: TextChampL(
                                                      controller: appIdController,
                                                      obligatoire: true,
                                                      hint: l10n.enterAppId,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(height: paddingV),

                                          /// System Settings Section
                                          _section(
                                            title: l10n.systemSettings,
                                            icon: "assets/icons/sidebar/parametre_icon.png",
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: halfScreenWidth,
                                                  child: ChampAvecLabel(
                                                    label: l10n.language,
                                                    child: TextListe(
                                                      value: selectedLanguage,
                                                      items: availableLanguages,
                                                      onChanged: (v) => setState(() => selectedLanguage = v),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                SizedBox(
                                                  width: halfScreenWidth,
                                                  child: ChampAvecLabel(
                                                    label: l10n.currency,
                                                    child: TextListe(
                                                      value: selectedCurrency,
                                                      items: availableCurrencies,
                                                      onChanged: (v) => setState(() => selectedCurrency = v),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(height: paddingV * 1.5),

                                          /// Buttons
                                          SizedBox(
                                            width: halfScreenWidth,
                                            child: Row(
                                              textDirection: textDirection,
                                              children: [
                                                Expanded(
                                                  child: MainButton(
                                                    text: _isLoading ? l10n.saving : l10n.save,
                                                    color: Appstyle.violet,
                                                    onPressed: _isLoading ? null : saveParameters,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: MainButton(
                                                    text: l10n.reset,
                                                    color: Appstyle.gris,
                                                    onPressed: _isLoading ? null : resetParameters,
                                                  ),
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
                        ],
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

/// Section widget matching the design of GestionCaisseScreen
Widget _section({
  required String title,
  required String icon,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    decoration: BoxDecoration(
      color: Appstyle.Tblanc,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Appstyle.grisC, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              icon,
              width: 22,
              height: 22,
              color: Appstyle.Tblue,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Appstyle.textL.copyWith(
                color: Appstyle.Tblue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}