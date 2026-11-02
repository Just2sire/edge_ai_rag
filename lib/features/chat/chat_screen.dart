import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_ai_kit/local_ai_kit.dart';
import 'package:path/path.dart' as p;

import '../../core/helpers/app_snack_bar.dart';
import '../../core/theme/app_theme.dart';
import '../documents/document_panel.dart';
import '../documents/models/indexed_doc.dart';
import '../documents/providers/documents_provider.dart';
import 'models/chat_message.dart';
import 'widgets/chat_empty_state.dart';
import 'widgets/chat_initialization_view.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';

/// Main conversation screen backed by the on-device RAG pipeline.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const List<ChatSuggestion> _suggestions = [
    ChatSuggestion(
      title: 'Le bornage',
      prompt: 'Qu\'est-ce que le bornage et ses objectifs ?',
      icon: Icons.gavel_rounded,
    ),
    ChatSuggestion(
      title: 'Mathématiques',
      prompt: 'Quelle est la dérivée de x² et la règle de la chaîne ?',
      icon: Icons.functions_rounded,
    ),
    ChatSuggestion(
      title: 'Démarche juridique',
      prompt: 'Explique la démarche juridique du bornage d\'un terrain.',
      icon: Icons.balance_rounded,
    ),
  ];

  LocalRag? _rag;
  LocalLlm? _llm;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];

  String _streaming = '';
  List<RetrievalResult> _streamingSources = [];
  DateTime _streamingStartedAt = DateTime.now();

  bool _isGenerating = false;
  bool _isReady = false;
  int _initStage = 0;
  String _initStatus = 'Ouverture de la base vectorielle…';
  String? _initError;

  bool _showScrollToBottom = false;
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _init();
  }

  Future<void> _init() async {
    if (mounted) {
      setState(() {
        _isReady = false;
        _initError = null;
        _initStage = 0;
        _initStatus = 'Ouverture de la base vectorielle…';
      });
    }

    try {
      await _llm?.dispose();
      await _rag?.dispose();
      _llm = null;
      _rag = null;

      final rag = LocalRag(
        const RagConfig(
          systemPrompt: 'Tu es un assistant pédagogique et technique. '
              'Réponds précisément en français en te basant exclusivement '
              'sur le contexte fourni. '
              'Si l\'information n\'est pas dans le contexte, indique-le '
              'honnêtement.',
          embedderProfileId: 'embeddinggemma-2-440m',
          topK: 4,
        ),
      );

      final llm = LocalLlm(
        systemPrompt: 'Tu es un assistant pédagogique et technique. '
            'Réponds précisément en français en te basant exclusivement '
            'sur le contexte fourni.',
      );

      _rag = rag;
      _llm = llm;

      await rag.init();
      if (!mounted) return;

      setState(() {
        _initStage = 1;
        _initStatus = 'Chargement du modèle de langage local…';
      });

      await llm.init();
      if (!mounted) return;

      setState(() {
        _initStage = 2;
        _initStatus = 'Préparation de l\'index de démonstration…';
      });

      await _seedDemoDocuments(rag);
      if (!mounted) return;

      setState(() {
        _initStage = 3;
        _isReady = true;
      });
    } catch (error) {
      debugPrint('❌ [INIT] $error');
      if (!mounted) return;
      setState(() => _initError = error.toString());
    }
  }

  Future<void> _seedDemoDocuments(LocalRag rag) async {
    final existingDocuments = ref.read(indexedDocumentsProvider);
    if (existingDocuments.isNotEmpty) return;

    await rag.addAll([
      const DocChunk(
        id: 'demo_bornage_chunk_0',
        text: 'Le bornage est une opération juridique et technique qui '
            'consiste à fixer et matérialiser les limites séparatives de '
            'deux terrains contigus.',
        metadata: {
          'source': 'guide_interne',
          'doc_id': 'demo_bornage',
          'sujet': 'bornage',
        },
      ),
      const DocChunk(
        id: 'demo_maths_chunk_0',
        text: 'La dérivée de x² est 2x. La règle de la chaîne permet de '
            'dériver des fonctions composées : si f(g(x)), alors '
            'f\'(g(x))×g\'(x). L\'intégrale de 2x est x² + C.',
        metadata: {
          'source': 'manuel_maths',
          'doc_id': 'demo_maths',
          'sujet': 'maths',
        },
      ),
    ]);

    ref.read(indexedDocumentsProvider.notifier).setInitialDocs([
      IndexedDocument(
        id: 'demo_bornage',
        name: 'Guide juridique : Le bornage.txt',
        extension: 'txt',
        chunkCount: 1,
        dateAdded: DateTime.now(),
        metadata: const {'source': 'guide_interne'},
        previewText: 'Le bornage est une opération juridique et technique...',
      ),
      IndexedDocument(
        id: 'demo_maths',
        name: 'Formulaire mathématiques.txt',
        extension: 'txt',
        chunkCount: 1,
        dateAdded: DateTime.now(),
        metadata: const {'source': 'manuel_maths'},
        previewText: 'La dérivée de x² est 2x. La règle de la chaîne...',
      ),
    ]);
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    final rag = _rag;
    final llm = _llm;

    if (question.isEmpty ||
        !_isReady ||
        _isGenerating ||
        rag == null ||
        llm == null) {
      return;
    }

    HapticFeedback.lightImpact();
    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(
        ChatMessage(
          isUser: true,
          text: question,
          timestamp: DateTime.now(),
        ),
      );
      _streaming = '';
      _streamingSources = [];
      _streamingStartedAt = DateTime.now();
      _isGenerating = true;
      _shouldAutoScroll = true;
    });

    _scrollToBottom(force: true);

    final stopwatch = Stopwatch()..start();
    var firstTokenReceived = false;
    var tokenCount = 0;
    var sources = <RetrievalResult>[];

    try {
      debugPrint('🔎 [RAG] Recherche : "$question"');

      final searchWatch = Stopwatch()..start();
      sources = await rag.search(question);
      searchWatch.stop();

      debugPrint(
        '✅ [RAG] ${sources.length} chunks récupérés en '
        '${searchWatch.elapsedMilliseconds} ms',
      );

      if (!mounted) return;

      setState(() => _streamingSources = sources);
      _scrollToBottom(force: true);

      debugPrint('🤖 [LLM] Début de la génération');
      final generationWatch = Stopwatch()..start();

      await for (final token in rag.queryStreamWithLlm(
        llm,
        question,
        results: sources,
      )) {
        if (!mounted) return;

        if (!firstTokenReceived) {
          firstTokenReceived = true;
          debugPrint(
            '⚡ [LLM] Premier token reçu après '
            '${generationWatch.elapsedMilliseconds} ms',
          );
        }

        tokenCount++;

        setState(() => _streaming += token);
        _scrollToBottom(animate: false);
      }

      generationWatch.stop();
      debugPrint(
        '✅ [LLM] Génération terminée : $tokenCount fragments, '
        '${_streaming.length} caractères, '
        '${generationWatch.elapsedMilliseconds} ms',
      );

      if (!mounted) return;

      final response = _streaming;
      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: response.isEmpty
                ? 'Le modèle n\'a généré aucune réponse. '
                    'Vérifiez les logs du moteur d\'inférence.'
                : response,
            sources: sources,
            timestamp: DateTime.now(),
          ),
        );
        _streaming = '';
        _streamingSources = [];
      });
    } catch (error, stackTrace) {
      debugPrint('❌ [CHAT] Erreur : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            isError: true,
            text: 'Une erreur est survenue pendant la génération.\n\n$error',
            timestamp: DateTime.now(),
          ),
        );
        _streaming = '';
        _streamingSources = [];
      });
    } finally {
      stopwatch.stop();
      debugPrint(
        '⏱️ [CHAT] Durée totale : ${stopwatch.elapsedMilliseconds} ms',
      );

      if (mounted) {
        setState(() => _isGenerating = false);
        _scrollToBottom(force: true);
      }
    }
  }

  Future<void> _quickAttachDocument() async {
    final rag = _rag;
    if (rag == null) return;

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'docx', 'md', 'json', 'csv'],
      );

      if (file == null || file.path == null) return;

      final filePath = file.path!;
      final fileName = file.name;
      final extension = p.extension(filePath).replaceAll('.', '').toLowerCase();
      final documentId =
          'doc_${p.basenameWithoutExtension(filePath).toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}_${DateTime.now().millisecondsSinceEpoch % 10000}';

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(minutes: 2),
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Extraction et indexation de $fileName…'),
              ),
            ],
          ),
        ),
      );

      const indexer = DocIndexer();
      final totalChunks = await indexer.indexDocumentFromFile(
        rag: rag,
        docId: documentId,
        filePath: filePath,
        metadata: {'source': extension, 'quick_upload': true},
      );

      final newDocument = IndexedDocument(
        id: documentId,
        name: fileName,
        extension: extension,
        chunkCount: totalChunks,
        dateAdded: DateTime.now(),
        metadata: {'source': extension},
      );

      ref.read(indexedDocumentsProvider.notifier).addDocument(newDocument);

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      AppSnackBar.success(
        context,
        '"$fileName" indexé · $totalChunks passages',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      AppSnackBar.error(context, 'Import impossible : $error');
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isNearBottom = position.maxScrollExtent - position.pixels < 140;
    _shouldAutoScroll = isNearBottom;

    if (_showScrollToBottom == isNearBottom) {
      setState(() => _showScrollToBottom = !isNearBottom);
    }
  }

  void _scrollToBottom({bool animate = true, bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (!force && !_shouldAutoScroll) return;

      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _showDocumentPanel() {
    final rag = _rag;
    if (rag == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentPanel(rag: rag),
    );
  }

  Future<void> _confirmClearConversation() async {
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Effacer la conversation ?'),
          content: const Text(
            'Tous les messages de cette session seront supprimés. '
            'Les documents indexés restent disponibles.',
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
              child: const Text('Effacer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _messages.clear();
      _streaming = '';
      _streamingSources = [];
    });

    if (!mounted) return;
    AppSnackBar.info(context, 'Conversation effacée');
  }

  void _sendSuggestion(String prompt) {
    _controller.text = prompt;
    _send();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _rag?.dispose();
    _llm?.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(indexedDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _AssistantStatusTitle(
          isReady: _isReady,
          isGenerating: _isGenerating,
          hasError: _initError != null,
          documentCount: documents.length,
          status: _initStatus,
        ),
        actions: [
          IconButton(
            tooltip: 'Documents indexés',
            onPressed: _isReady ? _showDocumentPanel : null,
            icon: Badge(
              isLabelVisible: documents.isNotEmpty,
              label: Text('${documents.length}'),
              child: const Icon(Icons.library_books_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Effacer la conversation',
            onPressed: _messages.isEmpty || _isGenerating
                ? null
                : _confirmClearConversation,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isReady
          ? _buildConversation(context, documents)
          : ChatInitializationView(
              status: _initStatus,
              stage: _initStage,
              error: _initError,
              onRetry: _init,
            ),
    );
  }

  Widget _buildConversation(
    BuildContext context,
    List<IndexedDocument> documents,
  ) {
    final hasMessages = _messages.isNotEmpty || _streaming.isNotEmpty;
    final showStreamingBubble = _isGenerating || _streaming.isNotEmpty;
    final messageCount = _messages.length + (showStreamingBubble ? 1 : 0);

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (!hasMessages && !_isGenerating)
                ChatEmptyState(
                  documents: documents,
                  suggestions: _suggestions,
                  onSuggestionSelected: _sendSuggestion,
                  onManageDocuments: _showDocumentPanel,
                )
              else
                ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messageCount,
                  itemBuilder: (context, index) {
                    final isStreamingItem = index == _messages.length;

                    final message = isStreamingItem
                        ? ChatMessage(
                            isUser: false,
                            text: _streaming,
                            sources: _streamingSources,
                            timestamp: _streamingStartedAt,
                          )
                        : _messages[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: MessageBubble(
                            key: ValueKey(
                              isStreamingItem
                                  ? 'streaming'
                                  : message.timestamp.microsecondsSinceEpoch,
                            ),
                            message: message,
                            isStreaming: isStreamingItem && _isGenerating,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (hasMessages || _isGenerating)
                Positioned(
                  right: 16,
                  bottom: 14,
                  child: _ScrollToBottomButton(
                    isVisible: _showScrollToBottom,
                    onPressed: () {
                      _shouldAutoScroll = true;
                      _scrollToBottom(force: true);
                    },
                  ),
                ),
            ],
          ),
        ),
        ChatInputBar(
          controller: _controller,
          focusNode: _focusNode,
          onSend: _send,
          onAttach: _quickAttachDocument,
          enabled: _isReady,
          isGenerating: _isGenerating,
        ),
      ],
    );
  }
}

/// Application bar title that reflects the assistant and index state.
class _AssistantStatusTitle extends StatelessWidget {
  const _AssistantStatusTitle({
    required this.isReady,
    required this.isGenerating,
    required this.hasError,
    required this.documentCount,
    required this.status,
  });

  final bool isReady;
  final bool isGenerating;
  final bool hasError;
  final int documentCount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final statusText = hasError
        ? 'Initialisation impossible'
        : !isReady
            ? status
            : isGenerating
                ? 'Génération en cours…'
                : documentCount == 0
                    ? 'Prêt · aucun document indexé'
                    : documentCount == 1
                        ? 'Prêt · 1 document indexé'
                        : 'Prêt · $documentCount documents indexés';

    final statusColor = hasError
        ? scheme.error
        : isGenerating
            ? AppColors.goldDeep
            : isReady
                ? scheme.tertiary
                : AppColors.gold;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 19,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assistant RAG',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Floating button that jumps back to the latest message.
class _ScrollToBottomButton extends StatelessWidget {
  const _ScrollToBottomButton({
    required this.isVisible,
    required this.onPressed,
  });

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: AnimatedScale(
          scale: isVisible ? 1 : 0.86,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            color: scheme.surfaceContainerLowest,
            shape: CircleBorder(
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: IconButton(
              tooltip: 'Revenir au dernier message',
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_downward_rounded, size: 20),
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
