// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
/// Message Sending Progress Listener
class OnMsgSendProgressListener {
  Function(String clientMsgID, int progress)? onProgress;

  OnMsgSendProgressListener({this.onProgress});

  /// Message sending progress
  void progress(String clientMsgID, int progress) {
    onProgress?.call(clientMsgID, progress);
  }
}
