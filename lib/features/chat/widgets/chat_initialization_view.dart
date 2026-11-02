import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Loading and failure view shown while the local RAG engine starts.
class ChatInitializationView extends StatelessWidget {
  const ChatInitializationView({
    super.key,
    required this.status,
    required this.stage,
    required this.error,
    required this.onRetry,
  });

  /// Human readable description of the current initialization step.
  final String status;

  /// Number of completed initialization stages, from 0 to 3.
  final int stage;

  /// Error message when startup failed, null while loading.
  final String? error;

  /// Retries the initialization sequence.
  final VoidCallback onRetry;

  static const List<String> _steps = [
    'Base vectorielle',
    'Modèle de langage',
    'Index des documents',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 56),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: error == null
                      ? _buildLoading(context, theme, scheme)
                      : _buildError(context, theme, scheme),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildLoading(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return [
      const _PulsingLogo(),
      const SizedBox(height: 28),
      Text(
        'Préparation de l\'assistant',
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 9),
      Text(
        status,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(minHeight: 5),
        ),
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          children: [
            for (var index = 0; index < _steps.length; index++) ...[
              _StepRow(
                label: _steps[index],
                isDone: stage > index,
                isActive: stage == index,
              ),
              if (index != _steps.length - 1) const SizedBox(height: 13),
            ],
          ],
        ),
      ),
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Aucune donnée ne quitte votre appareil.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildError(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return [
      Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error_outline_rounded,
          size: 38,
          color: scheme.onErrorContainer,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Le moteur local n\'a pas pu démarrer',
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 9),
      Text(
        'Vérifiez que les modèles sont bien installés, puis réessayez.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          error ?? '',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ),
      const SizedBox(height: 22),
      FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 19),
        label: const Text('Réessayer'),
      ),
    ];
  }
}

/// Gently breathing application mark shown while the engine loads.
class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo();

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _scale = Tween<double>(begin: 0.97, end: 1.04).animate(curved);
    _glow = Tween<double>(begin: 0.10, end: 0.22).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: _glow.value),
                ),
              ),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.memory_rounded,
                    size: 38,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One line of the startup checklist.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  final String label;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: isDone
              ? Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: scheme.primary,
                )
              : isActive
                  ? const Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.circle_outlined,
                      size: 16,
                      color: scheme.outlineVariant,
                    ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDone || isActive
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant.withValues(alpha: 0.65),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
