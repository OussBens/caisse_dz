import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RolePermissionTable extends StatefulWidget {
  const RolePermissionTable({super.key});

  @override
  State<RolePermissionTable> createState() => _RolePermissionTableState();
}

class _RolePermissionTableState extends State<RolePermissionTable> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    // ---- LISTE DES COLONNES ---- //
    final List<String> columns = [
      l10n.dashboard,
      l10n.caisse,
      l10n.produit,
      l10n.panier,
      l10n.client,
      l10n.fournisseur,
      l10n.stock,
      l10n.utilisateur,
      l10n.magasin,
    ];

    // ---- DONNÉES DES PERMISSIONS ---- //
    // Use keys for roles to allow translation
    Map<String, List<bool>> permissions = {
      "admin":       [true, true, true, true, true, true, true, true, true],
      "caissier":    [true, false, false, true, true, true, false, true, true],
      "magasinier":  [false, false, true, true, true, true, true, true, false],
    };

    return Directionality(
      textDirection: textDirection,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                textDirection: textDirection,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      l10n.role,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (var c in columns)
                    SizedBox(
                      width: 90,
                      child: Text(
                        c,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ROWS
              for (var roleKey in permissions.keys) ...[
                Row(
                  textDirection: textDirection,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        _getRoleName(roleKey, l10n),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    // Cases des permissions
                    for (int i = 0; i < columns.length; i++)
                      SizedBox(
                        width: 90,
                        child: CircleCheckBox(
                          value: permissions[roleKey]![i],
                          onChanged: (v) {
                            setState(() {
                              permissions[roleKey]![i] = v;
                            });
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleName(String key, AppLocalizations l10n) {
    switch (key) {
      case "admin": return l10n.admin;
      case "caissier": return l10n.caissier;
      case "magasinier": return l10n.magasinier;
      default: return key;
    }
  }
}

/* ---------------------------------------------------
   ---   WIDGET DE CASE A COCHER CIRCULAIRE (✓)    ---
   --------------------------------------------------- */

class CircleCheckBox extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const CircleCheckBox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? const Color(0xFF6A4CE3) : Colors.transparent,
          border: Border.all(
            color: value ? Colors.transparent : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: value
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}