// Basic widget test for edge_ai_test

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edge_ai_test/app.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EdgeAiTestApp()));

    // Verify the app loads and shows the onboarding screen.
    expect(find.text('Votre assistant, 100 % local'), findsOneWidget);
    expect(find.text('Télécharger les modèles'), findsOneWidget);
  });
}
