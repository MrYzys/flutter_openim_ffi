// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
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
