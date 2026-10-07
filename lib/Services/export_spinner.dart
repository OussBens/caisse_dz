import 'package:flutter/material.dart';

/// Ouvre un spinner bloquant sur le navigateur racine (là où showDialog le
/// pousse). La fonction retournée le ferme ; elle est idempotente, donc sûre à
/// appeler aussi bien dans le flux normal que dans un catch.
///
/// Ne jamais fermer ce spinner via Navigator.pop(context) de l'écran : ce
/// context pointe vers le navigateur GoRouter sous-jacent, dont le pop
/// dépile la page ("You have popped the last page off of the stack").
void Function() ouvrirSpinnerExport(BuildContext context) {
  final navigateur = Navigator.of(context, rootNavigator: true);
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  var ferme = false;
  return () {
    if (ferme) return;
    ferme = true;
    navigateur.pop();
  };
}

Future<T> executerAvecSpinner<T>(BuildContext context, Future<T> Function() travail) async {
  final fermer = ouvrirSpinnerExport(context);
  try {
    return await travail();
  } finally {
    fermer();
  }
}
