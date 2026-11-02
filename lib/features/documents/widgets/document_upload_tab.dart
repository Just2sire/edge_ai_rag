import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_ai_kit/local_ai_kit.dart';
import 'package:path/path.dart' as p;

import '../../../core/helpers/app_snack_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../models/indexed_doc.dart';
import '../providers/documents_provider.dart';
import 'file_type_badge.dart';

/// Import tab: pick a file, preview its text and index it in the local RAG.
class DocumentUploadTab extends ConsumerStatefulWidget {
  const DocumentUploadTab({
    super.key,
    required this.rag,
    required this.onIndexed,
  });

  /// Local index used to store the document chunks.
  final LocalRag rag;

  /// Called after a document has been successfully indexed.
  final VoidCallback onIndexed;

  @override
  ConsumerState<DocumentUploadTab> createState() => _DocumentUploadTabState();
}

class _DocumentUploadTabState extends ConsumerState<DocumentUploadTab>
    with AutomaticKeepAliveClientMixin {
  String? _selectedFilePath;
  String? _selectedFileName;
  int _selectedFileSize = 0;
  String _extractedText = '';
  bool _isExtracting = false;
  String? _extractionError;

  final _documentIdController = TextEditingController();
  final _metadataController = TextEditingController(
    text: '{"source": "user_upload"}',
  );
  final _targetCharsController = TextEditingController(text: '1800');
  final _overlapCharsController = TextEditingController(text: '200');

  ChunkingStrategy _strategy = ChunkingStrategy.paragraph;
  int _targetChars = 1800;
  int _overlapChars = 200;

  bool _isIndexing = false;
  double _indexProgress = 0;
  String _indexStatus = '';
  String? _indexError;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _documentIdController.dispose();
    _metadataController.dispose();
    _targetCharsController.dispose();
    _overlapCharsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'docx', 'md', 'json', 'csv'],
      );

      if (file == null || file.path == null) return;

      final filePath = file.path!;
      final fileSize = file.lengthSync() ?? await File(filePath).length();
      final fileName = file.name;
      final cleanId = p
          .basenameWithoutExtension(filePath)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_');

      setState(() {
        _selectedFilePath = filePath;
        _selectedFileName = fileName;
        _selectedFileSize = fileSize;
        _documentIdController.text =
            '${cleanId}_${DateTime.now().millisecondsSinceEpoch % 10000}';
        _isExtracting = true;
        _extractionError = null;
        _extractedText = '';
        _indexError = null;
        _indexStatus = '';
        _indexProgress = 0;
      });

      final text = await extractTextFromFile(filePath: filePath);
      if (!mounted) return;

      setState(() {
        _extractedText = text;
        _isExtracting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isExtracting = false;
        _extractionError = error.toString();
      });
    }
  }

  Future<void> _indexDocument() async {
    final filePath = _selectedFilePath;
    if (filePath == null || _extractedText.isEmpty) return;

    final documentId = _documentIdController.text.trim().isEmpty
        ? 'doc_${DateTime.now().millisecondsSinceEpoch}'
        : _documentIdController.text.trim();

    var customMetadata = <String, dynamic>{};
    final rawMetadata = _metadataController.text.trim();
    if (rawMetadata.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map<String, dynamic>) customMetadata = decoded;
      } catch (_) {
        customMetadata = {'raw_tag': rawMetadata};
      }
    }

    setState(() {
      _isIndexing = true;
      _indexProgress = 0;
      _indexStatus = 'Découpage et vectorisation du document…';
      _indexError = null;
    });

    try {
      final indexer = DocIndexer(
        chunker: TextChunker(
          targetChars: _targetChars,
          overlapChars: _overlapChars,
          strategy: _strategy,
        ),
      );

      final totalChunks = await indexer.indexDocumentFromFile(
        rag: widget.rag,
        docId: documentId,
        filePath: filePath,
        metadata: customMetadata,
        strategy: _strategy,
        targetChars: _targetChars,
        overlapChars: _overlapChars,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _indexProgress = total == 0 ? 0 : done / total;
            _indexStatus = 'Indexation du passage $done sur $total…';
          });
        },
      );

      final extension = p.extension(filePath).replaceAll('.', '').toLowerCase();
      final newDocument = IndexedDocument(
        id: documentId,
        name: _selectedFileName ?? documentId,
        extension: extension,
        chunkCount: totalChunks,
        dateAdded: DateTime.now(),
        metadata: customMetadata,
        previewText: _extractedText.length > 200
            ? '${_extractedText.substring(0, 200)}…'
            : _extractedText,
      );

      ref.read(indexedDocumentsProvider.notifier).addDocument(newDocument);

      if (!mounted) return;

      setState(() {
        _isIndexing = false;
        _indexProgress = 0;
        _indexStatus = '';
        _selectedFilePath = null;
        _selectedFileName = null;
        _selectedFileSize = 0;
        _extractedText = '';
        _documentIdController.clear();
      });

      AppSnackBar.success(
        context,
        '"${newDocument.name}" indexé · $totalChunks passages',
      );
      widget.onIndexed();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isIndexing = false;
        _indexError = error.toString();
        _indexStatus = '';
      });
      AppSnackBar.error(context, 'Indexation impossible : $error');
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _selectedFileSize = 0;
      _extractedText = '';
      _extractionError = null;
      _documentIdController.clear();
      _indexError = null;
      _indexStatus = '';
      _indexProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canIndex = !_isIndexing &&
        !_isExtracting &&
        _selectedFilePath != null &&
        _extractedText.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _UploadDropZone(
          isBusy: _isIndexing,
          onTap: _isIndexing ? null : _pickFile,
        ),
        if (_selectedFilePath != null) ...[
          const SizedBox(height: 12),
          _SelectedFileCard(
            filePath: _selectedFilePath!,
            fileName: _selectedFileName ?? '',
            fileSize: _selectedFileSize,
            extension: p.extension(_selectedFilePath!),
            isExtracting: _isExtracting,
            extractionError: _extractionError,
            extractedText: _extractedText,
            onClear: _isIndexing ? null : _clearSelection,
          ),
        ],
        const SizedBox(height: 12),
        _IndexingSettingsCard(
          documentIdController: _documentIdController,
          metadataController: _metadataController,
          targetCharsController: _targetCharsController,
          overlapCharsController: _overlapCharsController,
          strategy: _strategy,
          onStrategyChanged: (value) {
            if (value != null) setState(() => _strategy = value);
          },
          onTargetCharsChanged: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed > 50) _targetChars = parsed;
          },
          onOverlapCharsChanged: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed >= 0) _overlapChars = parsed;
          },
        ),
        if (_isIndexing) ...[
          const SizedBox(height: 14),
          _IndexingProgressCard(
            progress: _indexProgress,
            status: _indexStatus,
          ),
        ],
        if (_indexError != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 18, color: scheme.error),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _indexError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: canIndex ? _indexDocument : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 19),
          label: const Text('Découper et indexer'),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 12,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Les vecteurs restent stockés sur cet appareil.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Large tappable area inviting the user to choose a file.
class _UploadDropZone extends StatelessWidget {
  const _UploadDropZone({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: isBusy ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.55),
                  scheme.secondaryContainer.withValues(alpha: 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.ink,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choisir un fichier',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'PDF, DOCX, TXT, MD, JSON, CSV',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
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

/// Summary of the picked file with its extracted text preview.
class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.extension,
    required this.isExtracting,
    required this.extractionError,
    required this.extractedText,
    required this.onClear,
  });

  final String filePath;
  final String fileName;
  final int fileSize;
  final String extension;
  final bool isExtracting;
  final String? extractionError;
  final String extractedText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cleanExtension = extension.replaceAll('.', '').toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FileTypeBadge(extension: extension, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatFileSize(fileSize)} · $cleanExtension',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Retirer le fichier',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 19),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 20),
            if (isExtracting)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Extraction du texte…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else if (extractionError != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 17,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Extraction impossible : $extractionError',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: scheme.tertiary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${extractedText.length} caractères · '
                    '~${(extractedText.length / 4.5).round()} tokens',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 116,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? scheme.surfaceContainerLowest
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    extractedText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Taille inconnue';
    if (bytes < 1024) return '$bytes o';

    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} Ko';

    return '${(kilobytes / 1024).toStringAsFixed(1)} Mo';
  }
}

/// Collapsible chunking and metadata options.
class _IndexingSettingsCard extends StatelessWidget {
  const _IndexingSettingsCard({
    required this.documentIdController,
    required this.metadataController,
    required this.targetCharsController,
    required this.overlapCharsController,
    required this.strategy,
    required this.onStrategyChanged,
    required this.onTargetCharsChanged,
    required this.onOverlapCharsChanged,
  });

  final TextEditingController documentIdController;
  final TextEditingController metadataController;
  final TextEditingController targetCharsController;
  final TextEditingController overlapCharsController;
  final ChunkingStrategy strategy;
  final ValueChanged<ChunkingStrategy?> onStrategyChanged;
  final ValueChanged<String> onTargetCharsChanged;
  final ValueChanged<String> onOverlapCharsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          title: Text(
            'Paramètres d\'indexation',
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            'Découpage, identifiant et métadonnées',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 19,
              color: scheme.onSurfaceVariant,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  TextField(
                    controller: documentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant du document',
                      helperText: 'Préfixe des passages dans l\'index',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ChunkingStrategy>(
                    initialValue: strategy,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Stratégie de découpage',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ChunkingStrategy.paragraph,
                        child: Text('Par paragraphes (recommandé)'),
                      ),
                      DropdownMenuItem(
                        value: ChunkingStrategy.fixedSize,
                        child: Text('Taille fixe avec chevauchement'),
                      ),
                    ],
                    onChanged: onStrategyChanged,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: targetCharsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Cible',
                            suffixText: 'car.',
                            isDense: true,
                          ),
                          onChanged: onTargetCharsChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: overlapCharsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Chevauchement',
                            suffixText: 'car.',
                            isDense: true,
                          ),
                          onChanged: onOverlapCharsChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: metadataController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Métadonnées (JSON)',
                      hintText: '{"rubrique": "finance"}',
                      helperText: 'Facultatif, pour filtrer vos recherches',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress feedback shown while chunks are written to the index.
class _IndexingProgressCard extends StatelessWidget {
  const _IndexingProgressCard({
    required this.progress,
    required this.status,
  });

  final double progress;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$percent %',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
