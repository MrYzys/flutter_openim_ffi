// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
import 'dart:async';

import '../logger.dart';

class NativeMethodCall {
  NativeMethodCall(this.method, this.arguments);

  final String method;
  final dynamic arguments;
}

typedef NativeMethodCallHandler =
    FutureOr<void> Function(NativeMethodCall call);

class NativeInvocation {
  NativeInvocation.completed(this.result)
    : operationID = null,
      isCompleted = true;

  NativeInvocation.pending(this.operationID)
    : result = null,
      isCompleted = false;

  final bool isCompleted;
  final Object? result;
  final String? operationID;
}

class NativeBridge {
  NativeBridge();

  // ignore: unused_field
  NativeMethodCallHandler? _handler;

  void setMethodCallHandler(NativeMethodCallHandler handler) {
    _handler = handler;
    Logger.print(
      'NativeBridge stub active: native callbacks are disabled on this platform.',
    );
  }

  Future<T?> invokeMethod<T>(String method, Map<String, dynamic> arguments) {
    final error = UnsupportedError(
      'flutter_openim_ffi: FFI-backed APIs are unavailable on the current platform.',
    );
    Logger.print('NativeBridge stub invoked "$method" with $arguments: $error');
    return Future.error(error);
  }
}

class OpenIMNativeException implements Exception {
  OpenIMNativeException(this.code, this.message);

  final int code;
  final String? message;

  @override
  String toString() => 'OpenIMNativeException(code: $code, message: $message)';
}
