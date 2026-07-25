
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:level_up/main.dart';
import 'package:level_up/providers/player_state_manager.dart';

void main() {
  testWidgets('App launches successfully smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => PlayerProgressAndStatsController(),
        child: const LevelUpApp(),
      ),
    );

    // Verify that the title appears.
    expect(find.text('LevelUp - Player Status'), findsOneWidget);
  });
}
