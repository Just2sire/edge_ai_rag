import 'package:flutter/material.dart';

/// Shows short, consistent feedback messages above the bottom of the screen.
abstract final class AppSnackBar {
  /// Displays a confirmation message, typically after a successful action.
  static void success(BuildContext context, String message) {
    _show(context, message, icon: Icons.check_circle_rounded);
  }

  /// Displays a failure message when an action could not be completed.
  static void error(BuildContext context, String message) {
    _show(context, message, icon: Icons.error_outline_rounded);
  }

  /// Displays a neutral piece of information.
  static void info(BuildContext context, String message) {
    _show(context, message, icon: Icons.info_outline_rounded);
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.inversePrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
