<!--
Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
Created: 2025-09-26
License: AGPL-3.0-only (see LICENSE)
-->
# flutter_openim_ffi

Flutter FFI bindings for the [OpenIM](https://www.openim.io/) native SDK. The package exposes a typed Dart API with manager classes, listeners, and
utility models that align with the upstream OpenIM data contracts.

> If this project helps you, please ⭐️ star the repository and share it with your team!

## Documentation
- English (this document)
- 中文版请见 [README-zh.md](README-zh.md)

## Features
- Fully compatible with the `flutter_openim_sdk` API surface, keeping migration friction low.
- Dart-first façade for OpenIM `3.8.3+hotfix.3.1`, including conversation, friendship, group,
  message, and user managers.
- Pluggable listener system that forwards native events (`OnConnectListener`,
  `OnAdvancedMsgListener`, etc.) through `EventBridge`.
- Pure-Dart helpers for deterministic operations such as conversation sorting, used as fallbacks
  when the native SDK is unavailable (see the example app).

## Getting Started (consumer view)
1. Add the dependency to your `pubspec.yaml` and run `flutter pub get`.
2. Initialize the SDK before making API calls:

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

3. Interact with the managers exposed through `OpenIM.iMManager`. For example, to fetch the current
   user information after a successful `login` call:

```dart
final user = await OpenIM.iMManager.userManager.getSelfUserInfo();
debugPrint('Logged in as: ${user.nickName}');
```

The `example/` application demonstrates additional usage patterns, including the pure-Dart
fallback utilities that keep the UI responsive when the native layer has not been initialised.

## Repository Layout
- `lib/`: Public Dart API surface and generated FFI bindings (only edit hand-written files).
- `src/`: Native sources and headers compiled into the `openim_ffi` shared library across all
  supported platforms. Keep the library name stable when updating build scripts.
- `example/`: Minimal Flutter client that mirrors the exposed API and exercises the fallback logic.
- `analysis_options.yaml` / `ffigen.yaml`: Lint and binding configuration single sources of truth.

## Development Workflow
- Install dependencies: run `flutter pub get` in the repository root **and** in `example/`.
- Format code: `dart format .` (run before sending changes for review).
- Static analysis: `flutter analyze` must pass with zero warnings.
- Tests: `flutter test` (add `--coverage` when gathering coverage reports).
- Example smoke test: `cd example && flutter run -d <device>` to ensure the demo still launches.

## Regenerating FFI Bindings
When native headers change, regenerate the Dart bindings so that
`lib/openim_ffi_bindings_generated.dart` matches the latest C definitions:

```sh
dart run ffigen --config ffigen.yaml
```

## Native Build Notes
- The shared library is produced from `src/` using CMake (`android`, `ios`, `macos`, `linux`, and
  `windows` host the platform-specific glue).
- Keep the exported symbols aligned with `src/openim_ffi.h` and the generated bindings. Avoid
  renaming the library away from `openim_ffi`, as the Flutter loader and platform projects expect
  that identifier.
- Prefer running long-running native calls on background isolates so the Flutter UI thread stays
  responsive; the FFI managers already expose helpers that can be called from worker isolates.

## Contributing
Follow the commit convention (`feat(lib): ...`, `fix(src): ...`, etc.) and attach console output for
`flutter analyze`, `flutter test`, and any example runs in pull requests. Coordinate API changes with
updates to both the Dart wrapper and the native headers, and keep the example app in sync with new
features.

## Author
- Name: 河川
- GitHub: [MrYzYs](https://github.com/MrYzYs)
- Homepage: https://github.com/MrYzys?tab=repositories

## License Strategy
- The open-source edition is released under [AGPL-3.0](https://www.gnu.org/licenses/agpl-3.0.html).
  Derived works or hosted services must publish their complete source code and modifications.
- Reach out to the maintainer for a commercial agreement if you need closed-source distribution,
  commercial deployment, or official support packages. Commercial use without explicit approval
  constitutes a violation and will trigger legal action.
