import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Three softly pulsing dots shown while the local model is thinking.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      label: 'L\'assistant rédige une réponse',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final wave = math.sin(
                (_controller.value * 2 * math.pi) - (index * 0.9),
              );
              final intensity = 0.35 + (0.65 * ((wave + 1) / 2));

              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 5),
                child: Transform.translate(
                  offset: Offset(0, -2 * intensity),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: intensity),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
