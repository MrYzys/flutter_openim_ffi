<!--
Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
Created: 2025-09-26
License: AGPL-3.0-only (参见 LICENSE)
-->
# flutter_openim_ffi

基于 [OpenIM](https://www.openim.io/) 原生 SDK 的 Flutter FFI 封装。并通过 Dart FFI 提供与 OpenIM 数据契约一致的管理器、监听器和模型。

> 如果这个项目对你有帮助，请为仓库点一颗 ⭐️ Star，并分享给你的同事或朋友！

## 文档
- 英文版见 [README.md](README.md)
- 本文档为中文说明

## 功能特性
- 与 `flutter_openim_sdk` API 完全兼容，迁移成本极低。
- 覆盖 OpenIM `3.8.3+hotfix.3.1` 的会话、好友、群组、消息、用户等管理器能力。
- 通过 `EventBridge` 提供可插拔的监听体系（`OnConnectListener`、`OnAdvancedMsgListener` 等）。
- 提供纯 Dart 的确定性辅助函数（如会话排序），在未初始化原生 SDK 时提供兜底能力。

## 快速开始（使用方）
1. 在项目 `pubspec.yaml` 中添加依赖并执行 `flutter pub get`。
2. 在任何业务调用前初始化 SDK：

```dart
import 'package:flutter_openim_ffi/flutter_openim_ffi.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await OpenIM.iMManager.initSDK(
    platformID: IMPlatform.android,
    apiAddr: 'https://your-api-host',
    wsAddr: 'wss://your-ws-host',
    dataDir: '/path/to/cache',
    listener: MyConnectListener(),
  );

  runApp(const MyApp());
}

class MyConnectListener extends OnConnectListener {
  @override
  void connectSuccess() => debugPrint('OpenIM connected');

  @override
  void connectFailed(int? code, String? error) =>
      debugPrint('OpenIM connect failed [$code]: $error');
}
```

3. 通过 `OpenIM.iMManager` 暴露的各类管理器完成业务逻辑，例如在登录成功后获取个人信息：

```dart
final user = await OpenIM.iMManager.userManager.getSelfUserInfo();
debugPrint('Logged in as: ${user.nickName}');
```

示例应用 `example/` 展示了更多用法，包括未初始化原生层时的纯 Dart 兜底逻辑。

## 仓库结构
- `lib/`：对外暴露的 Dart API 以及自动生成的 FFI 绑定（仅修改手写部分）。
- `src/`：跨平台编译为 `openim_ffi` 共享库的原生源码和头文件，更新构建脚本时保持库名一致。
- `example/`：最小化示例工程，演示兜底逻辑和 API 的整体使用方式。
- `analysis_options.yaml` / `ffigen.yaml`：统一的静态检查与绑定生成配置。

## 开发流程
- 安装依赖：分别在仓库根目录与 `example/` 目录执行 `flutter pub get`。
- 代码格式化：提交前运行 `dart format .`。
- 静态分析：`flutter analyze` 必须全部通过且无告警。
- 测试：运行 `flutter test`（若需覆盖率数据，可追加 `--coverage`）。
- 示例验收：`cd example && flutter run -d <device>` 确认演示应用可正常启动。

## 重新生成 FFI 绑定
当原生头文件变动时，请重新生成 Dart 绑定，保持
`lib/openim_ffi_bindings_generated.dart` 与最新 C 定义一致：

```sh
dart run ffigen --config ffigen.yaml
```

## 原生构建说明
- 共享库由 `src/` 目录借助 CMake 构建，`android`、`ios`、`macos`、`linux`、`windows`
  目录提供平台适配层。
- 保持 `src/openim_ffi.h` 中导出符号与生成的 Dart 绑定一致，避免更改 `openim_ffi` 库名。
- 长耗时原生调用请放在后台 isolate 中执行，仿照示例中的 `sumAsync` 思路，确保 Flutter UI 顺滑。

## 贡献指南
遵循 `feat(lib): ...`、`fix(src): ...` 等提交规范，并在 PR 中附上 `flutter analyze`、
`flutter test` 以及示例运行的关键输出。若涉及 API 调整，请同步更新 Dart 封装、原生头文件
及示例应用。

## 作者信息
- 名称：河川
- GitHub：[@MrYzYs](https://github.com/MrYzYs)
- 主页：https://github.com/MrYzys?tab=repositories

## 许可策略
- 开源版本依据 [AGPL-3.0](https://www.gnu.org/licenses/agpl-3.0.html) 发布，对外提供服务或派生作品
  必须完整公开源代码及修改内容。
- 如需闭源分发、商业部署或获取官方支持，请联系维护者签署商业授权协议。未获授权的商业
  行为，或修改后未公开源代码即对外提供服务，将被依法追究责任。
