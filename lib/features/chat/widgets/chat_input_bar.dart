import 'package:flutter/material.dart';

/// Bottom composer used to type questions and attach documents.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.enabled,
    required this.isGenerating,
  });

  /// Text currently being written by the user.
  final TextEditingController controller;

  /// Focus node kept by the parent screen so the field can be refocused.
  final FocusNode focusNode;

  /// Called when the user submits a question.
  final VoidCallback onSend;

  /// Called when the user taps the attachment button.
  final VoidCallback onAttach;

  /// Whether the assistant is ready to accept a question.
  final bool enabled;

  /// Whether a response is currently being generated.
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: enabled && !isGenerating ? onAttach : null,
                        tooltip: 'Importer un document',
                        icon: const Icon(Icons.attach_file_rounded, size: 21),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(48, 48),
                          backgroundColor: scheme.surfaceContainerHigh,
                          disabledBackgroundColor:
                              scheme.surfaceContainerHigh.withValues(
                            alpha: 0.45,
                          ),
                          foregroundColor: scheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: enabled,
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: isGenerating
                                ? 'L\'assistant rédige une réponse…'
                                : 'Posez votre question…',
                            filled: true,
                            fillColor: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerLow,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide:
                                  BorderSide(color: scheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide:
                                  BorderSide(color: scheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 1.5,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SendButton(
                        controller: controller,
                        enabled: enabled,
                        isGenerating: isGenerating,
                        onSend: onSend,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Réponses générées sur l\'appareil · vérifiez les sources',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round action that sends the current question or shows generation progress.
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.controller,
    required this.enabled,
    required this.isGenerating,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isGenerating;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;
        final canSend = enabled && hasText && !isGenerating;

        return Semantics(
          button: true,
          enabled: canSend,
          label: isGenerating ? 'Génération en cours' : 'Envoyer le message',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: canSend ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: canSend
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.24),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: canSend ? onSend : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isGenerating
                        ? SizedBox(
                            key: const ValueKey('progress'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: scheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            key: const ValueKey('send'),
                            size: 22,
                            color: canSend
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
