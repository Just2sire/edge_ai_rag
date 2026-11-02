import 'package:flutter/widgets.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterEdgeAi.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    embeddingBackends: const [LiteRtEmbeddingBackend()],
  );

  final modelsReady = await _hasInstalledModels();

  runApp(
    ProviderScope(
      overrides: [
        modelsInstalledProvider.overrideWith((ref) => modelsReady),
      ],
      child: const EdgeAiTestApp(),
    ),
  );
}

/// Checks whether both the language model and the embedder are already
/// available on the device so returning users skip the download screen.
Future<bool> _hasInstalledModels() async {
  const llmFile = 'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm';
  const embedderFile = 'embeddinggemma-2-text-vision-440m.litertlm';

  try {
    final installedModels = await FlutterEdgeAi.listInstalledModels();
    final hasLlm = installedModels.any(
      (id) => id.toLowerCase().contains(llmFile.toLowerCase()),
    );
    final hasEmbedder = installedModels.any(
      (id) => id.toLowerCase().contains(embedderFile.toLowerCase()),
    );

    return hasLlm &&
        hasEmbedder &&
        FlutterEdgeAi.hasActiveModel() &&
        FlutterEdgeAi.hasActiveEmbedder();
  } catch (error) {
    debugPrint('Impossible de vérifier les modèles installés : $error');
    return false;
  }
}
