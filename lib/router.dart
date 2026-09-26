import 'package:caisse_dz/screens/Activation.dart';
import 'package:caisse_dz/screens/besion_screen.dart';
import 'package:caisse_dz/screens/entree_screen.dart';
import 'package:caisse_dz/screens/historique_screen.dart';
import 'package:caisse_dz/screens/login.dart';
import 'package:caisse_dz/screens/retour_screen.dart';
import 'package:caisse_dz/screens/sortie_screen.dart';
import 'package:go_router/go_router.dart';
import 'core/Auth/auth_state.dart';
import 'core/Auth/license_tier.dart';
import 'screens/dash_screen.dart';
import 'screens/caisse_screen.dart';
import 'screens/client_screen.dart';
import 'screens/fournisseur_screen.dart';
import 'screens/pannier_screen.dart';
import 'screens/produit_screen.dart';
import 'screens/parametre_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/utilisateur_screen.dart';
import 'screens/gestion_caisse_screen.dart';
import 'screens/magasin_screen.dart';
import 'screens/zekkat_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthState authState) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authState,
      redirect: (context, state) {
        final loggedIn        = authState.isAuthenticated;
        final activated       = authState.isActivated;
        final goingToLogin    = state.fullPath == '/login';
        final goingToActivate = state.fullPath == '/activate';

        // Activated but not logged in → go to login, unless already there
        if (activated && !loggedIn && !goingToLogin) return '/login';

        // Logged in & trying to go to login or activate → send to dashboard
        if (loggedIn && (goingToLogin || goingToActivate)) return '/caisse';

        // Gestion des magasins réservée au palier Premium — bloque l'accès
        // direct par URL même si l'entrée de menu est masquée (sidebar).
        if (loggedIn && state.fullPath == '/magasin' && authState.licenseTier != LicenseTier.premium) {
          return '/caisse';
        }

        // otherwise, no redirect
        return null;
      },

      routes: [
        GoRoute(path: '/login'          , builder: (context, state) =>  LoginScreen()),
        GoRoute(path: '/dash'           , builder: (context, state) =>  DashScreen()),
        GoRoute(path: '/caisse'         , builder: (_, __) =>  CaisseScreen()),
        GoRoute(path: '/client'         , builder: (_, __) =>  ClientScreen()),
        GoRoute(path: '/fournisseur'    , builder: (_, __) =>  FournisseurScreen()),
        GoRoute(path: '/magasin'        , builder: (_, __) =>  const MagasinScreen()),
        GoRoute(path: '/pannier'        , builder: (_, __) =>  PannierScreen()),
        GoRoute(path: '/produit'        , builder: (_, __) =>  ProduitScreen()),
        GoRoute(path: '/parametre'      , builder: (_, __) =>  ParametreScreen()),
        GoRoute(path: '/stock'          , builder: (_, __) =>  StockScreen()),
        GoRoute(path: '/utilisateur'    , builder: (_, __) =>  UtilisateurScreen()),
        GoRoute(path: '/gestion_caisse' , builder: (_, __) =>  GestionCaisseScreen()),
        GoRoute(path: '/zakat'          , builder: (_, __) =>  ZakatScreen()),
        GoRoute(path: '/historique'     , builder: (_, __) =>  HistoriqueScreen()),
        GoRoute(path: '/activate'       , builder: (_, __) =>  ActivationScreen()),
        GoRoute(path: '/entree'         , builder: (_, __) =>  EntreeScreen()),
        GoRoute(path: '/sortie'         , builder: (_, __) =>  SortieScreen()),
        GoRoute(path: '/retour'         , builder: (_, __) =>  RetourScreen()),
        GoRoute(path: '/besoin'         , builder: (_, __) =>  BesionScreen()),
      ],
    );
  }
}