import 'dart:async';

import 'package:caisse_dz/Services/BonReceptionServer.dart';
import 'package:caisse_dz/core/dialog/AI/reception_connection_dialog.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Bouton d'appairage d'un téléphone (app compagnon) avec ce desktop.
/// Ouvre [ReceptionConnectionDialog] (QR code + code d'appairage) et affiche
/// un badge vert quand au moins un téléphone est activement connecté.
class MobilePairingButton extends StatefulWidget {
  const MobilePairingButton({super.key});

  @override
  State<MobilePairingButton> createState() => _MobilePairingButtonState();
}

class _MobilePairingButtonState extends State<MobilePairingButton> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isConnected {
    final server = BonReceptionServer.instance;
    final last = server.lastPingAt.value;
    if (!server.isRunning.value || last == null) return false;
    return DateTime.now().difference(last) < const Duration(seconds: 30);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connected = _isConnected;

    return Tooltip(
      message: connected ? l10n.receptionStatusConnected : l10n.mobileConnectTooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ReceptionConnectionDialog.open(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.smartphone, size: 18, color: Colors.grey.shade700),
              if (connected)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
