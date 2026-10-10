import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'DBCreate.dart';
import 'router.dart';
import 'core/Auth/auth_state.dart';
import 'core/locale/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'Services/BackupService.dart';
import 'core/utilis/quantite_format.dart';
import 'core/theme/app_style.dart';
import 'core/widget/custom_title_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Taille minimale de fenêtre — les contrôles de fenêtre intégrés (voir
  // custom_title_bar.dart) remplacent le cadre Windows par défaut, qui imposait déjà
  // implicitement une taille minimale raisonnable.
  doWhenWindowReady(() {
    appWindow.minSize = const Size(1000, 700);
  });

  final localeProvider = LocaleProvider();

  final authState = AuthState.getInstance(localeProvider);

  await authState.loadActivationState();

  // Verify activation on start
  final isValid = await authState.verifyActivationOnStart();
  if (!isValid && authState.isActivated) {
    debugPrint('⚠️ Activation verification failed - possible license violation');
  }

  // Reconnecte automatiquement l'utilisateur si une session a été mémorisée
  // via la case "Rester connecté" du login (voir AuthState.tryAutoLogin).
  if (!authState.isAuthenticated) {
    await authState.tryAutoLogin();
  }

  // Sans cet appel, userParam reste null pour toute la session et l'écran
  // Paramètres tente une création au lieu d'une mise à jour, ce qui échoue
  // si la ligne existe déjà.
  if (authState.isAuthenticated) {
    await authState.loadUserParameters();
  }

  try {
    await DbCreator.openDb();
    debugPrint('🔐 Secure database initialized successfully');
  } catch (e) {
    debugPrint('❌ Database initialization failed: $e');
    rethrow;
  }

  try {
    await QuantiteFormat.load();
  } catch (e) {
    debugPrint('⚠️ Chargement du format quantité échoué (repli sur 2 décimales): $e');
  }

  try {
    await BackupService.checkAndRunAutoBackup();
  } catch (e) {
    debugPrint('⚠️ Sauvegarde automatique ignorée: $e');
  }

  // Le routeur ne doit être créé qu'une seule fois : `refreshListenable:
  // authState` (voir router.dart) suffit déjà à lui faire réévaluer ses
  // redirections à chaque notifyListeners(). Le recréer à chaque build de
  // MyApp (comme c'était fait avant, via Provider.of<AuthState>(listen:
  // true) + AppRouter.createRouter dans build()) réinitialise toute la
  // navigation sur initialLocation à chaque changement d'AuthState — par
  // exemple à chaque sauvegarde de paramètres — et éjecte l'utilisateur de
  // l'écran courant en pleine sauvegarde (setState after dispose).
  final router = AppRouter.createRouter(authState);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authState),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: MyApp(router: router),
    ),
  );
}


class MyApp extends StatelessWidget {
  final GoRouter router;

  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Caisse DZ',

      // 🌍 LOCALIZATION
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'), // French (default)
        Locale('ar'), // Arabic (RTL)
        Locale('en'), // English
      ],
      locale: localeProvider.locale,

      // Dynamic Theme with Arabic Font Support
      theme: _buildTheme(localeProvider),
      routerConfig: router,

      // Plus de barre de titre séparée : AppShell intègre logo, titre et
      // boutons de fenêtre (sidebar + ligne des favoris). Les écrans hors
      // AppShell (login, activation…) reçoivent ici des boutons flottants en
      // haut à droite. Voir custom_title_bar.dart et windows/runner/main.cpp
      // (bitsdojo_window_configure).
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(child: child ?? const SizedBox.shrink()),
            const Positioned(top: 0, left: 0, right: 0, child: BoutonsFenetreFlottants()),
          ],
        );
      },
    );
  }

  ThemeData _buildTheme(LocaleProvider localeProvider) {
    final isRTL = localeProvider.isRTL;
    // Thème aligné sur le design system CaisseDZ (Appstyle) : les widgets
    // Material qui n'overrident pas leur style (Checkbox, Switch, champs,
    // boutons, dialogs, infobulles, scrollbar…) héritent de la marque.
    // Police : Inter (latin) et Alexandria (arabe, en tête en RTL).
    final fontFamily = isRTL ? Appstyle.fontArabic : Appstyle.fontLatin;
    final fallback = [isRTL ? Appstyle.fontLatin : Appstyle.fontArabic];
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Appstyle.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: Appstyle.primary,
      onPrimary: Appstyle.onPrimary,
      primaryContainer: Appstyle.primarySoft,
      onPrimaryContainer: Appstyle.primaryDark,
      secondary: Appstyle.primaryDark,
      error: Appstyle.danger,
      surface: Appstyle.surface,
      onSurface: Appstyle.textPrimary,
      outline: Appstyle.border,
      outlineVariant: Appstyle.surfaceBorder,
    );
    final rayonChamp = BorderRadius.circular(Appstyle.radiusMD);
    final rayonBouton = BorderRadius.circular(Appstyle.radiusButton);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Appstyle.background,
      fontFamily: fontFamily,
      fontFamilyFallback: fallback,
      dividerColor: Appstyle.surfaceBorder,
      appBarTheme: AppBarTheme(
        centerTitle: isRTL, // Center title in Arabic
        backgroundColor: Appstyle.surface,
        foregroundColor: Appstyle.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Appstyle.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Appstyle.surface2,
        hintStyle: const TextStyle(color: Appstyle.disabledFg),
        border: OutlineInputBorder(borderRadius: rayonChamp, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: rayonChamp, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: rayonChamp,
          borderSide: const BorderSide(color: Appstyle.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: rayonChamp,
          borderSide: const BorderSide(color: Appstyle.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: rayonChamp,
          borderSide: const BorderSide(color: Appstyle.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Appstyle.primary,
          foregroundColor: Appstyle.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: rayonBouton),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Appstyle.primary,
          shape: RoundedRectangleBorder(borderRadius: rayonBouton),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Appstyle.primary,
          side: const BorderSide(color: Appstyle.primary),
          shape: RoundedRectangleBorder(borderRadius: rayonBouton),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Appstyle.primary,
          shape: RoundedRectangleBorder(borderRadius: rayonBouton),
        ),
      ),
      cardTheme: CardThemeData(
        color: Appstyle.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Appstyle.radiusCard),
          side: const BorderSide(color: Appstyle.surfaceBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Appstyle.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusDialog)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusXS)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Appstyle.surface2,
        selectedColor: Appstyle.primarySoft,
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Appstyle.textPrimary,
          borderRadius: BorderRadius.circular(Appstyle.radiusSM),
        ),
        textStyle: TextStyle(fontFamily: fontFamily, fontFamilyFallback: fallback, color: Appstyle.Tblanc, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Appstyle.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(Appstyle.border.withOpacity(0.8)),
        radius: const Radius.circular(Appstyle.radiusPill),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Appstyle.primary),
    );
  }
}