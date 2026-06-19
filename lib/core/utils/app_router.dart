// lib/core/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../data/models/user_model.dart';

// Screens
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/sign_up_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/client/client_shell.dart';
import '../../presentation/screens/client/client_dashboard_screen.dart';
import '../../presentation/screens/client/post_job_screen.dart';
import '../../presentation/screens/client/review_job_screen.dart';
import '../../presentation/screens/client/active_jobs_screen.dart';
import '../../presentation/screens/worker/worker_shell.dart';
import '../../presentation/screens/worker/worker_dashboard_screen.dart';
import '../../presentation/screens/worker/browse_jobs_screen.dart';
import '../../presentation/screens/worker/worker_earnings_screen.dart';
import '../../presentation/screens/shared/job_details_screen.dart';
import '../../presentation/screens/shared/booking_screen.dart';
import '../../presentation/screens/shared/payment_screen.dart';
import '../../presentation/screens/shared/active_job_screen.dart';
import '../../presentation/screens/shared/chat_screen.dart';
import '../../presentation/screens/shared/chats_list_screen.dart';
import '../../presentation/screens/shared/worker_profile_screen.dart';
import '../../presentation/screens/shared/search_screen.dart';
import '../../presentation/screens/shared/review_screen.dart';
import '../../presentation/screens/shared/reviews_list_screen.dart';
import '../../presentation/screens/shared/profile_settings_screen.dart';
import '../../presentation/screens/shared/addon_screen.dart';
import '../../presentation/screens/shared/addon_approval_screen.dart';
import '../../presentation/screens/shared/image_gallery_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthRoute) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/auth/signup/:type',
        builder: (_, state) => SignUpScreen(
          userType: state.pathParameters['type'] == 'worker'
              ? UserType.worker
              : UserType.client,
        ),
      ),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),

      // Client Shell
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/client',
            builder: (_, __) => const ClientDashboardScreen(),
          ),
          GoRoute(
            path: '/client/active-jobs',
            builder: (_, __) => const ActiveJobsScreen(),
          ),
        ],
      ),

      // Worker Shell
      ShellRoute(
        builder: (context, state, child) => WorkerShell(child: child),
        routes: [
          GoRoute(
            path: '/worker',
            builder: (_, __) => const WorkerDashboardScreen(),
          ),
          GoRoute(
            path: '/worker/browse',
            builder: (_, __) => const BrowseJobsScreen(),
          ),
          GoRoute(
            path: '/worker/earnings',
            builder: (_, __) => const WorkerEarningsScreen(),
          ),
        ],
      ),

      // Shared Routes (no shell)
      GoRoute(
        path: '/jobs/:jobId',
        builder: (_, state) => JobDetailsScreen(
          jobId: state.pathParameters['jobId']!,
        ),
      ),
      GoRoute(
        path: '/jobs/:jobId/book',
        builder: (_, state) => BookingScreen(
          jobId: state.pathParameters['jobId']!,
        ),
      ),
      GoRoute(
        path: '/jobs/:jobId/pay',
        builder: (_, state) => PaymentScreen(
          jobId: state.pathParameters['jobId']!,
          paymentType: state.uri.queryParameters['type'] ?? 'escrow',
          amount: double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/jobs/:jobId/active',
        builder: (_, state) => ActiveJobScreen(
          jobId: state.pathParameters['jobId']!,
        ),
      ),
      GoRoute(
        path: '/jobs/:jobId/addon',
        builder: (_, state) => AddOnScreen(
          jobId: state.pathParameters['jobId']!,
        ),
      ),
      GoRoute(
        path: '/jobs/:jobId/addon-approval/:addonId',
        builder: (_, state) => AddOnApprovalScreen(
          jobId: state.pathParameters['jobId']!,
          addOnId: state.pathParameters['addonId']!,
        ),
      ),
      GoRoute(
        path: '/jobs/:jobId/review',
        builder: (_, state) => ReviewScreen(
          jobId: state.pathParameters['jobId']!,
          revieweeId: state.uri.queryParameters['revieweeId'] ?? '',
          revieweeName: state.uri.queryParameters['revieweeName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/post-job',
        builder: (_, __) => const PostJobScreen(),
      ),
      GoRoute(
        path: '/review-job',
        builder: (_, __) => const ReviewJobScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (_, __) => const ChatsListScreen(),
      ),
      GoRoute(
        path: '/chats/:chatId',
        builder: (_, state) => ChatScreen(
          chatId: state.pathParameters['chatId']!,
          jobId: state.uri.queryParameters['jobId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/worker/:workerId/profile',
        builder: (_, state) => WorkerProfileScreen(
          workerId: state.pathParameters['workerId']!,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/reviews/:userId',
        builder: (_, state) => ReviewsListScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ImageGalleryScreen(
            images: List<String>.from(extra['images']),
            initialIndex: extra['initialIndex'] ?? 0,
          );
        },
      ),
    ],
  );
});
