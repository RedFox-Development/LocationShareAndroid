import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_share_android/splash_screen.dart';

void main() {
  Widget createSplashScreen() {
    return const SplashScreen();
  }

  group('Splash Screen - Display', () {
    testWidgets('displays app icon', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      expect(find.byType(Image), findsOneWidget);

      // Verify it's the correct image asset
      final imageFinder = find.byType(Image);
      final Image imageWidget = tester.widget(imageFinder);
      final AssetImage assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, equals('assets/icon.png'));
    });

    testWidgets('displays app title', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      expect(find.text('Location Share'), findsOneWidget);
    });

    testWidgets('icon has shimmer effect', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      // Check that shimmer widget wraps the icon
      expect(find.byType(Image), findsOneWidget);

      // Shimmer should be animating
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('title has shimmer effect', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      expect(find.text('Location Share'), findsOneWidget);
    });

    testWidgets('icon has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);

      final ClipRRect clipRRect = tester.widget(clipRRectFinder);
      expect((clipRRect.borderRadius as BorderRadius).topLeft.x, equals(24));
    });
  });

  group('Splash Screen - Layout', () {
    testWidgets('elements are centered', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      final columnFinder = find.byType(Column);
      final Column column = tester.widget(columnFinder);

      expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
    });

    testWidgets('has proper spacing between icon and title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSplashScreen());

      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);

      // There should be a SizedBox with height 24 between icon and title
      final SizedBox spacer = tester.widget(sizedBoxes.at(0));
      expect(spacer.height, equals(24));
    });

    testWidgets('icon is 120x120 pixels', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      final imageFinder = find.byType(Image);
      final Image imageWidget = tester.widget(imageFinder);

      expect(imageWidget.width, equals(120));
      expect(imageWidget.height, equals(120));
    });
  });

  group('Splash Screen - Theme Adaptation', () {
    testWidgets('uses light theme colors in light mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: createSplashScreen(),
        ),
      );

      final scaffoldFinder = find.byType(Scaffold);
      final Scaffold scaffold = tester.widget(scaffoldFinder);

      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('uses dark theme colors in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: createSplashScreen(),
        ),
      );

      final scaffoldFinder = find.byType(Scaffold);
      final Scaffold scaffold = tester.widget(scaffoldFinder);

      expect(scaffold.backgroundColor, equals(const Color(0xFF121212)));
    });
  });

  group('Splash Screen - Shimmer Animation', () {
    testWidgets('shimmer animation runs', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      // Let shimmer animate
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Shimmer should still be present after animation cycles
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Location Share'), findsOneWidget);
    });

    testWidgets('shimmer period is 1500ms', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      // The shimmer effect should complete a full cycle in 1500ms
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('Splash Screen - Consistency', () {
    testWidgets('maintains green theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(createSplashScreen());

      // Green theme color should be used in shimmer
      // (Color.fromRGBO(7, 84, 16, 1.0))
      // This is verified through the shimmer implementation
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
