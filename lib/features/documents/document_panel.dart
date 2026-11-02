import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_ai_kit/local_ai_kit.dart';

import '../../core/theme/app_theme.dart';
import 'providers/documents_provider.dart';
import 'widgets/document_search_tab.dart';
import 'widgets/document_upload_tab.dart';
import 'widgets/indexed_documents_tab.dart';

/// Bottom sheet that groups document import, library and search tools.
class DocumentPanel extends ConsumerStatefulWidget {
  const DocumentPanel({super.key, required this.rag});

  /// Local index shared with the conversation screen.
  final LocalRag rag;

  @override
  ConsumerState<DocumentPanel> createState() => _DocumentPanelState();
}

class _DocumentPanelState extends ConsumerState<DocumentPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(indexedDocumentsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.size.height;
        final panelHeight = math.max(
          0.0,
          (availableHeight - media.viewInsets.bottom) * 0.94,
        );

        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: panelHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    top: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    const _SheetHandle(),
                    _PanelHeader(
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    _PanelTabBar(
                      controller: _tabController,
                      documentCount: documents.length,
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          DocumentUploadTab(
                            rag: widget.rag,
                            onIndexed: () => _tabController.animateTo(1),
                          ),
                          IndexedDocumentsTab(
                            rag: widget.rag,
                            onImportRequested: () {
                              _tabController.animateTo(0);
                            },
                          ),
                          DocumentSearchTab(rag: widget.rag),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small pill at the top of the sheet indicating it can be dragged.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Title block of the document sheet.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 12, 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.26),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 20,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bibliothèque',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 1),
                Text(
                  'Import, index et recherche locale',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHigh,
              foregroundColor: scheme.onSurfaceVariant,
              fixedSize: const Size(38, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented tab bar used to move between the three sheet sections.
class _PanelTabBar extends StatelessWidget {
  const _PanelTabBar({
    required this.controller,
    required this.documentCount,
  });

  final TabController controller;
  final int documentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          const Tab(
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file_rounded, size: 17),
                  SizedBox(width: 6),
                  Text('Importer'),
                ],
              ),
            ),
          ),
          Tab(
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_outlined, size: 17),
                  const SizedBox(width: 6),
                  const Text('Indexés'),
                  if (documentCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$documentCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Tab(
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, size: 17),
                  SizedBox(width: 6),
                  Text('Recherche'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
