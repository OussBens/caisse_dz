import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../button/main_button.dart';

class ColumnSettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ColumnSettingsButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MainButton(
      text: "",
      icon: Icons.view_column,
      color: Appstyle.violet,
      onPressed: onPressed,
    );
  }
}
