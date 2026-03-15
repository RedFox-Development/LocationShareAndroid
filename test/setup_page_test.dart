import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_share_android/setup_page.dart';
import 'package:location_share_android/app_config.dart';
import 'package:location_share_android/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createSetupPage() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: FutureBuilder<AppConfig>(
        future: AppConfig.init(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SetupPage(appConfig: snapshot.data!);
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }

  group('Setup Page - QR-only setup flow', () {
    testWidgets('displays welcome message and QR scan prompt', (
      WidgetTester tester,
    ) async {
      // Set larger viewport to avoid overflow
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text('Welcome!'), findsOneWidget);
      expect(
        find.text('Scan a QR code to quickly configure the app'),
        findsOneWidget,
      );
    });

    testWidgets('displays scan QR code button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);
    });

    testWidgets('does not display manual setup action', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text('Enter configuration manually'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('does not show config form before scanning QR', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text('Save Configuration'), findsNothing);
      expect(find.text('Team Name'), findsNothing);
      expect(find.text('Event'), findsNothing);
    });

    testWidgets('displays app icon and dev logo composite', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      // Check that the stack with images is present
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('language selector shows English and Finnish options', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.byIcon(Icons.language), findsOneWidget);

      // Tap language button to show menu
      await tester.tap(find.byIcon(Icons.language));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('English (UK)'), findsOneWidget);
      expect(find.text('Suomi'), findsOneWidget);
    });
  });
}
