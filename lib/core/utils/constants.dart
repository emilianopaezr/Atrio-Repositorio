class AppConstants {
  AppConstants._();

  static const appName = 'Atrio';
  static const appTagline = 'Premium Marketplace';

  // Table names
  static const tableProfiles = 'profiles';
  static const tableListings = 'listings';
  static const tableAvailability = 'availability';
  static const tableBookings = 'bookings';
  static const tableConversations = 'conversations';
  static const tableMessages = 'messages';
  static const tableReviews = 'reviews';
  static const tableTransactions = 'transactions';
  static const tableHostProfiles = 'host_profiles';
  static const tableNotifications = 'notifications';
  static const tablePricingConfig = 'pricing_config';
  static const tableHostStats = 'host_stats';
  static const tableGuestStats = 'guest_stats';
  static const tableDisputes = 'disputes';

  // Storage buckets
  static const bucketListings = 'listings';
  static const bucketAvatars = 'avatars';
  static const bucketChat = 'chat';
  static const bucketKyc = 'kyc';

  // Pagination
  static const pageSize = 20;

  // Commission
  static const initialCommissionRate = 0.01;
  static const standardCommissionRate = 0.09;
  static const superhostCommissionRate = 0.07;
  static const maxCommissionUsd = 99.0;

  // Ratings
  static const superhostMinRating = 4.5;

  // API Keys
  static const String resendApiKey = 're_N79P3zqJ_6ydqnR9Pwwr7aQSMYCyw1iHr';
}
