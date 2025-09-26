// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
import 'package:flutter_openim_ffi/flutter_openim_ffi.dart';

import 'ffi/native_bridge.dart';

class OpenIM {
  static const version = '3.8.3+hotfix.3.1';

  static final _channel = NativeBridge();

  static final iMManager = IMManager(_channel);

  OpenIM._();
}
