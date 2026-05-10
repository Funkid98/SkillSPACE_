// TODO Implement this library.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Patches Flutter Web's keyboard engine assertion bug.
///
/// On Flutter Web, Alt+Tab (and other OS-level focus switches) cause the
/// browser to synthesize modifier key events that contradict Flutter's
/// internal pressed-key state. Flutter's engine then throws:
///
///   "A KeyDownEvent is dispatched but the physical key is already pressed"
///   "A KeyUpEvent is dispatched but the physical key is not pressed"
///
/// This CANNOT be caught with try/catch — the assertion fires deep inside
/// Flutter's engine (hardware_keyboard.dart:510) before any user code runs.
///
/// Fix: Register a HardwareKeyboard handler before runApp(). If an incoming
/// synthesized event contradicts current key state, consume it silently so
/// Flutter's engine never sees it.
///
/// Usage — call once in main() after WidgetsFlutterBinding.ensureInitialized():
///   KeyboardFix.apply();
class KeyboardFix {
  KeyboardFix._();

  static bool _applied = false;

  static void apply() {
    if (!kIsWeb) return; // Only needed on Flutter Web
    if (_applied) return;
    _applied = true;

    HardwareKeyboard.instance.addHandler(_safeKeyHandler);
    debugPrint(' KeyboardFix applied (Flutter Web keyboard desync patch)');
  }

  static bool _safeKeyHandler(KeyEvent event) {
    final pressedKeys = HardwareKeyboard.instance.physicalKeysPressed;

    // Swallow synthesized KeyDownEvent if key is already marked pressed.
    // This happens when Alt+Tab returns focus and the browser re-fires
    // the modifier key that Flutter thinks is still held.
    if (event is KeyDownEvent &&
        event.synthesized &&
        pressedKeys.contains(event.physicalKey)) {
      debugPrint(
        '⌨️ KeyboardFix: dropped duplicate KeyDown '
        '(${event.physicalKey.debugName})',
      );
      return true; // consumed — engine won't process this event
    }

    // Swallow synthesized KeyUpEvent if key is NOT marked as pressed.
    // Happens when the browser fires a phantom key-up for a key Flutter
    // never registered as down.
    if (event is KeyUpEvent &&
        event.synthesized &&
        !pressedKeys.contains(event.physicalKey)) {
      debugPrint(
        ' KeyboardFix: dropped phantom KeyUp '
        '(${event.physicalKey.debugName})',
      );
      return true; // consumed
    }

    return false; // not consumed — let Flutter handle normally
  }
}
