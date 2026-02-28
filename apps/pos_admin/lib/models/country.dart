class Country {
  final String name;
  final String code;
  final String currencyCode;
  final String dialCode;
  final String flag;

  Country({
    required this.name,
    required this.code,
    required this.currencyCode,
    required this.dialCode,
    required this.flag,
  });

  static List<Country> getAllCountries() {
    return [
      Country(
        name: 'Nigeria',
        code: 'NG',
        currencyCode: 'NGN',
        dialCode: '+234',
        flag: '🇳🇬',
      ),
      Country(
        name: 'United States',
        code: 'US',
        currencyCode: 'USD',
        dialCode: '+1',
        flag: '🇺🇸',
      ),
      Country(
        name: 'United Kingdom',
        code: 'GB',
        currencyCode: 'GBP',
        dialCode: '+44',
        flag: '🇬🇧',
      ),
      Country(
        name: 'Canada',
        code: 'CA',
        currencyCode: 'CAD',
        dialCode: '+1',
        flag: '🇨🇦',
      ),
      Country(
        name: 'Ghana',
        code: 'GH',
        currencyCode: 'GHS',
        dialCode: '+233',
        flag: '🇬🇭',
      ),
      Country(
        name: 'Kenya',
        code: 'KE',
        currencyCode: 'KES',
        dialCode: '+254',
        flag: '🇰🇪',
      ),
      Country(
        name: 'South Africa',
        code: 'ZA',
        currencyCode: 'ZAR',
        dialCode: '+27',
        flag: '🇿🇦',
      ),
      Country(
        name: 'Australia',
        code: 'AU',
        currencyCode: 'AUD',
        dialCode: '+61',
        flag: '🇦🇺',
      ),
      Country(
        name: 'India',
        code: 'IN',
        currencyCode: 'INR',
        dialCode: '+91',
        flag: '🇮🇳',
      ),
      Country(
        name: 'Germany',
        code: 'DE',
        currencyCode: 'EUR',
        dialCode: '+49',
        flag: '🇩🇪',
      ),
      Country(
        name: 'France',
        code: 'FR',
        currencyCode: 'EUR',
        dialCode: '+33',
        flag: '🇫🇷',
      ),
      Country(
        name: 'Spain',
        code: 'ES',
        currencyCode: 'EUR',
        dialCode: '+34',
        flag: '🇪🇸',
      ),
      Country(
        name: 'Italy',
        code: 'IT',
        currencyCode: 'EUR',
        dialCode: '+39',
        flag: '🇮🇹',
      ),
      Country(
        name: 'Brazil',
        code: 'BR',
        currencyCode: 'BRL',
        dialCode: '+55',
        flag: '🇧🇷',
      ),
      Country(
        name: 'Mexico',
        code: 'MX',
        currencyCode: 'MXN',
        dialCode: '+52',
        flag: '🇲🇽',
      ),
      Country(
        name: 'Japan',
        code: 'JP',
        currencyCode: 'JPY',
        dialCode: '+81',
        flag: '🇯🇵',
      ),
      Country(
        name: 'China',
        code: 'CN',
        currencyCode: 'CNY',
        dialCode: '+86',
        flag: '🇨🇳',
      ),
      Country(
        name: 'Singapore',
        code: 'SG',
        currencyCode: 'SGD',
        dialCode: '+65',
        flag: '🇸🇬',
      ),
      Country(
        name: 'UAE',
        code: 'AE',
        currencyCode: 'AED',
        dialCode: '+971',
        flag: '🇦🇪',
      ),
      Country(
        name: 'Saudi Arabia',
        code: 'SA',
        currencyCode: 'SAR',
        dialCode: '+966',
        flag: '🇸🇦',
      ),
    ];
  }
}
