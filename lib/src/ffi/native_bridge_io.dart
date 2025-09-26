import 'dart:async';

import '../logger.dart';
import '../utils.dart';
import 'bindings.dart';
import 'event_bridge.dart';

class NativeMethodCall {
  NativeMethodCall(this.method, this.arguments);

  final String method;
  final dynamic arguments;
}

typedef NativeMethodCallHandler =
    FutureOr<void> Function(NativeMethodCall call);

class NativeInvocation {
  NativeInvocation.completed(this.result)
    : operationID = null,
      isCompleted = true;

  NativeInvocation.pending(this.operationID)
    : result = null,
      isCompleted = false;

  final bool isCompleted;
  final Object? result;
  final String? operationID;
}

class NativeBridge {
  NativeBridge();

  NativeMethodCallHandler? _handler;
  final _pending = <String, Completer<dynamic>>{};

  void setMethodCallHandler(NativeMethodCallHandler handler) {
    _handler = handler;
    EventBridge.instance.setHandler(_handleNativeEvent);
  }

  Future<T?> invokeMethod<T>(String method, Map<String, dynamic> arguments) {
    final operationID =
        arguments['operationID'] as String? ?? Utils.checkOperationID(null);
    arguments['operationID'] = operationID;
    final cleaned = Utils.cleanMap(arguments);
    final invocation = NativeInvoker.instance.invoke(
      method,
      cleaned,
      operationID,
    );
    if (invocation.isCompleted) {
      return Future.value(invocation.result as T?);
    }
    final completer = Completer<T?>();
    _pending[invocation.operationID!] = completer;
    return completer.future;
  }

  void _handleNativeEvent(Map<String, dynamic> envelope) {
    // ignore: avoid_print
    print('FFI Event: ${Utils.toJson(envelope)}');
    final method = envelope['method'] as String?;
    if (method == null) {
      // ignore: avoid_print
      print('FFI Event missing method, keys=${envelope.keys}');
      return;
    }
    _handler?.call(NativeMethodCall(method, envelope));

    final opID = envelope['operationID'] as String?;
    if (opID != null) {
      final completer = _pending.remove(opID);
      if (completer != null) {
        final errCode = envelope['errCode'] as int?;
        final errMsg = envelope['errMsg'] as String?;
        if (errCode != null && errCode != 0) {
          completer.completeError(OpenIMNativeException(errCode, errMsg));
        } else {
          completer.complete(envelope['data']);
        }
      }
    }
  }
}

class OpenIMNativeException implements Exception {
  OpenIMNativeException(this.code, this.message);

  final int code;
  final String? message;

  @override
  String toString() => 'OpenIMNativeException(code: $code, message: $message)';
}

class NativeInvoker {
  NativeInvoker._();

  static final NativeInvoker instance = NativeInvoker._();

  NativeInvocation invoke(
    String method,
    Map<String, dynamic> arguments,
    String operationID,
  ) {
    switch (method) {
      case 'initSDK':
        final listener = OpenIMFFI.instance.getIMListener();
        final nativePort = EventBridge.instance.nativePort;
        final configJson = Utils.toJson(arguments);
        final ok = OpenIMFFI.instance.initSDK(
          listener,
          nativePort,
          operationID,
          configJson,
        );
        return NativeInvocation.completed(ok);
      case 'login':
        final userID = arguments['userID'] as String?;
        final token = arguments['token'] as String?;
        if (userID == null || token == null) {
          throw ArgumentError('login requires userID & token');
        }
        OpenIMFFI.instance.login(operationID, userID, token);
        return NativeInvocation.pending(operationID);
      case 'logout':
        OpenIMFFI.instance.logout(operationID);
        return NativeInvocation.pending(operationID);
      case 'getLoginStatus':
        final status = OpenIMFFI.instance.getLoginStatus(operationID);
        return NativeInvocation.completed(status);
      case 'getLoginUserID':
        final userID = OpenIMFFI.instance.getLoginUserID();
        return NativeInvocation.completed(userID);
      case 'acceptFriendApplication':
        OpenIMFFI.instance.acceptFriendApplication(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
        );
        return NativeInvocation.pending(operationID);

      case 'acceptGroupApplication':
        OpenIMFFI.instance.acceptGroupApplication(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'userID'),
          _stringArg(arguments, 'handleMsg'),
        );
        return NativeInvocation.pending(operationID);

      case 'addBlacklist':
        OpenIMFFI.instance.addBlack(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'userID'),
          _stringArg(arguments, 'ex'),
        );
        return NativeInvocation.pending(operationID);

      case 'addFriend':
        OpenIMFFI.instance.addFriend(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
        );
        return NativeInvocation.pending(operationID);

      case 'changeGroupMemberMute':
        OpenIMFFI.instance.changeGroupMemberMute(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'userID'),
          Utils.toInt(arguments['seconds']),
        );
        return NativeInvocation.pending(operationID);

      case 'changeGroupMute':
        OpenIMFFI.instance.changeGroupMute(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          Utils.toBool(arguments['mute']),
        );
        return NativeInvocation.pending(operationID);

      case 'changeInputStates':
        OpenIMFFI.instance.changeInputStates(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          Utils.toBool(arguments['focus']),
        );
        return NativeInvocation.pending(operationID);

      case 'checkFriend':
        OpenIMFFI.instance.checkFriend(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['userIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'clearConversationAndDeleteAllMsg':
        OpenIMFFI.instance.clearConversationAndDeleteAllMsg(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'createAdvancedQuoteMessage':
        final result = OpenIMFFI.instance.createAdvancedQuoteMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'quoteText'),
          Utils.toJsonString(arguments['quoteMessage']),
          Utils.toJsonString(arguments['richMessageInfoList']),
        );
        return NativeInvocation.completed(result);

      case 'createAdvancedTextMessage':
        final result = OpenIMFFI.instance.createAdvancedTextMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'text'),
          Utils.toJsonString(arguments['richMessageInfoList']),
        );
        return NativeInvocation.completed(result);

      case 'createCardMessage':
        final result = OpenIMFFI.instance.createCardMessage(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['cardMessage']),
        );
        return NativeInvocation.completed(result);

      case 'createCustomMessage':
        final result = OpenIMFFI.instance.createCustomMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'data'),
          _stringArg(arguments, 'extension'),
          _stringArg(arguments, 'description'),
        );
        return NativeInvocation.completed(result);

      case 'createFaceMessage':
        final result = OpenIMFFI.instance.createFaceMessage(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['index']),
          _stringArg(arguments, 'data'),
        );
        return NativeInvocation.completed(result);

      case 'createFileMessage':
        final result = OpenIMFFI.instance.createFileMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'filePath'),
          _stringArg(arguments, 'fileName'),
        );
        return NativeInvocation.completed(result);

      case 'createFileMessageByURL':
        final result = OpenIMFFI.instance.createFileMessageByURL(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['fileElem']),
        );
        return NativeInvocation.completed(result);

      case 'createFileMessageFromFullPath':
        final result = OpenIMFFI.instance.createFileMessageFromFullPath(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'filePath'),
          _stringArg(arguments, 'fileName'),
        );
        return NativeInvocation.completed(result);

      case 'createForwardMessage':
        final result = OpenIMFFI.instance.createForwardMessage(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['message']),
        );
        return NativeInvocation.completed(result);

      case 'createGroup':
        OpenIMFFI.instance.createGroup(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
        );
        return NativeInvocation.pending(operationID);

      case 'createImageMessage':
        final result = OpenIMFFI.instance.createImageMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'imagePath'),
        );
        return NativeInvocation.completed(result);

      case 'createImageMessageByURL':
        final result = OpenIMFFI.instance.createImageMessageByURL(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'sourcePath'),
          Utils.toJsonString(arguments['sourcePicture']),
          Utils.toJsonString(arguments['bigPicture']),
          Utils.toJsonString(arguments['snapshotPicture']),
        );
        return NativeInvocation.completed(result);

      case 'createImageMessageFromFullPath':
        final result = OpenIMFFI.instance.createImageMessageFromFullPath(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'imagePath'),
        );
        return NativeInvocation.completed(result);

      case 'createLocationMessage':
        final result = OpenIMFFI.instance.createLocationMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'description'),
          Utils.toDouble(arguments['longitude']),
          Utils.toDouble(arguments['latitude']),
        );
        return NativeInvocation.completed(result);

      case 'createMergerMessage':
        final result = OpenIMFFI.instance.createMergerMessage(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['messageList']),
          _stringArg(arguments, 'title'),
          Utils.toJsonString(arguments['summaryList']),
        );
        return NativeInvocation.completed(result);

      case 'createQuoteMessage':
        final result = OpenIMFFI.instance.createQuoteMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'quoteText'),
          Utils.toJsonString(arguments['quoteMessage']),
        );
        return NativeInvocation.completed(result);

      case 'createSoundMessage':
        final result = OpenIMFFI.instance.createSoundMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'soundPath'),
          Utils.toInt(arguments['duration']),
        );
        return NativeInvocation.completed(result);

      case 'createSoundMessageByURL':
        final result = OpenIMFFI.instance.createSoundMessageByURL(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['soundElem']),
        );
        return NativeInvocation.completed(result);

      case 'createSoundMessageFromFullPath':
        final result = OpenIMFFI.instance.createSoundMessageFromFullPath(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'soundPath'),
          Utils.toInt(arguments['duration']),
        );
        return NativeInvocation.completed(result);

      case 'createTextAtMessage':
        final result = OpenIMFFI.instance.createTextAtMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'text'),
          Utils.toJsonString(arguments['atUserIDList']),
          Utils.toJsonString(arguments['atUserInfoList']),
          Utils.toJsonString(arguments['quoteMessage']),
        );
        return NativeInvocation.completed(result);

      case 'createTextMessage':
        final result = OpenIMFFI.instance.createTextMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'text'),
        );
        return NativeInvocation.completed(result);

      case 'createVideoMessage':
        final result = OpenIMFFI.instance.createVideoMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'videoPath'),
          _stringArg(arguments, 'videoType'),
          Utils.toInt(arguments['duration']),
          _stringArg(arguments, 'snapshotPath'),
        );
        return NativeInvocation.completed(result);

      case 'createVideoMessageByURL':
        final result = OpenIMFFI.instance.createVideoMessageByURL(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['videoElem']),
        );
        return NativeInvocation.completed(result);

      case 'createVideoMessageFromFullPath':
        final result = OpenIMFFI.instance.createVideoMessageFromFullPath(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'videoPath'),
          _stringArg(arguments, 'videoType'),
          Utils.toInt(arguments['duration']),
          _stringArg(arguments, 'snapshotPath'),
        );
        return NativeInvocation.completed(result);

      case 'sendMessage':
        if (Utils.toBool(arguments['isOnlineOnly'])) {
          Logger.print(
            'sendMessage: isOnlineOnly is not supported via FFI bridge',
          );
        }
        OpenIMFFI.instance.sendMessage(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['message']),
          _stringArg(arguments, 'userID'),
          _stringArg(arguments, 'groupID'),
          Utils.toJsonString(arguments['offlinePushInfo']),
        );
        return NativeInvocation.pending(operationID);

      case 'sendMessageNotOss':
        if (Utils.toBool(arguments['isOnlineOnly'])) {
          Logger.print(
            'sendMessageNotOss: isOnlineOnly is not supported via FFI bridge',
          );
        }
        OpenIMFFI.instance.sendMessageNotOss(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['message']),
          _stringArg(arguments, 'userID'),
          _stringArg(arguments, 'groupID'),
          Utils.toJsonString(arguments['offlinePushInfo']),
        );
        return NativeInvocation.pending(operationID);

      case 'deleteAllMsgFromLocal':
        OpenIMFFI.instance.deleteAllMsgFromLocal(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'deleteAllMsgFromLocalAndSvr':
        OpenIMFFI.instance.deleteAllMsgFromLocalAndSvr(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'deleteConversationAndDeleteAllMsg':
        OpenIMFFI.instance.deleteConversationAndDeleteAllMsg(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'deleteFriend':
        OpenIMFFI.instance.deleteFriend(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'userID'),
        );
        return NativeInvocation.pending(operationID);

      case 'deleteMessageFromLocalAndSvr':
        OpenIMFFI.instance.deleteMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          _stringArg(arguments, 'clientMsgID'),
        );
        return NativeInvocation.pending(operationID);

      case 'deleteMessageFromLocalStorage':
        OpenIMFFI.instance.deleteMessageFromLocalStorage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          _stringArg(arguments, 'clientMsgID'),
        );
        return NativeInvocation.pending(operationID);

      case 'dismissGroup':
        OpenIMFFI.instance.dismissGroup(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
        );
        return NativeInvocation.pending(operationID);

      case 'findMessageList':
        OpenIMFFI.instance.findMessageList(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['searchParams']),
        );
        return NativeInvocation.pending(operationID);

      case 'getAdvancedHistoryMessageList':
        OpenIMFFI.instance.getAdvancedHistoryMessageList(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
        );
        return NativeInvocation.pending(operationID);

      case 'getAdvancedHistoryMessageListReverse':
        OpenIMFFI.instance.getAdvancedHistoryMessageListReverse(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
        );
        return NativeInvocation.pending(operationID);

      case 'getAllConversationList':
        OpenIMFFI.instance.getAllConversationList(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getAtAllTag':
        final result = OpenIMFFI.instance.getAtAllTag(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.completed(result);

      case 'getBlacklist':
        OpenIMFFI.instance.getBlackList(_stringArg(arguments, 'operationID'));
        return NativeInvocation.pending(operationID);

      case 'getConversationIDBySessionType':
        final result = OpenIMFFI.instance.getConversationIDBySessionType(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'sourceID'),
          Utils.toInt(arguments['sessionType']),
        );
        return NativeInvocation.completed(result);

      case 'getConversationListSplit':
        OpenIMFFI.instance.getConversationListSplit(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['offset']),
          Utils.toInt(arguments['count']),
        );
        return NativeInvocation.pending(operationID);

      case 'getFriendApplicationListAsApplicant':
        OpenIMFFI.instance.getFriendApplicationListAsApplicant(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['req']),
        );
        return NativeInvocation.pending(operationID);

      case 'getFriendApplicationListAsRecipient':
        OpenIMFFI.instance.getFriendApplicationListAsRecipient(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['req']),
        );
        return NativeInvocation.pending(operationID);

      case 'getFriendList':
        OpenIMFFI.instance.getFriendList(
          _stringArg(arguments, 'operationID'),
          Utils.toBool(arguments['filterBlack']),
        );
        return NativeInvocation.pending(operationID);

      case 'getFriendListPage':
        OpenIMFFI.instance.getFriendListPage(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['offset']),
          Utils.toInt(arguments['count']),
          Utils.toBool(arguments['filterBlack']),
        );
        return NativeInvocation.pending(operationID);

      case 'getFriendsInfo':
        OpenIMFFI.instance.getSpecifiedFriendsInfo(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['userIDList']),
          Utils.toBool(arguments['filterBlack']),
        );
        return NativeInvocation.pending(operationID);

      case 'getGroupMemberList':
        OpenIMFFI.instance.getGroupMemberList(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          Utils.toInt(arguments['filter']),
          Utils.toInt(arguments['offset']),
          Utils.toInt(arguments['count']),
        );
        return NativeInvocation.pending(operationID);

      case 'getGroupApplicationListAsApplicant':
        OpenIMFFI.instance.getGroupApplicationListAsApplicant(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['req']),
        );
        return NativeInvocation.pending(operationID);

      case 'getGroupApplicationListAsRecipient':
        OpenIMFFI.instance.getGroupApplicationListAsRecipient(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['req']),
        );
        return NativeInvocation.pending(operationID);

      case 'getGroupMemberListByJoinTimeFilter':
        OpenIMFFI.instance.getGroupMemberListByJoinTimeFilter(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          Utils.toInt(arguments['offset']),
          Utils.toInt(arguments['count']),
          Utils.toInt(arguments['joinTimeBegin']),
          Utils.toInt(arguments['joinTimeEnd']),
          Utils.toJsonString(arguments['excludeUserIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'getGroupMemberOwnerAndAdmin':
        OpenIMFFI.instance.getGroupMemberOwnerAndAdmin(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getGroupMembersInfo':
        OpenIMFFI.instance.getSpecifiedGroupMembersInfo(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          Utils.toJsonString(arguments['userIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'getGroupsInfo':
        OpenIMFFI.instance.getSpecifiedGroupsInfo(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['groupIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'getInputStates':
        OpenIMFFI.instance.getInputStates(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          _stringArg(arguments, 'userID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getJoinedGroupList':
        OpenIMFFI.instance.getJoinedGroupList(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getJoinedGroupListPage':
        OpenIMFFI.instance.getJoinedGroupListPage(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['offset']),
          Utils.toInt(arguments['count']),
        );
        return NativeInvocation.pending(operationID);

      case 'getMultipleConversation':
        OpenIMFFI.instance.getMultipleConversation(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['conversationIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'getOneConversation':
        OpenIMFFI.instance.getOneConversation(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['sessionType']),
          _stringArg(arguments, 'sourceID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getSelfUserInfo':
        OpenIMFFI.instance.getSelfUserInfo(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getSubscribeUsersStatus':
        OpenIMFFI.instance.getSubscribeUsersStatus(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getTotalUnreadMsgCount':
        OpenIMFFI.instance.getTotalUnreadMsgCount(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'getUsersInGroup':
        OpenIMFFI.instance.getUsersInGroup(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          Utils.toJsonString(arguments['userIDs']),
        );
        return NativeInvocation.pending(operationID);

      case 'getUsersInfo':
        OpenIMFFI.instance.getUsersInfo(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['userIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'hideAllConversations':
        OpenIMFFI.instance.hideAllConversations(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'hideConversation':
        OpenIMFFI.instance.hideConversation(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'insertGroupMessageToLocalStorage':
        OpenIMFFI.instance.insertGroupMessageToLocalStorage(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['message']),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'senderID'),
        );
        return NativeInvocation.pending(operationID);

      case 'insertSingleMessageToLocalStorage':
        OpenIMFFI.instance.insertSingleMessageToLocalStorage(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['message']),
          _stringArg(arguments, 'receiverID'),
          _stringArg(arguments, 'senderID'),
        );
        return NativeInvocation.pending(operationID);

      case 'inviteUserToGroup':
        OpenIMFFI.instance.inviteUserToGroup(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'reason'),
          Utils.toJsonString(arguments['userIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'isJoinGroup':
        OpenIMFFI.instance.isJoinGroup(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
        );
        return NativeInvocation.pending(operationID);

      case 'joinGroup':
        OpenIMFFI.instance.joinGroup(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'reason'),
          Utils.toInt(arguments['joinSource']),
          _stringArg(arguments, 'ex'),
        );
        return NativeInvocation.pending(operationID);

      case 'kickGroupMember':
        OpenIMFFI.instance.kickGroupMember(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'reason'),
          Utils.toJsonString(arguments['userIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'logs':
        OpenIMFFI.instance.logs(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['logLevel']),
          _stringArg(arguments, 'file'),
          Utils.toInt(arguments['line']),
          _stringArg(arguments, 'msgs'),
          _stringArg(arguments, 'err'),
          _stringArg(arguments, 'keyAndValue'),
        );
        return NativeInvocation.pending(operationID);

      case 'markConversationMessageAsRead':
        OpenIMFFI.instance.markConversationMessageAsRead(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'markMessagesAsReadByMsgID':
        OpenIMFFI.instance.markMessagesAsReadByMsgID(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          Utils.toJsonString(arguments['messageIDList']),
        );
        return NativeInvocation.pending(operationID);

      case 'networkStatusChanged':
        OpenIMFFI.instance.networkStatusChanged(
          _stringArg(arguments, 'operationID'),
        );
        return NativeInvocation.pending(operationID);

      case 'quitGroup':
        OpenIMFFI.instance.quitGroup(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
        );
        return NativeInvocation.pending(operationID);

      case 'refuseFriendApplication':
        OpenIMFFI.instance.refuseFriendApplication(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
        );
        return NativeInvocation.pending(operationID);

      case 'refuseGroupApplication':
        OpenIMFFI.instance.refuseGroupApplication(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'userID'),
          _stringArg(arguments, 'handleMsg'),
        );
        return NativeInvocation.pending(operationID);

      case 'removeBlacklist':
        OpenIMFFI.instance.removeBlack(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'userID'),
        );
        return NativeInvocation.pending(operationID);

      case 'revokeMessage':
        OpenIMFFI.instance.revokeMessage(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          _stringArg(arguments, 'clientMsgID'),
        );
        return NativeInvocation.pending(operationID);

      case 'searchConversation':
        OpenIMFFI.instance.searchConversation(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'name'),
        );
        return NativeInvocation.pending(operationID);

      case 'searchConversations':
        OpenIMFFI.instance.searchConversation(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'name'),
        );
        return NativeInvocation.pending(operationID);

      case 'searchFriends':
        OpenIMFFI.instance.searchFriends(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['searchParam']),
        );
        return NativeInvocation.pending(operationID);

      case 'searchGroupMembers':
        OpenIMFFI.instance.searchGroupMembers(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['searchParam']),
        );
        return NativeInvocation.pending(operationID);

      case 'searchGroups':
        OpenIMFFI.instance.searchGroups(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['searchParam']),
        );
        return NativeInvocation.pending(operationID);

      case 'searchLocalMessages':
        OpenIMFFI.instance.searchLocalMessages(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['filter']),
        );
        return NativeInvocation.pending(operationID);

      case 'setAppBackgroundStatus':
        OpenIMFFI.instance.setAppBackgroundStatus(
          _stringArg(arguments, 'operationID'),
          Utils.toBool(arguments['isBackground']),
        );
        return NativeInvocation.pending(operationID);

      case 'setAppBadge':
        OpenIMFFI.instance.setAppBadge(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['count']),
        );
        return NativeInvocation.pending(operationID);

      case 'setConversation':
        OpenIMFFI.instance.setConversation(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          Utils.toJsonString(arguments['req']),
        );
        return NativeInvocation.pending(operationID);

      case 'setConversationDraft':
        OpenIMFFI.instance.setConversationDraft(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          _stringArg(arguments, 'draftText'),
        );
        return NativeInvocation.pending(operationID);

      case 'setGroupInfo':
        OpenIMFFI.instance.setGroupInfo(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['groupInfo']),
        );
        return NativeInvocation.pending(operationID);

      case 'setGroupMemberInfo':
        OpenIMFFI.instance.setGroupMemberInfo(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['info']),
        );
        return NativeInvocation.pending(operationID);

      case 'setMessageLocalEx':
        OpenIMFFI.instance.setMessageLocalEx(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'conversationID'),
          _stringArg(arguments, 'clientMsgID'),
          _stringArg(arguments, 'localEx'),
        );
        return NativeInvocation.pending(operationID);

      case 'setSelfInfo':
        OpenIMFFI.instance.setSelfInfo(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
        );
        return NativeInvocation.pending(operationID);

      case 'subscribeUsersStatus':
        OpenIMFFI.instance.subscribeUsersStatus(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['userIDs']),
        );
        return NativeInvocation.pending(operationID);

      case 'transferGroupOwner':
        OpenIMFFI.instance.transferGroupOwner(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'groupID'),
          _stringArg(arguments, 'userID'),
        );
        return NativeInvocation.pending(operationID);

      case 'typingStatusUpdate':
        OpenIMFFI.instance.typingStatusUpdate(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'userID'),
          _stringArg(arguments, 'msgTip'),
        );
        return NativeInvocation.pending(operationID);

      case 'unsubscribeUsersStatus':
        OpenIMFFI.instance.unsubscribeUsersStatus(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['userIDs']),
        );
        return NativeInvocation.pending(operationID);

      case 'uploadFile':
        OpenIMFFI.instance.uploadFile(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments),
          _stringArg(arguments, 'id'),
        );
        return NativeInvocation.pending(operationID);

      case 'uploadLogs':
        OpenIMFFI.instance.uploadLogs(
          _stringArg(arguments, 'operationID'),
          Utils.toInt(arguments['line']),
          _stringArg(arguments, 'ex'),
          _stringArg(arguments, 'id'),
        );
        return NativeInvocation.pending(operationID);

      case 'updateFcmToken':
        OpenIMFFI.instance.updateFcmToken(
          _stringArg(arguments, 'operationID'),
          _stringArg(arguments, 'fcmToken'),
          Utils.toInt(arguments['expireTime']),
        );
        return NativeInvocation.pending(operationID);

      case 'updateFriends':
        OpenIMFFI.instance.updateFriends(
          _stringArg(arguments, 'operationID'),
          Utils.toJsonString(arguments['req']),
        );
        return NativeInvocation.pending(operationID);

      case 'unInitSDK':
        EventBridge.instance.dispose();
        return NativeInvocation.completed(null);

      case 'setAdvancedMsgListener':
      case 'setConversationListener':
      case 'setCustomBusinessListener':
      case 'setFriendListener':
      case 'setGroupListener':
      case 'setListenerForService':
      case 'setUserListener':
        Logger.print(
          'Listener registration via FFI is handled natively; treating "$method" as a no-op.',
        );
        return NativeInvocation.completed(null);

      default:
        throw UnimplementedError('FFI method "$method" not implemented yet');
    }
  }

  static String? _stringArg(Map<String, dynamic> args, String key) =>
      Utils.stringValue(args[key]);
}
