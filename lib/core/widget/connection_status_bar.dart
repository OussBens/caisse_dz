import 'package:caisse_dz/Services/Alertes.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/alertes/alerte_dialog.dart';
import 'package:caisse_dz/core/widget/internet_status_widget.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Bloc affiché dans l'en-tête de chaque écran : cloche des alertes, étoile
/// "module favori" puis témoin de connexion. Présent sur tous les modules, c'est le point
/// d'entrée unique pour ajouter le module courant aux favoris (onglets en
/// haut de l'écran, voir AppShell).
class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BoutonAlertes(),
        _EtoileFavori(),
        SizedBox(width: 8),
        InternetStatusWidget(),
      ],
    );
  }
}

/// Cloche ouvrant le dialog « Alertes », avec le nombre d'alertes du dernier
/// calcul en badge.
class _BoutonAlertes extends StatelessWidget {
  const _BoutonAlertes();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<int>(
      valueListenable: AlertesServices.nombreAlertes,
      builder: (context, nombre, _) => Tooltip(
        message: l10n.alerts,
        child: IconButton(
          onPressed: () => AlerteDialog(context),
          icon: Badge(
            isLabelVisible: nombre > 0,
            label: Text(nombre > 99 ? '99+' : '$nombre'),
            backgroundColor: Colors.red,
            child: Icon(
              nombre > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              color: nombre > 0 ? Colors.orange : Colors.grey,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _EtoileFavori extends StatelessWidget {
  const _EtoileFavori();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthState>();
    final chemin = GoRouterState.of(context).uri.path;
    final route = chemin == '/' ? '/dash' : chemin; // '/' = Tableau de bord (cf. sidebar)
    final favori = auth.estFavori(route);

    return Tooltip(
      message: favori ? l10n.removeFromFavorites : l10n.addToFavorites,
      child: IconButton(
        icon: Icon(
          favori ? Icons.star_rounded : Icons.star_border_rounded,
          color: favori ? Colors.amber : Colors.grey,
          size: 28,
        ),
        onPressed: () async {
          final ok = await auth.basculerFavori(route);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.maxFavoritesReached), backgroundColor: Colors.orange),
            );
          }
        },
      ),
    );
  }
}
