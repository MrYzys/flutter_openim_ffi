// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
class OnCustomBusinessListener {
  Function(String s)? onRecvCustomBusinessMessage;

  OnCustomBusinessListener({this.onRecvCustomBusinessMessage});

  void recvCustomBusinessMessage(String s) {
    onRecvCustomBusinessMessage?.call(s);
  }
}
