import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class ColumnSettingsDialog extends StatefulWidget {
  final Map<String, Map<String, dynamic>> columnVisibility;
  final Map<String, bool> defaultColumns;
  final bool garderSelection;
  final ValueChanged<bool> onToggleKeepSelection;
  final ValueChanged<Map<String, Map<String, dynamic>>> onApply;

  const ColumnSettingsDialog({
    super.key,
    required this.columnVisibility,
    required this.defaultColumns,
    required this.garderSelection,
    required this.onToggleKeepSelection,
    required this.onApply,
  });

  @override
  State<ColumnSettingsDialog> createState() => _ColumnSettingsDialogState();
}

class _ColumnSettingsDialogState extends State<ColumnSettingsDialog> {
  late Map<String, Map<String, dynamic>> localColumns;
  late bool garder;

  @override
  void initState() {
    super.initState();
    localColumns = Map.from(widget.columnVisibility);
    garder = widget.garderSelection;
  }

  @override
  Widget build(BuildContext context) {
    // Get localization
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusLG)),
      title: Text(l10n.showHideColumns), // 🔥 Translated
      content: SizedBox(
        width: 350,
        height: 450,
        child: Column(
          children: [
            /// Tout / Aucun
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.check_box),
                  label: Text(l10n.all), // 🔥 Translated
                  onPressed: () {
                    setState(() {
                      localColumns.forEach((k, v) {
                        v['visible'] = true;
                      });
                    });
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.check_box_outline_blank),
                  label: Text(l10n.none), // 🔥 Translated
                  onPressed: () {
                    setState(() {
                      localColumns.forEach((k, v) {
                        v['visible'] = false;
                      });
                    });
                  },
                ),
              ],
            ),

            const Divider(),

            /// Garder sélection
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.keepSelection), // 🔥 Translated
              value: garder,
              onChanged: (v) {
                setState(() => garder = v ?? true);

                if (v == false) {
                  setState(() {
                    localColumns.forEach((k, v) {
                      v['visible'] = widget.defaultColumns[k] ?? true;
                    });
                  });
                }
              },
            ),

            const Divider(),

            /// Liste colonnes
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: localColumns.entries.map((entry) {
                    return CheckboxListTile(
                      title: Text(entry.value['label']),
                      value: entry.value['visible'],
                      onChanged: (v) {
                        setState(() {
                          entry.value['visible'] = v ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(l10n.apply), // 🔥 Translated
          onPressed: () {
            widget.onToggleKeepSelection(garder);
            widget.onApply(localColumns);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}