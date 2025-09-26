// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
import 'package:flutter/material.dart';
import 'package:flutter_openim_ffi/flutter_openim_ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<_DemoResult> _demoFuture;

  @override
  void initState() {
    super.initState();
    _demoFuture = _runDemoScripts();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter OpenIM FFI Demo')),
        body: FutureBuilder<_DemoResult>(
          future: _demoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Demo failed: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }
            final result = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Conversation sorting (pure Dart utility):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(result.sortedConversationIDs.join(' → ')),
                const SizedBox(height: 24),
                const Text(
                  'Fallback getConversationRecvMessageOpt (empty list):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(result.recvMessageOpt.toString()),
                const SizedBox(height: 24),
                const Text(
                  'Fallback getUserStatus (empty list):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(result.userStatuses.toString()),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<_DemoResult> _runDemoScripts() async {
    // Demonstrate the pure Dart helpers.
    final conversations = [
      ConversationInfo(
        conversationID: 'beta',
        latestMsgSendTime: 25,
        draftTextTime: 10,
        isPinned: false,
        isNotInGroup: false,
      ),
      ConversationInfo(
        conversationID: 'alpha',
        latestMsgSendTime: 40,
        draftTextTime: 0,
        isPinned: true,
        isNotInGroup: false,
      ),
      ConversationInfo(
        conversationID: 'gamma',
        latestMsgSendTime: 5,
        draftTextTime: 30,
        isPinned: false,
        isNotInGroup: false,
      ),
    ];

    final sorted = OpenIM.iMManager.conversationManager.simpleSort(
      List.of(conversations),
    );

    // Demonstrate FFI fallbacks that safely short-circuit without an initialised SDK.
    final recvOpt = await OpenIM.iMManager.conversationManager
        .getConversationRecvMessageOpt(
          conversationIDList: const [],
          operationID: 'example-demo',
        );

    final statuses = await OpenIM.iMManager.userManager.getUserStatus(
      const [],
      operationID: 'example-demo',
    );

    return _DemoResult(
      sortedConversationIDs:
          sorted.map((conversation) => conversation.conversationID).toList(),
      recvMessageOpt: recvOpt,
      userStatuses: statuses,
    );
  }
}

class _DemoResult {
  _DemoResult({
    required this.sortedConversationIDs,
    required this.recvMessageOpt,
    required this.userStatuses,
  });

  final List<String> sortedConversationIDs;
  final List<dynamic> recvMessageOpt;
  final List<UserStatusInfo> userStatuses;
}
