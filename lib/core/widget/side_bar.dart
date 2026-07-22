import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Role.dart';
import 'package:caisse_dz/Services/RoleDetail.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/RoleDetail.dart';
import 'package:caisse_dz/data/models/role.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SideBarWidget extends StatefulWidget {
  const SideBarWidget({super.key});

  @override
  State<SideBarWidget> createState() => _SideBarWidgetState();
}

class _SideBarWidgetState extends State<SideBarWidget> {
  bool isExpanded = false;
  bool isPinned = false;

  static const double collapsedWidth = 80;
  static const double expandedWidth = 220;

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
  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final auth = Provider.of<AuthState>(context, listen: false);

    await rolecode(rolenom: auth.role!);

    if (mounted) {
      setState(() {});
    }
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
            // Header with logo
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  Image.asset(
                    "assets/icons/caisse_dz_logo.png",
                    width: isExpanded ? 90 : 40,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Scrollable menu items
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    if (roledetail?.dash == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/dash_icon.png",
                        text: l10n.dashboard,
                        route: "/dash",
                      ),
                    if (roledetail?.caisse == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/caisse_icon.png",
                        text: l10n.caisse,
                        route: "/caisse",
                      ),
                    if (roledetail?.produit == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/produit_icon.png",
                        text: l10n.produit,
                        route: "/produit",
                      ),
                    if (roledetail?.pannier == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/pannier_icon.png",
                        text: l10n.panier,
                        route: "/pannier",
                      ),
                    if (roledetail?.client == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/client_icon.png",
                        text: l10n.client,
                        route: "/client",
                      ),
                    if (roledetail?.fournisseur == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/fournisseur_icon.png",
                        text: l10n.fournisseur,
                        route: "/fournisseur",
                      ),
                    if (roledetail?.entree == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/entree_icon.png",
                        text: l10n.entree,
                        route: "/entree",
                      ),
                    if (roledetail?.sortie == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/sortie_icon.png",
                        text: l10n.sortie,
                        route: "/sortie",
                      ),
                    if (roledetail?.retour == true)
                      buildMenuItem(
                        iconPath: "assets/icons/cardwidget/retour_icon.png",
                        text: l10n.retour,
                        route: "/retour",
                      ),
                    if (roledetail?.stock == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/stock_icon.png",
                        text: l10n.stock,
                        route: "/stock",
                      ),
                    if (roledetail?.besoin == true)
                      buildMenuItem(
                        iconPath: "assets/icons/cardwidget/besion_icon.png",
                        text: l10n.besoin,
                        route: "/besoin",
                      ),
                    if (roledetail?.utilisateur == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/profile_icon.png",
                        text: l10n.utilisateur,
                        route: "/utilisateur",
                      ),
                    if (roledetail?.magasin == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/magasin_icon.png",
                        text: l10n.magasin,
                        route: "/magasin",
                      ),
                    if (roledetail?.gestionCaisse == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/caisse_icon.png",
                        text: l10n.gestionCaisse,
                        route: "/gestion_caisse",
                      ),
                    if (roledetail?.zakat == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/zakat_icon.png",
                        text: l10n.zakat,
                        route: "/zakat",
                      ),
                    if (roledetail?.parametre == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/parametre_icon.png",
                        text: l10n.parametre,
                        route: "/parametre",
                      ),
                    if (roledetail?.historique == true)
                      buildMenuItem(
                        iconPath: "assets/icons/sidebar/historique_icon.png",
                        text: l10n.historique,
                        route: "/historique",
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ✅ NOUVEAU : Footer avec bouton Pin et Exit
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                children: [
                  // Pin button
                  Align(
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

                  const SizedBox(height: 10),

                  // ✅ BOUTON EXIT ADAPTATIF AVEC TRADUCTION
                  _buildExitButton(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ✅ NOUVEAU : Widget pour le bouton Exit
  Widget _buildExitButton(AppLocalizations l10n) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          final auth = Provider.of<AuthState>(context, listen: false);

          auth.logout(
            username: auth.username!,
            userCode: auth.userCode!,
          );

          context.go('/login');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: isExpanded
              ? const EdgeInsets.symmetric(vertical: 12, horizontal: 30)
              : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isExpanded
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.exit, // ✅ TRADUCTION
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          )
              : const Icon(
            Icons.exit_to_app,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}