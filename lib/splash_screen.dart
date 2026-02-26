import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: const Color.fromRGBO(7, 84, 16, 1.0),
                highlightColor: isDark
                    ? const Color.fromRGBO(50, 200, 60, 1.0)
                    : const Color.fromRGBO(100, 200, 100, 1.0),
                period: const Duration(milliseconds: 1500),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/dev/icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Shimmer.fromColors(
                baseColor: const Color.fromRGBO(7, 84, 16, 0.9),
                highlightColor: const Color.fromRGBO(100, 200, 100, 1.0),
                period: const Duration(milliseconds: 1500),
                child: Text(
                  'Location Share',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
