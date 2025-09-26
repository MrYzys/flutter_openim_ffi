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
