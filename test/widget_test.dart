// Comprehensive UI tests for the Location Share Android app
//
// This file provides integration-level tests for the main app flow.
// For individual widget tests, see:
// - setup_page_test.dart
// - about_page_test.dart
// - app_config_test.dart
// - splash_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_share_android/main.dart';

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const AppLoader());
  await tester.pump(const Duration(milliseconds: 4600));
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('App Integration Tests', () {
    testWidgets('app loads and shows splash screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AppLoader());
      await tester.pump();

      // Splash screen should be shown initially
      expect(find.text('Location Share'), findsOneWidget);

      // Complete initialization timer to avoid pending timer errors.
      await tester.pump(const Duration(milliseconds: 4600));
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('app navigates to setup when not configured', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpPastSplash(tester);

      // Should show setup page
      expect(find.text('Welcome!'), findsOneWidget);
      expect(
        find.text('Scan a QR code to quickly configure the app'),
        findsOneWidget,
      );
    });

    testWidgets('app navigates to home when configured', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'team_name': 'Test Team',
        'event': 'Test Event',
        'api_url': 'https://api.example.com/api',
        'timezone': 'UTC',
        'setup_complete': true,
      });

      await _pumpPastSplash(tester);

      // Should show home page with navigation
      expect(find.text('Sharing'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('navigations between tabs work', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'team_name': 'Test Team',
        'event': 'Test Event',
        'api_url': 'https://api.example.com/api',
        'timezone': 'UTC',
        'setup_complete': true,
      });

      await _pumpPastSplash(tester);

      // Tap Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Current Configuration'), findsOneWidget);

      // Tap About
      await tester.tap(find.text('About'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Developer: RedFox Development'), findsOneWidget);

      // Back to Sharing
      await tester.tap(find.text('Sharing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Test Event'), findsOneWidget);
    });
  });

  group('App Theme Tests', () {
    testWidgets('app supports light and dark themes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpPastSplash(tester);

      // MaterialApp should have both themes defined
      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );

      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, equals(ThemeMode.system));
    });

    testWidgets('app uses Material 3', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpPastSplash(tester);

      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );

      expect(materialApp.theme?.useMaterial3, isTrue);
    });
  });

  group('App Localization Tests', () {
    testWidgets('app supports English localization', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({'language_code': 'en'});

      await _pumpPastSplash(tester);

      expect(find.text('Welcome!'), findsOneWidget);
    });

    testWidgets('app supports Finnish localization', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({'language_code': 'fi'});

      await _pumpPastSplash(tester);

      expect(find.text('Tervetuloa!'), findsOneWidget);
    });

    testWidgets('supported locales include en and fi', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpPastSplash(tester);

      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );

      expect(materialApp.supportedLocales, contains(const Locale('en', 'GB')));
      expect(materialApp.supportedLocales, contains(const Locale('fi', 'FI')));
    });
  });

  group('App Initialization Tests', () {
    testWidgets('splash screen shows for minimum duration', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AppLoader());

      // Immediately after first frame
      expect(find.text('Location Share'), findsOneWidget);

      // After 1 second, splash should still be shown.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Location Share'), findsOneWidget);

      // After 4.6 seconds total, should transition.
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pumpAndSettle();

      // Should now be on setup or home page
      expect(find.text('Welcome!'), findsAny);
    });
  });
}
