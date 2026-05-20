import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/contact_phone_section.dart';

class PublishServiceScreen extends ConsumerStatefulWidget {
  /// 'offer' = ofrecer servicio, 'request' = solicitar servicio
  final String mode;
  const PublishServiceScreen({super.key, this.mode = 'offer'});

  @override
  ConsumerState<PublishServiceScreen> createState() =>
      _PublishServiceScreenState();
}

class _PublishServiceScreenState extends ConsumerState<PublishServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = 'moving';
  String _selectedUrgency = 'flexible';
  bool _isLoading = false;
  final List<XFile> _pickedImages = [];
  final List<Uint8List> _imageBytes = [];
  static const int _maxImages = 15;
  String? _userPhone;
  bool _showHostPhone = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return;
    try {
      final res = await SupabaseConfig.client
          .from('profiles')
          .select('phone')
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted || res == null) return;
      setState(() => _userPhone = res['phone'] as String?);
    } catch (_) {}
  }

  static const _categories = <(String, String, IconData)>[
    ('moving', 'Mudanza', Icons.local_shipping_rounded),
    ('cleaning', 'Limpieza', Icons.cleaning_services_rounded),
    ('assembly', 'Armado', Icons.handyman_rounded),
    ('events', 'Eventos', Icons.celebration_rounded),
    ('gardening', 'Jardinería', Icons.grass_rounded),
    ('repairs', 'Reparaciones', Icons.build_rounded),
    ('painting', 'Pintura', Icons.format_paint_rounded),
    ('plumbing', 'Plomería', Icons.plumbing_rounded),
    ('electrical', 'Electricidad', Icons.electrical_services_rounded),
    ('tech', 'Tecnología', Icons.computer_rounded),
    ('pets', 'Mascotas', Icons.pets_rounded),
    ('beauty', 'Belleza', Icons.face_retouching_natural_rounded),
    ('classes', 'Clases', Icons.school_rounded),
    ('cooking', 'Cocina', Icons.restaurant_rounded),
    ('other', 'Otro', Icons.more_horiz_rounded),
  ];

  static const _urgencies = <(String, IconData)>[
    ('today', Icons.bolt_rounded),
    ('tomorrow', Icons.wb_sunny_rounded),
    ('week', Icons.date_range_rounded),
    ('flexible', Icons.all_inclusive_rounded),
  ];

  String _categoryLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'moving': return l.psCatMoving;
      case 'cleaning': return l.psCatCleaning;
      case 'assembly': return l.psCatAssembly;
      case 'events': return l.psCatEvents;
      case 'gardening': return l.psCatGardening;
      case 'repairs': return l.psCatRepairs;
      case 'painting': return l.psCatPainting;
      case 'plumbing': return l.psCatPlumbing;
      case 'electrical': return l.psCatElectrical;
      case 'tech': return l.psCatTech;
      case 'pets': return l.psCatPets;
      case 'beauty': return l.psCatBeauty;
      case 'classes': return l.psCatClasses;
      case 'cooking': return l.psCatCooking;
      case 'other': return l.psCatOther;
      default: return key;
    }
  }

  String _urgencyLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'today': return l.psUrgencyToday;
      case 'tomorrow': return l.psUrgencyTomorrow;
      case 'week': return l.psUrgencyWeek;
      case 'flexible': return l.psUrgencyFlexible;
      default: return key;
    }
  }

  bool get _isOffer => widget.mode == 'offer';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final l = AppLocalizations.of(context);
    if (_pickedImages.length >= _maxImages) {
      _snack(l.psMaxPhotos(_maxImages), isError: true);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AtrioColors.guestSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AtrioColors.guestCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.psAddPhoto,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AtrioColors.guestTextPrimary),
                ),
                title: Text(
                  l.psGallery,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AtrioColors.guestTextPrimary),
                ),
                title: Text(
                  l.psCamera,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picker = ImagePicker();
    List<XFile> picked;
    final remaining = _maxImages - _pickedImages.length;
    if (source == ImageSource.gallery) {
      picked = await picker.pickMultiImage(
          maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (picked.length > remaining) picked = picked.sublist(0, remaining);
    } else {
      final photo = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85);
      picked = photo != null ? [photo] : [];
    }

    for (final img in picked) {
      if (_pickedImages.length >= _maxImages) break;
      final bytes = await img.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) _snack(l.psImageTooLarge, isError: true);
        continue;
      }
      final ext = img.path.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) continue;
      setState(() {
        _pickedImages.add(img);
        _imageBytes.add(bytes);
      });
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception(l.psNotAuthenticated);

      final imageUrls = <String>[];
      final tempListingId = DateTime.now().millisecondsSinceEpoch.toString();
      for (int i = 0; i < _pickedImages.length; i++) {
        final url = await StorageService.uploadListingImage(
          hostId: userId,
          listingId: tempListingId,
          fileBytes: _imageBytes[i],
          fileName: '${i}_${_pickedImages[i].name}',
        );
        imageUrls.add(url);
      }

      await SupabaseConfig.client.from('listings').insert({
        'host_id': userId,
        'type': 'service',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'images': imageUrls,
        'base_price': double.tryParse(_priceController.text.trim()) ?? 0,
        'price_unit': 'hour',
        'rental_mode': 'hours',
        'cancellation_policy': 'flexible',
        'instant_booking': false,
        'status': 'published',
        'tags': [_selectedCategory.toLowerCase()],
        'is_request': !_isOffer,
        if (!_isOffer) 'urgency': _selectedUrgency,
        if (_userPhone != null && _userPhone!.trim().isNotEmpty)
          'host_phone': _userPhone!.trim(),
        'show_host_phone':
            _showHostPhone && (_userPhone?.trim().isNotEmpty ?? false),
      });

      if (mounted) {
        _snack(_isOffer ? l.psServicePublished : l.psRequestPublished,
            isError: false);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 18,
            color: isError ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: isError ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? AtrioColors.error : AtrioColors.neonLime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final eyebrow = _isOffer ? l.psEyebrowOffer : l.psEyebrowRequest;
    final subtitle = _isOffer ? l.psSubtitleOffer : l.psSubtitleRequest;
    final title = _isOffer ? l.psTitleOffer : l.psTitleRequest;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ─── HEADER ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AtrioColors.guestSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AtrioColors.guestCardBorder),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: AtrioColors.guestTextPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.guestTextPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      eyebrow,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextTertiary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.9,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── CONTENT ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _ModeTab(
                              label: l.psModeOffer,
                              icon: Icons.volunteer_activism_rounded,
                              isSelected: _isOffer,
                              onTap: () {
                                if (!_isOffer) {
                                  HapticFeedback.selectionClick();
                                  context.pushReplacement('/publish-service',
                                      extra: 'offer');
                                }
                              },
                            ),
                            _ModeTab(
                              label: l.psModeRequest,
                              icon: Icons.front_hand_rounded,
                              isSelected: !_isOffer,
                              onTap: () {
                                if (_isOffer) {
                                  HapticFeedback.selectionClick();
                                  context.pushReplacement('/publish-service',
                                      extra: 'request');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      _SectionLabel(
                          text: _isOffer
                              ? l.psLabelServiceTitle.toUpperCase()
                              : l.psLabelWhatYouNeed.toUpperCase()),
                      const SizedBox(height: 8),
                      _EditorialField(
                        controller: _titleController,
                        hint: _isOffer ? l.psHintOfferTitle : l.psHintRequestTitle,
                        maxLength: 80,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.psRequired
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // Description
                      _SectionLabel(text: l.psLabelDescription.toUpperCase()),
                      const SizedBox(height: 8),
                      _EditorialField(
                        controller: _descriptionController,
                        hint: _isOffer
                            ? l.psHintOfferDescription
                            : l.psHintRequestDescription,
                        maxLines: 10,
                        maxLength: 3000,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.psRequired
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // Photos (offers only)
                      if (_isOffer) ...[
                        _SectionLabel(text: l.psSectionPhotos),
                        const SizedBox(height: 4),
                        Text(
                          l.psPhotosSubtitle(_maxImages),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length +
                                (_pickedImages.length < _maxImages ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (ctx, index) {
                              if (index == _pickedImages.length) {
                                return GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 92,
                                    decoration: BoxDecoration(
                                      color: AtrioColors.guestSurface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AtrioColors.guestCardBorder,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: AtrioColors.neonLime,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.add_rounded,
                                              color: Colors.black,
                                              size: 20),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l.psAdd,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AtrioColors.guestTextPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      _imageBytes[index],
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _pickedImages.removeAt(index);
                                          _imageBytes.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            size: 13, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      bottom: 5,
                                      left: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AtrioColors.neonLime,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'COVER',
                                          style: GoogleFonts.inter(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Category
                      _SectionLabel(text: l.psSectionCategoryLabel),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final key = cat.$1;
                          final icon = cat.$3;
                          final isSelected = key == _selectedCategory;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = key);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AtrioColors.guestTextPrimary
                                    : AtrioColors.guestSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AtrioColors.guestTextPrimary
                                      : AtrioColors.guestCardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 14,
                                    color: isSelected
                                        ? AtrioColors.neonLime
                                        : AtrioColors.guestTextSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _categoryLabel(l, key),
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AtrioColors.guestTextPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),

                      // Price
                      _SectionLabel(text: l.psSectionPriceLabel),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AtrioColors.guestCardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_isOffer ? l.psPricePerHour : l.psBudget)
                                  .toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextTertiary,
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '\$',
                                  style: GoogleFonts.inter(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AtrioColors.guestTextPrimary,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    cursorColor: AtrioColors.guestTextPrimary,
                                    style: GoogleFonts.inter(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: AtrioColors.guestTextPrimary,
                                      letterSpacing: -0.8,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      hintText: '0',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: AtrioColors.guestTextTertiary,
                                        letterSpacing: -0.8,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return l.psRequired;
                                      }
                                      if (double.tryParse(v) == null) {
                                        return l.psNotANumber;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Urgency (request only)
                      if (!_isOffer) ...[
                        _SectionLabel(text: l.psSectionUrgencyLabel),
                        const SizedBox(height: 10),
                        Row(
                          children: _urgencies.map((u) {
                            final key = u.$1;
                            final icon = u.$2;
                            final isSelected = key == _selectedUrgency;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedUrgency = key);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AtrioColors.guestTextPrimary
                                        : AtrioColors.guestSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AtrioColors.guestTextPrimary
                                          : AtrioColors.guestCardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 20,
                                        color: isSelected
                                            ? AtrioColors.neonLime
                                            : AtrioColors.guestTextSecondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _urgencyLabel(l, key),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : AtrioColors.guestTextPrimary,
                                          height: 1.2,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Contact phone (offer + request: both can opt-in to show their phone)
                      _SectionLabel(text: 'Contacto'),
                      const SizedBox(height: 8),
                      ContactPhoneSection(
                        userPhone: _userPhone,
                        showHostPhone: _showHostPhone,
                        onShowChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _showHostPhone = v);
                        },
                      ),
                      const SizedBox(height: 22),

                      // Tip
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AtrioColors.neonLime,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lightbulb_rounded,
                                  size: 16, color: Colors.black),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.psTip,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AtrioColors.guestTextPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _isOffer ? l.psTipOffer : l.psTipRequest,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AtrioColors.guestTextSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ─── PUBLISH BUTTON ───
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  18 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: AtrioColors.guestBackground,
                  border: Border(top: BorderSide(color: AtrioColors.guestCardBorder)),
                ),
                child: GestureDetector(
                  onTap: _isLoading ? null : _publish,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AtrioColors.guestTextPrimary.withValues(alpha: 0.5)
                          : AtrioColors.guestTextPrimary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isOffer
                                    ? l.psPublishService
                                    : l.psPublishRequest,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: AtrioColors.neonLime),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AtrioColors.guestTextPrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AtrioColors.neonLime
                    : AtrioColors.guestTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AtrioColors.guestTextSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AtrioColors.guestTextTertiary,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _EditorialField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _EditorialField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        cursorColor: AtrioColors.guestTextPrimary,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AtrioColors.guestTextPrimary,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AtrioColors.guestTextTertiary,
            height: 1.4,
          ),
          counterStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AtrioColors.guestTextTertiary,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
