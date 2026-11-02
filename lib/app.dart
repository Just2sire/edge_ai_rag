import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/chat_screen.dart';
import 'features/setup/setup_screen.dart';

/// Whether the on-device models are installed and ready to be used.
final modelsInstalledProvider = StateProvider<bool>((ref) => false);

/// Root widget of the application.
class EdgeAiTestApp extends ConsumerWidget {
  const EdgeAiTestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsReady = ref.watch(modelsInstalledProvider);

    return MaterialApp(
      title: 'Assistant RAG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: modelsReady
            ? const ChatScreen(key: ValueKey('chat'))
            : SetupScreen(
                key: const ValueKey('setup'),
                onDone: () {
                  ref.read(modelsInstalledProvider.notifier).state = true;
                },
              ),
      ),
    );
  }
}
