import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
/// -------------------------------
/// TYPES D'ÉLÉMENTS POSSIBLES
/// -------------------------------
abstract class RowItem {}

class RowText extends RowItem {
  final String text;
  final Color color;
  final bool bold;

  RowText(
      this.text, {
        this.color = Appstyle.Tnoir, // 👈 couleur par défaut corrigée
        this.bold = false,
      });
}

class RowInput extends RowItem {
  final TextEditingController controller;
  RowInput(this.controller);
}

class RowButton extends RowItem {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;


  RowButton(
      this.text,
      this.onPressed, {
        this.backgroundColor = Colors.blue,
      });
}

class RowRadio extends RowItem {
  final bool selected;
  final VoidCallback onChanged;

  RowRadio({
    required this.selected,
    required this.onChanged,
  });
}

/// -------------------------------------------
/// WIDGET FLEXIBLE
/// -------------------------------------------
class SuperWidget extends StatelessWidget {
  final List<RowItem> items;
 final Color couleur;
  const SuperWidget({super.key, required this.items, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:couleur,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) => _buildItem(item)).toList(),
      ),
    );
  }

  /// GÉNÈRE CHAQUE ITEM SELON SON TYPE
  Widget _buildItem(RowItem item) {
    // ---------------- TEXT ----------------
    if (item is RowText) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          item.text,
          style: (item.bold ? Appstyle.textSB : Appstyle.textS)
              .copyWith(color: item.color),
        ),
      );
    }

    // ---------------- INPUT ----------------
    if (item is RowInput) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: item.controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      );
    }

    // ---------------- BUTTON ----------------
    if (item is RowButton) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: item.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: item.onPressed,
          child: Text(
            item.text,
            style: Appstyle.textS.copyWith(color: Appstyle.Tblanc),
          ),
        ),
      );
    }

    // ---------------- RADIO ----------------
    if (item is RowRadio) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Radio<bool>(
          value: true,
          groupValue: item.selected,
          onChanged: (_) => item.onChanged(),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
