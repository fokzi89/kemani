import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/accept_invitation_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/onboarding/staff_profile_setup_screen.dart';
import '../screens/onboarding/company_setup_screen.dart';
import '../screens/onboarding/passcode_setup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/lock_screen.dart';
import '../services/onboarding_service.dart';

final appRouter = GoRouter(
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
            // 1. Profile Setup
            if (!status.hasProfile) {
              return status.role == 'tenant_admin'
                  ? '/onboarding/profile'
                  : '/onboarding/staff-profile';
            }

            // 2. Company Setup (Only for Tenant Admin)
            if (status.role == 'tenant_admin' && status.tenantId == null) {
              return '/onboarding/company';
            }

            // 3. Passcode Setup
            if (!status.hasPasscode) {
              return '/onboarding/passcode';
            }

            // If all done but not marked complete, go to dashboard (or trigger complete)
            return '/dashboard';
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
    GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/accept-invite',
      builder: (context, state) => const AcceptInvitationScreen(),
    ),
    GoRoute(
      path: '/onboarding/profile',
      builder: (context, state) => const ProfileSetupScreen(),
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return '/login';

        // Prevent staff from accessing owner onboarding
        final onboardingService = OnboardingService();
        final status = await onboardingService.getOnboardingStatus();
        if (status.role != null && status.role != 'tenant_admin') {
          return '/onboarding/staff-profile';
        }

        return null;
      },
    ),
    GoRoute(
      path: '/onboarding/staff-profile',
      builder: (context, state) => const StaffProfileSetupScreen(),
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return '/login';

        // Prevent owners from accessing staff onboarding
        final onboardingService = OnboardingService();
        final status = await onboardingService.getOnboardingStatus();
        if (status.role == 'tenant_admin') {
          return '/onboarding/profile';
        }

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
          if (status.role == 'tenant_admin') {
            return '/onboarding/profile';
          } else {
            return '/onboarding/staff-profile';
          }
        }

        return null;
      },
    ),
  ],
);
