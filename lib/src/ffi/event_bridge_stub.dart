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
