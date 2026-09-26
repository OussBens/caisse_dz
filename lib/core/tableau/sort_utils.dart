/// Comparaison générique de deux valeurs de cellule pour le tri par
/// en-tête de colonne, réutilisée par les [DataGridSource] "faits main" de
/// lib/core/tableau/** qui n'étendent pas [BaseTableDataSource] (celles-ci
/// ont leur propre logique d'affichage/sélection trop spécifique pour
/// partager cette base, mais le besoin de tri générique est le même).
int compareCellValues(dynamic a, dynamic b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  if (a is num && b is num) return a.compareTo(b);
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  if (a is bool && b is bool) return (a == b) ? 0 : (a ? 1 : -1);
  return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
}
