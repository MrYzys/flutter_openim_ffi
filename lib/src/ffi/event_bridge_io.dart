// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:isolate';

import '../logger.dart';
import 'bindings.dart';

typedef EventHandler = FutureOr<void> Function(Map<String, dynamic> event);

class EventBridge {
  EventBridge._();

  static final EventBridge instance = EventBridge._();

  ReceivePort? _port;
  StreamSubscription? _sub;
  EventHandler? _handler;

  bool get isInitialized => _port != null;

  void setHandler(EventHandler handler) {
    _handler = handler;
  }

  /// Initialize Dart DL API and start listening for native events.
  void ensureInitialized() {
    if (_port != null) return;
    _port = ReceivePort();

    // Initialize Dart API DL
    final initData = NativeApi.initializeApiDLData;
    final result = OpenIMFFI.instance.dartInitializeApiDL(initData);
    if (result != 0) {
      throw StateError('Dart_InitializeApiDL failed: $result');
    }

    _sub = _port!.listen((message) {
      try {
        if (message is String) {
          final map = jsonDecode(message) as Map<String, dynamic>;
          _handler?.call(map);
        } else {
          Logger.print('Unknown native event: $message');
        }
      } catch (e) {
        Logger.print('Event parse error: $e');
      }
    });
  }

  int get nativePort => _port?.sendPort.nativePort ?? 0;

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _port?.close();
    _port = null;
  }
}
