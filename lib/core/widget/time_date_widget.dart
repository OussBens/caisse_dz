
import 'dart:async';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Affiche l'heure et la date courantes, mises à jour automatiquement
/// chaque minute (pas besoin de les passer depuis l'écran parent).
class TimeDateWidget extends StatefulWidget {
  final String iconHeure;
  final String iconDate;

  const TimeDateWidget({
    super.key,
    required this.iconHeure,
    required this.iconDate,
  });

  @override
  State<TimeDateWidget> createState() => _TimeDateWidgetState();
}

class _TimeDateWidgetState extends State<TimeDateWidget> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleNextTick();
  }

  // Aligne le prochain rafraîchissement sur le début de la minute suivante.
  void _scheduleNextTick() {
    final msUntilNextMinute =
        (60 - _now.second) * 1000 - _now.millisecond;
    _timer = Timer(
      Duration(milliseconds: msUntilNextMinute.clamp(1000, 60000)),
      () {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        _scheduleNextTick();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heure = DateFormat('HH:mm').format(_now);
    final date = DateFormat('dd/MM/yyyy').format(_now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heure
          Image.asset(
            widget.iconHeure,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            heure,
            style: Appstyle.textXSB.copyWith(color: Appstyle.Tnoir),
          ),
          const SizedBox(width: 25),

          // Date
          Image.asset(
            widget.iconDate,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            date,
            style: Appstyle.textXSB.copyWith(color: Appstyle.Tnoir),
          ),
        ],
      ),
    );
  }
}
