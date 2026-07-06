import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/main.dart';
import 'package:youbike_android/services/app_state.dart';
import 'package:youbike_android/services/language_service.dart';
import 'package:youbike_android/widgets/app_theme.dart';

void main() {
  testWidgets('App boots successfully with AppState', (WidgetTester tester) async {
    // Wrap the app with the required AppState provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const YouBikeApp(),
      ),
    );

    // Instead of pumpAndSettle (which hangs on timers), 
    // we pump a specific duration to allow the first frame and a few ticks to pass.
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the MaterialApp is present.
    // We search for the MaterialApp through the YouBikeApp structure.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
