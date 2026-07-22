import 'package:flutter/cupertino.dart';

import '../../../data/models/produit.dart';

class ProduitColumn {
  final String id;
  final String label;
  final Comparable Function(Produit p)? sortField;
  final Widget Function(Produit p) cellBuilder;
  bool visible;

  ProduitColumn({
    required this.id,
    required this.label,
    this.sortField,
    required this.cellBuilder,
    this.visible = true,
  });
}