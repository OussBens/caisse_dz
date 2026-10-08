import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le rôle par défaut est enregistré « admin » (minuscules) en base alors
/// que les rôles proposés à la saisie s'écrivent « Admin » : toute
/// vérification passe par AuthState.estRoleAdmin.
void main() {
  group('AuthState.estRoleAdmin', () {
    test('reconnaît Admin quelle que soit la casse ou les espaces', () {
      expect(AuthState.estRoleAdmin('admin'), isTrue);
      expect(AuthState.estRoleAdmin('Admin'), isTrue);
      expect(AuthState.estRoleAdmin('ADMIN'), isTrue);
      expect(AuthState.estRoleAdmin(' Admin '), isTrue);
    });

    test('refuse les autres rôles et l\'absence de rôle', () {
      expect(AuthState.estRoleAdmin('Caissier'), isFalse);
      expect(AuthState.estRoleAdmin('Magasinier'), isFalse);
      expect(AuthState.estRoleAdmin('administrateur'), isFalse);
      expect(AuthState.estRoleAdmin(''), isFalse);
      expect(AuthState.estRoleAdmin(null), isFalse);
    });
  });
}
