import 'package:caisse_dz/data/models/caisse.dart';
import 'package:caisse_dz/data/models/client.dart';

/// Garde en mémoire les paniers en cours et le client sélectionné de l'écran
/// Caisse pendant toute la durée de vie de l'application.
///
/// `CaisseScreen` est recréé à chaque navigation (go_router remplace la route,
/// il n'y a pas d'`IndexedStack`/`ShellRoute` gardant les écrans en vie -
/// voir docs/02_architecture.md "Router"). Sans ce singleton, revenir sur
/// l'écran Caisse après être passé par un autre module réinitialisait le
/// panier et le client sélectionné. Suit le même pattern singleton que
/// [AuthState] (lib/core/Auth/auth_state.dart).
class CaisseSessionState {
  static final CaisseSessionState instance = CaisseSessionState._internal();

  CaisseSessionState._internal();

  List<CaisseState> caisses = [];
  int selectedCaisse = 0;
  Client? clientSelectione;
}
