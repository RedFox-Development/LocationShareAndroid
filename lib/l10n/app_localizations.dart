import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'GB'),
    Locale('fi', 'FI'),
  ];

  // Get translated strings
  Map<String, String> get _localizedValues {
    if (locale.languageCode == 'fi') {
      return _finnishStrings;
    }
    return _englishStrings;
  }

  // Common
  String get appTitle => _localizedValues['appTitle']!;
  String get sharing => _localizedValues['sharing']!;
  String get settings => _localizedValues['settings']!;
  String get about => _localizedValues['about']!;
  String get developer => _localizedValues['developer']!;
  String get sourceCode => _localizedValues['sourceCode']!;

  // Setup Page
  String get initialSetup => _localizedValues['initialSetup']!;
  String get welcome => _localizedValues['welcome']!;
  String get scanQRPrompt => _localizedValues['scanQRPrompt']!;
  String get scanQRCode => _localizedValues['scanQRCode']!;
  String get enterManually => _localizedValues['enterManually']!;
  String get manualConfiguration => _localizedValues['manualConfiguration']!;
  String get backToQRScan => _localizedValues['backToQRScan']!;
  String get teamName => _localizedValues['teamName']!;
  String get teamNameHint => _localizedValues['teamNameHint']!;
  String get event => _localizedValues['event']!;
  String get eventHint => _localizedValues['eventHint']!;
  String get dbHost => _localizedValues['dbHost']!;
  String get dbHostHint => _localizedValues['dbHostHint']!;
  String get dbPort => _localizedValues['dbPort']!;
  String get dbPortHint => _localizedValues['dbPortHint']!;
  String get dbName => _localizedValues['dbName']!;
  String get dbNameHint => _localizedValues['dbNameHint']!;
  String get dbUser => _localizedValues['dbUser']!;
  String get dbUserHint => _localizedValues['dbUserHint']!;
  String get dbPassword => _localizedValues['dbPassword']!;
  String get dbPasswordHint => _localizedValues['dbPasswordHint']!;
  String get dbTable => _localizedValues['dbTable']!;
  String get dbTableHint => _localizedValues['dbTableHint']!;
  String get imageUrl => _localizedValues['imageUrl']!;
  String get imageUrlHint => _localizedValues['imageUrlHint']!;
  String get expirationDate => _localizedValues['expirationDate']!;
  String get selectExpirationDate => _localizedValues['selectExpirationDate']!;
  String get expirationDateHint => _localizedValues['expirationDateHint']!;
  String get notSelected => _localizedValues['notSelected']!;
  String get configWillReset => _localizedValues['configWillReset']!;
  String get saveConfiguration => _localizedValues['saveConfiguration']!;
  String get pleaseSelectDate => _localizedValues['pleaseSelectDate']!;
  String get configSavedSuccess => _localizedValues['configSavedSuccess']!;
  String get errorSavingConfig => _localizedValues['errorSavingConfig']!;
  String get qrLoadedReview => _localizedValues['qrLoadedReview']!;
  String get invalidQRFormat => _localizedValues['invalidQRFormat']!;
  String get errorScanningQR => _localizedValues['errorScanningQR']!;
  String get timezone => _localizedValues['timezone']!;
  String get selectTimezone => _localizedValues['selectTimezone']!;
  String get timezoneRequired => _localizedValues['timezoneRequired']!;
  String get pleaseSelectTimezone => _localizedValues['pleaseSelectTimezone']!;

  // Validation
  String fieldRequired(String field) =>
      locale.languageCode == 'fi' ? '$field vaaditaan' : '$field is required';
  String get urlRequired => _localizedValues['urlRequired']!;
  String get enterValidUrl => _localizedValues['enterValidUrl']!;

  // Sharing Page
  String get startLocationSharing => _localizedValues['startLocationSharing']!;
  String get stopLocationSharing => _localizedValues['stopLocationSharing']!;
  String get failedToLoadImage => _localizedValues['failedToLoadImage']!;
  String get noImageConfigured => _localizedValues['noImageConfigured']!;
  String get noEvent => _localizedValues['noEvent']!;

  // Settings Page
  String get currentConfiguration => _localizedValues['currentConfiguration']!;
  String get expiresOn => _localizedValues['expiresOn']!;
  String get notSet => _localizedValues['notSet']!;
  String get resetConfiguration => _localizedValues['resetConfiguration']!;
  String get resetWarning => _localizedValues['resetWarning']!;
  String get resetConfirmTitle => _localizedValues['resetConfirmTitle']!;
  String get resetConfirmMessage => _localizedValues['resetConfirmMessage']!;
  String get cancel => _localizedValues['cancel']!;
  String get reset => _localizedValues['reset']!;
  String get configResetSuccess => _localizedValues['configResetSuccess']!;
  String get errorResettingConfig => _localizedValues['errorResettingConfig']!;
  String get urlCopied => _localizedValues['urlCopied']!;
  String get language => _localizedValues['language']!;
  String get selectLanguage => _localizedValues['selectLanguage']!;

  // QR Scanner
  String get scanQRTitle => _localizedValues['scanQRTitle']!;
  String get positionQRCode => _localizedValues['positionQRCode']!;

  // English strings
  static const Map<String, String> _englishStrings = {
    'sourceCode': 'Source code',
    'developer': 'Developer',
    'appTitle': 'Simple location sharing',
    'sharing': 'Sharing',
    'settings': 'Settings',
    'about': 'About',
    'initialSetup': 'Initial Setup',
    'welcome': 'Welcome!',
    'scanQRPrompt': 'Scan a QR code to quickly configure the app',
    'scanQRCode': 'Scan QR Code',
    'enterManually': 'Enter configuration manually',
    'manualConfiguration': 'Manual Configuration',
    'backToQRScan': 'Back to QR scan',
    'teamName': 'Team Name',
    'teamNameHint': 'Enter your team name',
    'event': 'Event',
    'eventHint': 'Enter event name',
    'dbHost': 'Database Host',
    'dbHostHint': 'e.g. db.example.com',
    'dbPort': 'Database Port',
    'dbPortHint': '5432',
    'dbName': 'Database Name',
    'dbNameHint': 'location_sharing',
    'dbUser': 'Database User',
    'dbUserHint': 'postgres',
    'dbPassword': 'Database Password',
    'dbPasswordHint': 'Enter password',
    'dbTable': 'Database Table',
    'dbTableHint': 'location_updates',
    'imageUrl': 'Image URL',
    'imageUrlHint': 'https://example.com/image.png',
    'expirationDate': 'Expiration Date',
    'selectExpirationDate': 'Select expiration date',
    'expirationDateHint': 'Select when config expires',
    'notSelected': 'Not selected',
    'configWillReset': 'Configuration will reset after this date',
    'saveConfiguration': 'Save Configuration',
    'pleaseSelectDate': 'Please select an expiration date',
    'configSavedSuccess': 'Configuration saved successfully!',
    'errorSavingConfig': 'Error saving configuration',
    'qrLoadedReview': 'Configuration loaded from QR code - review and save',
    'invalidQRFormat': 'Invalid QR code format',
    'errorScanningQR': 'Error scanning QR code',
    'timezone': 'Timezone',
    'selectTimezone': 'Select timezone',
    'timezoneRequired': 'Timezone is required',
    'pleaseSelectTimezone': 'Please select a timezone',
    'urlRequired': 'URL is required',
    'enterValidUrl': 'Please enter a valid URL',
    'startLocationSharing': 'Start location sharing',
    'stopLocationSharing': 'Stop location sharing',
    'failedToLoadImage': 'Failed to load image',
    'noImageConfigured': 'No image configured',
    'noEvent': 'No event',
    'currentConfiguration': 'Current Configuration',
    'expiresOn': 'Expires On',
    'notSet': 'Not set',
    'resetConfiguration': 'Reset Configuration',
    'resetWarning':
        'Resetting will clear all settings and return you to the setup screen.',
    'resetConfirmTitle': 'Reset Configuration',
    'resetConfirmMessage':
        'Are you sure you want to reset the configuration? You will need to set up the app again.',
    'cancel': 'Cancel',
    'reset': 'Reset',
    'configResetSuccess': 'Configuration reset successfully',
    'errorResettingConfig': 'Error resetting configuration',
    'urlCopied': 'copied to clipboard',
    'language': 'Language',
    'selectLanguage': 'Select Language',
    'scanQRTitle': 'Scan QR Code',
    'positionQRCode': 'Position the QR code within the frame',
  };

  // Finnish strings
  static const Map<String, String> _finnishStrings = {
    'sourceCode': 'Lähdekoodi',
    'developer': 'Kehittäjä',
    'appTitle': 'Helppo sijaintijako',
    'sharing': 'Jakaminen',
    'settings': 'Määritykset',
    'about': 'Tietoja',
    'initialSetup': 'Alkumääritys',
    'welcome': 'Tervetuloa!',
    'scanQRPrompt': 'Skannaa QR-koodi sovelluksen nopeaan määritykseen',
    'scanQRCode': 'Skannaa QR-koodi',
    'enterManually': 'Syötä määritykset käsin',
    'manualConfiguration': 'Määritys käsin',
    'backToQRScan': 'Takaisin QR-skannaukseen',
    'teamName': 'Tiimin nimi',
    'teamNameHint': 'Syötä tiimisi nimi',
    'event': 'Tapahtuma',
    'eventHint': 'Syötä tapahtuman nimi',
    'dbHost': 'Tietokannan palvelin',
    'dbHostHint': 'esim. db.esimerkki.com',
    'dbPort': 'Tietokannan portti',
    'dbPortHint': '5432',
    'dbName': 'Tietokannan nimi',
    'dbNameHint': 'location_sharing',
    'dbUser': 'Tietokannan käyttäjä',
    'dbUserHint': 'postgres',
    'dbPassword': 'Tietokannan salasana',
    'dbPasswordHint': 'Syötä salasana',
    'dbTable': 'Tietokannan taulu',
    'dbTableHint': 'location_updates',
    'imageUrl': 'Kuva-URL',
    'imageUrlHint': 'https://esimerkki.com/kuva.png',
    'expirationDate': 'Vanhenemispäivä',
    'selectExpirationDate': 'Valitse vanhenemispäivä',
    'expirationDateHint': 'Valitse milloin määritykset vanhenevat',
    'notSelected': 'Ei valittu',
    'configWillReset': 'Asetukset nollautuvat tämän päivämäärän jälkeen',
    'saveConfiguration': 'Tallenna asetukset',
    'pleaseSelectDate': 'Valitse vanhenemispäivä',
    'configSavedSuccess': 'Määritykset tallennettu onnistuneesti!',
    'errorSavingConfig': 'Virhe tallennettaessa määrityksiä',
    'qrLoadedReview': 'Määritykset ladattu QR-koodista - tarkista ja tallenna',
    'invalidQRFormat': 'Virheellinen QR-koodin muoto',
    'errorScanningQR': 'Virhe skannattaessa QR-koodia',
    'timezone': 'Aikavyöhyke',
    'selectTimezone': 'Valitse aikavyöhyke',
    'timezoneRequired': 'Aikavyöhyke vaaditaan',
    'pleaseSelectTimezone': 'Valitse aikavyöhyke',
    'urlRequired': 'URL vaaditaan',
    'enterValidUrl': 'Anna kelvollinen URL',
    'startLocationSharing': 'Aloita sijainnin jakaminen',
    'stopLocationSharing': 'Lopeta sijainnin jakaminen',
    'failedToLoadImage': 'Kuvan lataus epäonnistui',
    'noImageConfigured': 'Kuvaa ei määritetty',
    'noEvent': 'Ei tapahtumaa',
    'currentConfiguration': 'Tapahtumamääritykset',
    'expiresOn': 'Vanhenee',
    'notSet': 'Ei asetettu',
    'resetConfiguration': 'Nollaa määritykset',
    'resetWarning':
        'Nollaaminen tyhjentää kaikki määritykset ja palaa määritysnäkymään.',
    'resetConfirmTitle': 'Nollaa määritykset',
    'resetConfirmMessage':
        'Haluatko varmasti nollata määritykset? Sinun täytyy määrittää sovellus uudelleen.',
    'cancel': 'Peruuta',
    'reset': 'Nollaa',
    'configResetSuccess': 'Määritykset nollattu',
    'errorResettingConfig': 'Virhe nollattaessa määrityksiä',
    'urlCopied': 'kopioitu leikepöydälle',
    'language': 'Kieli',
    'selectLanguage': 'Valitse kieli',
    'scanQRTitle': 'Skannaa QR-koodi',
    'positionQRCode': 'Aseta QR-koodi kehyksen sisälle',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
