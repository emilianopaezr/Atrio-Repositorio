import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../utils/constants.dart';

/// Service for Supabase Storage operations
class StorageService {
  StorageService._();

  static SupabaseClient get _client => SupabaseConfig.client;

  /// Upload a listing image
  static Future<String> uploadListingImage({
    required String hostId,
    required String listingId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final path = '$hostId/$listingId/$fileName';

    await _client.storage
        .from(AppConstants.bucketListings)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage
        .from(AppConstants.bucketListings)
        .getPublicUrl(path);
  }

  /// Upload user avatar
  static Future<String> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    String fileName = 'avatar.jpg',
  }) async {
    final path = '$userId/$fileName';

    await _client.storage
        .from(AppConstants.bucketAvatars)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage
        .from(AppConstants.bucketAvatars)
        .getPublicUrl(path);
  }

  /// Upload chat image
  static Future<String> uploadChatImage({
    required String conversationId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final path = '$conversationId/$fileName';

    await _client.storage
        .from(AppConstants.bucketChat)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage
        .from(AppConstants.bucketChat)
        .getPublicUrl(path);
  }

  /// Upload KYC document
  static Future<String> uploadKycDocument({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final path = '$userId/$fileName';

    await _client.storage
        .from(AppConstants.bucketKyc)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage
        .from(AppConstants.bucketKyc)
        .getPublicUrl(path);
  }

  /// Delete file from bucket
  static Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }

  /// Delete multiple listing images
  static Future<void> deleteListingImages(String hostId, String listingId) async {
    final files = await _client.storage
        .from(AppConstants.bucketListings)
        .list(path: '$hostId/$listingId');

    if (files.isNotEmpty) {
      final paths = files.map((f) => '$hostId/$listingId/${f.name}').toList();
      await _client.storage.from(AppConstants.bucketListings).remove(paths);
    }
  }
}
