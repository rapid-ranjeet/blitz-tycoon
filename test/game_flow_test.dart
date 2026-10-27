import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blitz_tycoon/main.dart';
import 'package:blitz_tycoon/ui/screens/game_board_screen.dart';
import 'package:blitz_tycoon/ui/screens/home_empire_screen.dart';
import 'package:blitz_tycoon/ui/screens/matchmaking_screen.dart';

void main() {
  testWidgets('Test full play flow from Home to GameBoard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(const BlitzTycoonApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeEmpireScreen), findsOneWidget);

    final playBtn = find.text("BATTLE LOBBY / QUICK MATCH");
    await tester.ensureVisible(playBtn);
    await tester.tap(playBtn);
    await tester.pumpAndSettle();

    expect(find.byType(MatchmakingScreen), findsOneWidget);

    // Tap PLAY INSTANT MATCH
    final instantMatchBtn = find.text("PLAY INSTANT MATCH");
    expect(instantMatchBtn, findsOneWidget);
    await tester.tap(instantMatchBtn);
    await tester.pumpAndSettle();

    expect(find.byType(GameBoardScreen), findsOneWidget);

    // Pump frames to see if anything crashes or renders blank
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });
}
