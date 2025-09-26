import 'package:flutter_openim_ffi/flutter_openim_ffi.dart';

import 'ffi/native_bridge.dart';

class OpenIM {
  static const version = '3.8.3+hotfix.3.1';

  static final _channel = NativeBridge();

  static final iMManager = IMManager(_channel);

  OpenIM._();
}
