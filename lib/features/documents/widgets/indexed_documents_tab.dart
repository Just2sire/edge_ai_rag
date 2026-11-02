import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_ai_kit/local_ai_kit.dart';

import '../../../core/helpers/app_snack_bar.dart';
import '../models/indexed_doc.dart';
import '../providers/documents_provider.dart';
import 'file_type_badge.dart';

/// Lists every document currently stored in the local vector index.
class IndexedDocumentsTab extends ConsumerWidget {
  const IndexedDocumentsTab({
    super.key,
    required this.rag,
    required this.onImportRequested,
  });

  /// Local index the documents belong to.
  final LocalRag rag;

  /// Switches the sheet to the import tab.
  final VoidCallback onImportRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(indexedDocumentsProvider);

    if (documents.isEmpty) {
      return _EmptyLibraryView(onImportRequested: onImportRequested);
    }

    final totalChunks = documents.fold<int>(
      0,
      (total, document) => total + document.chunkCount,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.description_outlined,
                value: '${documents.length}',
                label: documents.length == 1 ? 'Document' : 'Documents',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                icon: Icons.layers_outlined,
                value: '$totalChunks',
                label: totalChunks == 1 ? 'Passage' : 'Passages',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _StatTile(
                icon: Icons.offline_bolt_outlined,
                value: 'Local',
                label: 'Hors ligne',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Documents indexés',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < documents.length; index++) ...[
          _DocumentCard(
            document: documents[index],
            onDelete: () => _confirmDelete(
              context,
              ref,
              documents[index],
            ),
          ),
          if (index != documents.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    IndexedDocument document,
  ) async {
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer ce document ?'),
          content: Text(
            'Les ${document.chunkCount} passages de "${document.name}" '
            'seront retirés de l\'index local.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      const indexer = DocIndexer();
      await indexer.removeDocument(rag, document.id, document.chunkCount);

      if (!context.mounted) return;
      ref.read(indexedDocumentsProvider.notifier).removeDocument(document.id);
      AppSnackBar.success(context, '"${document.name}" supprimé de l\'index');
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Suppression impossible : $error');
    }
  }
}

/// Small metric card used in the library header.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// One indexed document with its metadata and delete action.
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.onDelete});

  final IndexedDocument document;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FileTypeBadge(extension: document.extension, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.chunkCount} passage'
                        '${document.chunkCount == 1 ? '' : 's'} · '
                        '${_formatDate(document.dateAdded)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer le document',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: scheme.error,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (document.previewText != null) ...[
              const SizedBox(height: 10),
              Text(
                document.previewText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    document.extension.replaceAll('.', '').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.tag_rounded,
                  size: 12,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    document.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;

    if (difference == 0) return 'aujourd\'hui';
    if (difference == 1) return 'hier';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Empty state inviting the user to import a first document.
class _EmptyLibraryView extends StatelessWidget {
  const _EmptyLibraryView({required this.onImportRequested});

  final VoidCallback onImportRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 36,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Votre bibliothèque est vide',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 7),
            Text(
              'Importez un document pour que l\'assistant puisse '
              's\'appuyer sur vos connaissances locales.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onImportRequested,
              icon: const Icon(Icons.upload_file_rounded, size: 19),
              label: const Text('Importer un document'),
            ),
          ],
        ),
      ),
    );
  }
}
