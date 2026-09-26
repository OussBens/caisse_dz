import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:caisse_dz/Services/BonReceptionServer.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Panneau de connexion avec l'app mobile compagnon CaisseDZ Scanner
/// (Produit, Panier, envoi de photos SmartScan) : IP(s) locales, port
/// (modifiable), démarrage du serveur HTTP local et QR code pour appairer
/// facilement le téléphone. Réutilisé depuis plusieurs écrans (Réception,
/// Produit, Caisse, Stock) via [MobilePairingButton] — pas spécifique à un
/// seul module.
class ReceptionConnectionDialog extends StatefulWidget {
  const ReceptionConnectionDialog({super.key});

  static Future<void> open(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ReceptionConnectionDialog(),
    );
  }

  @override
  State<ReceptionConnectionDialog> createState() => _ReceptionConnectionDialogState();
}

class _ReceptionConnectionDialogState extends State<ReceptionConnectionDialog> {
  List<String> _ips = [];
  String? _selectedIp;
  final TextEditingController _portController = TextEditingController();
  Timer? _statusTimer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
    // ✅ Rafraîchit périodiquement l'indicateur "connecté" et le compte à
    // rebours du code d'appairage, même sans nouvelle activité.
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _init() async {
    final ips = await BonReceptionServer.localIPv4Addresses();
    final savedPort = await BonReceptionServer.getSavedPort();
    if (!mounted) return;
    setState(() {
      _ips = ips;
      _selectedIp = _pickBestIp(ips);
      _portController.text = savedPort.toString();
    });
    await _autoConnect(savedPort);
  }

  /// Préfère les adresses de réseau local classiques (box/routeur du
  /// magasin) aux adaptateurs virtuels (VPN, hyperviseurs) pour que le QR
  /// affiché fonctionne du premier coup sans que l'utilisateur n'ait à
  /// choisir lui-même une adresse dans la liste. Aucune IP n'est codée en
  /// dur : une IP figée ici finit toujours par pointer sur un réseau qui
  /// n'est plus le bon dès que la boutique change de box/routeur.
  String? _pickBestIp(List<String> ips) {
    if (ips.isEmpty) return null;
    bool is192(String ip) => ip.startsWith('192.168.');
    bool is10(String ip) => ip.startsWith('10.');
    bool is172(String ip) {
      final parts = ip.split('.');
      if (parts.length < 2 || parts[0] != '172') return false;
      final second = int.tryParse(parts[1]);
      return second != null && second >= 16 && second <= 31;
    }

    return ips.firstWhere(
      is192,
      orElse: () => ips.firstWhere(
        is10,
        orElse: () => ips.firstWhere(is172, orElse: () => ips.first),
      ),
    );
  }

  /// Démarre automatiquement le serveur (sans action de l'utilisateur) dès
  /// l'ouverture du panneau, pour que le QR soit prêt à scanner
  /// immédiatement — l'IP et le port restent modifiables dans "Paramètres
  /// avancés" pour les cas particuliers (plusieurs cartes réseau, port
  /// déjà utilisé, etc.).
  Future<void> _autoConnect(int savedPort) async {
    final server = BonReceptionServer.instance;
    if (!server.isRunning.value) {
      final response = await server.start(port: savedPort);
      if (!mounted) return;
      if (!response.success) {
        setState(() {
          _loading = false;
          _error = response.message;
        });
        return;
      }
    }
    if (server.pairingCode.value == null) {
      server.generatePairingCode();
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _toggleServer() async {
    final server = BonReceptionServer.instance;

    if (server.isRunning.value) {
      await server.stop();
      server.clearPairingCode();
      if (mounted) setState(() {});
      return;
    }

    final port = int.tryParse(_portController.text.trim()) ?? BonReceptionServer.defaultPort;
    final response = await server.start(port: port);
    if (!mounted) return;
    setState(() {
      _error = response.success ? null : response.message;
    });
    if (response.success) {
      server.generatePairingCode();
    }
  }

  void _regeneratePairingCode() {
    BonReceptionServer.instance.generatePairingCode();
    setState(() {});
  }

  bool get _isConnected {
    final last = BonReceptionServer.instance.lastPingAt.value;
    if (last == null) return false;
    return DateTime.now().difference(last) < const Duration(seconds: 30);
  }

  String _formatPairingCode(String code) {
    // Découpe en groupes de 4 pour une lecture/saisie manuelle plus facile.
    final groups = <String>[];
    for (var i = 0; i < code.length; i += 4) {
      groups.add(code.substring(i, i + 4 > code.length ? code.length : i + 4));
    }
    return groups.join('-');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final server = BonReceptionServer.instance;
    final url = (_selectedIp != null && server.port != null)
        ? 'http://$_selectedIp:${server.port}'
        : null;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: BaseDialog(
          width: 660,
          height: 700,
          header: TitreAvecLigne(
            imagePath: 'assets/icons/ai_icon.png',
            text: l10n.connectMobileAppTitle,
          ),
          content: _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.startingServerAutomatically, style: Appstyle.textSB),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_ips.isEmpty)
                        Text(
                          l10n.receptionNoNetwork,
                          textAlign: TextAlign.center,
                          style: Appstyle.textSB,
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_error!, style: TextStyle(color: Appstyle.red)),
                        ),
                      const SizedBox(height: 20),
                      ValueListenableBuilder<bool>(
                        valueListenable: server.isRunning,
                        builder: (context, running, _) {
                          return ValueListenableBuilder<String?>(
                            valueListenable: server.pairingCode,
                            builder: (context, pairingCode, __) {
                              if (!running || url == null || pairingCode == null) {
                                return const SizedBox.shrink();
                              }
                              final expiresAt = server.pairingCodeExpiresAt.value;
                              final remaining = expiresAt?.difference(DateTime.now());
                              final expired = remaining == null || remaining.isNegative;
                              final payload = jsonEncode({
                                'ip': _selectedIp,
                                'port': server.port,
                                'pairing_token': pairingCode,
                                'desktop_name': server.desktopName,
                              });

                              return Column(
                                children: [
                                  Text(l10n.scanOrTypeCode, textAlign: TextAlign.center, style: Appstyle.textSB),
                                  const SizedBox(height: 12),
                                  QrImageView(data: payload, size: 180),
                                  const SizedBox(height: 12),
                                  Text(l10n.pairingCodeLabel, style: Appstyle.textSB),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () async {
                                      await Clipboard.setData(ClipboardData(text: pairingCode));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l10n.pairingCodeCopied)),
                                        );
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _formatPairingCode(pairingCode),
                                          style: Appstyle.textSB.copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.copy, size: 18),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    expired
                                        ? l10n.pairingCodeExpired
                                        : '${l10n.pairingCodeExpiresLabel} ${remaining.inSeconds}s',
                                    style: Appstyle.textXS.copyWith(color: expired ? Appstyle.red : null),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _regeneratePairingCode,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: Text(l10n.regeneratePairingCode),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<DateTime?>(
                        valueListenable: server.lastPingAt,
                        builder: (context, _, __) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _isConnected ? Appstyle.green : Appstyle.gris,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isConnected ? l10n.receptionStatusConnected : l10n.receptionStatusWaiting,
                              style: Appstyle.textSB,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ValueListenableBuilder<List<PairedDevice>>(
                        valueListenable: server.pairedDevices,
                        builder: (context, devices, __) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l10n.pairedDevicesSection, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (devices.isEmpty)
                                Text(
                                  l10n.noPairedDevices,
                                  textAlign: TextAlign.center,
                                  style: Appstyle.textXS,
                                )
                              else
                                ...devices.map(
                                  (d) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.smartphone, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(l10n.phone, style: Appstyle.textSB)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: server.isRunning,
                        builder: (context, running, _) => MainButton(
                          text: running ? l10n.receptionStopServer : l10n.receptionStartServer,
                          color: running ? Appstyle.red : Appstyle.green,
                          icon: running ? Icons.stop : Icons.play_arrow,
                          onPressed: _toggleServer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(l10n.advancedConnectionSettings, style: Appstyle.textXS),
                          childrenPadding: const EdgeInsets.only(top: 8),
                          children: [
                            if (_ips.isNotEmpty)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedIp,
                                decoration: InputDecoration(labelText: l10n.ipAddressLabel),
                                items: _ips
                                    .map((ip) => DropdownMenuItem(value: ip, child: Text(ip)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedIp = v),
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: l10n.portLabel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          footer: Align(
            alignment: Alignment.centerRight,
            child: MainButton(
              text: l10n.close,
              color: Appstyle.gris,
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}
