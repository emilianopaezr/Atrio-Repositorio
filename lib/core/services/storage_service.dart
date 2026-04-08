import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../utils/constants.dart';

/// Service for Supabase Storage operations
class StorageService {
  StorageService._();

  static SupabaseClient get _client => SupabaseConfig.client;

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxAvatarSizeBytes = 2 * 1024 * 1024; // 2MB

  static void _validateFileSize(Uint8List bytes, int maxSize) {
    if (bytes.length > maxSize) {
      throw Exception('Archivo demasiado grande. Máximo ${(maxSize / 1024 / 1024).toStringAsFixed(0)}MB');
    }
  }

  /// Sanitize filename to prevent path traversal attacks
  static String _sanitizeFileName(String fileName) {
    // Remove path traversal characters and directory separators
    var safe = fileName.replaceAll(RegExp(r'[/\\]'), '_');
    safe = safe.replaceAll('..', '_');
    // Only allow safe characters
    safe = safe.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    if (safe.isEmpty) safe = 'file';
    // Limit length
    if (safe.length > 100) safe = safe.substring(0, 100);
    return safe;
  }

  static const _allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  static const _allowedKycExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  static const _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'pdf': 'application/pdf',
  };

  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return _mimeTypes[ext] ?? 'image/jpeg';
  }

  static String _validateImageExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (!_allowedImageExtensions.contains(ext)) {
      return '${fileName.split('.').first}.jpg';
    }
    return fileName;
  }

  /// Upload a listing image
  static Future<String> uploadListingImage({
    required String hostId,
    required String listingId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    _validateFileSize(fileBytes, maxFileSizeBytes);
    final safeName = _validateImageExtension(_sanitizeFileName(fileName));
    final path = '$hostId/$listingId/$safeName';

    await _client.storage
        .from(AppConstants.bucketListings)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getMimeType(safeName),
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
    _validateFileSize(fileBytes, maxAvatarSizeBytes);
    final safeName = _validateImageExtension(_sanitizeFileName(fileName));
    final path = '$userId/$safeName';

    await _client.storage
        .from(AppConstants.bucketAvatars)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getMimeType(safeName),
            upsert: true,
          ),
        );

    return _client.storage
        .from(AppConstants.bucketAvatars)
        .getPublicUrl(path);
  }

  /// Upload chat image (private bucket → returns long-lived signed URL)
  static Future<String> uploadChatImage({
    required String conversationId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    _validateFileSize(fileBytes, maxFileSizeBytes);
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sesión expirada. Inicia sesión nuevamente.');
    }
    final safeName = _validateImageExtension(_sanitizeFileName(fileName));
    final ts = DateTime.now().millisecondsSinceEpoch;
    // Path includes conversationId and userId (matches RLS policies) and a
    // unique timestamp prefix to prevent collisions across messages.
    final path = '$conversationId/$userId/${ts}_$safeName';

    await _client.storage
        .from(AppConstants.bucketChat)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getMimeType(safeName),
            upsert: false,
          ),
        );

    // chat bucket is private → public URL would 403. Use a signed URL with
    // 1-year expiry so the receiver can render it directly.
    return await _client.storage
        .from(AppConstants.bucketChat)
        .createSignedUrl(path, 60 * 60 * 24 * 365);
  }

  /// Upload KYC document (only JPG, PNG, PDF allowed)
  static Future<String> uploadKycDocument({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    _validateFileSize(fileBytes, maxFileSizeBytes);
    final safeName = _sanitizeFileName(fileName);
    final ext = safeName.split('.').last.toLowerCase();
    if (!_allowedKycExtensions.contains(ext)) {
      throw Exception('Tipo de archivo no permitido. Solo JPG, PNG o PDF.');
    }
    final path = '$userId/$safeName';

    await _client.storage
        .from(AppConstants.bucketKyc)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getMimeType(safeName),
            upsert: true,
          ),
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
