import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountWidget extends StatelessWidget {
  final String name;
  final String imageUrl;

  const AccountWidget({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        onSelected: (value) {
          // Handle menu selection
        },
        itemBuilder: (context) => [
          // Uncomment when you add menu items:
          // PopupMenuItem(
          //   value: 'profile',
          //   child: Text(l10n.profile),
          // ),
          // PopupMenuItem(
          //   value: 'settings',
          //   child: Text(l10n.settings),
          // ),
          // PopupMenuItem(
          //   value: 'logout',
          //   child: Text(l10n.logout),
          // ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            textDirection: textDirection,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage(imageUrl),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: Appstyle.textXSB.copyWith(color: Appstyle.Tnoir),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}