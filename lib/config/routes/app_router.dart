import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
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
import '../../shared/layouts/guest_shell.dart';
import '../../shared/layouts/host_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _guestShellKey = GlobalKey<NavigatorState>();
final _hostShellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/guest/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) return '/auth/login';
      if (isAuthenticated && isAuthRoute) return '/guest/home';
      return null;
    },
    routes: [
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

      // === GUEST MODE ===
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            GuestShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            navigatorKey: _guestShellKey,
            routes: [
              GoRoute(
                path: '/guest/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guest/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Tab 2: Bookings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guest/bookings',
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),
          // Tab 3: Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guest/chat',
                builder: (context, state) => const ConversationsScreen(),
              ),
            ],
          ),
          // Tab 4: Profile
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
          // Tab 0: Dashboard
          StatefulShellBranch(
            navigatorKey: _hostShellKey,
            routes: [
              GoRoute(
                path: '/host/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Calendar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/host/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          // Tab 2: Listings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/host/listings',
                builder: (context, state) => const HostListingsScreen(),
              ),
            ],
          ),
          // Tab 3: Wallet
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/host/wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          // Tab 4: Profile
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

      // === FULL-SCREEN ROUTES (no bottom nav) ===
      GoRoute(
        path: '/listing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/checkout/:listingId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CheckoutScreen(listingId: state.pathParameters['listingId']!),
      ),
      GoRoute(
        path: '/booking-confirmed',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookingConfirmedScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId']!),
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
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
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
        builder: (context, state) => DisputeDetailScreen(
          disputeId: state.pathParameters['disputeId']!,
        ),
      ),
    ],
  );
});
