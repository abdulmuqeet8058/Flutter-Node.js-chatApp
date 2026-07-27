import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const int port = 3000;
  static const String _hostOverride = String.fromEnvironment('BACKEND_HOST');

  static String get baseUrl => 'http://$_host:$port';
  static String get socketUrl => baseUrl;

  static String get _host {
    if (_hostOverride.isNotEmpty) return _hostOverride;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '192.168.100.5';
    return 'localhost';
  }
}
