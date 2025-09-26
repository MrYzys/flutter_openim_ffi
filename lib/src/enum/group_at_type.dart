// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
/// Conversation Strong Hint Content
class GroupAtType {
  /// Cancel all hints, equivalent to calling the resetConversationGroupAtType method
  static const atNormal = 0;

  /// @ me hint
  static const atMe = 1;

  /// @ all hint
  static const atAll = 2;

  /// @ all and @ me hint
  static const atAllAtMe = 3;

  /// Group notification hint
  static const groupNotification = 4;
}
