import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/email_confirmation_pending_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/country_selection_screen.dart';
import 'screens/business_setup_screen.dart';
import 'screens/staff/staff_set_password_screen.dart';
import 'screens/staff/staff_profile_settings_screen.dart';
import 'screens/staff/staff_passcode_setup_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/sales_provider.dart';
import 'services/local_database_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'services/sales_service.dart';
import 'services/product_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ykbpznoqebhopyqpoqaf.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38'),
  );

  // Initialize services
  final localDb = LocalDatabaseService();
  await localDb.initialize();

  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  final salesService = SalesService();
  final productService = ProductService();

  final syncService = SyncService(
    localDb,
    salesService,
    productService,
    connectivityService,
  );

  // Start periodic sync
  syncService.startPeriodicSync();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider.value(value: localDb),
        Provider.value(value: connectivityService),
        Provider.value(value: syncService),
        Provider.value(value: salesService),
        Provider.value(value: productService),
        ChangeNotifierProvider(
          create: (_) => SalesProvider(
            localDb,
            salesService,
            productService,
            connectivityService,
            syncService,
          ),
        ),
      ],
      child: const POSAdminApp(),
    ),
  );
}

class POSAdminApp extends StatelessWidget {
  const POSAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Kemani POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/profile-settings': (context) => const ProfileSettingsScreen(),
            '/country-selection': (context) => const CountrySelectionScreen(),
            '/business-setup': (context) => const BusinessSetupScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/staff-profile-settings': (context) => const StaffProfileSettingsScreen(),
            '/staff-passcode-setup': (context) => const StaffPasscodeSetupScreen(),
            '/staff-dashboard': (context) => const StaffDashboardScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle email confirmation pending screen with email parameter
            if (settings.name == '/email-confirmation-pending') {
              final args = settings.arguments as Map<String, dynamic>?;
              final email = args?['email'] as String? ?? '';
              return MaterialPageRoute(
                builder: (context) => EmailConfirmationPendingScreen(email: email),
              );
            }

            // Handle staff invite routes with token parameter
            if (settings.name != null && settings.name!.startsWith('/staff-invite/')) {
              final token = settings.name!.substring('/staff-invite/'.length);
              return MaterialPageRoute(
                builder: (context) => StaffSetPasswordScreen(inviteToken: token),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.session != null) {
          return const DashboardScreen();
        }
        return const SignUpScreen();
      },
    );
  }
}
