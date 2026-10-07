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
    // Le ColorScheme Material3 est aligné sur Appstyle (seul système de
    // couleurs utilisé concrètement dans l'app, cf. lib/core/theme/app_style.dart)
    // plutôt que sur un violet Material générique : les widgets standards
    // (Checkbox, Switch, Scrollbar...) qui n'overrident pas leur couleur
    // héritent ainsi de la même identité que le reste de l'UI.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Appstyle.violet,
      brightness: Brightness.light,
    ).copyWith(
      primary: Appstyle.violet,
      secondary: Appstyle.indigo,
      error: Appstyle.red,
      surface: Appstyle.Tblanc,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Appstyle.background,
      // Font family based on locale
      fontFamily: isRTL ? 'Cairo' : 'Poppins',
      // RTL-specific adjustments
      textTheme: isRTL
          ? const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Cairo'),
        bodyMedium: TextStyle(fontFamily: 'Cairo'),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      )
          : null,
      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: isRTL, // Center title in Arabic
        titleTextStyle: TextStyle(
          fontFamily: isRTL ? 'Cairo' : 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}