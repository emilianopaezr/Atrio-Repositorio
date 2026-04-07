import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../utils/constants.dart';

/// Generic database service for Supabase PostgREST queries
class DatabaseService {
  DatabaseService._();

  static SupabaseClient get _client => SupabaseConfig.client;

  /// Get current authenticated user ID or throw
  static String get _currentUserId {
    final uid = SupabaseConfig.auth.currentUser?.id;
    if (uid == null) throw Exception('No authenticated user');
    return uid;
  }

  /// Verify the caller is the specified user
  static void _assertIsUser(String userId) {
    if (_currentUserId != userId) {
      throw Exception('Unauthorized: user mismatch');
    }
  }

  // =============================================
  // LISTINGS
  // =============================================

  /// Fetch all published listings with optional filters
  static Future<List<Map<String, dynamic>>> getPublishedListings({
    String? type,
    String? city,
    String? category,
    String? search,
    int limit = AppConstants.pageSize,
    int offset = 0,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    var query = _client
        .from(AppConstants.tableListings)
        .select('*, host:profiles!host_id(id, display_name, photo_url, is_verified)')
        .eq('status', 'published');

    if (type != null) {
      query = query.eq('type', type);
    }
    if (city != null) {
      query = query.eq('city', city);
    }
    if (category != null) {
      query = query.eq('category', category);
    }
    if (search != null && search.isNotEmpty) {
      // Sanitize search input: remove PostgREST filter special chars and limit length
      final truncated = search.length > 100 ? search.substring(0, 100) : search;
      final sanitized = truncated
          .replaceAll(RegExp(r'[%_\\()\[\]{}|^$.*+?<>;"' "'" r'`/]'), '')
          .trim();
      if (sanitized.isNotEmpty && sanitized.length >= 2) {
        query = query.or('title.ilike.%$sanitized%,description.ilike.%$sanitized%');
      }
    }

    final response = await query
        .order(orderBy, ascending: ascending)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch featured listings
  static Future<List<Map<String, dynamic>>> getFeaturedListings({
    int limit = 10,
  }) async {
    final response = await _client
        .from(AppConstants.tableListings)
        .select('*, host:profiles!host_id(id, display_name, photo_url, is_verified)')
        .eq('status', 'published')
        .eq('is_featured', true)
        .order('rating', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch a single listing by ID
  static Future<Map<String, dynamic>?> getListingById(String id) async {
    final response = await _client
        .from(AppConstants.tableListings)
        .select('*, host:profiles!host_id(id, display_name, photo_url, is_verified, bio)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    // Fetch host_profile separately (no direct FK from listings to host_profiles)
    final hostId = response['host_id'] as String?;
    if (hostId != null) {
      try {
        final hostProfile = await _client
            .from(AppConstants.tableHostProfiles)
            .select('is_superhost, response_rate, total_earnings')
            .eq('id', hostId)
            .maybeSingle();
        if (hostProfile != null && response['host'] != null) {
          final host = Map<String, dynamic>.from(response['host'] as Map<String, dynamic>);
          host.addAll(hostProfile);
          response['host'] = host;
        }
      } catch (_) {
        // Host profile may not exist
      }
    }

    return response;
  }

  /// Fetch listings by host ID
  static Future<List<Map<String, dynamic>>> getHostListings(String hostId) async {
    final response = await _client
        .from(AppConstants.tableListings)
        .select()
        .eq('host_id', hostId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new listing
  static Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tableListings)
        .insert(data)
        .select()
        .single();

    return response;
  }

  /// Update a listing
  static Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from(AppConstants.tableListings)
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return response;
  }

  /// Delete a listing
  static Future<void> deleteListing(String id) async {
    // Verify the current user owns this listing
    final listing = await _client
        .from(AppConstants.tableListings)
        .select('host_id')
        .eq('id', id)
        .maybeSingle();
    if (listing == null) return;
    if (listing['host_id'] != _currentUserId) {
      throw Exception('Unauthorized: not the listing owner');
    }
    await _client.from(AppConstants.tableListings).delete().eq('id', id);
  }

  /// Increment view count
  static Future<void> incrementViewCount(String listingId) async {
    await _client.rpc('increment_view_count', params: {'listing_id_param': listingId});
  }

  // =============================================
  // PROFILES
  // =============================================

  /// Get user profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Update user profile (only own profile)
  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    _assertIsUser(userId);
    final response = await _client
        .from(AppConstants.tableProfiles)
        .update(data)
        .eq('id', userId)
        .select()
        .single();

    return response;
  }

  /// Toggle favorite listing (only own favorites)
  static Future<void> toggleFavorite(String userId, String listingId) async {
    _assertIsUser(userId);
    final profile = await getProfile(userId);
    if (profile == null) return;

    final favorites = List<String>.from(profile['favorite_listing_ids'] ?? []);

    if (favorites.contains(listingId)) {
      favorites.remove(listingId);
    } else {
      favorites.add(listingId);
    }

    await _client
        .from(AppConstants.tableProfiles)
        .update({'favorite_listing_ids': favorites})
        .eq('id', userId);
  }

  /// Become a host
  static Future<void> becomeHost(String userId) async {
    await _client
        .from(AppConstants.tableProfiles)
        .update({'is_host': true})
        .eq('id', userId);

    // Create host profile if not exists
    await _client.from(AppConstants.tableHostProfiles).upsert({
      'id': userId,
      'joined_as_host_at': DateTime.now().toIso8601String(),
    });
  }

  // =============================================
  // BOOKINGS
  // =============================================

  /// Create a booking
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tableBookings)
        .insert(data)
        .select('*, listing:listings(id, title, images, type, base_price, price_unit, city)')
        .single();

    return response;
  }

  /// Get guest bookings
  static Future<List<Map<String, dynamic>>> getGuestBookings(
    String guestId, {
    String? status,
  }) async {
    var query = _client
        .from(AppConstants.tableBookings)
        .select('*, listing:listings(id, title, images, type, base_price, price_unit, city), host:profiles!host_id(id, display_name, photo_url)')
        .eq('guest_id', guestId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get host bookings
  static Future<List<Map<String, dynamic>>> getHostBookings(
    String hostId, {
    String? status,
  }) async {
    var query = _client
        .from(AppConstants.tableBookings)
        .select('*, listing:listings(id, title, images, type), guest:profiles!guest_id(id, display_name, photo_url)')
        .eq('host_id', hostId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get a single booking by ID with listing and host/guest info
  static Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    final response = await _client
        .from(AppConstants.tableBookings)
        .select('*, listing:listings(id, title, images, type, base_price, price_unit, city, rating, address), host:profiles!host_id(id, display_name, photo_url, is_verified), guest:profiles!guest_id(id, display_name, photo_url)')
        .eq('id', bookingId)
        .maybeSingle();

    return response;
  }

  /// Update booking status
  static Future<void> updateBookingStatus(String bookingId, String status) async {
    await _client
        .from(AppConstants.tableBookings)
        .update({'status': status})
        .eq('id', bookingId);
  }

  // =============================================
  // AVAILABILITY
  // =============================================

  /// Get availability for a listing in a date range
  static Future<List<Map<String, dynamic>>> getAvailability(
    String listingId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from(AppConstants.tableAvailability)
        .select()
        .eq('listing_id', listingId);

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('date');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Set date availability
  static Future<void> setDateAvailability(
    String listingId,
    DateTime date,
    bool isAvailable, {
    double? customPrice,
  }) async {
    await _client.from(AppConstants.tableAvailability).upsert(
      {
        'listing_id': listingId,
        'date': date.toIso8601String().split('T')[0],
        'is_available': isAvailable,
        'custom_price': ?customPrice,
      },
      onConflict: 'listing_id,date',
    );
  }

  /// Batch set availability for date range
  static Future<void> setDateRangeAvailability(
    String listingId,
    DateTime startDate,
    DateTime endDate,
    bool isAvailable,
  ) async {
    final dates = <Map<String, dynamic>>[];
    var current = startDate;
    while (current.isBefore(endDate)) {
      dates.add({
        'listing_id': listingId,
        'date': current.toIso8601String().split('T')[0],
        'is_available': isAvailable,
      });
      current = current.add(const Duration(days: 1));
    }
    if (dates.isNotEmpty) {
      await _client.from(AppConstants.tableAvailability).upsert(
            dates,
            onConflict: 'listing_id,date',
          );
    }
  }

  /// Get booked dates via RPC (efficient)
  static Future<List<Map<String, dynamic>>> getBookedDates(
    String listingId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client.rpc('get_booked_dates', params: {
        'p_listing_id': listingId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (_) {
      // Fallback: query bookings directly
      return _getBookedDatesFallback(listingId, startDate, endDate);
    }
  }

  static Future<List<Map<String, dynamic>>> _getBookedDatesFallback(
    String listingId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final bookings = await _client
        .from(AppConstants.tableBookings)
        .select('id, check_in, check_out, status')
        .eq('listing_id', listingId)
        .inFilter('status', ['pending', 'confirmed', 'active'])
        .lte('check_in', endDate.toIso8601String())
        .gte('check_out', startDate.toIso8601String());

    final blocked = await _client
        .from(AppConstants.tableAvailability)
        .select('date, booking_id')
        .eq('listing_id', listingId)
        .eq('is_available', false)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    final results = <Map<String, dynamic>>[];

    for (final b in bookings) {
      var d = DateTime.parse(b['check_in'].toString());
      final end = DateTime.parse(b['check_out'].toString());
      while (d.isBefore(end)) {
        results.add({
          'booked_date': d.toIso8601String().split('T')[0],
          'is_blocked': false,
          'booking_id': b['id'],
          'booking_status': b['status'],
        });
        d = d.add(const Duration(days: 1));
      }
    }

    for (final a in blocked) {
      results.add({
        'booked_date': a['date'],
        'is_blocked': true,
        'booking_id': a['booking_id'],
        'booking_status': null,
      });
    }

    return results;
  }

  /// Get booked time slots for a specific date
  static Future<List<Map<String, dynamic>>> getBookedTimeSlots(
    String listingId,
    DateTime date,
  ) async {
    try {
      final response = await _client.rpc('get_booked_time_slots', params: {
        'p_listing_id': listingId,
        'p_date': date.toIso8601String().split('T')[0],
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (_) {
      // Fallback
      final response = await _client
          .from('time_slot_bookings')
          .select('start_time, end_time, status, booking_id')
          .eq('listing_id', listingId)
          .eq('slot_date', date.toIso8601String().split('T')[0])
          .inFilter('status', ['held', 'confirmed']);
      return List<Map<String, dynamic>>.from(response);
    }
  }

  /// Check date availability via RPC
  static Future<bool> checkDatesAvailable(
    String listingId,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      final response = await _client.rpc('check_dates_available', params: {
        'p_listing_id': listingId,
        'p_check_in': checkIn.toIso8601String().split('T')[0],
        'p_check_out': checkOut.toIso8601String().split('T')[0],
      });
      return response == true;
    } catch (_) {
      return false; // Fail-safe: block booking if availability check fails
    }
  }

  /// Book time slots atomically via RPC
  static Future<bool> bookTimeSlots(
    String listingId,
    String bookingId,
    DateTime date,
    List<Map<String, String>> slots,
  ) async {
    try {
      final response = await _client.rpc('check_and_book_slots', params: {
        'p_listing_id': listingId,
        'p_booking_id': bookingId,
        'p_slot_date': date.toIso8601String().split('T')[0],
        'p_slots': slots,
      });
      return response == true;
    } catch (_) {
      return false;
    }
  }

  /// Create booking with availability check (atomic)
  static Future<Map<String, dynamic>?> createBookingWithCheck(
    Map<String, dynamic> data,
  ) async {
    final rentalMode = data['rental_mode'] ?? 'nights';

    if (rentalMode == 'nights' || rentalMode == 'full_day') {
      final available = await checkDatesAvailable(
        data['listing_id'],
        DateTime.parse(data['check_in']),
        DateTime.parse(data['check_out']),
      );
      if (!available) return null;
    }

    final response = await _client
        .from(AppConstants.tableBookings)
        .insert(data)
        .select('*, listing:listings(id, title, images, type, base_price, price_unit, city, rental_mode)')
        .single();

    // For hours: book time slots
    if (rentalMode == 'hours' && data['time_slots'] != null) {
      final slots = (data['time_slots'] as List)
          .map((s) => {'start_time': s['start_time'].toString(), 'end_time': s['end_time'].toString()})
          .toList();
      await bookTimeSlots(
        data['listing_id'],
        response['id'],
        DateTime.parse(data['booking_date'] ?? data['check_in']),
        slots,
      );
    }

    return response;
  }

  /// Count completed/confirmed bookings for a host (for promotional pricing)
  /// First 5 bookings per host get 1% commission, then 7%
  static Future<int> getHostBookingsCount(String hostId) async {
    try {
      final response = await _client
          .from(AppConstants.tableBookings)
          .select('id')
          .eq('host_id', hostId)
          .inFilter('status', ['confirmed', 'completed']);
      return (response as List).length;
    } catch (_) {
      return 999; // On error, assume past promo to avoid giving wrong discount
    }
  }

  // =============================================
  // CONVERSATIONS & MESSAGES
  // =============================================

  /// Get conversations for a user
  static Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    final response = await _client
        .from(AppConstants.tableConversations)
        .select('*, listing:listings(id, title, images)')
        .contains('participant_ids', [userId])
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get or create conversation between two users
  static Future<Map<String, dynamic>> getOrCreateConversation({
    required String userId1,
    required String userId2,
    String? listingId,
    String? bookingId,
  }) async {
    // Try to find existing conversation
    final existing = await _client
        .from(AppConstants.tableConversations)
        .select()
        .contains('participant_ids', [userId1])
        .contains('participant_ids', [userId2]);

    final existingList = List<Map<String, dynamic>>.from(existing);

    if (existingList.isNotEmpty) {
      return existingList.first;
    }

    // Create new conversation
    final response = await _client
        .from(AppConstants.tableConversations)
        .insert({
          'participant_ids': [userId1, userId2],
          'listing_id': ?listingId,
          'booking_id': ?bookingId,
        })
        .select()
        .single();

    return response;
  }

  /// Get messages for a conversation
  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from(AppConstants.tableMessages)
        .select('*, sender:profiles!sender_id(id, display_name, photo_url)')
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Send a message
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String type = 'text',
    String? imageUrl,
  }) async {
    final message = await _client
        .from(AppConstants.tableMessages)
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'text': text,
          'type': type,
          'image_url': ?imageUrl,
        })
        .select()
        .single();

    // Update conversation last message
    await _client
        .from(AppConstants.tableConversations)
        .update({
          'last_message_text': text,
          'last_message_sender': senderId,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    return message;
  }

  // =============================================
  // REVIEWS
  // =============================================

  /// Get reviews for a listing
  static Future<List<Map<String, dynamic>>> getListingReviews(
    String listingId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from(AppConstants.tableReviews)
        .select('*, reviewer:profiles!reviewer_id(id, display_name, photo_url)')
        .eq('listing_id', listingId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a review
  static Future<Map<String, dynamic>> createReview(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tableReviews)
        .insert(data)
        .select()
        .single();

    return response;
  }

  // =============================================
  // HOST WALLET / TRANSACTIONS
  // =============================================

  /// Get host profile (financial)
  static Future<Map<String, dynamic>?> getHostProfile(String hostId) async {
    final response = await _client
        .from(AppConstants.tableHostProfiles)
        .select()
        .eq('id', hostId)
        .maybeSingle();

    return response;
  }

  /// Get transactions for host
  static Future<List<Map<String, dynamic>>> getHostTransactions(
    String hostId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from(AppConstants.tableTransactions)
        .select()
        .eq('host_id', hostId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  // =============================================
  // NOTIFICATIONS
  // =============================================

  /// Get notifications for user
  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    int limit = 30,
  }) async {
    final response = await _client
        .from(AppConstants.tableNotifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Mark notification as read
  static Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from(AppConstants.tableNotifications)
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Get unread notification count
  static Future<int> getUnreadNotificationCount(String userId) async {
    final response = await _client
        .from(AppConstants.tableNotifications)
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .count(CountOption.exact);

    return response.count;
  }

  // =============================================
  // DISPUTES
  // =============================================

  /// Get disputes for a user (as guest or host)
  static Future<List<Map<String, dynamic>>> getUserDisputes(
    String userId, {
    String? status,
  }) async {
    final response = await _client
        .from(AppConstants.tableDisputes)
        .select('*, guest:profiles!guest_id(id, display_name, photo_url), host:profiles!host_id(id, display_name, photo_url)')
        .or('guest_id.eq.$userId,host_id.eq.$userId')
        .order('created_at', ascending: false);

    final list = List<Map<String, dynamic>>.from(response);
    if (status != null) {
      return list.where((d) => d['status'] == status).toList();
    }
    return list;
  }

  /// Get a single dispute by ID
  static Future<Map<String, dynamic>?> getDisputeById(String disputeId) async {
    final response = await _client
        .from(AppConstants.tableDisputes)
        .select('*, guest:profiles!guest_id(id, display_name, photo_url), host:profiles!host_id(id, display_name, photo_url)')
        .eq('id', disputeId)
        .maybeSingle();

    return response;
  }

  // =============================================
  // STORAGE
  // =============================================

  /// Upload an image to a bucket
  static Future<String> uploadImage({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String contentType = 'image/jpeg',
  }) async {
    await _client.storage.from(bucket).uploadBinary(
      path,
      fileBytes as dynamic,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  /// Delete an image from a bucket
  static Future<void> deleteImage(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
