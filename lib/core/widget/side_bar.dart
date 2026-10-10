import 'dart:async';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/parametre/initial_setup_dialog.dart';
import 'package:caisse_dz/core/Auth/license_tier.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/wordmark.dart';
import 'package:caisse_dz/core/widget/custom_title_bar.dart';
import 'package:caisse_dz/data/models/RoleDetail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class SideBarWidget extends StatefulWidget {
  const SideBarWidget({super.key});

  @override
  State<SideBarWidget> createState() => SideBarWidgetState();
}

class SideBarWidgetState extends State<SideBarWidget> {
  bool isExpanded = false;

  // Délai avant qu'un survol n'ouvre/replie la sidebar (repliée uniquement,
  // cf. isPinned) — évite l'ouverture/fermeture instantanée au moindre
  // passage de souris. Annulé si la souris ressort avant l'échéance.
  static const Duration _hoverDelay = Duration(milliseconds: 300);
  Timer? _hoverTimer;
  String? _routeAffichee;

  // Backé par AuthState (singleton) plutôt qu'un champ local : même si
  // SideBarWidget est désormais monté une seule fois pour toute la session
  // (AppShell, voir router.dart), AuthState reste la source de vérité unique
  // pour ce flag (ex. épinglage forcé au clic sur un module, cf. isExpanded
  // plus bas dans buildMenuItem).
  bool get isPinned => Provider.of<AuthState>(context, listen: false).isSidebarPinned;
  set isPinned(bool value) => Provider.of<AuthState>(context, listen: false).setSidebarPinned(value);

  static const double collapsedWidth = 80;
  static const double expandedWidth = 220;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  // Empêche que deux instances de SideBarWidget montées en même temps (ex.
  // pendant la chaîne de redirections juste après le login) ne déclenchent
  // toutes les deux le dialog avant que le flag n'ait fini d'être persisté.
  static bool _initialSetupChecked = false;

  // Chargé une seule fois à la connexion (AuthState.roleDetail) — voir
  // commentaire sur roleReady ci-dessous.
  RoleDetail? get roledetail => Provider.of<AuthState>(context, listen: false).roleDetail;

  // ─────────────────────────────────────────────
  bool _isRouteActive(String currentPath, String routePath) {
    if (routePath == '/dash' && currentPath == '/') {
      return true;
    }
    return currentPath == routePath;
  }

  // ─────────────────────────────────────────────
  // Les permissions du rôle sont chargées une seule fois à la connexion
  // (AuthState.roleDetail) plutôt que rechargées ici. roleReady reste exposé
  // pour compatibilité (AppShell l'attend avant showModuleMenu au démarrage,
  // voir app_shell.dart) mais se résout immédiatement, la donnée étant déjà
  // chargée avant même que le premier écran authentifié ne s'affiche.
  Future<void> get roleReady => Future.value();

  @override
  void initState() {
    super.initState();
    // SideBarWidget est monté une seule fois pour toute la session (AppShell,
    // voir router.dart) : si elle était épinglée lors d'une session
    // précédente (AuthState), elle doit rester dépliée dès son montage.
    isExpanded = isPinned;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInitialSetupCheck());
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  // ✅ SideBarWidget est présent sur tous les écrans authentifiés (sauf
  // login/activation) : c'est donc l'endroit pour afficher le dialog de
  // configuration initiale une seule fois, à vie (flag persistant dans
  // FlutterSecureStorage — même mécanisme, déjà fiable, que le flag
  // d'activation de l'app, voir DbCreator._isActivated), quel que soit le
  // premier écran ouvert par l'utilisateur après sa connexion — plutôt que
  // seulement depuis CaisseScreen.
  Future<void> _runInitialSetupCheck() async {
    if (_initialSetupChecked) return;
    _initialSetupChecked = true;

    final completed = await _secureStorage.read(key: 'initial_setup_completed');
    if (completed == 'true') return;

    await _secureStorage.write(key: 'initial_setup_completed', value: 'true');
    if (!mounted) return;
    await InitialSetupDialog(context);
  }

  // ─────────────────────────────────────────────
  // Dashboard reste hors catégorie, toujours en premier et cliquable
  // directement (écran d'accueil le plus consulté).
  Map<String, dynamic> _dashboardModule(AppLocalizations l10n) =>
      {'visible': roledetail?.dash == true, 'icon': "assets/icons/sidebar/dash_icon.png", 'text': l10n.dashboard, 'route': "/dash"};

  // Modules (icône/texte/route) regroupés par catégorie dépliable, filtrés
  // par les permissions du rôle courant — utilisé à la fois par la liste de
  // la sidebar et par le menu rapide ouvert en cliquant sur le logo, pour ne
  // pas dupliquer la logique de permissions à deux endroits.
  List<Map<String, dynamic>> _moduleCategories(AppLocalizations l10n, LicenseTier tier) => [
    {
      'key': 'ventes',
      'label': l10n.sales,
      'icon': Icons.point_of_sale_outlined,
      'modules': [
        {'visible': roledetail?.caisse == true, 'icon': "assets/icons/sidebar/caisse_icon.png", 'text': l10n.caisse, 'route': "/caisse"},
        {'visible': roledetail?.pannier == true, 'icon': "assets/icons/sidebar/pannier_icon.png", 'text': l10n.panier, 'route': "/pannier"},
        {'visible': roledetail?.retour == true, 'icon': "assets/icons/cardwidget/retour_icon.png", 'text': l10n.retour, 'route': "/retour"},
      ],
    },
    {
      'key': 'stock',
      'label': l10n.stock,
      'icon': Icons.inventory_2_outlined,
      'modules': [
        {'visible': roledetail?.produit == true, 'icon': "assets/icons/sidebar/produit_icon.png", 'text': l10n.produit, 'route': "/produit"},
        {'visible': roledetail?.stock == true, 'icon': "assets/icons/sidebar/stock_icon.png", 'text': l10n.stock, 'route': "/stock"},
        {'visible': roledetail?.entree == true, 'icon': "assets/icons/sidebar/entree_icon.png", 'text': l10n.entree, 'route': "/entree"},
        {'visible': roledetail?.sortie == true, 'icon': "assets/icons/sidebar/sortie_icon.png", 'text': l10n.sortie, 'route': "/sortie"},
        // Gestion des magasins réservée au palier Avancé (Basic reste
        // mono-magasin) — voir aussi le garde équivalent dans router.dart et
        // le refus côté MagasinNouveau (défense en profondeur).
        {'visible': tier == LicenseTier.avance, 'icon': "assets/icons/sidebar/magasin_icon.png", 'text': l10n.magasin, 'route': "/magasin"},
        {'visible': roledetail?.besoin == true, 'icon': "assets/icons/cardwidget/besion_icon.png", 'text': l10n.besoin, 'route': "/besoin"},
      ],
    },
    {
      'key': 'people',
      'label': l10n.peopleCategory,
      'icon': Icons.groups_outlined,
      'modules': [
        {'visible': roledetail?.client == true, 'icon': "assets/icons/sidebar/client_icon.png", 'text': l10n.client, 'route': "/client"},
        {'visible': roledetail?.fournisseur == true, 'icon': "assets/icons/sidebar/fournisseur_icon.png", 'text': l10n.fournisseur, 'route': "/fournisseur"},
        {'visible': roledetail?.utilisateur == true, 'icon': "assets/icons/sidebar/profile_icon.png", 'text': l10n.utilisateur, 'route': "/utilisateur"},
      ],
    },
    {
      'key': 'autre',
      'label': l10n.autre,
      'icon': Icons.widgets_outlined,
      'modules': [
        {'visible': roledetail?.gestionCaisse == true, 'icon': "assets/icons/sidebar/caisse_icon.png", 'text': l10n.gestionCaisse, 'route': "/gestion_caisse"},
        {'visible': roledetail?.zakat == true, 'icon': "assets/icons/sidebar/zakat_icon.png", 'text': l10n.zakat, 'route': "/zakat"},
        {'visible': roledetail?.parametre == true, 'icon': "assets/icons/sidebar/parametre_icon.png", 'text': l10n.parametre, 'route': "/parametre"},
        {'visible': roledetail?.historique == true, 'icon': "assets/icons/sidebar/historique_icon.png", 'text': l10n.historique, 'route': "/historique"},
      ],
    },
  ];

  // Tous les modules visibles, à plat (dashboard + toutes catégories) —
  // pour le menu rapide (showModuleMenu) et le mode replié de la sidebar,
  // qui n'ont pas besoin du regroupement par catégorie.
  List<Map<String, dynamic>> _allVisibleModules(AppLocalizations l10n, LicenseTier tier) {
    final dashboard = _dashboardModule(l10n);
    final fromCategories = _moduleCategories(l10n, tier)
        .expand((c) => (c['modules'] as List<Map<String, dynamic>>))
        .toList();
    return [dashboard, ...fromCategories].where((m) => m['visible'] == true).toList();
  }

  /// Modules accessibles (permissions + licence), à plat : utilisé par la
  /// barre des favoris d'AppShell pour retrouver icône et nom d'une route et
  /// masquer un favori devenu inaccessible.
  List<Map<String, dynamic>> modulesVisibles(AppLocalizations l10n) =>
      _allVisibleModules(l10n, Provider.of<AuthState>(context, listen: false).licenseTier);

  static const List<Color> _moduleColors = [
    Appstyle.violet,
    Appstyle.indigo,
    Appstyle.blueC,
    Appstyle.crevete,
    Appstyle.successInk,
    Appstyle.blueF,
  ];

  // ─────────────────────────────────────────────
  // Menu rapide "lanceur de modules" ouvert en cliquant sur le logo : une
  // grille moderne (carte + icône colorée + animation d'entrée) de tous les
  // modules accessibles, en complément de la liste verticale de la sidebar
  // (utile notamment quand la sidebar est repliée).
  Future<void> showModuleMenu(BuildContext context, AppLocalizations l10n) {
    final tier = Provider.of<AuthState>(context, listen: false).licenseTier;
    final modules = _allVisibleModules(l10n, tier);

    return showGeneralDialog(
      context: context,
      barrierLabel: l10n.dashboard,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        final blur = 10 * anim.value.clamp(0.0, 1.0);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Opacity(
            opacity: anim.value.clamp(0, 1),
            child: Transform.scale(
              scale: 0.9 + (0.1 * curved.value.clamp(0.0, 1.0)),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 1100,
                    constraints: const BoxConstraints(maxHeight: 780),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Appstyle.Tblanc,
                      borderRadius: BorderRadius.circular(Appstyle.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: Appstyle.shadowTint.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset("assets/icons/caisse_dz_logo.png", height: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.menu,
                                style: Appstyle.textXLB.copyWith(
                                  color: Appstyle.Tnoir,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Appstyle.gris),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 1.15,
                              children: List.generate(modules.length, (i) {
                                final m = modules[i];
                                final color = _moduleColors[i % _moduleColors.length];
                                return _ModuleTile(
                                  icon: m['icon'] as String,
                                  text: m['text'] as String,
                                  color: color,
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(m['route'] as String);
                                  },
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authWatch = context.watch<AuthState>();

    // ✅ LOADING STATE
    if (roledetail == null) {
      return Container(
        width: collapsedWidth,
        decoration: BoxDecoration(
          color: Appstyle.Tblanc,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final GoRouterState routeState = GoRouterState.of(context);
    final String currentLocation = routeState.uri.path;

    // Seule la catégorie du module affiché s'ouvre automatiquement, à chaque
    // changement de route ; les autres restent repliées au démarrage.
    if (currentLocation != _routeAffichee) {
      _routeAffichee = currentLocation;
      for (final categorie in _moduleCategories(l10n, authWatch.licenseTier)) {
        final modules = categorie['modules'] as List<Map<String, dynamic>>;
        if (modules.any((m) => m['route'] == currentLocation)) {
          authWatch.ouvrirSidebarCategorie(categorie['key'] as String);
        }
      }
    }

    Widget buildMenuItem({
      required String iconPath,
      required String text,
      required String route,
    }) {
      final bool isActive = _isRouteActive(currentLocation, route);

      return Builder(
        builder: (context) {
          bool isHovered = false;

          return StatefulBuilder(
            builder: (context, setState) {
              return MouseRegion(
                onEnter: (_) {
                  setState(() {
                    isHovered = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    isHovered = false;
                  });
                },
                child: InkWell(
                  onTap: () {
                    // Naviguer ne doit jamais refermer une sidebar
                    // actuellement ouverte : si elle n'était ouverte que par
                    // survol (non épinglée), l'épingler ici évite qu'elle se
                    // replie au remontage de l'écran suivant (voir isPinned).
                    if (isExpanded) isPinned = true;
                    context.go(route);
                  },
                  borderRadius: BorderRadius.circular(Appstyle.radiusLG),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Appstyle.violet
                          : isHovered
                          ? Appstyle.violetC
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                    ),
                    child: isExpanded
                        ? Row(
                      children: [
                        Opacity(
                          opacity: isActive ? 1.0 : 0.8,
                          child: Image.asset(
                            iconPath,
                            width: 20,
                            height: 20,
                            color: isActive
                                ? Colors.white
                                : isHovered
                                ? Appstyle.violet
                                : Appstyle.gris,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Opacity(
                            opacity: isActive ? 1.0 : 0.8,
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: Appstyle.textXS.copyWith(
                                color: isActive
                                    ? Appstyle.Tblanc
                                    : isHovered
                                    ? Appstyle.violet
                                    : Appstyle.TgrisC,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Center(
                      child: Opacity(
                        opacity: isActive ? 1.0 : 0.8,
                        child: Image.asset(
                          iconPath,
                          width: 20,
                          height: 20,
                          color: isActive
                              ? Colors.white
                              : isHovered
                              ? Appstyle.violet
                              : Appstyle.gris,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // En-tête de catégorie : libellé + chevron dépliée, icône seule (avec
    // tooltip) repliée — clic pour déplier/replier dans les deux cas, même
    // logique de survol que buildMenuItem mais sans navigation (toggle
    // persisté dans AuthState, voir plus haut).
    Widget buildCategoryHeader({
      required String label,
      required IconData icon,
      required String categoryKey,
    }) {
      final bool expanded = authWatch.expandedSidebarCategories.contains(categoryKey);

      return Builder(
        builder: (context) {
          bool isHovered = false;

          return StatefulBuilder(
            builder: (context, setLocalState) {
              // Design distinct des modules : fond violet très clair en
              // permanence (pas seulement au survol), libellé en majuscules
              // espacées et coloré violet — lecture immédiate "ceci est une
              // section", pas un élément cliquable comme les autres.
              final header = MouseRegion(
                onEnter: (_) => setLocalState(() => isHovered = true),
                onExit: (_) => setLocalState(() => isHovered = false),
                child: InkWell(
                  onTap: () => authWatch.toggleSidebarCategory(categoryKey),
                  borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(6, 10, 6, 2),
                    padding: EdgeInsets.symmetric(horizontal: isExpanded ? 14 : 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHovered ? Appstyle.violet.withOpacity(0.14) : Appstyle.violetC,
                      borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                    ),
                    child: isExpanded
                        ? Row(
                      children: [
                        Icon(icon, size: 15, color: Appstyle.violet),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: Appstyle.textXSB.copyWith(
                              color: Appstyle.violet,
                              fontSize: 11,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Appstyle.violet.withOpacity(0.7),
                        ),
                      ],
                    )
                        : Center(
                      child: Icon(icon, size: 16, color: Appstyle.violet),
                    ),
                  ),
                ),
              );

              return isExpanded ? header : Tooltip(message: label, child: header);
            },
          );
        },
      );
    }

    return MouseRegion(
      onEnter: (_) {
        _hoverTimer?.cancel();
        if (!isPinned) {
          _hoverTimer = Timer(_hoverDelay, () {
            if (mounted) setState(() => isExpanded = true);
          });
        }
      },
      onExit: (_) {
        _hoverTimer?.cancel();
        if (!isPinned) {
          _hoverTimer = Timer(_hoverDelay, () {
            if (mounted) setState(() => isExpanded = false);
          });
        }
      },
      child: Container(
        height: double.infinity,
        width: isExpanded ? expandedWidth : collapsedWidth,
        decoration: BoxDecoration(
          color: Appstyle.Tblanc,
          boxShadow: const [
            BoxShadow(
              color: Appstyle.shadowSoft,
              blurRadius: 12,
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with logo — cliquable : ouvre le menu rapide "lanceur
            // de modules" (grille moderne, cf. showModuleMenu), pratique
            // notamment quand la sidebar est repliée.
            // Remplace aussi l'ancienne barre de titre : logo + titre de
            // l'app, et glisser cette zone déplace la fenêtre.
            ZoneDeplacementFenetre(
              doubleClicAgrandit: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    Tooltip(
                      message: l10n.situation,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                        onTap: () => showModuleMenu(context, l10n),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            "assets/icons/caisse_dz_logo.png",
                            width: isExpanded ? 90 : 40,
                          ),
                        ),
                      ),
                    ),
                    if (isExpanded)
                      const Wordmark(size: 18),
                  ],
                ),
              ),
            ),

            // Scrollable menu items
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    if (_dashboardModule(l10n)['visible'] == true)
                      buildMenuItem(
                        iconPath: _dashboardModule(l10n)['icon'] as String,
                        text: _dashboardModule(l10n)['text'] as String,
                        route: _dashboardModule(l10n)['route'] as String,
                      ),

                    // Regroupement par catégorie dans les deux modes (dépliée
                    // ou repliée) : chaque catégorie reste dépliable
                    // indépendamment, l'en-tête s'affiche en icône seule
                    // (avec tooltip) quand la sidebar est repliée.
                    for (final categorie in _moduleCategories(l10n, authWatch.licenseTier))
                      if ((categorie['modules'] as List<Map<String, dynamic>>).any((m) => m['visible'] == true)) ...[
                        buildCategoryHeader(
                          label: categorie['label'] as String,
                          icon: categorie['icon'] as IconData,
                          categoryKey: categorie['key'] as String,
                        ),
                        if (authWatch.expandedSidebarCategories.contains(categorie['key']))
                          for (final m in (categorie['modules'] as List<Map<String, dynamic>>)
                              .where((m) => m['visible'] == true))
                            buildMenuItem(
                              iconPath: m['icon'] as String,
                              text: m['text'] as String,
                              route: m['route'] as String,
                            ),
                      ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Footer avec bouton Collapse/Expand — le bouton de déconnexion a
            // été déplacé dans HeaderModule (coin haut-gauche du header,
            // présent sur tous les écrans) pour rester accessible même
            // repliée. Dépliée manuellement : reste ouverte (épinglée),
            // insensible au survol. Repliée manuellement : redevient
            // survolable (peek au survol, avec délai — voir _hoverDelay).
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: isExpanded ? l10n.close : l10n.pinSidebar,
                  icon: Icon(
                    isExpanded
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: Appstyle.violet,
                  ),
                  onPressed: () {
                    _hoverTimer?.cancel();
                    setState(() {
                      isExpanded = !isExpanded;
                      isPinned = isExpanded;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Tuile d'un module dans le menu rapide ouvert depuis le logo — carte
/// colorée avec icône, animée (échelle) au survol/appui pour un rendu
/// moderne cohérent avec les tuiles de situation du tableau de bord.
class _ModuleTile extends StatefulWidget {
  final String icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.94 : (_hovered ? 1.04 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: _hovered ? widget.color.withOpacity(0.12) : Appstyle.Tblanc,
              borderRadius: BorderRadius.circular(Appstyle.radiusCard),
              border: Border.all(
                color: widget.color.withOpacity(_hovered ? 0.4 : 0.15),
                width: 1.2,
              ),
              boxShadow: _hovered
                  ? [BoxShadow(color: widget.color.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))]
                  : const [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(widget.icon, width: 22, height: 22, color: widget.color),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Appstyle.textXS.copyWith(
                    color: Appstyle.Tnoir,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}