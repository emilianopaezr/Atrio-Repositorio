import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  /// Compress image bytes to max 1200px width and 85% JPEG quality.
  /// Returns original bytes if compression fails or on unsupported platforms.
  static Future<Uint8List> _compressImage(Uint8List bytes, {int maxWidth = 1200, int quality = 85}) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      debugPrint('Image compressed: ${bytes.length} → ${result.length} bytes');
      return result;
    } catch (e) {
      debugPrint('Image compression skipped: $e');
      return bytes;
    }
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
    final compressed = await _compressImage(fileBytes);
    final safeName = _validateImageExtension(_sanitizeFileName(fileName));
    final path = '$hostId/$listingId/$safeName';

    await _client.storage
        .from(AppConstants.bucketListings)
        .uploadBinary(
          path,
          compressed,
          fileOptions: FileOptions(
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
    _validateFileSize(fileBytes, maxAvatarSizeBytes);
    final compressed = await _compressImage(fileBytes, maxWidth: 400, quality: 80);
    final safeName = _validateImageExtension(_sanitizeFileName(fileName));
    final path = '$userId/$safeName';

    await _client.storage
        .from(AppConstants.bucketAvatars)
        .uploadBinary(
          path,
          compressed,
          fileOptions: FileOptions(
            contentType: 'image/jpeg',
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
    // IMPORTANT: First folder MUST be auth.uid() — Supabase default storage
    // RLS policy enforces (storage.foldername(name))[1] = auth.uid()::text.
    // Path layout: {userId}/{conversationId}/{timestamp}_{filename}
    final path = '$userId/$conversationId/${ts}_$safeName';

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

  /// Best-effort delete of a chat image given its public OR signed URL.
  /// Extracts the storage path after '/object/(public|sign)/chat/' and
  /// removes that object. Errors are swallowed (the message row is the
  /// source of truth — orphan files are tolerable).
  static Future<void> deleteChatImageByUrl(String url) async {
    try {
      final marker = RegExp(r'/object/(?:public|sign|authenticated)/chat/');
      final m = marker.firstMatch(url);
      if (m == null) return;
      var path = url.substring(m.end);
      // Strip query string (signed URLs have ?token=...)
      final q = path.indexOf('?');
      if (q >= 0) path = path.substring(0, q);
      if (path.isEmpty) return;
      await _client.storage.from(AppConstants.bucketChat).remove([path]);
    } catch (e) {
      // Intentionally ignored — keep the user-facing delete flow snappy.
    }
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
