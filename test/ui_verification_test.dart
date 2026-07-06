import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/services/app_state.dart';
import 'package:youbike_android/services/language_service.dart';
import 'package:youbike_android/widgets/app_theme.dart';
import 'package:youbike_android/screens/home_screen.dart';
import 'package:youbike_android/widgets/electric_bike_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestApp(Widget child) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: child,
      ),
    );
  }

  testWidgets('HomeScreen should render without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
 
  testWidgets('ElectricBikeDetailsModal should render without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(
      const Scaffold(
        body: ElectricBikeDetailsModal(
          stationId: 'S1',
          stationName: 'Test Station',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Test Station'), findsOneWidget);
  });
}
