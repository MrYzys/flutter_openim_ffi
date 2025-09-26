// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
class OpenIMFFI {
  OpenIMFFI._();

  static final OpenIMFFI instance = OpenIMFFI._();

  Never _unsupported() =>
      throw UnsupportedError(
        'flutter_openim_ffi: Native FFI bindings are not available on this platform.',
      );

  int dartInitializeApiDL(Object? data) => _unsupported();

  @override
  dynamic noSuchMethod(Invocation invocation) => _unsupported();
}
