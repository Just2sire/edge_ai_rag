import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:local_ai_kit/local_ai_kit.dart';

import '../../../core/helpers/app_snack_bar.dart';

/// Search tab used to inspect the passages retrieved for a question.
class DocumentSearchTab extends StatefulWidget {
  const DocumentSearchTab({super.key, required this.rag});

  /// Local index queried by the search field.
  final LocalRag rag;

  @override
  State<DocumentSearchTab> createState() => _DocumentSearchTabState();
}

class _DocumentSearchTabState extends State<DocumentSearchTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();

  List<RetrievalResult> _allResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int _topK = 4;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _topK = math.max(1, widget.rag.config.topK);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _isSearching) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _allResults = [];
    });

    try {
      final results = await widget.rag.search(query);
      if (!mounted) return;
      setState(() {
        _allResults = results;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      AppSnackBar.error(context, 'Recherche impossible : $error');
    }
  }

  void _useExample(String query) {
    _searchController.text = query;
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxResults = math.max(1, widget.rag.config.topK);
    final visibleResults = _allResults.take(_topK).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText: 'Ex. : Quelle est la dérivée de x² ?',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip: 'Rechercher',
                onPressed: _isSearching ? null : _performSearch,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          if (maxResults > 1)
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Passages affichés',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _topK.toDouble(),
                    min: 1,
                    max: maxResults.toDouble(),
                    divisions: maxResults - 1,
                    label: '$_topK',
                    onChanged: (value) {
                      setState(() => _topK = value.round());
                    },
                  ),
                ),
                Container(
                  width: 28,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$_topK',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          if (_isSearching)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _isSearching
                  ? const _SearchMessage(
                      key: ValueKey('loading'),
                      icon: Icons.hourglass_top_rounded,
                      title: 'Recherche vectorielle…',
                      message: 'Comparaison de votre question avec les '
                          'passages indexés.',
                    )
                  : visibleResults.isEmpty
                      ? _EmptySearchView(
                          key: ValueKey(
                            _hasSearched ? 'no-result' : 'idle',
                          ),
                          hasSearched: _hasSearched,
                          onExampleSelected: _useExample,
                        )
                      : ListView.separated(
                          key: const ValueKey('results'),
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: visibleResults.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _SearchResultCard(
                              result: visibleResults[index],
                              index: index + 1,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact card showing one retrieved passage and its similarity.
class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result, required this.index});

  final RetrievalResult result;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final similarity = result.similarity.clamp(0.0, 1.0);
    final percent = (similarity * 100).round();
    final content = result.content.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$index',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Passage $index',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$percent %',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: similarity,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.tag_rounded,
                  size: 12,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    result.id,
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
}

/// Default view with example queries before any search is run.
class _EmptySearchView extends StatelessWidget {
  const _EmptySearchView({
    super.key,
    required this.hasSearched,
    required this.onExampleSelected,
  });

  final bool hasSearched;
  final ValueChanged<String> onExampleSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (hasSearched) {
      return const _SearchMessage(
        icon: Icons.search_off_rounded,
        title: 'Aucun passage trouvé',
        message: 'Essayez une formulation plus courte ou importez un '
            'document sur le sujet.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.manage_search_rounded,
              size: 32,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Interrogez votre index',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Testez la recherche sémantique sans passer par le modèle '
            'de langage.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in const [
                'bornage',
                'dérivée',
                'règle de la chaîne',
              ])
                ActionChip(
                  label: Text(example),
                  onPressed: () => onExampleSelected(example),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Centered icon and text used for the search tab states.
class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
