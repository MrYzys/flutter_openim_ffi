import 'dart:convert';
import 'dart:developer';

class Logger {
  static void print(Object? msg) {
    // Keep minimal logging; integrate with existing logging if needed.
    // ignore: avoid_print
    if (msg != null) {
      // ignore: avoid_print
      log('flutter_openim_ffi - ${jsonEncode(msg)}');
    }
  }
}
