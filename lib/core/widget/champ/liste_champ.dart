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

  // Survol du champ — même langage visuel (bordure/accent qui réagit) que
  // les autres champs restylés (cf. login.dart) plutôt qu'un bloc statique.
  bool _isHovered = false;

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

        // États visuels : deux structures distinctes plutôt qu'une simple
        // nuance de couleur — "spéciale" (dégradé violet, coins plus
        // arrondis, badge ✓) quand une valeur est sélectionnée, "normale"
        // (fond clair, coins standards, pas de badge) sinon.
        final bool showError = state.hasError;
        final bool showSelectedStyle = hasValue && widget.enabled;
        final Color accent = showError ? Appstyle.danger : Appstyle.violet;
        final Color borderColor = !widget.enabled
            ? Appstyle.border
            : showError
            ? Appstyle.danger
            : hasValue
            ? accent
            : _isHovered
            ? Appstyle.violet.withOpacity(0.5)
            : Appstyle.border;
        // Fond plein utilisé seulement quand la structure n'est PAS en
        // dégradé (BoxDecoration n'accepte pas color + gradient en même
        // temps) — cf. plus bas.
        final Color fillColor = !widget.enabled
            ? Appstyle.background
            : hasValue
            ? accent
            : Appstyle.surface;
        final double radius = showSelectedStyle ? Appstyle.radiusLG : Appstyle.radiusMD;
        // Liste figée (enabled = false) : fond clair, donc texte gris — le blanc
        // n'est lisible que sur le fond violet de l'état sélectionné.
        final Color labelColor = !widget.enabled
            ? Appstyle.gris
            : hasValue ? Appstyle.Tblanc : Appstyle.textMuted;
        final Color valueColor = !widget.enabled
            ? Appstyle.gris
            : hasValue ? Appstyle.Tblanc : Appstyle.textPrimary;
        final Color iconColor = !widget.enabled
            ? Appstyle.textMuted.withOpacity(0.5)
            : hasValue
            ? Appstyle.Tblanc
            : Appstyle.textMuted;

        Widget dropdown = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: showSelectedStyle ? null : fillColor,
                  gradient: showSelectedStyle ? Appstyle.violetGradient : null,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: borderColor,
                    width: hasValue || showError ? 1.6 : 1.2,
                  ),
                  boxShadow: showSelectedStyle ? Appstyle.shadowHover(color: accent) : null,
                ),
                child: Row(
                  children: [
                    // Badge ✓ — ne s'affiche que dans la structure "spéciale"
                    // (valeur sélectionnée), renforce la différence avec
                    // l'état normal au-delà de la seule couleur de fond.
                    if (showSelectedStyle)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                      ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          value: validValue,
                          hint: Text(
                            widget.hint ?? l10n.select,
                            style: Appstyle.textXSB.copyWith(
                              color: labelColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
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
                                    color: isSelected ? Appstyle.Tblanc : Appstyle.textPrimary,
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
                                    color: valueColor,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                              color: Appstyle.surface,
                              boxShadow: Appstyle.shadowCard,
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
                                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
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
                              Icons.expand_more_rounded,
                              color: iconColor,
                              size: 22,
                            ),
                            openMenuIcon: Icon(
                              Icons.expand_less_rounded,
                              color: iconColor,
                              size: 22,
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
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: iconColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Appstyle.danger,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Appstyle.danger,
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
