// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
/// Group Join Verification Settings
class GroupVerification {
  /// Apply and invite directly for entry
  static const int applyNeedVerificationInviteDirectly = 0;

  /// Everyone needs verification to join, except for group owners and administrators who can invite directly
  static const int allNeedVerification = 1;

  /// Directly join the group
  static const int directly = 2;
}
