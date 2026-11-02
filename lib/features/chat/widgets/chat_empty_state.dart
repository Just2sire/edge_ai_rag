import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../documents/models/indexed_doc.dart';

/// A question proposed to the user when the conversation is empty.
class ChatSuggestion {
  const ChatSuggestion({
    required this.title,
    required this.prompt,
    required this.icon,
  });

  /// Short label describing the topic.
  final String title;

  /// Full question sent to the assistant when the card is tapped.
  final String prompt;

  /// Icon illustrating the topic.
  final IconData icon;
}

/// Welcome view displayed before the first question is asked.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.documents,
    required this.suggestions,
    required this.onSuggestionSelected,
    required this.onManageDocuments,
  });

  /// Documents currently indexed on the device.
  final List<IndexedDocument> documents;

  /// Example questions offered to the user.
  final List<ChatSuggestion> suggestions;

  /// Called with the full prompt of the selected suggestion.
  final ValueChanged<String> onSuggestionSelected;

  /// Opens the document management sheet.
  final VoidCallback onManageDocuments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDocuments = documents.isNotEmpty;
    final totalChunks = documents.fold<int>(
      0,
      (total, document) => total + document.chunkCount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 56),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _HeroMark(),
                      const SizedBox(height: 22),
                      Text(
                        hasDocuments
                            ? 'Que souhaitez-vous explorer ?'
                            : 'Ajoutez votre premier document',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasDocuments
                            ? 'Votre assistant analyse les passages pertinents '
                                'de vos documents avant de répondre. Tout reste '
                                'sur cet appareil.'
                            : 'Importez un PDF, un document Word ou un fichier '
                                'texte pour construire votre base de '
                                'connaissances locale.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(
                            icon: Icons.description_outlined,
                            label: documents.length == 1
                                ? '1 document'
                                : '${documents.length} documents',
                          ),
                          _MetaPill(
                            icon: Icons.layers_outlined,
                            label: totalChunks == 1
                                ? '1 passage'
                                : '$totalChunks passages',
                          ),
                          const _MetaPill(
                            icon: Icons.lock_outline_rounded,
                            label: '100 % local',
                          ),
                        ],
                      ),
                      if (hasDocuments) ...[
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Text(
                              'Suggestions',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Touchez pour envoyer',
                                maxLines: 1,
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var index = 0;
                            index < suggestions.length;
                            index++) ...[
                          _SuggestionCard(
                            suggestion: suggestions[index],
                            onTap: () => onSuggestionSelected(
                              suggestions[index].prompt,
                            ),
                          ),
                          if (index != suggestions.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                      const SizedBox(height: 28),
                      hasDocuments
                          ? OutlinedButton.icon(
                              onPressed: onManageDocuments,
                              icon: const Icon(
                                Icons.library_books_outlined,
                                size: 19,
                              ),
                              label: const Text('Gérer les documents'),
                            )
                          : FilledButton.icon(
                              onPressed: onManageDocuments,
                              icon: const Icon(
                                Icons.upload_file_rounded,
                                size: 19,
                              ),
                              label: const Text('Importer un document'),
                            ),
                    ],
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

/// Golden badge and soft halo that open the welcome view.
class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
              ),
            ),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.38),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 34,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded label showing an index statistic.
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable card that sends a prewritten question.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onTap});

  final ChatSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? scheme.surfaceContainerLow
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    suggestion.icon,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        suggestion.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
