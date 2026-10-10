import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/core/widget/champ/radio_champ.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class CategoryMultiSelector extends StatefulWidget {
  final List<String> categories;
  final double tagBoxHeight;

  const CategoryMultiSelector({
    super.key,
    required this.categories,
    this.tagBoxHeight = 120,
  });

  @override
  State<CategoryMultiSelector> createState() => _CategoryMultiSelectorState();
}

class _CategoryMultiSelectorState extends State<CategoryMultiSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<String> selectedCategories = [];
  bool autoValue = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ----- Label -----
          Text(
            l10n.category,
            style: Appstyle.textLB.copyWith(color: Appstyle.TgrisC),
          ),
          const SizedBox(height: 10),

          // ----- Dropdown -----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Appstyle.neutral150,
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            ),
            child: DropdownButton<String>(
              hint: Text(l10n.chooseCategory),
              value: null,
              isExpanded: true,
              underline: const SizedBox(),
              items: widget.categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && !selectedCategories.contains(value)) {
                  setState(() {
                    selectedCategories.add(value);
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 15),

          // ----- Zone scrollable -----
          if (selectedCategories.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 0,
                maxHeight: widget.tagBoxHeight,
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedCategories.map((cat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Appstyle.violet,
                        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat,
                            style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategories.remove(cat);
                              });
                            },
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          if (selectedCategories.isNotEmpty)
            const SizedBox(height: 20),

          const SizedBox(height: 20),

          // ----- Search Field -----
          Row(
            textDirection: textDirection,
            children: [
              Text(
                l10n.product,
                style: Appstyle.textLB.copyWith(color: Appstyle.TgrisC),
              ),
              const SizedBox(width: 200),
              Expanded(child: SearchField(controller: _searchController)),
            ],
          ),

          // -------Tous ------------
          Row(
            textDirection: textDirection,
            children: [
              TextRadio(
                value: autoValue,
                onChanged: (v) {
                  setState(() {
                    autoValue = v!;
                  });
                },
              ),
              const SizedBox(width: 20),
              Text(
                l10n.all,
                style: Appstyle.textLB.copyWith(color: Appstyle.TgrisC),
              ),
            ],
          ),
        ],
      ),
    );
  }
}