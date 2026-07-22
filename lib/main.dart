import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'DBCreate.dart';
import 'router.dart';
import 'core/Auth/auth_state.dart';
import 'core/locale/locale_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final localeProvider = LocaleProvider();

  final authState = AuthState.getInstance(localeProvider);

  await authState.loadActivationState();

  // Verify activation on start
  final isValid = await authState.verifyActivationOnStart();
  if (!isValid && authState.isActivated) {
    debugPrint('⚠️ Activation verification failed - possible license violation');
  }

  try {
    await DbCreator.openDb();
    debugPrint('🔐 Secure database initialized successfully');
  } catch (e) {
    debugPrint('❌ Database initialization failed: $e');
    rethrow;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authState),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
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
      routerConfig: AppRouter.createRouter(authState),
    );
  }

  ThemeData _buildTheme(LocaleProvider localeProvider) {
    final isRTL = localeProvider.isRTL;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
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