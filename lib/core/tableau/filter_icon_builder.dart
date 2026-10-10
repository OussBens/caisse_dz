import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../theme/app_style.dart';

/// Icône de filtre dynamique pour l'en-tête d'un [SfDataGrid] : jaune et
/// plus grande quand un filtre est actif sur la colonne, pour que
/// l'utilisateur repère immédiatement quelles colonnes sont filtrées —
/// sinon un filtre actif sur une colonne hors écran passe inaperçu.
///
/// À passer via `SfDataGridTheme(data: SfDataGridThemeData(filterIcon:
/// Builder(builder: (context) => buildFilterIcon(context, dataSource))))`
/// — c'est le mécanisme officiellement documenté par Syncfusion pour
/// personnaliser l'icône par colonne (voir le commentaire sur
/// `SfDataGridThemeData.filterIcon` dans le package).
Widget buildFilterIcon(BuildContext context, DataGridSource dataSource) {
  String columnName = '';
  context.visitAncestorElements((element) {
    if (element is GridHeaderCellElement) {
      columnName = element.column.columnName;
    }
    return true;
  });

  final isActive = dataSource.filterConditions.keys.contains(columnName);

  if (isActive) {
    return const Icon(Icons.filter_alt, size: 22, color: Appstyle.warning);
  }

  return Icon(Icons.filter_alt_outlined, size: 16, color: Appstyle.Tblanc.withOpacity(0.85));
}
