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

  group('Setup Page - QR Scan View', () {
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

    testWidgets('displays enter manually button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text('Enter configuration manually'), findsOneWidget);
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

  group('Setup Page - Manual Entry View', () {
    testWidgets('switches to manual entry when button tapped', (
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

      // Tap "Enter configuration manually"
      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Manual Configuration'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays all required form fields', (
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

      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Team Name'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('API URL'), findsOneWidget);
      expect(find.text('Image URL'), findsOneWidget);
      expect(find.text('Expiration Date'), findsOneWidget);
      expect(find.text('Timezone'), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to save button
      await tester.ensureVisible(find.text('Save Configuration'));
      await tester.pump();

      // Try to save without filling fields
      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Team Name is required'), findsOneWidget);
      expect(find.text('Event is required'), findsOneWidget);
    });

    testWidgets('validates API URL format', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to API URL field
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'API URL'));
      await tester.pump();

      // Enter invalid URL
      await tester.enterText(
        find.widgetWithText(TextFormField, 'API URL'),
        'not-a-url',
      );

      // Scroll to save button
      await tester.ensureVisible(find.text('Save Configuration'));
      await tester.pump();

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(find.text('Enter a valid URL'), findsOneWidget);
    });

    testWidgets('date picker opens when expiration date tapped', (
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

      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find all TextFormFields and scroll to the page
      final formFields = find.byType(TextFormField);
      expect(formFields, findsWidgets);

      // Look for the expiration date label text
      await tester.ensureVisible(find.text('Expiration Date'));
      await tester.pump();

      // Tap on the expiration date field area
      await tester.tap(find.text('Expiration Date'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Date picker should be shown
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('timezone dropdown shows options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to timezone dropdown
      await tester.ensureVisible(find.text('Select timezone'));
      await tester.pump();

      // Tap timezone dropdown
      await tester.tap(find.text('Select timezone'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Common timezones should be visible
      expect(find.text('UTC'), findsOneWidget);
      expect(find.text('Europe/Helsinki'), findsOneWidget);
    });

    testWidgets('back button returns to QR scan view', (
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

      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Welcome!'), findsOneWidget);
      expect(find.text('Back to QR scan'), findsNothing);
    });
  });

  group('Setup Page - Form Submission', () {
    testWidgets('accepts valid configuration', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSetupPage());
      // Allow multiple frames for image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      await tester.tap(find.text('Enter configuration manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Fill in valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Team Name'),
        'Test Team',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event'),
        'Test Event',
      );

      // Scroll to API URL field
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'API URL'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'API URL'),
        'https://api.example.com/api',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Image URL'),
        'https://example.com/image.png',
      );

      // Scroll to expiration date field and tap the InkWell widget
      final dateInkWell = find
          .ancestor(
            of: find.byIcon(Icons.calendar_today),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.ensureVisible(dateInkWell);
      await tester.pump();

      // Select expiration date
      await tester.tap(dateInkWell);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to timezone and tap the DropdownButtonFormField
      final timezoneDropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(timezoneDropdown);
      await tester.pump();

      // Select timezone
      await tester.tap(timezoneDropdown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('UTC').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to save button
      await tester.ensureVisible(find.text('Save Configuration'));
      await tester.pump();

      // Submit form - should navigate away or show success
      await tester.tap(find.text('Save Configuration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Allow time for async save operation
      await tester.pumpAndSettle();

      // Configuration should be saved (would navigate to home in real app)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('team_name'), equals('Test Team'));
      expect(prefs.getString('event'), equals('Test Event'));
    });
  });
}
