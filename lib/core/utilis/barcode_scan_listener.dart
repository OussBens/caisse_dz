import 'package:flutter/services.dart';

/// Détecte les scans d'un lecteur code-barres/QR code branché en USB (mode
/// "keyboard wedge") : le lecteur tape tous les caractères du code puis
/// Entrée, beaucoup plus vite qu'une saisie humaine. On accumule les
/// caractères frappés et on ne déclenche [onScan] que si la rafale précédant
/// Entrée était assez rapide et assez longue pour être un scan, ce qui évite
/// de réagir à une saisie clavier normale dans n'importe quel champ.
///
/// Écoute au niveau global (HardwareKeyboard), donc fonctionne quel que soit
/// le widget qui a le focus au moment du scan.
class BarcodeScanListener {
  BarcodeScanListener({
    required this.onScan,
    this.maxIntervalMs = 60,
    this.minLength = 3,
  });

  final void Function(String code) onScan;
  final int maxIntervalMs;
  final int minLength;

  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastCharTime;

  // Chiffres 0-9 mappés depuis la touche physique (logicalKey), indépendamment
  // de la disposition clavier active. Un lecteur code-barres USB envoie des
  // frappes "brutes" pensées pour un clavier QWERTY ; sur un poste configuré
  // en AZERTY (standard en France/Algérie), `event.character` pour ces mêmes
  // touches renvoie des symboles (&é"'(-è_çà)=) au lieu de chiffres, ce qui
  // corromprait tout code-barres scanné (essentiellement numérique : EAN-8,
  // EAN-13, UPC-A, Code128 numérique). On force donc les chiffres via
  // logicalKey et on ne retombe sur `event.character` que pour le reste
  // (lettres de codes alphanumériques plus rares).
  static final Map<LogicalKeyboardKey, String> _digitKeys = {
    LogicalKeyboardKey.digit0: '0',
    LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.digit2: '2',
    LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.digit4: '4',
    LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.digit6: '6',
    LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.digit8: '8',
    LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
  };

  void start() {
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  void stop() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _buffer.toString();
      _resetBuffer();
      if (code.length >= minLength) {
        onScan(code);
      }
      return false;
    }

    final char = _digitKeys[event.logicalKey] ?? event.character;
    if (char == null || char.isEmpty) return false;

    final now = DateTime.now();
    if (_lastCharTime != null &&
        now.difference(_lastCharTime!).inMilliseconds > maxIntervalMs) {
      _resetBuffer();
    }
    _lastCharTime = now;
    _buffer.write(char);
    return false;
  }

  void _resetBuffer() {
    _buffer.clear();
    _lastCharTime = null;
  }
}
