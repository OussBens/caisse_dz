import 'package:caisse_dz/Services/Role.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le rôle par défaut est enregistré « admin » (minuscules) en base alors
/// que les rôles proposés à la saisie s'écrivent « Admin » : toute
/// vérification passe par RoleServices.estRoleAdmin.
void main() {
  group('RoleServices.estRoleAdmin', () {
    test('reconnaît Admin quelle que soit la casse ou les espaces', () {
      expect(RoleServices.estRoleAdmin('admin'), isTrue);
      expect(RoleServices.estRoleAdmin('Admin'), isTrue);
      expect(RoleServices.estRoleAdmin('ADMIN'), isTrue);
      expect(RoleServices.estRoleAdmin(' Admin '), isTrue);
    });

    test('refuse les autres rôles et l\'absence de rôle', () {
      expect(RoleServices.estRoleAdmin('Caissier'), isFalse);
      expect(RoleServices.estRoleAdmin('Magasinier'), isFalse);
      expect(RoleServices.estRoleAdmin('administrateur'), isFalse);
      expect(RoleServices.estRoleAdmin(''), isFalse);
      expect(RoleServices.estRoleAdmin(null), isFalse);
    });
  });
}
