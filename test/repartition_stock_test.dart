import 'package:caisse_dz/Services/RepartitionStock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ordre = ['MAG1', 'MAG2', 'MAG3']; // MAG1 = principal

  group('Vente (séquentielle : magasin 1, puis 2…)', () {
    test('tout dans le magasin principal s\'il suffit', () {
      expect(RepartitionStock.sequentielle(5, ordre, {'MAG1': 10, 'MAG2': 10}), [const PartMagasin('MAG1', 5)]);
    });

    test('complète avec le magasin suivant', () {
      expect(
        RepartitionStock.sequentielle(6, ordre, {'MAG1': 4, 'MAG2': 10}),
        [const PartMagasin('MAG1', 4), const PartMagasin('MAG2', 2)],
      );
    });

    test('saute un magasin vide ou négatif', () {
      expect(
        RepartitionStock.sequentielle(3, ordre, {'MAG1': 0, 'MAG2': -2, 'MAG3': 5}),
        [const PartMagasin('MAG3', 3)],
      );
    });

    test('total insuffisant : le reste sur le principal', () {
      expect(
        RepartitionStock.sequentielle(10, ordre, {'MAG1': 2, 'MAG2': 3}),
        [const PartMagasin('MAG1', 7), const PartMagasin('MAG2', 3)],
      );
    });

    test('quantités décimales (kg)', () {
      final parts = RepartitionStock.sequentielle(1.5, ordre, {'MAG1': 0.75, 'MAG2': 4});
      expect(parts.map((p) => p.magasinCode), ['MAG1', 'MAG2']);
      expect(parts[0].quantite, closeTo(0.75, 1e-9));
      expect(parts[1].quantite, closeTo(0.75, 1e-9));
    });

    test('Basic : un seul magasin', () {
      expect(RepartitionStock.sequentielle(4, ['MAG0000'], {'MAG0000': 1}), [const PartMagasin('MAG0000', 4)]);
    });
  });

  group('Retour fournisseur / Sortie (un magasin, sinon réparti)', () {
    test('premier magasin qui a toute la quantité, même s\'il n\'est pas le principal', () {
      expect(
        RepartitionStock.unMagasinSinonSequentielle(8, ordre, {'MAG1': 5, 'MAG2': 9, 'MAG3': 20}),
        [const PartMagasin('MAG2', 8)],
      );
    });

    test('aucun magasin seul : réparti dans l\'ordre', () {
      expect(
        RepartitionStock.unMagasinSinonSequentielle(12, ordre, {'MAG1': 5, 'MAG2': 4, 'MAG3': 6}),
        [const PartMagasin('MAG1', 5), const PartMagasin('MAG2', 4), const PartMagasin('MAG3', 3)],
      );
    });
  });

  group('Retour client (vers le magasin d\'origine)', () {
    const vente = [PartMagasin('MAG1', 4), PartMagasin('MAG2', 2)];

    test('retour partiel : d\'abord le dernier magasin servi', () {
      expect(
        RepartitionStock.retourVersOrigine(3, vente),
        [const PartMagasin('MAG2', 2), const PartMagasin('MAG1', 1)],
      );
    });

    test('retour total : chaque magasin récupère ce qui en est sorti', () {
      expect(
        RepartitionStock.retourVersOrigine(6, vente),
        [const PartMagasin('MAG2', 2), const PartMagasin('MAG1', 4)],
      );
    });

    test('second retour : tient compte de ce qui a déjà été rendu', () {
      expect(
        RepartitionStock.retourVersOrigine(2, vente, dejaRetourne: {'MAG2': 2, 'MAG1': 1}),
        [const PartMagasin('MAG1', 2)],
      );
    });

    test('vente d\'un seul magasin', () {
      expect(RepartitionStock.retourVersOrigine(1, const [PartMagasin('MAG3', 5)]), [const PartMagasin('MAG3', 1)]);
    });
  });

  group('Distribution (total conservé)', () {
    test('valide si la somme est égale au total', () {
      expect(RepartitionStock.distributionValide(100, {'MAG1': 60, 'MAG2': 40}), isTrue);
    });

    test('refusée si la somme diffère (création ou perte de stock)', () {
      expect(RepartitionStock.distributionValide(100, {'MAG1': 60, 'MAG2': 50}), isFalse);
      expect(RepartitionStock.distributionValide(100, {'MAG1': 60}), isFalse);
    });

    test('refusée avec une quantité négative', () {
      expect(RepartitionStock.distributionValide(100, {'MAG1': 120, 'MAG2': -20}), isFalse);
    });

    test('mouvements à créer = écarts par magasin', () {
      expect(
        RepartitionStock.deltasDistribution({'MAG1': 100}, {'MAG1': 60, 'MAG2': 40}),
        {'MAG1': -40, 'MAG2': 40},
      );
    });
  });
}
