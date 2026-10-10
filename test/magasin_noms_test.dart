import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nom du magasin d'un mouvement (tableau, détail, exports) : un seul
/// endroit, MagasinServices.nomMagasin.
void main() {
  Magasin magasin(String code, String nom, {bool etat = true}) =>
      Magasin(id: 1, code: code, nom: nom, etat: etat, dateCree: DateTime(2026), creeParCode: 'ADMIN');

  final noms = MagasinServices.nomsParCode([
    magasin('MAG0000', 'Principal'),
    magasin('MAG000002', 'Dépôt', etat: false),
  ]);

  test('nom du magasin, y compris un magasin désactivé', () {
    expect(MagasinServices.nomMagasin(noms, 'MAG0000'), 'Principal');
    expect(MagasinServices.nomMagasin(noms, 'MAG000002'), 'Dépôt');
  });

  test('code inconnu : le code ; pas de magasin : tiret', () {
    expect(MagasinServices.nomMagasin(noms, 'MAG999'), 'MAG999');
    expect(MagasinServices.nomMagasin(noms, null), '-');
  });
}
