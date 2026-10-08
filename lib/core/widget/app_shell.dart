import '../theme/app_style.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../locale/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../Auth/auth_state.dart';
import '../dialog/alertes/alerte_dialog.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/dialog_kind.dart';
import '../dialog/caisse_session/caisse_fermee_dialog.dart';
import '../../Services/CaisseGestion.dart';
import '../../Services/CaisseSession.dart';
import 'custom_title_bar.dart';
import 'side_bar.dart';

/// Shell partagé par tous les écrans authentifiés (branché sur un ShellRoute,
/// voir router.dart) : la sidebar est montée une seule fois pour toute la
/// session et reste en place d'un module à l'autre — seul `child` (le
/// contenu du module courant) est remonté au changement de route, au lieu de
/// toute la page comme auparavant (chaque écran instanciait son propre
/// Scaffold + SideBarWidget, ce qui recréait aussi la sidebar à chaque clic).
class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Permet de déclencher showModuleMenu() sur la sidebar depuis
  // _runFirstLaunchMenu ci-dessous.
  final GlobalKey<SideBarWidgetState> _sideBarKey = GlobalKey<SideBarWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // AppShell intègre ses propres boutons de fenêtre : masque les boutons
      // flottants de main.dart (après le build, pas pendant).
      BoutonsFenetreFlottants.shellActif.value = true;
      // La barre des favoris a besoin de l'état de la sidebar (modules
      // visibles), disponible seulement après le premier build.
      if (mounted) setState(() {});
      _showMenuAfterLogin();
    });
  }

  // ✅ AppShell est démonté au logout (redirection vers /login, hors du
  // ShellRoute, voir router.dart) et remonté à chaque connexion suivante :
  // son initState se déclenche donc exactement une fois par login, ce qui en
  // fait l'endroit fiable pour ouvrir le menu rapide de modules à chaque
  // connexion (et non plus une seule fois par lancement de process) —
  // reprend la logique qui vivait auparavant dans CaisseScreen, qui ne
  // fonctionnait que parce que /caisse était toujours l'écran d'atterrissage
  // après login.
  Future<void> _showMenuAfterLogin() async {
    if (!mounted) return;

    await _sideBarKey.currentState?.roleReady;
    if (!mounted) return;
    // Alertes (rupture, expirations, crédits, sessions non clôturées) avant
    // le menu rapide — seulement s'il y a quelque chose à signaler.
    await AlerteDialog(context, seulementSiAlertes: true);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await _sideBarKey.currentState?.showModuleMenu(context, l10n);
    if (!mounted) return;
    await _ouvrirCaisseSiFermee();
  }

  // ✅ Juste après le menu rapide de connexion : si la caisse courante de
  // l'utilisateur n'a pas de session ouverte, propose immédiatement de
  // l'ouvrir (même flux que CaisseFermeeDialog déjà utilisé dans
  // caisse_screen.dart quand on tente de composer un panier caisse fermée).
  Future<void> _ouvrirCaisseSiFermee() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    final caisses = await GCServices.getAllCaisses();
    if (!mounted || caisses.isEmpty) return;

    // ✅ Même règle de résolution de la "caisse courante" qu'ailleurs dans
    // l'app (cf. caisse_screen.dart _LoadAllData) : un non-Admin est
    // verrouillé sur sa caisse attachée, un Admin par défaut sur la première.
    final caisseAttachee = !auth.estAdmin && auth.userCaisseCode != null
        ? caisses.where((c) => c.code == auth.userCaisseCode).firstOrNull
        : null;
    final caisseActuelle = caisseAttachee ?? caisses.first;

    final session = await CaisseSessionServices.getSessionOuverte(caisseActuelle.code);
    if (!mounted || session != null) return;

    await CaisseFermeeDialog(
      context: context,
      caisses: caisses,
      caisseInitiale: caisseActuelle,
    );
  }

  @override
  void dispose() {
    // Retour au login : les boutons flottants reprennent le relais.
    WidgetsBinding.instance.addPostFrameCallback((_) => BoutonsFenetreFlottants.shellActif.value = false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Provider.of<LocaleProvider>(context).locale.languageCode == 'ar';
    // Écoute AuthState : favoris (barre d'onglets) et changement de caisse /
    // magasin (contexteVersion, voir la clé du module plus bas).
    final auth = Provider.of<AuthState>(context);

    return Scaffold(
      body: Row(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SideBarWidget(key: _sideBarKey),
          Expanded(
            child: Column(
              children: [
                // Ligne du haut : onglets favoris + zone de déplacement de la
                // fenêtre + boutons réduire / agrandir / fermer (remplace
                // l'ancienne barre de titre séparée).
                Container(
                  height: 44,
                  // Fond blanc qui prolonge la sidebar : forme avec elle le
                  // cadre de la fenêtre.
                  decoration: BoxDecoration(
                    color: Appstyle.Tblanc,
                    border: Border(bottom: BorderSide(color: Appstyle.grisC.withOpacity(0.5))),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              // Arrière-plan : la zone vide déplace la fenêtre ;
                              // les onglets, au-dessus, gardent des clics immédiats.
                              const Positioned.fill(child: ZoneDeplacementFenetre()),
                              Directionality(
                                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                                child: _BarreFavoris(sideBarKey: _sideBarKey, favoris: auth.favoris),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: Appstyle.grisC.withOpacity(0.7),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: BoutonsFenetre(hauteur: 30),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  // Transition douce (fondu + léger glissement) entre modules —
                  // sans ça le changement de module était un cut instantané, plus
                  // perceptible depuis que la sidebar elle-même reste stable
                  // (AppShell) au lieu d'être remontée en même temps que le contenu.
                  // Clé sur le type du widget (chaque module a sa propre classe
                  // Screen) : AnimatedSwitcher ne rejoue l'animation que lorsque le
                  // module change réellement, pas à chaque rebuild interne.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    // contexteVersion : changer de caisse / magasin reconstruit le
                    // module affiché, qui recharge ses données.
                    child: KeyedSubtree(
                      key: ValueKey('${widget.child.runtimeType}-${auth.contexteVersion}'),
                      child: widget.child,
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

/// Onglets des modules favoris (7 max, étoile dans l'en-tête de chaque
/// module) : clic = ouvrir le module, croix = retirer des favoris. Masquée
/// sans favori ; un favori devenu inaccessible (permission retirée) n'est
/// pas affiché.
class _BarreFavoris extends StatelessWidget {
  final GlobalKey<SideBarWidgetState> sideBarKey;
  final List<String> favoris;

  const _BarreFavoris({required this.sideBarKey, required this.favoris});

  @override
  Widget build(BuildContext context) {
    if (favoris.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final modules = sideBarKey.currentState?.modulesVisibles(l10n) ?? const [];
    final chemin = GoRouterState.of(context).uri.path;
    final routeCourante = chemin == '/' ? '/dash' : chemin;

    final onglets = favoris
        .map((route) => modules.firstWhereOrNull((m) => m['route'] == route))
        .whereType<Map<String, dynamic>>()
        .toList();
    if (onglets.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            ),
            const SizedBox(width: 10),
            for (final m in onglets)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _OngletFavori(
                  icone: m['icon'] as String,
                  texte: m['text'] as String,
                  actif: m['route'] == routeCourante,
                  onOuvrir: () => context.go(m['route'] as String),
                  onRetirer: () => _confirmerRetrait(context, m['route'] as String, m['text'] as String),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Croix d'un onglet favori : demande confirmation avant de retirer le
/// module des favoris (l'onglet disparaît de la barre).
Future<void> _confirmerRetrait(BuildContext context, String route, String nomModule) async {
  final l10n = AppLocalizations.of(context);
  final auth = Provider.of<AuthState>(context, listen: false);
  final confirme = await ConfirmationDialog(
    context: context,
    titre: l10n.removeFromFavorites,
    message: l10n.confirmRemoveFavorite(nomModule),
    kind: DialogKind.attention,
  );
  if (confirme == true) await auth.basculerFavori(route);
}

class _OngletFavori extends StatelessWidget {
  final String icone;
  final String texte;
  final bool actif;
  final VoidCallback onOuvrir;
  final VoidCallback onRetirer;

  const _OngletFavori({
    required this.icone,
    required this.texte,
    required this.actif,
    required this.onOuvrir,
    required this.onRetirer,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? Colors.white : Appstyle.violet;
    return Material(
      color: actif ? Appstyle.violet : Appstyle.violetC,
      borderRadius: BorderRadius.circular(10),
      elevation: actif ? 1.5 : 0,
      shadowColor: Appstyle.violet.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onOuvrir,
        hoverColor: Appstyle.violet.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 4, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icone, width: 16, height: 16, color: couleur),
              const SizedBox(width: 6),
              Text(
                texte,
                style: Appstyle.textSB.copyWith(color: couleur, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(width: 2),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onRetirer,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.close_rounded, size: 14, color: couleur.withOpacity(0.75)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
