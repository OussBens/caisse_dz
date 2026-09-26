import 'package:caisse_dz/data/models/catalog_product.dart';
import '../base_table_data_source.dart';

/// Source de données du DataGrid de l'écran d'administration du catalogue
/// distant (voir lib/screens/catalog_screen.dart). Réutilise
/// [BaseTableDataSource], partagé par les autres tableaux de l'app.
class CatalogDataSource extends BaseTableDataSource<CatalogProduct> {
  CatalogDataSource({
    required List<CatalogProduct> products,
    required super.columnConfig,
  }) : super(items: products);

  @override
  dynamic cellValue(CatalogProduct product, String field) {
    switch (field) {
      case 'codeProduit':
        return product.codeProduit;
      case 'nom':
        return product.nom;
      case 'marque':
        return product.marque ?? '';
      case 'categorie':
        return product.categorie ?? '';
      case 'couleur':
        return product.couleur ?? '';
      case 'taille':
        return product.taille ?? '';
      case 'barcode':
        return product.barcode ?? '';
      default:
        return '';
    }
  }

  void update(List<CatalogProduct> newProducts) => updateItems(newProducts);
}
