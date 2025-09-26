import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_openim_ffi/flutter_openim_ffi.dart';
import 'package:flutter_openim_ffi/src/logger.dart';

import '../ffi/event_bridge.dart';
import '../ffi/native_bridge.dart';

class IMManager {
  NativeBridge _channel;
  late ConversationManager conversationManager;
  late FriendshipManager friendshipManager;
  late MessageManager messageManager;
  late GroupManager groupManager;
  late UserManager userManager;

  late OnConnectListener _connectListener;
  OnListenerForService? _listenerForService;
  OnUploadFileListener? _uploadFileListener;
  OnUploadLogsListener? _uploadLogsListener;

  late String userID;
  late UserInfo userInfo;
  bool isLogined = false;
  String? token;

  IMManager(this._channel) {
    conversationManager = ConversationManager(_channel);
    friendshipManager = FriendshipManager(_channel);
    messageManager = MessageManager(_channel);
    groupManager = GroupManager(_channel);
    userManager = UserManager(_channel);
    _addNativeCallback(_channel);
  }

  void _addNativeCallback(NativeBridge bridge) {
    bridge.setMethodCallHandler((call) {
      try {
        Logger.print('Flutter : $call');
        if (_handleNewStyleEvent(call)) {
          return Future.value(null);
        }
        if (call.method == ListenerType.connectListener) {
          String type = call.arguments['type'];
          switch (type) {
            case 'onConnectFailed':
              int? errCode = call.arguments['errCode'];
              String? errMsg = call.arguments['errMsg'];
              _connectListener.connectFailed(errCode, errMsg);
              break;
            case 'onConnecting':
              _connectListener.connecting();
              break;
            case 'onConnectSuccess':
              _connectListener.connectSuccess();
              break;
            case 'onKickedOffline':
              _connectListener.kickedOffline();
              break;
            case 'onUserTokenExpired':
              _connectListener.userTokenExpired();
              break;
            case 'onUserTokenInvalid':
              _connectListener.userTokenInvalid();
              break;
          }
        } else if (call.method == ListenerType.userListener) {
          String type = call.arguments['type'];
          dynamic data = call.arguments['data'];
          switch (type) {
            case 'onSelfInfoUpdated':
              userInfo = Utils.toObj(data, (map) => UserInfo.fromJson(map));
              userManager.listener.selfInfoUpdated(userInfo);
              break;
            case 'onUserStatusChanged':
              final status = Utils.toObj(
                data,
                (map) => UserStatusInfo.fromJson(map),
              );
              userManager.listener.userStatusChanged(status);
              break;
          }
        } else if (call.method == ListenerType.groupListener) {
          String type = call.arguments['type'];
          dynamic data = call.arguments['data'];
          switch (type) {
            case 'onGroupApplicationAccepted':
              final i = Utils.toObj(
                data,
                (map) => GroupApplicationInfo.fromJson(map),
              );
              groupManager.listener.groupApplicationAccepted(i);
              break;
            case 'onGroupApplicationAdded':
              final i = Utils.toObj(
                data,
                (map) => GroupApplicationInfo.fromJson(map),
              );
              groupManager.listener.groupApplicationAdded(i);
              break;
            case 'onGroupApplicationDeleted':
              final i = Utils.toObj(
                data,
                (map) => GroupApplicationInfo.fromJson(map),
              );
              groupManager.listener.groupApplicationDeleted(i);
              break;
            case 'onGroupApplicationRejected':
              final i = Utils.toObj(
                data,
                (map) => GroupApplicationInfo.fromJson(map),
              );
              groupManager.listener.groupApplicationRejected(i);
              break;
            case 'onGroupDismissed':
              final i = Utils.toObj(data, (map) => GroupInfo.fromJson(map));
              groupManager.listener.groupDismissed(i);
              break;
            case 'onGroupInfoChanged':
              final i = Utils.toObj(data, (map) => GroupInfo.fromJson(map));
              groupManager.listener.groupInfoChanged(i);
              break;
            case 'onGroupMemberAdded':
              final i = Utils.toObj(
                data,
                (map) => GroupMembersInfo.fromJson(map),
              );
              groupManager.listener.groupMemberAdded(i);
              break;
            case 'onGroupMemberDeleted':
              final i = Utils.toObj(
                data,
                (map) => GroupMembersInfo.fromJson(map),
              );
              groupManager.listener.groupMemberDeleted(i);
              break;
            case 'onGroupMemberInfoChanged':
              final i = Utils.toObj(
                data,
                (map) => GroupMembersInfo.fromJson(map),
              );
              groupManager.listener.groupMemberInfoChanged(i);
              break;
            case 'onJoinedGroupAdded':
              final i = Utils.toObj(data, (map) => GroupInfo.fromJson(map));
              groupManager.listener.joinedGroupAdded(i);
              break;
            case 'onJoinedGroupDeleted':
              final i = Utils.toObj(data, (map) => GroupInfo.fromJson(map));
              groupManager.listener.joinedGroupDeleted(i);
              break;
          }
        } else if (call.method == ListenerType.advancedMsgListener) {
          var type = call.arguments['type'];
          // var id = call.arguments['data']['id'];
          switch (type) {
            case 'onMsgDeleted':
              var value = call.arguments['data']['message'];
              final msg = Utils.toObj(value, (map) => Message.fromJson(map));
              messageManager.msgListener.msgDeleted(msg);
              break;
            case 'onNewRecvMessageRevoked':
              var value = call.arguments['data']['messageRevoked'];
              var info = Utils.toObj(value, (map) => RevokedInfo.fromJson(map));
              messageManager.msgListener.newRecvMessageRevoked(info);
              break;
            case 'onRecvC2CReadReceipt':
              var value = call.arguments['data']['msgReceiptList'];
              var list = Utils.toList(
                value,
                (map) => ReadReceiptInfo.fromJson(map),
              );
              messageManager.msgListener.recvC2CReadReceipt(list);
              break;
            case 'onRecvNewMessage':
              var value = call.arguments['data']['message'];
              final msg = Utils.toObj(value, (map) => Message.fromJson(map));
              messageManager.msgListener.recvNewMessage(msg);
              break;
            case 'onRecvOfflineNewMessage':
              var value = call.arguments['data']['message'];
              final msg = Utils.toObj(value, (map) => Message.fromJson(map));
              messageManager.msgListener.recvOfflineNewMessage(msg);
              break;
            case 'onRecvOnlineOnlyMessage':
              var value = call.arguments['data']['message'];
              final msg = Utils.toObj(value, (map) => Message.fromJson(map));
              messageManager.msgListener.recvOnlineOnlyMessage(msg);
              break;
          }
        } else if (call.method == ListenerType.msgSendProgressListener) {
          String type = call.arguments['type'];
          dynamic data = call.arguments['data'];
          String msgID = data['clientMsgID'] ?? '';
          int progress = data['progress'] ?? 100;
          switch (type) {
            case 'onProgress':
              messageManager.msgSendProgressListener?.progress(msgID, progress);
              break;
          }
        } else if (call.method == ListenerType.conversationListener) {
          String type = call.arguments['type'];
          dynamic data = call.arguments['data'];
          switch (type) {
            case 'onSyncServerStart':
              print('dart onSyncServerStart: $data');
              conversationManager.listener.syncServerStart(data);
              break;
            case 'onSyncServerProgress':
              conversationManager.listener.syncServerProgress(data);
              break;
            case 'onSyncServerFinish':
              conversationManager.listener.syncServerFinish(data);
              break;
            case 'onSyncServerFailed':
              conversationManager.listener.syncServerFailed(data);
              break;
            case 'onNewConversation':
              var list = Utils.toList(
                data,
                (map) => ConversationInfo.fromJson(map),
              );
              conversationManager.listener.newConversation(list);
              break;
            case 'onConversationChanged':
              var list = Utils.toList(
                data,
                (map) => ConversationInfo.fromJson(map),
              );
              conversationManager.listener.conversationChanged(list);
              break;
            case 'onTotalUnreadMessageCountChanged':
              conversationManager.listener.totalUnreadMessageCountChanged(
                data ?? 0,
              );
              break;
            case 'onConversationUserInputStatusChanged':
              final i = Utils.toObj(
                data,
                (map) => InputStatusChangedData.fromJson(map),
              );
              conversationManager.listener.conversationUserInputStatusChanged(
                i,
              );
              break;
          }
        } else if (call.method == ListenerType.friendListener) {
          String type = call.arguments['type'];
          dynamic data = call.arguments['data'];

          switch (type) {
            case 'onBlackAdded':
              final u = Utils.toObj(data, (map) => BlacklistInfo.fromJson(map));
              friendshipManager.listener.blackAdded(u);
              break;
            case 'onBlackDeleted':
              final u = Utils.toObj(data, (map) => BlacklistInfo.fromJson(map));
              friendshipManager.listener.blackDeleted(u);
              break;
            case 'onFriendAdded':
              final u = Utils.toObj(data, (map) => FriendInfo.fromJson(map));
              friendshipManager.listener.friendAdded(u);
              break;
            case 'onFriendApplicationAccepted':
              final u = Utils.toObj(
                data,
                (map) => FriendApplicationInfo.fromJson(map),
              );
              friendshipManager.listener.friendApplicationAccepted(u);
              break;
            case 'onFriendApplicationAdded':
              final u = Utils.toObj(
                data,
                (map) => FriendApplicationInfo.fromJson(map),
              );
              friendshipManager.listener.friendApplicationAdded(u);
              break;
            case 'onFriendApplicationDeleted':
              final u = Utils.toObj(
                data,
                (map) => FriendApplicationInfo.fromJson(map),
              );
              friendshipManager.listener.friendApplicationDeleted(u);
              break;
            case 'onFriendApplicationRejected':
              final u = Utils.toObj(
                data,
                (map) => FriendApplicationInfo.fromJson(map),
              );
              friendshipManager.listener.friendApplicationRejected(u);
              break;
            case 'onFriendDeleted':
              final u = Utils.toObj(data, (map) => FriendInfo.fromJson(map));
              friendshipManager.listener.friendDeleted(u);
              break;
            case 'onFriendInfoChanged':
              final u = Utils.toObj(data, (map) => FriendInfo.fromJson(map));
              friendshipManager.listener.friendInfoChanged(u);
              break;
          }
        } else if (call.method == ListenerType.customBusinessListener) {
          String type = call.arguments['type'];
          String data = call.arguments['data'];
          switch (type) {
            case 'onRecvCustomBusinessMessage':
              messageManager.customBusinessListener?.recvCustomBusinessMessage(
                data,
              );
              break;
          }
        } else if (call.method == ListenerType.listenerForService) {
          String type = call.arguments['type'];
          String data = call.arguments['data'];
          switch (type) {
            case 'onFriendApplicationAccepted':
              final u = Utils.toObj(
                data,
                (map) => FriendApplicationInfo.fromJson(map),
              );
              _listenerForService?.friendApplicationAccepted(u);
              break;
            case 'onFriendApplicationAdded':
              final u = Utils.toObj(
                data,
                (map) => FriendApplicationInfo.fromJson(map),
              );
              _listenerForService?.friendApplicationAdded(u);
              break;
            case 'onGroupApplicationAccepted':
              final i = Utils.toObj(
                data,
                (map) => GroupApplicationInfo.fromJson(map),
              );
              _listenerForService?.groupApplicationAccepted(i);
              break;
            case 'onGroupApplicationAdded':
              final i = Utils.toObj(
                data,
                (map) => GroupApplicationInfo.fromJson(map),
              );
              _listenerForService?.groupApplicationAdded(i);
              break;
            case 'onRecvNewMessage':
              final msg = Utils.toObj(data, (map) => Message.fromJson(map));
              _listenerForService?.recvNewMessage(msg);
              break;
          }
        } else if (call.method == ListenerType.uploadLogsListener) {
          String type = call.arguments['type'];
          dynamic data = call.arguments['data'];
          switch (type) {
            case 'onProgress':
              int size = data['size'];
              int current = data['current'];
              _uploadLogsListener?.onProgress(current, size);
          }
        } else if (call.method == ListenerType.uploadFileListener) {
          String type = call.arguments['type'];
          dynamic data = call.arguments['data'];
          switch (type) {
            case 'complete':
              String id = data['id'];
              int size = data['size'];
              String url = data['url'];
              int type = data['type'];
              _uploadFileListener?.complete(id, size, url, type);
              break;
            case 'hashPartComplete':
              String id = data['id'];
              String partHash = data['partHash'];
              String fileHash = data['fileHash'];
              _uploadFileListener?.hashPartComplete(id, partHash, fileHash);
              break;
            case 'hashPartProgress':
              String id = data['id'];
              int index = data['index'];
              int size = data['size'];
              String partHash = data['partHash'];
              _uploadFileListener?.hashPartProgress(id, index, size, partHash);
              break;
            case 'open':
              String id = data['id'];
              int size = data['size'];
              _uploadFileListener?.open(id, size);
              break;
            case 'partSize':
              String id = data['id'];
              int partSize = data['partSize'];
              int num = data['num'];
              _uploadFileListener?.partSize(id, partSize, num);
              break;
            case 'uploadProgress':
              String id = data['id'];
              int fileSize = data['fileSize'];
              int streamSize = data['streamSize'];
              int storageSize = data['storageSize'];
              _uploadFileListener?.uploadProgress(
                id,
                fileSize,
                streamSize,
                storageSize,
              );
              break;
            case 'uploadID':
              String id = data['id'];
              String uploadID = data['uploadID'];
              _uploadFileListener?.uploadID(id, uploadID);
              break;
            case 'uploadPartComplete':
              String id = data['id'];
              int index = data['index'];
              int partSize = data['partSize'];
              String partHash = data['partHash'];
              _uploadFileListener?.uploadPartComplete(
                id,
                index,
                partSize,
                partHash,
              );
              break;
          }
        }
      } catch (error, stackTrace) {
        Logger.print(
          "回调失败了。${call.method} ${call.arguments['type']} ${call.arguments['data']} $error $stackTrace",
        );
      }
      return Future.value(null);
    });
  }

  bool _handleNewStyleEvent(NativeMethodCall call) {
    final method = call.method;
    final rawArgs = call.arguments;
    if (rawArgs is! Map) {
      return false;
    }
    final args = Map<String, dynamic>.from(rawArgs as Map);
    final dynamic data = args['data'];
    switch (method) {
      case 'OnConnecting':
        _connectListener.connecting();
        return true;
      case 'OnConnectSuccess':
        _connectListener.connectSuccess();
        return true;
      case 'OnConnectFailed':
        _connectListener.connectFailed(
          Utils.toInt(args['errCode']),
          Utils.stringValue(args['errMsg']),
        );
        return true;
      case 'OnKickedOffline':
        _connectListener.kickedOffline();
        return true;
      case 'OnUserTokenExpired':
        _connectListener.userTokenExpired();
        return true;
      case 'OnUserTokenInvalid':
        _connectListener.userTokenInvalid();
        return true;
      case 'OnSyncServerStart':
        conversationManager.listener.syncServerStart(_asNullableBool(data, args));
        return true;
      case 'OnSyncServerProgress':
        conversationManager.listener.syncServerProgress(
          Utils.toInt(data ?? args['errCode']),
        );
        return true;
      case 'OnSyncServerFinish':
        conversationManager.listener.syncServerFinish(_asNullableBool(data, args));
        return true;
      case 'OnSyncServerFailed':
        conversationManager.listener.syncServerFailed(_asNullableBool(data, args));
        return true;
      case 'OnConversationChanged':
        conversationManager.listener.conversationChanged(
          Utils.toList(
            data,
            (map) => ConversationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnNewConversation':
        conversationManager.listener.newConversation(
          Utils.toList(
            data,
            (map) => ConversationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnTotalUnreadMessageCountChanged':
        conversationManager.listener.totalUnreadMessageCountChanged(
          Utils.toInt(data ?? args['errCode']),
        );
        return true;
      case 'OnConversationUserInputStatusChanged':
        if (data != null) {
          final info = Utils.toObj(
            data,
            (map) => InputStatusChangedData.fromJson(map),
          );
          conversationManager.listener.conversationUserInputStatusChanged(info);
        }
        return true;
      case 'OnRecvNewMessage':
        messageManager.msgListener.recvNewMessage(_parseMessage(data));
        return true;
      case 'OnRecvOfflineNewMessage':
        messageManager.msgListener.recvOfflineNewMessage(_parseMessage(data));
        return true;
      case 'OnRecvOnlineOnlyMessage':
        messageManager.msgListener.recvOnlineOnlyMessage(_parseMessage(data));
        return true;
      case 'OnRecvC2CReadReceipt':
        messageManager.msgListener.recvC2CReadReceipt(
          Utils.toList(
            _unwrapPayload(data, 'msgReceiptList'),
            (map) => ReadReceiptInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnNewRecvMessageRevoked':
        messageManager.msgListener.newRecvMessageRevoked(
          Utils.toObj(
            _unwrapPayload(data, 'messageRevoked'),
            (map) => RevokedInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnMsgDeleted':
        messageManager.msgListener.msgDeleted(
          Utils.toObj(
            _unwrapPayload(data, 'message'),
            (map) => Message.fromJson(map),
          ),
        );
        return true;
      case 'OnProgress':
        final progressPayload = _unwrapPayload(data, 'data');
        if (progressPayload is Map) {
          final progressMap = Map<String, dynamic>.from(progressPayload);
          messageManager.msgSendProgressListener?.progress(
            Utils.stringValue(progressMap['clientMsgID']) ?? '',
            Utils.toInt(progressMap['progress'], 100),
          );
        }
        return true;
      case 'OnSelfInfoUpdated':
        if (data != null) {
          userInfo = Utils.toObj(data, (map) => UserInfo.fromJson(map));
          userManager.listener.selfInfoUpdated(userInfo);
        }
        return true;
      case 'OnUserStatusChanged':
        if (data != null) {
          final status = Utils.toObj(
            data,
            (map) => UserStatusInfo.fromJson(map),
          );
          userManager.listener.userStatusChanged(status);
        }
        return true;
      case 'OnBlackAdded':
        friendshipManager.listener.blackAdded(
          Utils.toObj(
            data,
            (map) => BlacklistInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnBlackDeleted':
        friendshipManager.listener.blackDeleted(
          Utils.toObj(
            data,
            (map) => BlacklistInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnFriendAdded':
        friendshipManager.listener.friendAdded(
          Utils.toObj(
            data,
            (map) => FriendInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnFriendDeleted':
        friendshipManager.listener.friendDeleted(
          Utils.toObj(
            data,
            (map) => FriendInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnFriendInfoChanged':
        friendshipManager.listener.friendInfoChanged(
          Utils.toObj(
            data,
            (map) => FriendInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnFriendApplicationAdded':
        friendshipManager.listener.friendApplicationAdded(
          Utils.toObj(
            data,
            (map) => FriendApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnFriendApplicationAccepted':
        friendshipManager.listener.friendApplicationAccepted(
          Utils.toObj(
            data,
            (map) => FriendApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnFriendApplicationDeleted':
        friendshipManager.listener.friendApplicationDeleted(
          Utils.toObj(
            data,
            (map) => FriendApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnFriendApplicationRejected':
        friendshipManager.listener.friendApplicationRejected(
          Utils.toObj(
            data,
            (map) => FriendApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupApplicationAccepted':
        groupManager.listener.groupApplicationAccepted(
          Utils.toObj(
            data,
            (map) => GroupApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupApplicationAdded':
        groupManager.listener.groupApplicationAdded(
          Utils.toObj(
            data,
            (map) => GroupApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupApplicationDeleted':
        groupManager.listener.groupApplicationDeleted(
          Utils.toObj(
            data,
            (map) => GroupApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupApplicationRejected':
        groupManager.listener.groupApplicationRejected(
          Utils.toObj(
            data,
            (map) => GroupApplicationInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupDismissed':
        groupManager.listener.groupDismissed(
          Utils.toObj(
            data,
            (map) => GroupInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupInfoChanged':
        groupManager.listener.groupInfoChanged(
          Utils.toObj(
            data,
            (map) => GroupInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupMemberAdded':
        groupManager.listener.groupMemberAdded(
          Utils.toObj(
            data,
            (map) => GroupMembersInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupMemberDeleted':
        groupManager.listener.groupMemberDeleted(
          Utils.toObj(
            data,
            (map) => GroupMembersInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnGroupMemberInfoChanged':
        groupManager.listener.groupMemberInfoChanged(
          Utils.toObj(
            data,
            (map) => GroupMembersInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnJoinedGroupAdded':
        groupManager.listener.joinedGroupAdded(
          Utils.toObj(
            data,
            (map) => GroupInfo.fromJson(map),
          ),
        );
        return true;
      case 'OnJoinedGroupDeleted':
        groupManager.listener.joinedGroupDeleted(
          Utils.toObj(
            data,
            (map) => GroupInfo.fromJson(map),
          ),
        );
        return true;
      default:
        return false;
    }
  }

  bool? _asNullableBool(dynamic data, Map<String, dynamic> args) {
    if (data != null) {
      return Utils.toBool(data);
    }
    if (args.containsKey('errCode')) {
      return Utils.toBool(args['errCode']);
    }
    return null;
  }

  dynamic _unwrapPayload(dynamic source, String key) {
    if (source is Map<String, dynamic> && source.containsKey(key)) {
      return source[key];
    }
    return source;
  }

  Message _parseMessage(dynamic source) => Utils.toObj(
        _unwrapPayload(source, 'message'),
        (map) => Message.fromJson(map),
      );

  Future<bool?> init(
    InitConfig config,
    OnConnectListener listener, {
    String? operationID,
  }) {
    _connectListener = listener;
    EventBridge.instance.ensureInitialized();
    config.logFilePath ??= config.dataDir;
    return _channel.invokeMethod(
      'initSDK',
      _buildParam({
        ...config.toMap(),
        "operationID": Utils.checkOperationID(operationID),
      }),
    );
  }

  /// Initialize the SDK
  /// [platform] Platform ID [IMPlatform]
  /// [apiAddr] SDK API address
  /// [wsAddr] SDK WebSocket address
  /// [dataDir] SDK database storage directory
  /// [logLevel] Log level, 1: no printing
  /// [enabledEncryption] true: encryption
  /// [enabledCompression] true: compression
  Future<dynamic> initSDK({
    required int platformID,
    required String apiAddr,
    required String wsAddr,
    required String dataDir,
    required OnConnectListener listener,
    int logLevel = 6,
    bool isNeedEncryption = false,
    bool isCompression = false,
    bool isLogStandardOutput = true,
    String? logFilePath,
    String? operationID,
  }) {
    _connectListener = listener;
    EventBridge.instance.ensureInitialized();
    return _channel.invokeMethod(
      'initSDK',
      _buildParam({
        "platformID": platformID,
        "apiAddr": apiAddr,
        "wsAddr": wsAddr,
        "dataDir": dataDir,
        "logLevel": logLevel,
        "isCompression": isCompression,
        'isNeedEncryption': isNeedEncryption,
        "isLogStandardOutput": isLogStandardOutput,
        "logFilePath": logFilePath,
        'systemType': 'flutter',
        "operationID": Utils.checkOperationID(operationID),
      }),
    );
  }

  /// Deinitialize the SDK
  void unInitSDK() {
    _channel.invokeMethod('unInitSDK', _buildParam({}));
  }

  /// Login
  /// [userID] User ID
  /// [token] Login token obtained from the business server
  /// [defaultValue] Default value to use if login fails
  Future<UserInfo> login({
    required String userID,
    required String token,
    String? operationID,
    Future<UserInfo> Function()? defaultValue,
    bool checkLoginStatus = true,
  }) async {
    int? status;
    if (checkLoginStatus) {
      // 1: logout 2: logging  3: logged
      status = await getLoginStatus();
    }
    if (status != LoginStatus.logging && status != LoginStatus.logged) {
      await _channel.invokeMethod(
        'login',
        _buildParam({
          'userID': userID,
          'token': token,
          'operationID': Utils.checkOperationID(operationID),
        }),
      );
    }
    this.isLogined = true;
    this.userID = userID;
    this.token = token;
    try {
      return this.userInfo = await userManager.getSelfUserInfo();
    } catch (error, stackTrace) {
      log('login e: $error  s: $stackTrace');
      if (null != defaultValue) {
        return this.userInfo = await (defaultValue.call());
      }
      return Future.error(error, stackTrace);
    }
    // return uInfo;
  }

  /// Logout
  Future<dynamic> logout({String? operationID}) async {
    var value = await _channel.invokeMethod(
      'logout',
      _buildParam({'operationID': Utils.checkOperationID(operationID)}),
    );
    this.isLogined = false;
    this.token = null;
    return value;
  }

  /// Get login status
  /// 1: logout 2: logging  3: logged
  Future<int?> getLoginStatus({String? operationID}) =>
      _channel.invokeMethod<int>(
        'getLoginStatus',
        _buildParam({'operationID': Utils.checkOperationID(operationID)}),
      );

  /// Get the current logged-in user ID
  Future<String> getLoginUserID() async => userID;

  /// Get the current logged-in user information
  Future<UserInfo> getLoginUserInfo() async => userInfo;

  /// [id] Same as [OnUploadFileListener] ID, to distinguish which file callback it is
  Future uploadFile({
    required String id,
    required String filePath,
    required String fileName,
    String? contentType,
    String? cause,
    String? operationID,
  }) => _channel.invokeMethod(
    'uploadFile',
    _buildParam({
      'id': id,
      'filePath': filePath,
      'name': fileName,
      'contentType': contentType,
      'cause': cause,
      'operationID': Utils.checkOperationID(operationID),
    }),
  );

  /// Update the Firebase client registration token
  /// [fcmToken] Firebase token
  Future updateFcmToken({
    required String fcmToken,
    required int expireTime,
    String? operationID,
  }) => _channel.invokeMethod(
    'updateFcmToken',
    _buildParam({
      'fcmToken': fcmToken,
      'expireTime': expireTime,
      'operationID': Utils.checkOperationID(operationID),
    }),
  );

  /// Upload logs
  Future uploadLogs({String? ex, int line = 0, String? operationID}) =>
      _channel.invokeMethod(
        'uploadLogs',
        _buildParam({
          'ex': ex,
          'line': line,
          'operationID': Utils.checkOperationID(operationID),
        }),
      );

  Future logs({
    int logLevel = 5,
    String? file,
    int line = 0,
    String? msgs,
    String? err,
    List<dynamic>? keyAndValues,
    String? operationID,
  }) => _channel.invokeMethod(
    'logs',
    _buildParam({
      'line': line,
      'logLevel': logLevel,
      'file': file,
      'msgs': msgs,
      'err': err,
      if (keyAndValues != null) 'keyAndValue': jsonEncode(keyAndValues),
      'operationID': Utils.checkOperationID(operationID),
    }),
  );

  void setUploadLogsListener(OnUploadLogsListener listener) {
    _uploadLogsListener = listener;
  }

  void setUploadFileListener(OnUploadFileListener listener) {
    _uploadFileListener = listener;
  }

  ///
  Future setListenerForService(OnListenerForService listener) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      this._listenerForService = listener;
      return _channel.invokeMethod('setListenerForService', _buildParam({}));
    } else {
      throw UnsupportedError("only supprot android platform");
    }
  }

  NativeBridge get channel => _channel;

  static Map<String, dynamic> _buildParam(Map<Object?, Object?> param) {
    final typed = <String, dynamic>{};
    param.forEach((key, value) {
      if (key == null) {
        return;
      }
      if (key is! String) {
        throw ArgumentError('Only string keys are supported. Found key: $key');
      }
      typed[key] = value;
    });
    return Utils.cleanMap(typed);
  }
}
