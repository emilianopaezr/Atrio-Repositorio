import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/atrio_button.dart';
import '../../../shared/widgets/atrio_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return;

      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        _nameController.text = data['display_name'] as String? ?? '';
        _phoneController.text = data['phone'] as String? ?? '';
        _bioController.text = data['bio'] as String? ?? '';
        _avatarUrl = data['photo_url'] as String?;
      }
    } catch (e) {
      debugPrint('_loadProfile error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return;

      final ext = picked.path.split('.').last;
      final path = '$userId/avatar.$ext';
      final bytes = await picked.readAsBytes();

      await SupabaseConfig.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = SupabaseConfig.client.storage
          .from('avatars')
          .getPublicUrl(path);

      // Add cache-buster
      final urlWithCacheBust = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await SupabaseConfig.client.from('profiles').update({
        'photo_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        setState(() => _avatarUrl = urlWithCacheBust);
        ref.invalidate(userProfileStreamProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).editProfilePhotoUpdated,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            backgroundColor: AtrioColors.neonLime,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('_pickAndUploadAvatar error: $e');
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return;

      await SupabaseConfig.client.from('profiles').update({
        'display_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      ref.invalidate(userProfileStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).editProfileUpdatedOk),
            backgroundColor: AtrioColors.neonLimeDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('_saveProfile error: $e');
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.editProfileTitle,
          style: AtrioTypography.headingSmall.copyWith(
            color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AtrioColors.neonLimeDark),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor:
                                AtrioColors.neonLimeDark.withValues(alpha: 0.15),
                            backgroundImage: _avatarUrl != null
                                ? CachedNetworkImageProvider(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? const Icon(Icons.person,
                                    size: 56, color: AtrioColors.neonLimeDark)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AtrioColors.neonLimeDark,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AtrioColors.hostBackground
                                      : AtrioColors.guestBackground,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.editProfileChangePhoto,
                      style: AtrioTypography.labelMedium.copyWith(
                        color: AtrioColors.neonLimeDark,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name
                    AtrioTextField(
                      controller: _nameController,
                      label: l.editProfileFullName,
                      hint: l.editProfileNameHint,
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l.editProfileNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email (read only)
                    AtrioTextField(
                      label: l.editProfileEmailLabel,
                      hint: AuthService.currentUser?.email ?? '',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    AtrioTextField(
                      controller: _phoneController,
                      label: l.editProfilePhone,
                      hint: l.editProfilePhoneHint,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    ),
                    const SizedBox(height: 20),

                    // Bio
                    AtrioTextField(
                      controller: _bioController,
                      label: l.editProfileAboutYou,
                      hint: l.editProfileAboutHint,
                      maxLines: 4,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 32),

                    AtrioButton(
                      label: l.editProfileSaveChanges,
                      onTap: _saveProfile,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
