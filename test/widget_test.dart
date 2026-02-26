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
import 'package:location_share_android/l10n/app_localizations.dart';

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

      // Complete the timer to avoid pending timer error
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    });

    testWidgets('app navigates to setup when not configured', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AppLoader());
      // Wait for 3-second splash screen delay
      await tester.pump(const Duration(seconds: 3));
      // Additional pumps to process state changes
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

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
        'teamName': 'Test Team',
        'event': 'Test Event',
        'apiUrl': 'https://api.example.com/api',
        'imageUrl': 'https://example.com/logo.png',
        'expirationDate': '2026-12-31',
        'timezone': 'UTC',
        'setup_complete': true,
      });

      await tester.pumpWidget(const AppLoader());
      // Wait for 3-second splash screen delay
      await tester.pump(const Duration(seconds: 3));
      // Additional pumps to process state changes
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

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
        'teamName': 'Test Team',
        'event': 'Test Event',
        'apiUrl': 'https://api.example.com/api',
        'imageUrl': 'https://example.com/logo.png',
        'expirationDate': '2026-12-31',
        'timezone': 'UTC',
        'setup_complete': true,
      });

      await tester.pumpWidget(const AppLoader());
      // Wait for 3-second splash screen delay
      await tester.pump(const Duration(seconds: 3));
      // Additional pumps to process state changes
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

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

      await tester.pumpWidget(const AppLoader());
      // Wait for splash screen delay
      await tester.pump(const Duration(seconds: 3));
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

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

      await tester.pumpWidget(const AppLoader());
      // Wait for splash screen delay
      await tester.pump(const Duration(seconds: 3));
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

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

      await tester.pumpWidget(const AppLoader());
      // Wait for 3-second splash screen delay
      await tester.pump(const Duration(seconds: 3));
      // Additional pumps to process state changes
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

      expect(find.text('Welcome!'), findsOneWidget);
    });

    testWidgets('app supports Finnish localization', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({'language_code': 'fi'});

      await tester.pumpWidget(const AppLoader());
      // Wait for 3-second splash screen delay
      await tester.pump(const Duration(seconds: 3));
      // Additional pumps to process state changes
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

      expect(find.text('Tervetuloa!'), findsOneWidget);
    });

    testWidgets('supported locales include en and fi', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AppLoader());
      // Wait for splash screen delay to get the actual MyApp
      await tester.pump(const Duration(seconds: 3));
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

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

      // After 1 second (still within 3s minimum)
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Location Share'), findsOneWidget);

      // After 3 seconds, should transition
      await tester.pump(const Duration(seconds: 2));
      // Additional pumps to process state changes
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }

      // Should now be on setup or home page
      expect(find.text('Welcome!'), findsAny);
    });
  });
}
