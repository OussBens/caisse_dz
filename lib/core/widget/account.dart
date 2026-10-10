import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/compte/mon_compte.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        ),
        elevation: 4,
        onSelected: (value) {
          switch (value) {
            case 'compte':
              MonCompteDialog(context);
              break;
            case 'settings':
              context.go('/parametre');
              break;
            case 'logout':
              final auth = Provider.of<AuthState>(context, listen: false);
              auth.logout(
                username: auth.username ?? '',
                userCode: auth.userCode ?? '',
              );
              context.go('/login');
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'compte',
            child: Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.black54),
                const SizedBox(width: 10),
                Text(l10n.compte),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings, size: 18, color: Colors.black54),
                const SizedBox(width: 10),
                Text(l10n.settings),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout, size: 18, color: Appstyle.danger),
                const SizedBox(width: 10),
                Text(l10n.logout, style: const TextStyle(color: Appstyle.danger)),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            boxShadow: [
              BoxShadow(
                color: Appstyle.shadowSoft,
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