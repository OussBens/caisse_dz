
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

class CategorySelector extends StatefulWidget {
  final List<String?> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12, // espace horizontal
      runSpacing: 12, // espace vertical
      children: widget.categories.map((cat) {
        final bool isSelected = cat == widget.selected;

        return GestureDetector(
          onTap: () => widget.onChanged(cat!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Appstyle.violet : Appstyle.grisC,
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            ),
            child: Text(
              cat!,
              style: Appstyle.textMB.copyWith(color: Appstyle.Tblanc),
            ),
          ),
        );
      }).toList(),
    );
  }
}
