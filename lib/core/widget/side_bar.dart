import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Role.dart';
import 'package:caisse_dz/Services/RoleDetail.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/parametre/initial_setup_dialog.dart';
import 'package:caisse_dz/core/dialog/magasin/magasin_actif_dialog.dart';
import 'package:caisse_dz/core/Auth/license_tier.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/RoleDetail.dart';
import 'package:caisse_dz/data/models/role.dart';
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

  // Backé par AuthState (singleton) plutôt qu'un champ local : SideBarWidget
  // est recréé sans état partagé par chaque écran, donc un champ local
  // reviendrait à false à chaque changement de module.
  bool get isPinned => Provider.of<AuthState>(context, listen: false).isSidebarPinned;
  set isPinned(bool value) => Provider.of<AuthState>(context, listen: false).setSidebarPinned(value);

  static const double collapsedWidth = 80;
  static const double expandedWidth = 220;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  // Empêche que deux instances de SideBarWidget montées en même temps (ex.
  // pendant la chaîne de redirections juste après le login) ne déclenchent
  // toutes les deux le dialog avant que le flag n'ait fini d'être persisté.
  static bool _initialSetupChecked = false;

  RoleDetail? roledetail;

  // ─────────────────────────────────────────────
  bool _isRouteActive(String currentPath, String routePath) {
    if (routePath == '/dash' && currentPath == '/') {
      return true;
    }
    return currentPath == routePath;
  }

  // ─────────────────────────────────────────────
  Future<void> rolecode({required String rolenom}) async {
    final db = DbCreator.openDb();
    List<Role> roles = await RoleServices.getAllRoles();
    String rolecod = roles.where((e) => e.rolenom == rolenom).first.code;

    roledetail = await RoleDetailServices.getRoleByCode(rolecod);
  }

  // ─────────────────────────────────────────────
  // Future exposée (via GlobalKey<SideBarWidgetState>) pour permettre à un
  // écran parent (ex. CaisseScreen, menu auto-ouvert au démarrage) d'attendre
  // que les permissions du rôle soient chargées avant d'appeler showModuleMenu.
  Future<void>? _roleReadyFuture;
  Future<void> get roleReady => _roleReadyFuture ?? Future.value();

  @override
  void initState() {
    super.initState();
    _roleReadyFuture = _initRole();
    // La sidebar est recréée à chaque changement de module (voir isPinned) :
    // si elle était épinglée, elle doit rester dépliée dès son montage.
    isExpanded = isPinned;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInitialSetupCheck());
  }

  Future<void> _initRole() async {
    final auth = Provider.of<AuthState>(context, listen: false);

    await rolecode(rolenom: auth.role!);

    if (mounted) {
      setState(() {});
    }
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
  // Liste des modules (icône/texte/route), filtrée par les permissions du
  // rôle courant — utilisée à la fois par la liste de la sidebar et par le
  // menu rapide ouvert en cliquant sur le logo, pour ne pas dupliquer la
  // logique de permissions à deux endroits.
  List<Map<String, dynamic>> _modules(AppLocalizations l10n, LicenseTier tier) => [
    {'visible': roledetail?.dash == true, 'icon': "assets/icons/sidebar/dash_icon.png", 'text': l10n.dashboard, 'route': "/dash"},
    {'visible': roledetail?.caisse == true, 'icon': "assets/icons/sidebar/caisse_icon.png", 'text': l10n.caisse, 'route': "/caisse"},
    {'visible': roledetail?.produit == true, 'icon': "assets/icons/sidebar/produit_icon.png", 'text': l10n.produit, 'route': "/produit"},
    {'visible': roledetail?.pannier == true, 'icon': "assets/icons/sidebar/pannier_icon.png", 'text': l10n.panier, 'route': "/pannier"},
    {'visible': roledetail?.client == true, 'icon': "assets/icons/sidebar/client_icon.png", 'text': l10n.client, 'route': "/client"},
    {'visible': roledetail?.fournisseur == true, 'icon': "assets/icons/sidebar/fournisseur_icon.png", 'text': l10n.fournisseur, 'route': "/fournisseur"},
    // Gestion des magasins réservée au palier Premium (Basic/Avancé restent
    // mono-magasin) — voir aussi le garde équivalent dans router.dart et le
    // refus côté MagasinNouveau (défense en profondeur).
    {'visible': tier == LicenseTier.premium, 'icon': "assets/icons/sidebar/magasin_icon.png", 'text': l10n.magasin, 'route': "/magasin"},
    {'visible': roledetail?.entree == true, 'icon': "assets/icons/sidebar/entree_icon.png", 'text': l10n.entree, 'route': "/entree"},
    {'visible': roledetail?.sortie == true, 'icon': "assets/icons/sidebar/sortie_icon.png", 'text': l10n.sortie, 'route': "/sortie"},
    {'visible': roledetail?.retour == true, 'icon': "assets/icons/cardwidget/retour_icon.png", 'text': l10n.retour, 'route': "/retour"},
    {'visible': roledetail?.stock == true, 'icon': "assets/icons/sidebar/stock_icon.png", 'text': l10n.stock, 'route': "/stock"},
    {'visible': roledetail?.besoin == true, 'icon': "assets/icons/cardwidget/besion_icon.png", 'text': l10n.besoin, 'route': "/besoin"},
    {'visible': roledetail?.utilisateur == true, 'icon': "assets/icons/sidebar/profile_icon.png", 'text': l10n.utilisateur, 'route': "/utilisateur"},
    {'visible': roledetail?.gestionCaisse == true, 'icon': "assets/icons/sidebar/caisse_icon.png", 'text': l10n.gestionCaisse, 'route': "/gestion_caisse"},
    {'visible': roledetail?.zakat == true, 'icon': "assets/icons/sidebar/zakat_icon.png", 'text': l10n.zakat, 'route': "/zakat"},
    {'visible': roledetail?.parametre == true, 'icon': "assets/icons/sidebar/parametre_icon.png", 'text': l10n.parametre, 'route': "/parametre"},
    {'visible': roledetail?.historique == true, 'icon': "assets/icons/sidebar/historique_icon.png", 'text': l10n.historique, 'route': "/historique"},
  ];

  static const List<Color> _moduleColors = [
    Appstyle.violet,
    Appstyle.indigo,
    Appstyle.blueC,
    Appstyle.crevete,
    Colors.teal,
    Appstyle.blueF,
  ];

  // ─────────────────────────────────────────────
  // Menu rapide "lanceur de modules" ouvert en cliquant sur le logo : une
  // grille moderne (carte + icône colorée + animation d'entrée) de tous les
  // modules accessibles, en complément de la liste verticale de la sidebar
  // (utile notamment quand la sidebar est repliée).
  void showModuleMenu(BuildContext context, AppLocalizations l10n) {
    final tier = Provider.of<AuthState>(context, listen: false).licenseTier;
    final modules = _modules(l10n, tier).where((m) => m['visible'] == true).toList();

    showGeneralDialog(
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
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
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
    // Écoute (pas listen:false) : le libellé du magasin actif doit se
    // rafraîchir dès que MagasinActifDialog appelle updateUserParameters().
    final authWatch = context.watch<AuthState>();
    final authMagasin = authWatch.currentMagasin;

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
                  onTap: () => context.go(route),
                  borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isExpanded
                        ? Row(
                      children: [
                        Image.asset(
                          iconPath,
                          width: 24,
                          height: 24,
                          color: isActive
                              ? Colors.white
                              : isHovered
                              ? Appstyle.violet
                              : Appstyle.gris,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                      ],
                    )
                        : Center(
                      child: Image.asset(
                        iconPath,
                        width: 24,
                        height: 24,
                        color: isActive
                            ? Colors.white
                            : isHovered
                            ? Appstyle.violet
                            : Appstyle.gris,
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

    return MouseRegion(
      onEnter: (_) {
        if (!isPinned) setState(() => isExpanded = true);
      },
      onExit: (_) {
        if (!isPinned) setState(() => isExpanded = false);
      },
      child: Container(
        height: double.infinity,
        width: isExpanded ? expandedWidth : collapsedWidth,
        decoration: BoxDecoration(
          color: Appstyle.Tblanc,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
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
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  Tooltip(
                    message: l10n.situation,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 10),
                  // Magasin actif de la session — mécanisme neuf (n'existait
                  // pas avant, cf. dialog) : ouvre le sélecteur au clic. Reste
                  // affiché même en Basic/Avancé (un seul magasin) pour que
                  // l'utilisateur sache toujours dans quel magasin il opère ;
                  // le futur gating par palier ne touchera que la capacité
                  // d'en choisir un AUTRE, pas la visibilité de l'indicateur.
                  Tooltip(
                    message: l10n.defaultStore,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => MagasinActifDialog(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isExpanded ? 10 : 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: Appstyle.violetC,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isExpanded
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.storefront_outlined, size: 16, color: Appstyle.violet),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      (authMagasin == null || authMagasin.isEmpty) ? l10n.defaultStore : authMagasin,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Appstyle.textXS.copyWith(
                                        color: Appstyle.violet,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Icon(Icons.storefront_outlined, size: 18, color: Appstyle.violet),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Scrollable menu items
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    for (final m in _modules(l10n, authWatch.licenseTier).where((m) => m['visible'] == true))
                      buildMenuItem(
                        iconPath: m['icon'] as String,
                        text: m['text'] as String,
                        route: m['route'] as String,
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Footer avec bouton Pin — le bouton de déconnexion a été
            // déplacé dans HeaderModule (coin haut-gauche du header, présent
            // sur tous les écrans) pour rester accessible même repliée.
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    color: Appstyle.violet,
                  ),
                  onPressed: () {
                    setState(() {
                      isPinned = !isPinned;
                      isExpanded = isPinned;
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
              borderRadius: BorderRadius.circular(18),
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