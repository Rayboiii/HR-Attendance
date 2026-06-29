class AppConfig {
  /// Base URL of the backend API.
  ///
  /// USB device via `adb reverse tcp:5294 tcp:5294` — the phone's localhost is
  /// tunneled to the PC, so this address is stable across networks. Re-run the
  /// adb reverse command after each replug/reboot.
  ///   adb reverse tcp:5294 tcp:5294
  /// Alternatives: Android emulator → 'http://10.0.2.2:5294/api';
  /// Wi-Fi/hotspot (no USB) → the PC's current LAN IP.
  static const String apiBaseUrl = 'http://127.0.0.1:5294/api';
}
