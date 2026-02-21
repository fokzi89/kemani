import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Removed
import 'package:provider/provider.dart' as provider;
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Removed
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Kept for future use if needed, but confusing if not used in MyApp directly.
// Wait, MyApp wraps with ProviderScope in main(). But now main() is gone.
// We must ensure the Providers are wrapping MyApp in the new mains!
// Actually, let's export a RootApp widget that includes the Providers.

import 'theme.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

// main.dart serves as the shared entry point for MyApp widget
// The actual main() functions are in main_dev.dart and main_prod.dart

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: ThemeProvider is still using Provider for now, will migrate to Riverpod later
    final themeProvider = provider.Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Kemani POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
