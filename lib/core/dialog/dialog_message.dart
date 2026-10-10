import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Nature du message affiché par ConfirmationDialog / InformationDialog,
/// matérialisée par une grande icône à côté du texte.
enum NatureMessage { succes, information, erreur }

extension NatureMessageStyle on NatureMessage {
  IconData get icone => switch (this) {
        NatureMessage.succes => Icons.check_circle_rounded,
        NatureMessage.information => Icons.error_rounded, // point d'exclamation
        NatureMessage.erreur => Icons.cancel_rounded,
      };

  Color get couleur => switch (this) {
        NatureMessage.succes => Appstyle.success,
        NatureMessage.information => Appstyle.warning,
        NatureMessage.erreur => Appstyle.danger,
      };
}

/// Corps de message des dialogues : grande icône colorée puis le texte.
class MessageAvecIcone extends StatelessWidget {
  final NatureMessage nature;
  final String message;
  final TextStyle? style;

  const MessageAvecIcone({
    super.key,
    required this.nature,
    required this.message,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(nature.icone, color: nature.couleur, size: 64),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.start,
              style: style ?? Appstyle.textSB,
            ),
          ),
        ],
      ),
    );
  }
}
