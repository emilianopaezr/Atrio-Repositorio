import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// Editorial profile editor.
///
/// Layout: full-bleed header (eyebrow + title), framed avatar with overlapping
/// camera FAB, two grouped sections ("Datos personales" + "Acerca de ti"),
/// sticky lime CTA in the footer. Matches the rest of Atrio's editorial
/// system (lime accent bar, INTER 800 titles, surface cards 16-radius).
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
  final _professionController = TextEditingController();
  String? _decadeBorn;
  Set<String> _languages = {};
  Set<String> _interests = {};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;
  String? _initialName;
  String? _initialPhone;
  String? _initialBio;
  String? _initialProfession;
  String? _initialDecade;
  Set<String> _initialLanguages = {};
  Set<String> _initialInterests = {};

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_rebuild);
    _phoneController.addListener(_rebuild);
    _bioController.addListener(_rebuild);
    _professionController.addListener(_rebuild);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  void _rebuild() => mounted ? setState(() {}) : null;

  bool get _hasChanges =>
      _nameController.text.trim() != (_initialName ?? '') ||
      _phoneController.text.trim() != (_initialPhone ?? '') ||
      _bioController.text.trim() != (_initialBio ?? '') ||
      _professionController.text.trim() != (_initialProfession ?? '') ||
      _decadeBorn != _initialDecade ||
      !_setsEqual(_languages, _initialLanguages) ||
      !_setsEqual(_interests, _initialInterests);

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
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
        _professionController.text = data['profession'] as String? ?? '';
        _decadeBorn = data['decade_born'] as String?;
        _languages = (data['languages'] as List?)
                ?.cast<String>()
                .toSet() ??
            <String>{};
        _interests = (data['interests'] as List?)
                ?.cast<String>()
                .toSet() ??
            <String>{};
        _avatarUrl = data['photo_url'] as String?;
        _initialName = _nameController.text.trim();
        _initialPhone = _phoneController.text.trim();
        _initialBio = _bioController.text.trim();
        _initialProfession = _professionController.text.trim();
        _initialDecade = _decadeBorn;
        _initialLanguages = Set.from(_languages);
        _initialInterests = Set.from(_interests);
      }
    } catch (e) {
      debugPrint('_loadProfile error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
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

      // Store the cache-busted URL in DB so every subsequent fetch
      // gets the latest version without us having to invalidate the
      // CachedNetworkImage cache manually.
      final publicUrl =
          SupabaseConfig.client.storage.from('avatars').getPublicUrl(path);
      final cacheBust =
          '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await SupabaseConfig.client.from('profiles').update({
        'photo_url': cacheBust,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        setState(() => _avatarUrl = cacheBust);
        ref.invalidate(userProfileStreamProvider);
        _toast(AppLocalizations.of(context).editProfilePhotoUpdated);
      }
    } catch (e) {
      debugPrint('_pickAndUploadAvatar error: $e');
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return;

      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();
      final profession = _professionController.text.trim();
      await SupabaseConfig.client.from('profiles').update({
        'display_name': _nameController.text.trim(),
        'phone': phone.isNotEmpty ? phone : null,
        'bio': bio.isNotEmpty ? bio : null,
        'profession': profession.isNotEmpty ? profession : null,
        'decade_born': _decadeBorn,
        'languages': _languages.toList(),
        'interests': _interests.toList(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      ref.invalidate(userProfileStreamProvider);

      if (mounted) {
        _toast(AppLocalizations.of(context).editProfileUpdatedOk);
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('_saveProfile error: $e');
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AtrioColors.neonLime,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final email = AuthService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header (sized to fit) ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AtrioColors.guestTextPrimary),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(height: 6),
                    const PageEyebrow(text: 'Tu perfil'),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.editProfileTitle,
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AtrioColors.neonLimeDark,
                          strokeWidth: 2.5,
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ─── Avatar ───
                              Center(
                                child: _AvatarPicker(
                                  url: _avatarUrl,
                                  uploading: _uploadingAvatar,
                                  onTap: _pickAndUploadAvatar,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: _uploadingAvatar
                                      ? null
                                      : _pickAndUploadAvatar,
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        AtrioColors.guestTextPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                  child: Text(
                                    _uploadingAvatar
                                        ? 'Subiendo…'
                                        : l.editProfileChangePhoto,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AtrioColors.guestTextPrimary,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 1.5,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ─── Section: Datos personales ───
                              _SectionHeader(label: 'DATOS PERSONALES'),
                              const SizedBox(height: 14),

                              _FieldLabel('Nombre completo'),
                              const SizedBox(height: 6),
                              _Field(
                                controller: _nameController,
                                hint: l.editProfileNameHint,
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? l.editProfileNameRequired
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('Correo electrónico'),
                              const SizedBox(height: 6),
                              _ReadOnlyField(
                                value: email,
                                prefixIcon: Icons.mail_outline_rounded,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AtrioColors.neonLime
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'VERIFICADO',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AtrioColors.neonLimeDark,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'No se puede cambiar.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AtrioColors.guestTextTertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('Teléfono'),
                              const SizedBox(height: 6),
                              _Field(
                                controller: _phoneController,
                                hint: l.editProfilePhoneHint,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d\s\+\-\(\)]')),
                                  LengthLimitingTextInputFormatter(20),
                                ],
                                prefixIcon: Icons.phone_outlined,
                              ),
                              const SizedBox(height: 28),

                              // ─── Section: Acerca de ti ───
                              _SectionHeader(label: 'ACERCA DE TI'),
                              const SizedBox(height: 14),

                              _FieldLabel('Biografía'),
                              const SizedBox(height: 6),
                              _Field(
                                controller: _bioController,
                                hint: l.editProfileAboutHint,
                                maxLines: 5,
                                maxLength: 200,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'Contale a los huéspedes quién sos. '
                                  'Aumenta la confianza para tus reservas.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AtrioColors.guestTextTertiary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('A qué te dedicas'),
                              const SizedBox(height: 6),
                              _Field(
                                controller: _professionController,
                                hint: 'Ej. Arquitecto, Diseñadora, Estudiante',
                                maxLength: 40,
                                prefixIcon: Icons.work_outline_rounded,
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('Década en que naciste'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ['60s', '70s', '80s', '90s', '00s', '10s']
                                    .map((d) {
                                  final selected = _decadeBorn == d;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _decadeBorn = selected ? null : d;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AtrioColors.guestTextPrimary
                                            : AtrioColors.guestSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? AtrioColors.guestTextPrimary
                                              : AtrioColors.guestCardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        d,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ? Colors.white
                                              : AtrioColors.guestTextPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('Idiomas que hablás'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ('es', 'Español'),
                                  ('en', 'Inglés'),
                                  ('pt', 'Portugués'),
                                  ('fr', 'Francés'),
                                  ('it', 'Italiano'),
                                  ('de', 'Alemán'),
                                ].map((lang) {
                                  final selected =
                                      _languages.contains(lang.$1);
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (selected) {
                                          _languages.remove(lang.$1);
                                        } else {
                                          _languages.add(lang.$1);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AtrioColors.neonLime
                                            : AtrioColors.guestSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? AtrioColors.neonLime
                                              : AtrioColors.guestCardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        lang.$2,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AtrioColors.guestTextPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('Tus intereses'),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'Marcá algunas cosas que te apasionen — '
                                  'ayuda a los huéspedes a conocerte.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AtrioColors.guestTextTertiary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  'Cocina',
                                  'Viajes',
                                  'Música',
                                  'Cine',
                                  'Fotografía',
                                  'Arte',
                                  'Lectura',
                                  'Naturaleza',
                                  'Yoga',
                                  'Fitness',
                                  'Surf',
                                  'Senderismo',
                                  'Vino',
                                  'Café',
                                  'Tecnología',
                                  'Diseño',
                                  'Mascotas',
                                  'Plantas',
                                  'Deporte',
                                  'Bailar',
                                ].map((i) {
                                  final selected = _interests.contains(i);
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (selected) {
                                          _interests.remove(i);
                                        } else if (_interests.length < 10) {
                                          _interests.add(i);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AtrioColors.neonLime
                                            : AtrioColors.guestSurface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selected
                                              ? AtrioColors.neonLime
                                              : AtrioColors.guestCardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        i,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AtrioColors.guestTextPrimary,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              _Footer(
                enabled: _hasChanges && !_isSaving,
                isSaving: _isSaving,
                onSave: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Avatar picker
// ═══════════════════════════════════════════════════════════════
class _AvatarPicker extends StatelessWidget {
  final String? url;
  final bool uploading;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.url,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Lime ring frame
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AtrioColors.guestSurface,
              border: Border.all(
                color: AtrioColors.guestCardBorder,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: ClipOval(
                child: url != null && url!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: url!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _AvatarPlaceholder(),
                        errorWidget: (_, _, _) => _AvatarPlaceholder(),
                      )
                    : _AvatarPlaceholder(),
              ),
            ),
          ),
          // Loading overlay
          if (uploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ),
          // Camera FAB
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AtrioColors.guestBackground,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AtrioColors.neonLime.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AtrioColors.neonLime.withValues(alpha: 0.18),
            AtrioColors.neonLime.withValues(alpha: 0.06),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 56,
        color: AtrioColors.neonLimeDark,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section / labels
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AtrioColors.neonLime,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextSecondary,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AtrioColors.guestTextPrimary,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Fields
// ═══════════════════════════════════════════════════════════════
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final int maxLines;
  final int? maxLength;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: AtrioColors.neonLimeDark,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AtrioColors.guestTextPrimary,
        letterSpacing: -0.2,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AtrioColors.guestTextTertiary,
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(prefixIcon,
                    size: 18, color: AtrioColors.guestTextSecondary),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AtrioColors.guestSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AtrioColors.guestCardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AtrioColors.guestTextPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AtrioColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AtrioColors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AtrioColors.error,
        ),
        counterStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AtrioColors.guestTextTertiary,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final IconData prefixIcon;
  final Widget? trailing;

  const _ReadOnlyField({
    required this.value,
    required this.prefixIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Row(
        children: [
          Icon(prefixIcon, size: 18, color: AtrioColors.guestTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AtrioColors.guestTextSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Footer CTA
// ═══════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final bool enabled;
  final bool isSaving;
  final VoidCallback onSave;

  const _Footer({
    required this.enabled,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AtrioColors.guestBackground,
        border: Border(
          top: BorderSide(color: AtrioColors.guestCardBorder, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: enabled ? onSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AtrioColors.neonLime,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            disabledBackgroundColor:
                AtrioColors.neonLime.withValues(alpha: 0.35),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.editProfileSaveChanges,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.black),
                  ],
                ),
        ),
      ),
    );
  }
}
