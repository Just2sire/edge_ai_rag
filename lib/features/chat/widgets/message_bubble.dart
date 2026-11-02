import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import 'source_card.dart';
import 'typing_indicator.dart';

/// A conversation bubble with its assistant header, actions and sources.
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  /// Message displayed inside the bubble.
  final ChatMessage message;

  /// Whether tokens are still being appended to [message].
  final bool isStreaming;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _copyResetTimer;
  bool _sourcesExpanded = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = curved;
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.03 : -0.02, 0.05),
      end: Offset.zero,
    ).animate(curved);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _copyMessage() async {
    await Clipboard.setData(ClipboardData(text: widget.message.text));
    if (!mounted) return;

    HapticFeedback.selectionClick();
    setState(() => _copied = true);

    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final maxBubbleWidth = math.min(
      680.0,
      MediaQuery.sizeOf(context).width * 0.84,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _AssistantHeader(
                  timestamp: message.timestamp,
                  isError: message.isError,
                ),
                const SizedBox(height: 7),
              ],
              Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? (isDark
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFD873), Color(0xFFE0A21B)],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2B2E38), AppColors.ink],
                              ))
                        : null,
                    color: isUser
                        ? null
                        : message.isError
                            ? scheme.error.withValues(alpha: 0.07)
                            : (isDark
                                ? scheme.surfaceContainerLow
                                : Colors.white),
                    border: isUser
                        ? null
                        : Border.all(
                            color: message.isError
                                ? scheme.error.withValues(alpha: 0.45)
                                : scheme.outlineVariant,
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? scheme.primary.withValues(alpha: 0.12)
                            : Colors.black.withValues(
                                alpha: isDark ? 0.16 : 0.035,
                              ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildBubbleContent(
                    context: context,
                    isUser: isUser,
                    isDark: isDark,
                  ),
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (!isUser && !widget.isStreaming && message.text.isNotEmpty)
                _buildActions(context),
              if (!isUser && message.sources.isNotEmpty)
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: _sourcesExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.min(
                                680.0,
                                MediaQuery.sizeOf(context).width * 0.88,
                              ),
                            ),
                            child: Column(
                              children: [
                                for (var index = 0;
                                    index < message.sources.length;
                                    index++)
                                  SourceCard(
                                    source: message.sources[index],
                                    index: index + 1,
                                  ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent({
    required BuildContext context,
    required bool isUser,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14.5,
      height: 1.55,
      color: textColor,
    );

    if (widget.isStreaming && widget.message.text.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: TypingIndicator(),
      );
    }

    return SelectableText.rich(
      TextSpan(
        text: widget.message.text,
        children: [
          if (widget.isStreaming)
            TextSpan(
              text: '▌',
              style: TextStyle(
                color: isUser
                    ? scheme.onPrimary.withValues(alpha: 0.85)
                    : scheme.primary,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      style: textStyle,
    );
  }

  Widget _buildActions(BuildContext context) {
    final message = widget.message;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sourceCount = message.sources.length;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _BubbleAction(
            icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
            label: _copied ? 'Copié' : 'Copier',
            isActive: _copied,
            onTap: _copyMessage,
          ),
          if (sourceCount > 0)
            _BubbleAction(
              icon: Icons.auto_awesome_mosaic_outlined,
              label: sourceCount == 1
                  ? '1 passage utilisé'
                  : '$sourceCount passages utilisés',
              isActive: _sourcesExpanded,
              trailing: AnimatedRotation(
                turns: _sourcesExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _sourcesExpanded
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                setState(() => _sourcesExpanded = !_sourcesExpanded);
              },
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

/// Name, avatar and timestamp displayed above an assistant bubble.
class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    required this.timestamp,
    required this.isError,
  });

  final DateTime timestamp;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isError ? null : AppColors.goldGradient,
            color: isError ? scheme.errorContainer : null,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
            size: 14,
            color: isError ? scheme.onErrorContainer : AppColors.ink,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'Assistant RAG',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 7),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: scheme.outline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          isError ? 'Erreur' : _MessageBubbleState._formatTime(timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isError ? scheme.error : scheme.onSurfaceVariant,
            fontWeight: isError ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Compact text action displayed below an assistant bubble.
class _BubbleAction extends StatelessWidget {
  const _BubbleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
