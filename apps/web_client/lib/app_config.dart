enum AppFlavor { dev, prod }

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String supabaseUrl;
  final String supabaseAnonKey;

  AppConfig({
    required this.flavor,
    required this.appName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  static late AppConfig instance;

  static void initialize({
    required AppFlavor flavor,
    required String appName,
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    instance = AppConfig(
      flavor: flavor,
      appName: appName,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }
}
