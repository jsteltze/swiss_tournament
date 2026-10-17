// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:js_flutter/components/app_layout.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:js_flutter/utils/package_info_global.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:swiss_tournament/main.dart';

/// Helper function to configure the test database resource file path.
Future<void> configureTestDatabasePath(String path) async {
  if (path.isNotEmpty) {
    await databaseFactoryFfi.setDatabasesPath(path);
    databaseFactory = databaseFactoryFfi;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    /*sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    databaseFactory.setDatabasesPath('resources');*/

    await FileLogger.init();
    Globals.packageInfo = PackageInfo(
      appName: 'Chess Swiss Tournament',
      packageName: 'de.jsteltze.chesstournamentapp',
      version: '1.0.0',
      buildNumber: '1',
    );
  });

  group('Welcome Dialog Tests', () {
    testWidgets(
      'Welcome dialog shows up and app logo is visible on first launch',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(JsFlutterApp(ChessTournamentApp()));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verify that the welcome dialog title is displayed
        expect(find.text('Welcome!'), findsOneWidget);

        // Verify welcome dialog message text
        expect(
          find.textContaining(
            'Thank you for using the Chess Swiss Tournament App!',
          ),
          findsOneWidget,
        );

        // Verify the app logo is displayed inside the welcome dialog
        final dialogLogoFinder = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image == const AssetImage('assets/app_logo.png'),
          ),
        );
        expect(dialogLogoFinder, findsOneWidget);

        // Verify "Get Started" button is visible
        final getStartedButton = find.text('Get Started');
        expect(getStartedButton, findsOneWidget);

        // Dismiss dialog
        await tester.tap(getStartedButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify dialog is dismissed
        expect(find.text('Welcome!'), findsNothing);
      },
    );

    testWidgets('Welcome dialog does not show up on subsequent launches', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'first_time': false});

      await tester.pumpWidget(JsFlutterApp(ChessTournamentApp()));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));

      //tester.allWidgets.forEach((w) => print(w.toString()));
      // Verify welcome dialog does not show up
      expect(find.text('Welcome!'), findsNothing);
      expect(find.text('No tournaments added yet.'), findsOne);
    });
  });
}
