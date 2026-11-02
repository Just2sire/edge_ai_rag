import 'package:edge_ai_test/features/documents/document_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_kit/local_ai_kit.dart';

void main() {
  testWidgets('opening indexing settings does not crash', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final rag = LocalRag(
      const RagConfig(systemPrompt: 'test', embedderProfileId: 'test'),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DocumentPanel(rag: rag)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paramètres d\'indexation'));
    await tester.pumpAndSettle();

    expect(find.text('Identifiant du document'), findsOneWidget);
  });
}
