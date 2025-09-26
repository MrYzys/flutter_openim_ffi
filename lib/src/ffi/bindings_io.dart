// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart' as ffi;
import 'package:ffi/ffi.dart';

import '../../openim_ffi_bindings_generated.dart';

typedef _DartInitializeApiDLNative =
    ffi.IntPtr Function(ffi.Pointer<ffi.Void> data);
typedef _DartInitializeApiDLDart = int Function(ffi.Pointer<ffi.Void> data);

/// Thin, typed wrapper around the generated bindings.
class OpenIMFFI {
  OpenIMFFI._(this._lib)
    : _bindings = OpenimFfiBindings(_lib),
      _dartInitApi = _lib
          .lookupFunction<_DartInitializeApiDLNative, _DartInitializeApiDLDart>(
            'Dart_InitializeApiDL',
          );

  final ffi.DynamicLibrary _lib;
  final OpenimFfiBindings _bindings;
  final _DartInitializeApiDLDart _dartInitApi;

  static ffi.DynamicLibrary _open() {
    if (Platform.isIOS) {
      // On iOS, symbols are linked into the app process.
      return ffi.DynamicLibrary.process();
    }
    if (Platform.isMacOS) {
      final candidates = <String>[
        'flutter_openim_ffi.framework/flutter_openim_ffi',
        'libflutter_openim_ffi.dylib',
        'libopenim_sdk_ffi.dylib',
      ];
      return _openFirstAvailable(candidates);
    }
    if (Platform.isAndroid || Platform.isLinux) {
      final candidates = <String>[
        'libflutter_openim_ffi.so',
        'libopenim_sdk_ffi.so',
      ];
      return _openFirstAvailable(candidates);
    }
    if (Platform.isWindows) {
      final candidates = <String>[
        'flutter_openim_ffi.dll',
        'openim_sdk_ffi.dll',
      ];
      return _openFirstAvailable(candidates);
    }
    throw UnsupportedError('Unsupported platform for FFI');
  }

  static ffi.DynamicLibrary _openFirstAvailable(List<String> candidates) {
    Object? lastError;
    for (final path in candidates) {
      try {
        return ffi.DynamicLibrary.open(path);
      } catch (err) {
        lastError = err;
      }
    }
    throw StateError(
      'Unable to load OpenIM native library. Tried: $candidates, last error: $lastError',
    );
  }

  static final OpenIMFFI instance = OpenIMFFI._(_open());

  Openim_Listener getIMListener() => _bindings.getIMListener();

  int dartInitializeApiDL(ffi.Pointer<ffi.Void> data) => _dartInitApi(data);

  bool initSDK(
    Openim_Listener listener,
    int port,
    String operationID,
    String configJson,
  ) {
    return _withCString(operationID, (op) {
      return _withCString(configJson, (cfg) {
        return _bindings.InitSDK(listener, port, op, cfg);
      });
    });
  }

  void login(String operationID, String userID, String token) {
    _withCString(operationID, (op) {
      _withCString(userID, (uid) {
        _withCString(token, (tok) {
          _bindings.Login(op, uid, tok);
        });
      });
    });
  }

  void logout(String operationID) {
    _withCString(operationID, (op) {
      _bindings.Logout(op);
    });
  }

  int getLoginStatus(String operationID) {
    return _withCString(operationID, (op) {
      return _bindings.GetLoginStatus(op);
    });
  }

  String getLoginUserID() {
    final ptr = _bindings.GetLoginUserID();
    return _consumeCString(ptr);
  }

  T _withCString<T>(String value, T Function(ffi.Pointer<ffi.Char>) fn) {
    final ptr = value.toNativeUtf8().cast<ffi.Char>();
    try {
      return fn(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  T _withCStrings<T>(
    List<String?> values,
    T Function(List<ffi.Pointer<ffi.Char>>) action,
  ) {
    if (values.isEmpty) {
      return action(const <ffi.Pointer<ffi.Char>>[]);
    }
    final ptrs = <ffi.Pointer<ffi.Char>>[];
    final allocations = <ffi.Pointer<ffi.Utf8>>[];
    for (final value in values) {
      if (value == null) {
        ptrs.add(ffi.Pointer<ffi.Char>.fromAddress(0));
        continue;
      }
      final utf8 = value.toNativeUtf8();
      allocations.add(utf8);
      ptrs.add(utf8.cast<ffi.Char>());
    }
    try {
      return action(ptrs);
    } finally {
      for (final utf8 in allocations) {
        calloc.free(utf8);
      }
    }
  }

  String _consumeCString(ffi.Pointer<ffi.Char> ptr) {
    if (ptr == ffi.nullptr) {
      return '';
    }
    final str = ptr.cast<Utf8>().toDartString();
    // The native SDK owns the returned buffer; we rely on it to manage
    // the lifetime. If a free callback is exposed in the future, wire it here.
    return str;
  }

  void acceptFriendApplication(String? operationID, String? userIDHandleMsg) {
    _withCStrings([operationID, userIDHandleMsg], (ptrs) {
      _bindings.AcceptFriendApplication(ptrs[0], ptrs[1]);
    });
  }

  void acceptGroupApplication(
    String? operationID,
    String? groupID,
    String? fromUserID,
    String? handleMsg,
  ) {
    _withCStrings([operationID, groupID, fromUserID, handleMsg], (ptrs) {
      _bindings.AcceptGroupApplication(ptrs[0], ptrs[1], ptrs[2], ptrs[3]);
    });
  }

  void addBlack(String? operationID, String? blackUserID, String? ex) {
    _withCStrings([operationID, blackUserID, ex], (ptrs) {
      _bindings.AddBlack(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void addFriend(String? operationID, String? userIDReqMsg) {
    _withCStrings([operationID, userIDReqMsg], (ptrs) {
      _bindings.AddFriend(ptrs[0], ptrs[1]);
    });
  }

  void changeGroupMemberMute(
    String? operationID,
    String? groupID,
    String? userID,
    int mutedSeconds,
  ) {
    _withCStrings([operationID, groupID, userID], (ptrs) {
      _bindings.ChangeGroupMemberMute(ptrs[0], ptrs[1], ptrs[2], mutedSeconds);
    });
  }

  void changeGroupMute(String? operationID, String? groupID, bool isMute) {
    _withCStrings([operationID, groupID], (ptrs) {
      _bindings.ChangeGroupMute(ptrs[0], ptrs[1], isMute);
    });
  }

  void changeInputStates(
    String? operationID,
    String? conversationID,
    bool focus,
  ) {
    _withCStrings([operationID, conversationID], (ptrs) {
      _bindings.ChangeInputStates(ptrs[0], ptrs[1], focus);
    });
  }

  void checkFriend(String? operationID, String? userIDList) {
    _withCStrings([operationID, userIDList], (ptrs) {
      _bindings.CheckFriend(ptrs[0], ptrs[1]);
    });
  }

  void clearConversationAndDeleteAllMsg(
    String? operationID,
    String? conversationID,
  ) {
    _withCStrings([operationID, conversationID], (ptrs) {
      _bindings.ClearConversationAndDeleteAllMsg(ptrs[0], ptrs[1]);
    });
  }

  String createAdvancedQuoteMessage(
    String? operationID,
    String? text,
    String? message,
    String? messageEntityList,
  ) => _withCStrings([operationID, text, message, messageEntityList], (ptrs) {
    final result = _bindings.CreateAdvancedQuoteMessage(
      ptrs[0],
      ptrs[1],
      ptrs[2],
      ptrs[3],
    );
    return _consumeCString(result);
  });

  String createAdvancedTextMessage(
    String? operationID,
    String? text,
    String? messageEntityList,
  ) => _withCStrings([operationID, text, messageEntityList], (ptrs) {
    final result = _bindings.CreateAdvancedTextMessage(
      ptrs[0],
      ptrs[1],
      ptrs[2],
    );
    return _consumeCString(result);
  });

  String createCardMessage(String? operationID, String? cardInfo) =>
      _withCStrings([operationID, cardInfo], (ptrs) {
        final result = _bindings.CreateCardMessage(ptrs[0], ptrs[1]);
        return _consumeCString(result);
      });

  String createCustomMessage(
    String? operationID,
    String? data,
    String? extension1,
    String? description,
  ) => _withCStrings([operationID, data, extension1, description], (ptrs) {
    final result = _bindings.CreateCustomMessage(
      ptrs[0],
      ptrs[1],
      ptrs[2],
      ptrs[3],
    );
    return _consumeCString(result);
  });

  String createFaceMessage(String? operationID, int index, String? data) =>
      _withCStrings([operationID, data], (ptrs) {
        final result = _bindings.CreateFaceMessage(ptrs[0], index, ptrs[1]);
        return _consumeCString(result);
      });

  String createFileMessage(
    String? operationID,
    String? filePath,
    String? fileName,
  ) => _withCStrings([operationID, filePath, fileName], (ptrs) {
    final result = _bindings.CreateFileMessage(ptrs[0], ptrs[1], ptrs[2]);
    return _consumeCString(result);
  });

  String createFileMessageByURL(String? operationID, String? fileBaseInfo) =>
      _withCStrings([operationID, fileBaseInfo], (ptrs) {
        final result = _bindings.CreateFileMessageByURL(ptrs[0], ptrs[1]);
        return _consumeCString(result);
      });

  String createFileMessageFromFullPath(
    String? operationID,
    String? fileFullPath,
    String? fileName,
  ) => _withCStrings([operationID, fileFullPath, fileName], (ptrs) {
    final result = _bindings.CreateFileMessageFromFullPath(
      ptrs[0],
      ptrs[1],
      ptrs[2],
    );
    return _consumeCString(result);
  });

  String createForwardMessage(String? operationID, String? m) =>
      _withCStrings([operationID, m], (ptrs) {
        final result = _bindings.CreateForwardMessage(ptrs[0], ptrs[1]);
        return _consumeCString(result);
      });

  void createGroup(String? operationID, String? groupReqInfo) {
    _withCStrings([operationID, groupReqInfo], (ptrs) {
      _bindings.CreateGroup(ptrs[0], ptrs[1]);
    });
  }

  String createImageMessage(String? operationID, String? imagePath) =>
      _withCStrings([operationID, imagePath], (ptrs) {
        final result = _bindings.CreateImageMessage(ptrs[0], ptrs[1]);
        return _consumeCString(result);
      });

  String createImageMessageByURL(
    String? operationID,
    String? sourcePath,
    String? sourcePicture,
    String? bigPicture,
    String? snapshotPicture,
  ) => _withCStrings(
    [operationID, sourcePath, sourcePicture, bigPicture, snapshotPicture],
    (ptrs) {
      final result = _bindings.CreateImageMessageByURL(
        ptrs[0],
        ptrs[1],
        ptrs[2],
        ptrs[3],
        ptrs[4],
      );
      return _consumeCString(result);
    },
  );

  String createImageMessageFromFullPath(
    String? operationID,
    String? imageFullPath,
  ) => _withCStrings([operationID, imageFullPath], (ptrs) {
    final result = _bindings.CreateImageMessageFromFullPath(ptrs[0], ptrs[1]);
    return _consumeCString(result);
  });

  String createLocationMessage(
    String? operationID,
    String? description,
    double longitude,
    double latitude,
  ) => _withCStrings([operationID, description], (ptrs) {
    final result = _bindings.CreateLocationMessage(
      ptrs[0],
      ptrs[1],
      longitude,
      latitude,
    );
    return _consumeCString(result);
  });

  String createMergerMessage(
    String? operationID,
    String? messageList,
    String? title,
    String? summaryList,
  ) => _withCStrings([operationID, messageList, title, summaryList], (ptrs) {
    final result = _bindings.CreateMergerMessage(
      ptrs[0],
      ptrs[1],
      ptrs[2],
      ptrs[3],
    );
    return _consumeCString(result);
  });

  String createQuoteMessage(
    String? operationID,
    String? text,
    String? message,
  ) => _withCStrings([operationID, text, message], (ptrs) {
    final result = _bindings.CreateQuoteMessage(ptrs[0], ptrs[1], ptrs[2]);
    return _consumeCString(result);
  });

  String createSoundMessage(
    String? operationID,
    String? soundPath,
    int duration,
  ) => _withCStrings([operationID, soundPath], (ptrs) {
    final result = _bindings.CreateSoundMessage(ptrs[0], ptrs[1], duration);
    return _consumeCString(result);
  });

  String createSoundMessageByURL(String? operationID, String? soundBaseInfo) =>
      _withCStrings([operationID, soundBaseInfo], (ptrs) {
        final result = _bindings.CreateSoundMessageByURL(ptrs[0], ptrs[1]);
        return _consumeCString(result);
      });

  String createSoundMessageFromFullPath(
    String? operationID,
    String? soundFullPath,
    int duration,
  ) => _withCStrings([operationID, soundFullPath], (ptrs) {
    final result = _bindings.CreateSoundMessageFromFullPath(
      ptrs[0],
      ptrs[1],
      duration,
    );
    return _consumeCString(result);
  });

  String createTextAtMessage(
    String? operationID,
    String? text,
    String? atUserList,
    String? atUsersInfo,
    String? message,
  ) => _withCStrings([operationID, text, atUserList, atUsersInfo, message], (
    ptrs,
  ) {
    final result = _bindings.CreateTextAtMessage(
      ptrs[0],
      ptrs[1],
      ptrs[2],
      ptrs[3],
      ptrs[4],
    );
    return _consumeCString(result);
  });

  String createTextMessage(String? operationID, String? text) =>
      _withCStrings([operationID, text], (ptrs) {
        final result = _bindings.CreateTextMessage(ptrs[0], ptrs[1]);
        return _consumeCString(result);
      });

  String createVideoMessage(
    String? operationID,
    String? videoPath,
    String? videoType,
    int duration,
    String? snapshotPath,
  ) => _withCStrings([operationID, videoPath, videoType, snapshotPath], (ptrs) {
    final result = _bindings.CreateVideoMessage(
      ptrs[0],
      ptrs[1],
      ptrs[2],
      duration,
      ptrs[3],
    );
    return _consumeCString(result);
  });

  String createVideoMessageByURL(String? operationID, String? videoBaseInfo) =>
      _withCStrings([operationID, videoBaseInfo], (ptrs) {
        final result = _bindings.CreateVideoMessageByURL(ptrs[0], ptrs[1]);
        return _consumeCString(result);
      });

  String createVideoMessageFromFullPath(
    String? operationID,
    String? videoFullPath,
    String? videoType,
    int duration,
    String? snapshotFullPath,
  ) => _withCStrings(
    [operationID, videoFullPath, videoType, snapshotFullPath],
    (ptrs) {
      final result = _bindings.CreateVideoMessageFromFullPath(
        ptrs[0],
        ptrs[1],
        ptrs[2],
        duration,
        ptrs[3],
      );
      return _consumeCString(result);
    },
  );

  void deleteAllMsgFromLocal(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.DeleteAllMsgFromLocal(ptrs[0]);
    });
  }

  void deleteAllMsgFromLocalAndSvr(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.DeleteAllMsgFromLocalAndSvr(ptrs[0]);
    });
  }

  void deleteConversationAndDeleteAllMsg(
    String? operationID,
    String? conversationID,
  ) {
    _withCStrings([operationID, conversationID], (ptrs) {
      _bindings.DeleteConversationAndDeleteAllMsg(ptrs[0], ptrs[1]);
    });
  }

  void deleteFriend(String? operationID, String? friendUserID) {
    _withCStrings([operationID, friendUserID], (ptrs) {
      _bindings.DeleteFriend(ptrs[0], ptrs[1]);
    });
  }

  void deleteMessage(
    String? operationID,
    String? conversationID,
    String? clientMsgID,
  ) {
    _withCStrings([operationID, conversationID, clientMsgID], (ptrs) {
      _bindings.DeleteMessage(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void deleteMessageFromLocalStorage(
    String? operationID,
    String? conversationID,
    String? clientMsgID,
  ) {
    _withCStrings([operationID, conversationID, clientMsgID], (ptrs) {
      _bindings.DeleteMessageFromLocalStorage(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void dismissGroup(String? operationID, String? groupID) {
    _withCStrings([operationID, groupID], (ptrs) {
      _bindings.DismissGroup(ptrs[0], ptrs[1]);
    });
  }

  void findMessageList(String? operationID, String? findMessageOptions) {
    _withCStrings([operationID, findMessageOptions], (ptrs) {
      _bindings.FindMessageList(ptrs[0], ptrs[1]);
    });
  }

  void getAdvancedHistoryMessageList(
    String? operationID,
    String? getMessageOptions,
  ) {
    _withCStrings([operationID, getMessageOptions], (ptrs) {
      _bindings.GetAdvancedHistoryMessageList(ptrs[0], ptrs[1]);
    });
  }

  void getAdvancedHistoryMessageListReverse(
    String? operationID,
    String? getMessageOptions,
  ) {
    _withCStrings([operationID, getMessageOptions], (ptrs) {
      _bindings.GetAdvancedHistoryMessageListReverse(ptrs[0], ptrs[1]);
    });
  }

  void getAllConversationList(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetAllConversationList(ptrs[0]);
    });
  }

  String getAtAllTag(String? operationID) =>
      _withCStrings([operationID], (ptrs) {
        final result = _bindings.GetAtAllTag(ptrs[0]);
        return _consumeCString(result);
      });

  void getBlackList(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetBlackList(ptrs[0]);
    });
  }

  String getConversationIDBySessionType(
    String? operationID,
    String? sourceID,
    int sessionType,
  ) => _withCStrings([operationID, sourceID], (ptrs) {
    final result = _bindings.GetConversationIDBySessionType(
      ptrs[0],
      ptrs[1],
      sessionType,
    );
    return _consumeCString(result);
  });

  void getConversationListSplit(String? operationID, int offset, int count) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetConversationListSplit(ptrs[0], offset, count);
    });
  }

  void getFriendApplicationListAsApplicant(String? operationID, String? req) {
    _withCStrings([operationID, req], (ptrs) {
      _bindings.GetFriendApplicationListAsApplicant(ptrs[0], ptrs[1]);
    });
  }

  void getFriendApplicationListAsRecipient(String? operationID, String? req) {
    _withCStrings([operationID, req], (ptrs) {
      _bindings.GetFriendApplicationListAsRecipient(ptrs[0], ptrs[1]);
    });
  }

  void getFriendList(String? operationID, bool filterBlack) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetFriendList(ptrs[0], filterBlack);
    });
  }

  void getFriendListPage(
    String? operationID,
    int offset,
    int count,
    bool filterBlack,
  ) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetFriendListPage(ptrs[0], offset, count, filterBlack);
    });
  }

  void getGroupApplicationListAsApplicant(String? operationID, String? req) {
    _withCStrings([operationID, req], (ptrs) {
      _bindings.GetGroupApplicationListAsApplicant(ptrs[0], ptrs[1]);
    });
  }

  void getGroupApplicationListAsRecipient(String? operationID, String? req) {
    _withCStrings([operationID, req], (ptrs) {
      _bindings.GetGroupApplicationListAsRecipient(ptrs[0], ptrs[1]);
    });
  }

  void getGroupMemberList(
    String? operationID,
    String? groupID,
    int filter,
    int offset,
    int count,
  ) {
    _withCStrings([operationID, groupID], (ptrs) {
      _bindings.GetGroupMemberList(ptrs[0], ptrs[1], filter, offset, count);
    });
  }

  void getGroupMemberListByJoinTimeFilter(
    String? operationID,
    String? groupID,
    int offset,
    int count,
    int joinTimeBegin,
    int joinTimeEnd,
    String? filterUserIDList,
  ) {
    _withCStrings([operationID, groupID, filterUserIDList], (ptrs) {
      _bindings.GetGroupMemberListByJoinTimeFilter(
        ptrs[0],
        ptrs[1],
        offset,
        count,
        joinTimeBegin,
        joinTimeEnd,
        ptrs[2],
      );
    });
  }

  void getGroupMemberOwnerAndAdmin(String? operationID, String? groupID) {
    _withCStrings([operationID, groupID], (ptrs) {
      _bindings.GetGroupMemberOwnerAndAdmin(ptrs[0], ptrs[1]);
    });
  }

  void getInputStates(
    String? operationID,
    String? conversationID,
    String? userID,
  ) {
    _withCStrings([operationID, conversationID, userID], (ptrs) {
      _bindings.GetInputStates(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void getJoinedGroupList(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetJoinedGroupList(ptrs[0]);
    });
  }

  void getJoinedGroupListPage(String? operationID, int offset, int count) {
    _withCStrings([operationID], (ptrs) {
      _bindings.getJoinedGroupListPage(ptrs[0], offset, count);
    });
  }

  void getMultipleConversation(
    String? operationID,
    String? conversationIDList,
  ) {
    _withCStrings([operationID, conversationIDList], (ptrs) {
      _bindings.GetMultipleConversation(ptrs[0], ptrs[1]);
    });
  }

  void getOneConversation(
    String? operationID,
    int sessionType,
    String? sourceID,
  ) {
    _withCStrings([operationID, sourceID], (ptrs) {
      _bindings.GetOneConversation(ptrs[0], sessionType, ptrs[1]);
    });
  }

  void getSelfUserInfo(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetSelfUserInfo(ptrs[0]);
    });
  }

  void getSpecifiedFriendsInfo(
    String? operationID,
    String? userIDList,
    bool filterBlack,
  ) {
    _withCStrings([operationID, userIDList], (ptrs) {
      _bindings.GetSpecifiedFriendsInfo(ptrs[0], ptrs[1], filterBlack);
    });
  }

  void getSpecifiedGroupMembersInfo(
    String? operationID,
    String? groupID,
    String? userIDList,
  ) {
    _withCStrings([operationID, groupID, userIDList], (ptrs) {
      _bindings.GetSpecifiedGroupMembersInfo(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void getSpecifiedGroupsInfo(String? operationID, String? groupIDList) {
    _withCStrings([operationID, groupIDList], (ptrs) {
      _bindings.GetSpecifiedGroupsInfo(ptrs[0], ptrs[1]);
    });
  }

  void getSubscribeUsersStatus(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetSubscribeUsersStatus(ptrs[0]);
    });
  }

  void getTotalUnreadMsgCount(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.GetTotalUnreadMsgCount(ptrs[0]);
    });
  }

  void getUsersInGroup(
    String? operationID,
    String? groupID,
    String? userIDList,
  ) {
    _withCStrings([operationID, groupID, userIDList], (ptrs) {
      _bindings.GetUsersInGroup(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void getUsersInfo(String? operationID, String? userIDList) {
    _withCStrings([operationID, userIDList], (ptrs) {
      _bindings.GetUsersInfo(ptrs[0], ptrs[1]);
    });
  }

  void hideAllConversations(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.HideAllConversations(ptrs[0]);
    });
  }

  void hideConversation(String? operationID, String? conversationID) {
    _withCStrings([operationID, conversationID], (ptrs) {
      _bindings.HideConversation(ptrs[0], ptrs[1]);
    });
  }

  void insertGroupMessageToLocalStorage(
    String? operationID,
    String? message,
    String? groupID,
    String? sendID,
  ) {
    _withCStrings([operationID, message, groupID, sendID], (ptrs) {
      _bindings.InsertGroupMessageToLocalStorage(
        ptrs[0],
        ptrs[1],
        ptrs[2],
        ptrs[3],
      );
    });
  }

  void insertSingleMessageToLocalStorage(
    String? operationID,
    String? message,
    String? recvID,
    String? sendID,
  ) {
    _withCStrings([operationID, message, recvID, sendID], (ptrs) {
      _bindings.InsertSingleMessageToLocalStorage(
        ptrs[0],
        ptrs[1],
        ptrs[2],
        ptrs[3],
      );
    });
  }

  void inviteUserToGroup(
    String? operationID,
    String? groupID,
    String? reason,
    String? userIDList,
  ) {
    _withCStrings([operationID, groupID, reason, userIDList], (ptrs) {
      _bindings.InviteUserToGroup(ptrs[0], ptrs[1], ptrs[2], ptrs[3]);
    });
  }

  void isJoinGroup(String? operationID, String? groupID) {
    _withCStrings([operationID, groupID], (ptrs) {
      _bindings.IsJoinGroup(ptrs[0], ptrs[1]);
    });
  }

  void joinGroup(
    String? operationID,
    String? groupID,
    String? reqMsg,
    int joinSource,
    String? ex,
  ) {
    _withCStrings([operationID, groupID, reqMsg, ex], (ptrs) {
      _bindings.JoinGroup(ptrs[0], ptrs[1], ptrs[2], joinSource, ptrs[3]);
    });
  }

  void kickGroupMember(
    String? operationID,
    String? groupID,
    String? reason,
    String? userIDList,
  ) {
    _withCStrings([operationID, groupID, reason, userIDList], (ptrs) {
      _bindings.KickGroupMember(ptrs[0], ptrs[1], ptrs[2], ptrs[3]);
    });
  }

  void logs(
    String? operationID,
    int logLevel,
    String? file,
    int line,
    String? msgs,
    String? err,
    String? keyAndValue,
  ) {
    _withCStrings([operationID, file, msgs, err, keyAndValue], (ptrs) {
      _bindings.Logs(
        ptrs[0],
        logLevel,
        ptrs[1],
        line,
        ptrs[2],
        ptrs[3],
        ptrs[4],
      );
    });
  }

  void markConversationMessageAsRead(
    String? operationID,
    String? conversationID,
  ) {
    _withCStrings([operationID, conversationID], (ptrs) {
      _bindings.MarkConversationMessageAsRead(ptrs[0], ptrs[1]);
    });
  }

  void markMessagesAsReadByMsgID(
    String? operationID,
    String? conversationID,
    String? clientMsgIDs,
  ) {
    _withCStrings([operationID, conversationID, clientMsgIDs], (ptrs) {
      _bindings.MarkMessagesAsReadByMsgID(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void networkStatusChanged(String? operationID) {
    _withCStrings([operationID], (ptrs) {
      _bindings.NetworkStatusChanged(ptrs[0]);
    });
  }

  void quitGroup(String? operationID, String? groupID) {
    _withCStrings([operationID, groupID], (ptrs) {
      _bindings.QuitGroup(ptrs[0], ptrs[1]);
    });
  }

  void refuseFriendApplication(String? operationID, String? userIDHandleMsg) {
    _withCStrings([operationID, userIDHandleMsg], (ptrs) {
      _bindings.RefuseFriendApplication(ptrs[0], ptrs[1]);
    });
  }

  void refuseGroupApplication(
    String? operationID,
    String? groupID,
    String? fromUserID,
    String? handleMsg,
  ) {
    _withCStrings([operationID, groupID, fromUserID, handleMsg], (ptrs) {
      _bindings.RefuseGroupApplication(ptrs[0], ptrs[1], ptrs[2], ptrs[3]);
    });
  }

  void removeBlack(String? operationID, String? removeUserID) {
    _withCStrings([operationID, removeUserID], (ptrs) {
      _bindings.RemoveBlack(ptrs[0], ptrs[1]);
    });
  }

  void revokeMessage(
    String? operationID,
    String? conversationID,
    String? clientMsgID,
  ) {
    _withCStrings([operationID, conversationID, clientMsgID], (ptrs) {
      _bindings.RevokeMessage(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void searchConversation(String? operationID, String? searchParam) {
    _withCStrings([operationID, searchParam], (ptrs) {
      _bindings.SearchConversation(ptrs[0], ptrs[1]);
    });
  }

  void searchFriends(String? operationID, String? searchParam) {
    _withCStrings([operationID, searchParam], (ptrs) {
      _bindings.SearchFriends(ptrs[0], ptrs[1]);
    });
  }

  void searchGroupMembers(String? operationID, String? searchParam) {
    _withCStrings([operationID, searchParam], (ptrs) {
      _bindings.SearchGroupMembers(ptrs[0], ptrs[1]);
    });
  }

  void searchGroups(String? operationID, String? searchParam) {
    _withCStrings([operationID, searchParam], (ptrs) {
      _bindings.SearchGroups(ptrs[0], ptrs[1]);
    });
  }

  void searchLocalMessages(String? operationID, String? searchParam) {
    _withCStrings([operationID, searchParam], (ptrs) {
      _bindings.SearchLocalMessages(ptrs[0], ptrs[1]);
    });
  }

  void sendMessage(
    String? operationID,
    String? message,
    String? recvID,
    String? groupID,
    String? offlinePushInfo,
  ) {
    _withCStrings([operationID, message, recvID, groupID, offlinePushInfo], (
      ptrs,
    ) {
      _bindings.SendMessage(ptrs[0], ptrs[1], ptrs[2], ptrs[3], ptrs[4]);
    });
  }

  void sendMessageNotOss(
    String? operationID,
    String? message,
    String? recvID,
    String? groupID,
    String? offlinePushInfo,
  ) {
    _withCStrings([operationID, message, recvID, groupID, offlinePushInfo], (
      ptrs,
    ) {
      _bindings.SendMessageNotOss(ptrs[0], ptrs[1], ptrs[2], ptrs[3], ptrs[4]);
    });
  }

  void setAppBackgroundStatus(String? operationID, bool isBackground) {
    _withCStrings([operationID], (ptrs) {
      _bindings.SetAppBackgroundStatus(ptrs[0], isBackground);
    });
  }

  void setAppBadge(String? operationID, int appUnreadCount) {
    _withCStrings([operationID], (ptrs) {
      _bindings.SetAppBadge(ptrs[0], appUnreadCount);
    });
  }

  void setConversation(
    String? operationID,
    String? conversationID,
    String? draftText,
  ) {
    _withCStrings([operationID, conversationID, draftText], (ptrs) {
      _bindings.SetConversation(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void setConversationDraft(
    String? operationID,
    String? conversationID,
    String? draftText,
  ) {
    _withCStrings([operationID, conversationID, draftText], (ptrs) {
      _bindings.SetConversationDraft(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void setGroupInfo(String? operationID, String? groupInfo) {
    _withCStrings([operationID, groupInfo], (ptrs) {
      _bindings.SetGroupInfo(ptrs[0], ptrs[1]);
    });
  }

  void setGroupMemberInfo(String? operationID, String? groupMemberInfo) {
    _withCStrings([operationID, groupMemberInfo], (ptrs) {
      _bindings.SetGroupMemberInfo(ptrs[0], ptrs[1]);
    });
  }

  void setMessageLocalEx(
    String? operationID,
    String? conversationID,
    String? clientMsgID,
    String? localEx,
  ) {
    _withCStrings([operationID, conversationID, clientMsgID, localEx], (ptrs) {
      _bindings.SetMessageLocalEx(ptrs[0], ptrs[1], ptrs[2], ptrs[3]);
    });
  }

  void setSelfInfo(String? operationID, String? userInfo) {
    _withCStrings([operationID, userInfo], (ptrs) {
      _bindings.SetSelfInfo(ptrs[0], ptrs[1]);
    });
  }

  void subscribeUsersStatus(String? operationID, String? userIDs) {
    _withCStrings([operationID, userIDs], (ptrs) {
      _bindings.SubscribeUsersStatus(ptrs[0], ptrs[1]);
    });
  }

  void transferGroupOwner(
    String? operationID,
    String? groupID,
    String? newOwnerUserID,
  ) {
    _withCStrings([operationID, groupID, newOwnerUserID], (ptrs) {
      _bindings.TransferGroupOwner(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void typingStatusUpdate(String? operationID, String? recvID, String? msgTip) {
    _withCStrings([operationID, recvID, msgTip], (ptrs) {
      _bindings.TypingStatusUpdate(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void unsubscribeUsersStatus(String? operationID, String? userIDs) {
    _withCStrings([operationID, userIDs], (ptrs) {
      _bindings.UnsubscribeUsersStatus(ptrs[0], ptrs[1]);
    });
  }

  void updateFcmToken(String? operationID, String? fcmToken, int expireTime) {
    _withCStrings([operationID, fcmToken], (ptrs) {
      _bindings.UpdateFcmToken(ptrs[0], ptrs[1], expireTime);
    });
  }

  void updateFriends(String? operationID, String? req) {
    _withCStrings([operationID, req], (ptrs) {
      _bindings.UpdateFriends(ptrs[0], ptrs[1]);
    });
  }

  void uploadFile(String? operationID, String? req, String? uuid) {
    _withCStrings([operationID, req, uuid], (ptrs) {
      _bindings.UploadFile(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  void uploadLogs(String? operationID, int line, String? ex, String? uuid) {
    _withCStrings([operationID, ex, uuid], (ptrs) {
      _bindings.UploadLogs(ptrs[0], line, ptrs[1], ptrs[2]);
    });
  }
}
