import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android emulators to reach localhost on the host machine
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
