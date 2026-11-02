import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../../core/theme/app_theme.dart';

/// First-launch screen that downloads the on-device models.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onDone});

  /// Called once both models are installed and ready to use.
  final VoidCallback onDone;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isInstalling = false;
  int _languageModelProgress = 0;
  int _embedderProgress = 0;
  String _status = '';
  String? _error;

  Future<void> _install() async {
    setState(() {
      _isInstalling = true;
      _error = null;
      _languageModelProgress = 0;
      _embedderProgress = 0;
      _status = 'Téléchargement du modèle de langage…';
    });

    try {
      await FlutterEdgeAi.installModel(
        modelType: ModelType.qwen,
        fileType: ModelFileType.litertlm,
      )
          .fromHuggingFace(
        'litert-community/Qwen2.5-1.5B-Instruct',
        file: 'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm',
      )
          .withProgress((progress) {
        if (!mounted) return;
        setState(() => _languageModelProgress = progress);
      }).install();

      if (!mounted) return;

      setState(() {
        _languageModelProgress = 100;
        _status = 'Téléchargement de l\'embedder…';
      });

      const embedderUrl = 'https://huggingface.co/litert-community/'
          'embeddinggemma-2-text-vision-440m-litert-lm/'
          'resolve/e301f74d5551b0c2641bd5cb4652a76239d5c5f8/'
          'embeddinggemma-2-text-vision-440m.litertlm';

      await FlutterEdgeAi.installEmbedder()
          .modelFromNetwork(embedderUrl)
          .withModelProgress((progress) {
        if (!mounted) return;
        setState(() => _embedderProgress = progress);
      }).install();

      if (!mounted) return;

      setState(() {
        _embedderProgress = 100;
        _status = 'Installation terminée';
      });

      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInstalling = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: _GlowOrb(
              size: 330,
              color: AppColors.gold.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _GlowOrb(
              size: 320,
              color: scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.05,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight - 56),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _SetupLogo(),
                            const SizedBox(height: 22),
                            Text(
                              'Votre assistant, 100 % local',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Téléchargez les modèles une seule fois. '
                              'Ensuite, tout fonctionne hors ligne, '
                              'directement sur votre appareil.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const _FeatureCard(),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: _error != null
                                  ? _SetupErrorCard(
                                      key: const ValueKey('error'),
                                      error: _error!,
                                      onRetry: _install,
                                    )
                                  : _isInstalling
                                      ? _DownloadProgressCard(
                                          key: const ValueKey('progress'),
                                          status: _status,
                                          languageModelProgress:
                                              _languageModelProgress,
                                          embedderProgress: _embedderProgress,
                                        )
                                      : _DownloadCard(
                                          key: const ValueKey('ready'),
                                          onInstall: _install,
                                        ),
                            ),
                            const SizedBox(height: 20),
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
                                    'Propulsé par LiteRT-LM · aucune donnée '
                                    'envoyée à un serveur',
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
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft colored circle used as a background accent.
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Application mark displayed above the welcome title.
class _SetupLogo extends StatelessWidget {
  const _SetupLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 38,
        color: AppColors.ink,
      ),
    );
  }
}

/// Privacy and capability summary shown during onboarding.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            _FeatureRow(
              icon: Icons.shield_outlined,
              title: 'Confidentialité totale',
              description:
                  'Vos documents et questions restent sur l\'appareil.',
            ),
            Divider(height: 1),
            _FeatureRow(
              icon: Icons.wifi_off_rounded,
              title: 'Fonctionne hors ligne',
              description: 'Aucune connexion requise après le téléchargement.',
            ),
            Divider(height: 1),
            _FeatureRow(
              icon: Icons.auto_awesome_mosaic_outlined,
              title: 'Réponses sourcées',
              description: 'Chaque réponse cite les passages utilisés.',
            ),
          ],
        ),
      ),
    );
  }
}

/// One benefit line of the onboarding card.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card listing the models and the download action.
class _DownloadCard extends StatelessWidget {
  const _DownloadCard({super.key, required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Modèles requis',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '~2 Go',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _ModelInfoRow(
              icon: Icons.memory_rounded,
              name: 'Qwen 2.5 · 1.5B',
              description: 'Génération des réponses',
              size: '~1,5 Go',
            ),
            const Divider(height: 1),
            const _ModelInfoRow(
              icon: Icons.hub_rounded,
              name: 'EmbeddingGemma · 440M',
              description: 'Recherche sémantique',
              size: '~0,5 Go',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onInstall,
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text('Télécharger les modèles'),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_rounded,
                  size: 12,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Wi-Fi recommandé · téléchargement unique',
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
        ),
      ),
    );
  }
}

/// Name and size of one model to download.
class _ModelInfoRow extends StatelessWidget {
  const _ModelInfoRow({
    required this.icon,
    required this.name,
    required this.description,
    required this.size,
  });

  final IconData icon;
  final String name;
  final String description;
  final String size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            size,
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

/// Card showing download progress for both models.
class _DownloadProgressCard extends StatelessWidget {
  const _DownloadProgressCard({
    super.key,
    required this.status,
    required this.languageModelProgress,
    required this.embedderProgress,
  });

  final String status;
  final int languageModelProgress;
  final int embedderProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ModelProgressRow(
              name: 'Qwen 2.5 · 1.5B',
              progress: languageModelProgress,
            ),
            const SizedBox(height: 14),
            _ModelProgressRow(
              name: 'EmbeddingGemma · 440M',
              progress: embedderProgress,
            ),
            const SizedBox(height: 12),
            Text(
              'Ne fermez pas l\'application pendant l\'installation.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One model line with its progress bar and percentage.
class _ModelProgressRow extends StatelessWidget {
  const _ModelProgressRow({required this.name, required this.progress});

  final String name;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isComplete = progress >= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isComplete ? Icons.check_circle_rounded : Icons.download_rounded,
              size: 15,
              color: isComplete ? scheme.tertiary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              isComplete ? 'Terminé' : '$progress %',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isComplete ? scheme.tertiary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress / 100 : null,
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

/// Failure card shown when a download cannot be completed.
class _SetupErrorCard extends StatelessWidget {
  const _SetupErrorCard({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: scheme.error,
              ),
              const SizedBox(width: 9),
              Text(
                'Téléchargement interrompu',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez votre connexion, puis relancez le téléchargement. '
            'Les fichiers déjà récupérés sont conservés.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFamily: 'monospace',
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
