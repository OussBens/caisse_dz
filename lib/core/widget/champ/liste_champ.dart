import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class TextListe extends StatefulWidget {
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool enabled;
  final double? width;
  final String? hint;
  final bool clearable;
  final bool obligatoire;

  const TextListe({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.width,
    this.hint,
    this.clearable = true,
    this.obligatoire = false,
  });

  @override
  State<TextListe> createState() => _TextListeState();
}

class _TextListeState extends State<TextListe> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Helper method to get unique items
  List<String> get _uniqueItems => widget.items.toSet().toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FormField<String>(
      initialValue: widget.value,
      validator: widget.obligatoire
          ? (value) {
        if (value == null || value.isEmpty) {
          return l10n.requiredField;
        }
        return null;
      }
          : null,
      builder: (FormFieldState<String> state) {
        final bool hasValue = widget.value != null && widget.value!.isNotEmpty;
        final uniqueItems = _uniqueItems;

        // ✅ Validate that value exists in items
        final String? validValue = hasValue && uniqueItems.contains(widget.value)
            ? widget.value
            : null;

        Widget dropdown = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: widget.enabled
                    ? Appstyle.violetGradient.withOpacity(0.8)
                    : Appstyle.disabledGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: validValue,
                        hint: Text(
                          widget.hint ?? l10n.select,
                          style: Appstyle.textXSB.copyWith(
                            color: Appstyle.Tblanc,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onChanged: widget.enabled
                            ? (value) {
                          widget.onChanged(value);
                          state.didChange(value);
                        }
                            : null,
                        // ✅ Use unique items for dropdown
                        items: uniqueItems.map((e) {
                          final bool isSelected = e == widget.value;
                          return DropdownMenuItem<String>(
                            value: e,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                e,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  letterSpacing: isSelected ? 0.3 : 0,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        // ✅ Use unique items for selected item builder
                        selectedItemBuilder: (context) {
                          return uniqueItems.map((e) {
                            return Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.value ?? '',
                                style: Appstyle.textXSB.copyWith(
                                  color: Appstyle.Tblanc,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        menuItemStyleData: MenuItemStyleData(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          selectedMenuItemBuilder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: Appstyle.violetGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DefaultTextStyle(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                child: child,
                              ),
                            );
                          },
                        ),
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: widget.enabled
                                ? Appstyle.Tblanc
                                : Appstyle.Tblanc.withOpacity(0.6),
                            size: 24,
                          ),
                          openMenuIcon: Icon(
                            Icons.arrow_drop_up,
                            color: widget.enabled
                                ? Appstyle.Tblanc
                                : Appstyle.Tblanc.withOpacity(0.6),
                            size: 24,
                          ),
                        ),
                        buttonStyleData: ButtonStyleData(
                          height: 40,
                          padding: EdgeInsets.zero,
                          overlayColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.enabled &&
                      widget.clearable &&
                      hasValue)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        onTap: () {
                          widget.onChanged("");
                          state.didChange("");
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.clear,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

        return widget.width != null
            ? SizedBox(width: widget.width, child: dropdown)
            : dropdown;
      },
    );
  }
}