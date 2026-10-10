import 'dart:async';
import 'dart:io';

import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Témoin de connexion internet (vert = connecté, rouge = déconnecté).
/// Vérifie périodiquement l'accès réseau via une résolution DNS,
/// quel que soit le support (wifi ou câble).
class InternetStatusWidget extends StatefulWidget {
  const InternetStatusWidget({super.key});

  @override
  State<InternetStatusWidget> createState() => _InternetStatusWidgetState();
}

/// Vérification ponctuelle de la connexion (hors widget), pour les actions
/// qui ont besoin du réseau (ex: scan IA d'une photo) et doivent prévenir
/// l'utilisateur avant d'essayer plutôt que d'échouer silencieusement.
Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('one.one.one.one')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on Exception {
    return false;
  }
}

class _InternetStatusWidgetState extends State<InternetStatusWidget> {
  static const _checkInterval = Duration(seconds: 5);

  Timer? _timer;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _timer = Timer.periodic(_checkInterval, (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    final connected = await hasInternetConnection();
    if (mounted) {
      setState(() => _isConnected = connected);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _isConnected ? Appstyle.success : Appstyle.danger;

    return Tooltip(
      message: _isConnected ? l10n.internetConnected : l10n.internetDisconnected,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Appstyle.shadowSoft,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 4, spreadRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}
