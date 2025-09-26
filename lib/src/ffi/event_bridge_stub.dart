// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
import 'dart:async';

typedef EventHandler = FutureOr<void> Function(Map<String, dynamic> event);

class EventBridge {
  EventBridge._();

  static final EventBridge instance = EventBridge._();

  EventHandler? _handler;

  bool get isInitialized => true;

  void setHandler(EventHandler handler) {
    _handler = handler;
  }

  void ensureInitialized() {}

  int get nativePort => 0;

  void dispose() {
    _handler = null;
  }
}
