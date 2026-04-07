import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/supabase/supabase_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/chat/presentation/conversations_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/favorites_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/terms_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';
import '../../features/profile/presentation/payment_methods_screen.dart';
import '../../features/profile/presentation/kyc_screen.dart';
import '../../features/profile/presentation/help_center_screen.dart';
import '../../features/bookings/presentation/booking_detail_screen.dart';
import '../../features/listing_detail/presentation/listing_detail_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/booking_confirmed_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/host_dashboard/presentation/dashboard_screen.dart';
import '../../features/host_calendar/presentation/calendar_screen.dart';
import '../../features/host_listings/presentation/host_listings_screen.dart';
import '../../features/host_wallet/presentation/wallet_screen.dart';
import '../../features/create_listing/presentation/create_listing_screen.dart';
import '../../features/host_benefits/presentation/host_benefits_screen.dart';
import '../../features/disputes/presentation/disputes_screen.dart';
import '../../features/disputes/presentation/dispute_detail_screen.dart';
import '../../features/quick_services/presentation/quick_services_screen.dart';
import '../../features/quick_services/presentation/publish_service_screen.dart';
import '../../features/reviews/presentation/write_review_screen.dart';
import '../../features/reviews/presentation/reviews_list_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/host_analytics/presentation/analytics_screen.dart';
import '../../shared/layouts/guest_shell.dart';
import '../../shared/layouts/host_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _guestShellKey = GlobalKey<NavigatorState>();
final _hostShellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = SupabaseConfig.client.auth.currentSession;
      final isAuthenticated = session != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth');
      final isSplash = loc == '/';
      final isOnboarding = loc == '/onboarding';

      // Allow splash and onboarding without auth
      if (isSplash || isOnboarding) return null;

      // Not authenticated → force login
      if (!isAuthenticated && !isAuthRoute) return '/auth/login';

      // Authenticated: check email verification
      if (isAuthenticated) {
        final verified = AuthService.emailVerified;

        // Email NOT verified → force verification screen
        if (verified == false && loc != '/auth/verify-email') {
          return '/auth/verify-email';
        }

        // Email verified → redirect away from auth routes to home
        if (verified == true && isAuthRoute) {
          return '/guest/home';
        }

        // verified == null (unknown): stay on current screen, let it resolve
      }

      return null;
    },
    routes: [
      // === SPLASH & ONBOARDING ===
      GoRoute(
        path: '/',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // === AUTH ROUTES ===
      GoRoute(
        path: '/auth/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmailVerificationScreen(),
      ),

      // === GUEST MODE ===
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            GuestShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _guestShellKey,
            routes: [
              GoRoute(
                path: '/guest/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guest/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guest/bookings',
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guest/chat',
                builder: (context, state) => const ConversationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guest/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // === HOST MODE ===
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            HostShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _hostShellKey,
            routes: [
              GoRoute(
                path: '/host/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/host/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/host/listings',
                builder: (context, state) => const HostListingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/host/wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/host/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // === FULL-SCREEN ROUTES ===
      GoRoute(
        path: '/listing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) return const HomeScreen();
          return ListingDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/checkout/:listingId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['listingId'];
          if (id == null || id.isEmpty) return const HomeScreen();
          return CheckoutScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/booking-confirmed',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookingConfirmedScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['conversationId'];
          if (id == null || id.isEmpty) return const ConversationsScreen();
          return ChatScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/host/create-listing',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/host-benefits',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HostBenefitsScreen(),
      ),
      GoRoute(
        path: '/terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/payment-methods',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/identity-verification',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KycScreen(),
      ),
      GoRoute(
        path: '/help-center',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/booking-detail/:bookingId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['bookingId'];
          if (id == null || id.isEmpty) return const BookingsScreen();
          return BookingDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/write-review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return WriteReviewScreen(
            bookingId: extra['bookingId'] ?? '',
            listingId: extra['listingId'] ?? '',
            hostId: extra['hostId'] ?? '',
            listingTitle: extra['listingTitle'],
          );
        },
      ),
      GoRoute(
        path: '/quick-services',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuickServicesScreen(),
      ),
      GoRoute(
        path: '/publish-service',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final mode = state.extra as String? ?? 'offer';
          return PublishServiceScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/disputes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DisputesScreen(),
      ),
      GoRoute(
        path: '/dispute/:disputeId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['disputeId'];
          if (id == null || id.isEmpty) return const DisputesScreen();
          return DisputeDetailScreen(disputeId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/reviews/:listingId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['listingId'];
          if (id == null || id.isEmpty) return const HomeScreen();
          return ReviewsListScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/host/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],
  );
});
