import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'package:go_router/go_router.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/onboarding/company_setup_screen.dart';
import 'screens/onboarding/passcode_setup_screen.dart';
import 'services/onboarding_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // Check onboarding status
          final onboardingService = OnboardingService();
          final status = await onboardingService.getOnboardingStatus();

          if (!status.isComplete) {
            return '/onboarding/profile';
          }
          return '/dashboard';
        } else {
          return '/login';
        }
      },
      builder: (context, state) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding/profile',
      builder: (context, state) => const ProfileSetupScreen(),
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return '/login';
        return null;
      },
    ),
    GoRoute(
      path: '/onboarding/company',
      builder: (context, state) => const CompanySetupScreen(),
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return '/login';
        return null;
      },
    ),
    GoRoute(
      path: '/onboarding/passcode',
      builder: (context, state) => const PasscodeSetupScreen(),
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return '/login';
        return null;
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return '/login';
        }

        // Check if onboarding is complete
        final onboardingService = OnboardingService();
        final status = await onboardingService.getOnboardingStatus();

        if (!status.isComplete) {
          return '/onboarding/profile';
        }

        return null;
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Kemani POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
