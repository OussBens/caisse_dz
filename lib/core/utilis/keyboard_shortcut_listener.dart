import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Un raccourci clavier associant soit une touche logique (F4, Suppr, ...)
/// soit un caractère imprimable (+, -, n, c, ...) à une action, avec ou sans
/// Ctrl. Par défaut, les raccourcis "simples" (une lettre ou +/-) sont
/// ignorés quand un champ de texte a le focus, pour ne pas gêner la saisie ;
/// mets [ignoreWhenTextFieldFocused] à false pour les raccourcis qui doivent
/// rester actifs partout (touches F, combinaisons Ctrl).
class KeyboardShortcut {
  const KeyboardShortcut({
    required this.onTrigger,
    this.key,
    this.character,
    this.control = false,
    this.ignoreWhenTextFieldFocused = true,
  }) : assert(key != null || character != null,
            'Un KeyboardShortcut doit définir key ou character');

  final LogicalKeyboardKey? key;
  final String? character;
  final bool control;
  final bool ignoreWhenTextFieldFocused;
  final VoidCallback onTrigger;

  bool _matches(KeyDownEvent event) {
    if (control != HardwareKeyboard.instance.isControlPressed) return false;
    if (key != null) return event.logicalKey == key;
    return event.character?.toLowerCase() == character;
  }
}

/// Écoute globale de raccourcis clavier pour les écrans dont les actions
/// sont déjà exposées par des boutons (ex: caisse). Fonctionne quel que soit
/// le widget qui a le focus au moment de l'appui.
class KeyboardShortcutListener {
  KeyboardShortcutListener(this.shortcuts);

  final List<KeyboardShortcut> shortcuts;

  void start() {
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  void stop() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
  }

  bool _isTextFieldFocused() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null && ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final textFieldFocused = _isTextFieldFocused();

    for (final shortcut in shortcuts) {
      if (shortcut.ignoreWhenTextFieldFocused && textFieldFocused) continue;
      if (shortcut._matches(event)) {
        shortcut.onTrigger();
        return true;
      }
    }
    return false;
  }
}
