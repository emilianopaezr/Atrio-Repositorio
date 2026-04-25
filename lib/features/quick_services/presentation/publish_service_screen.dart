import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';


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

  // Internal category key (stable, used as UI state). DB stores Spanish value.
  String _selectedCategory = 'moving';
  // Internal urgency key. Only used for UI state.
  String _selectedUrgency = 'flexible';
  bool _isLoading = false;
  final List<XFile> _pickedImages = [];
  final List<Uint8List> _imageBytes = [];
  static const int _maxImages = 6;

  // (internalKey, dbValue, icon)
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.psMaxPhotos(_maxImages), style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AtrioColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AtrioColors.hostSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(l.psAddPhoto, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AtrioColors.neonLimeDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_rounded, color: AtrioColors.neonLimeDark),
              ),
              title: Text(l.psGallery, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AtrioColors.neonLimeDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_rounded, color: AtrioColors.neonLimeDark),
              ),
              title: Text(l.psCamera, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ]),
        ),
      ),
    );

    if (source == null) return;
    final picker = ImagePicker();
    List<XFile> picked;
    final remaining = _maxImages - _pickedImages.length;
    if (source == ImageSource.gallery) {
      picked = await picker.pickMultiImage(maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (picked.length > remaining) picked = picked.sublist(0, remaining);
    } else {
      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      picked = photo != null ? [photo] : [];
    }

    for (final img in picked) {
      if (_pickedImages.length >= _maxImages) break;
      final bytes = await img.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.psImageTooLarge, style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AtrioColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
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

    Haptics.medium();
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception(l.psNotAuthenticated);

      // Upload images first
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

      if (_isOffer) {
        // Persist as a real service listing
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
        });
      } else {
        // Request: simulate (no quick_requests table yet)
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isOffer
                        ? l.psServicePublished
                        : l.psRequestPublished,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AtrioColors.neonLime,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      appBar: AppBar(
        backgroundColor: AtrioColors.hostBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AtrioColors.hostTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isOffer ? l.psTitleOffer : l.psTitleRequest,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AtrioColors.hostSurface,
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
              _buildLabel(_isOffer ? l.psLabelServiceTitle : l.psLabelWhatYouNeed),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: _isOffer ? l.psHintOfferTitle : l.psHintRequestTitle,
                maxLength: 80,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.psRequired : null,
              ),
              const SizedBox(height: 20),

              // Description
              _buildLabel(l.psLabelDescription),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: _isOffer ? l.psHintOfferDescription : l.psHintRequestDescription,
                maxLines: 5,
                maxLength: 500,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.psRequired : null,
              ),
              const SizedBox(height: 20),

              // Photos (offers only, max 6)
              if (_isOffer) ...[
                _buildLabel(l.psPhotosLabel(_maxImages)),
                const SizedBox(height: 4),
                Text(
                  l.psPhotosHint(_maxImages),
                  style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length + (_pickedImages.length < _maxImages ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (ctx, index) {
                      if (index == _pickedImages.length) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 90,
                            decoration: BoxDecoration(
                              color: AtrioColors.hostSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AtrioColors.neonLimeDark.withValues(alpha: 0.5),
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, color: AtrioColors.neonLimeDark, size: 26),
                                const SizedBox(height: 4),
                                Text(l.psAdd, style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.hostTextSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _imageBytes[index],
                              width: 90, height: 90, fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _pickedImages.removeAt(index);
                                _imageBytes.removeAt(index);
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Category
              _buildLabel(l.psCategory),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final key = cat.$1;
                  final icon = cat.$3;
                  final isSelected = key == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AtrioColors.neonLime : AtrioColors.hostSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected ? Colors.black : AtrioColors.hostTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _categoryLabel(l, key),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? Colors.black : AtrioColors.hostTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Price
              _buildLabel(_isOffer ? l.psPricePerHour : l.psBudget),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: _isOffer ? l.psHintPrice25 : l.psHintBudget50,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.psRequired;
                  if (double.tryParse(v) == null) return l.psNotANumber;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Urgency (only for requests)
              if (!_isOffer) ...[
                _buildLabel(l.psUrgency),
                const SizedBox(height: 10),
                Row(
                  children: _urgencies.map((u) {
                    final key = u.$1;
                    final icon = u.$2;
                    final isSelected = key == _selectedUrgency;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedUrgency = key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AtrioColors.neonLime : AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: isSelected ? Colors.black : AtrioColors.hostTextSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _urgencyLabel(l, key),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? Colors.black : AtrioColors.hostTextSecondary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AtrioColors.neonLime.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: AtrioColors.neonLime),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.psTip,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AtrioColors.neonLime,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOffer ? l.psTipOffer : l.psTipRequest,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AtrioColors.hostTextSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Publish button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.neonLime,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AtrioColors.neonLime.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _isOffer ? l.psPublishService : l.psPublishRequest,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AtrioColors.hostTextPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: AtrioColors.hostTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextTertiary),
        filled: true,
        fillColor: AtrioColors.hostSurface,
        counterStyle: GoogleFonts.inter(fontSize: 11, color: AtrioColors.hostTextTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AtrioColors.hostCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AtrioColors.hostCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AtrioColors.neonLimeDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AtrioColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AtrioColors.neonLime : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.black : AtrioColors.hostTextSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : AtrioColors.hostTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
