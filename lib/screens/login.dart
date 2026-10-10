import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/Auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  String? error;
  bool rememberMe = false;

  // Animation d'entrée du logo (slide gauche → centre + fade), jouée une
  // seule fois à l'ouverture de l'écran de login — léger effet "ressort"
  // (easeOutBack) pour un rendu moderne et énergique plutôt qu'un simple fondu.
  late final AnimationController _logoController;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoFade;

  // Titre "Connexion à votre compte" : fondu + léger glissement du bas vers
  // le haut, décalé après le logo (Interval démarrant à 0.35) sur le même
  // contrôleur — un seul enchaînement logo → titre au lieu de deux
  // animations indépendantes qui démarreraient en même temps.
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(-1.8, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)));
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  // Style de champ unique (au lieu d'être dupliqué pour username/password) —
  // bordure/focus alignés sur le violet de marque plutôt que le bleu
  // générique utilisé auparavant.
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    final radius = BorderRadius.circular(Appstyle.radiusMD);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Appstyle.textSecondary),
      prefixIcon: Icon(icon, color: Appstyle.textMuted),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Appstyle.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Appstyle.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Appstyle.violet, width: 2),
      ),
      filled: true,
      fillColor: Appstyle.violetC,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            // ✅ Ordre photo/formulaire toujours LTR, même en arabe (RTL) :
            // la mise en page reste identique quelle que soit la langue.
            textDirection: TextDirection.ltr,
            children: [
              // SECTION GAUCHE - Image de fond avec voile dégradé violet
              // (reprend le gradient de marque utilisé par la sidebar/le
              // header, plutôt qu'une simple photo sans lien avec l'identité
              // visuelle de l'app) — assure aussi la lisibilité du texte.
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/login_back.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(

                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            l10n.loginWelcome,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(width: 100, height: 4, color: Colors.white),
                          SizedBox(height: Appstyle.spaceL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // SECTION DROITE - Formulaire de connexion
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 30,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo — animation d'entrée slide gauche → centre
                          SlideTransition(
                            position: _logoSlide,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: Image.asset(
                                'assets/icons/caisse_dz_logo.png',
                                height: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.shopping_cart,
                                    size: 80,
                                    color: Appstyle.info,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Titre — fondu + glissement du bas vers le haut,
                          // enchaîné après l'animation du logo.
                          SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleFade,
                              child: Text(
                                l10n.loginToYourAccount,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Appstyle.violet,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.loginInstructions,
                            style: TextStyle(
                              fontSize: 14,
                              color: Appstyle.neutral500,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Champ Utilisateur
                          TextField(
                            controller: usernameController,
                            decoration: _fieldDecoration(
                              label: l10n.username,
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Champ Mot de passe
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: _fieldDecoration(
                              label: l10n.password,
                              icon: Icons.lock_outline,
                            ),
                          ),

                          // Rester connecté + Mot de passe oublié
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () =>
                                    setState(() => rememberMe = !rememberMe),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      activeColor: Appstyle.violet,
                                      onChanged: (value) => setState(
                                        () => rememberMe = value ?? false,
                                      ),
                                    ),
                                    Text(
                                      l10n.rememberMe,
                                      style: TextStyle(
                                        color: Appstyle.ink500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Ajouter la logique de mot de passe oublié
                                },
                                child: Text(
                                  l10n.forgotPassword,
                                  style: TextStyle(
                                    color: Appstyle.violet,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Message d'erreur
                          if (error != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Appstyle.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                                border: Border.all(color: Appstyle.danger.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Appstyle.danger,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: TextStyle(
                                        color: Appstyle.danger,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],

                          // Bouton Se connecter — MainButton unifié (Phase 1)
                          // au lieu d'un ElevatedButton ad hoc.
                          MainButton(
                            width: double.infinity,
                            height: 52,
                            text: l10n.signIn,
                            color: Appstyle.violet,
                            icon: Icons.lock_outline,
                            loading: loading,
                            onPressed: () async {
                              setState(() {
                                loading = true;
                                error = null;
                              });

                              final success = await auth.login(
                                usernameController.text.trim(),
                                passwordController.text.trim(),
                                rememberMe: rememberMe,
                              );

                              if (!success) {
                                setState(() {
                                  error = l10n.invalidCredentials;
                                  loading = false;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 20),

                          // Lien Activation
                          if (!auth.isActivated)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.appNotActivatedQuestion,
                                    style: TextStyle(
                                      color: Appstyle.neutral500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.push('/activate');
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Appstyle.dangerInk,
                                    ),
                                    child: Text(
                                      l10n.activateNow,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 10),

                          // Version
                          Text(
                            "${l10n.version} 1.0.0",
                            style: TextStyle(
                              color: Appstyle.neutral300,
                              fontSize: 12,
                            ),
                          ),

                          // Debug uniquement : l'activation/le palier vivent
                          // dans le secure storage, indépendamment de la base
                          // — supprimer la base ne les réinitialise pas.
                          // Toujours visible ici (contrairement au lien
                          // "Activer maintenant" ci-dessus, masqué une fois
                          // activé) puisque c'est justement pour sortir de
                          // l'état "déjà activé" en test.
                          if (kDebugMode) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () async {
                                await auth.resetActivationForTesting();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Appstyle.neutral300,
                              ),
                              child: const Text(
                                "[DEBUG] Réinitialiser l'activation",
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
