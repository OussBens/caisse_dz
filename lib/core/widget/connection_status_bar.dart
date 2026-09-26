import 'package:caisse_dz/core/widget/internet_status_widget.dart';
import 'package:caisse_dz/core/widget/mobile_pairing_button.dart';
import 'package:flutter/material.dart';

/// Regroupe le témoin de connexion internet et le bouton d'appairage
/// mobile ; remplace [InternetStatusWidget] dans l'en-tête de chaque écran.
class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InternetStatusWidget(),
        SizedBox(width: 8),
        MobilePairingButton(),
      ],
    );
  }
}
