import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'l10n/app_localizations.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // App info constants
  static const String _developerName = 'RedFox Development';
  static const String _repositoryUrl =
      'https://github.com/RedFox-Development/LocationShareAndroid';

  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // If launchUrl returns false, show an error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open URL: $url'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      // Handle any exceptions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(
            builder: (context) => Icon(
              Icons.info_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(loc.about, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(loc.appTitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Builder(
            builder: (context) => Text(
              _version,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Shimmer.fromColors(
                baseColor: const Color.fromRGBO(7, 84, 16, 1.0),
                highlightColor: isDark
                    ? const Color.fromRGBO(50, 200, 60, 1.0)
                    : const Color.fromRGBO(100, 200, 100, 1.0),
                period: const Duration(milliseconds: 1500),
                child: Image.asset(
                  'assets/dev/redfox_dev_app.png',
                  width: 120,
                  height: 120,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${loc.developer}: $_developerName',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _launchUrl(_repositoryUrl),
            child: Text(
              loc.sourceCode,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
