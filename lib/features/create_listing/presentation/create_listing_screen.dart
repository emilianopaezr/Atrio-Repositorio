import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/contact_phone_section.dart';
import '../../../shared/widgets/location_picker_widget.dart';
import '../../../core/utils/amenities_catalog.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/profanity_filter.dart';
import '../../../core/utils/rules_catalog.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/rental_mode_step.dart';

class CreateListingScreen extends StatefulWidget {
  final String? editId;
  const CreateListingScreen({super.key, this.editId});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  int _currentStep = 0;
  final _totalSteps = 8;
  final List<String> _selectedRules = [];
  final List<String> _selectedAmenities = [];
  static const int _maxRules = 5;
  String? _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _capacityController = TextEditingController();
  final List<XFile> _pickedImages = [];
  final List<Uint8List> _imageBytes = [];
  bool _isPublishing = false;
  double? _latitude;
  double? _longitude;
  String _priceUnit = 'night';
  String _rentalMode = 'nights';
  String _cancellationPolicy = 'flexible';
  bool _instantBooking = false;
  String _availableFrom = '09:00';
  String _availableUntil = '22:00';
  int _blockHours = 1;
  String? _userPhone;
  bool _showHostPhone = false;

  @override
  void initState() {
    super.initState();
    // Re-evaluate `_canAdvance` whenever the user types in fields whose
    // emptiness gates the "Next" button.
    _titleController.addListener(_handleTextChange);
    _priceController.addListener(_handleTextChange);
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    try {
      final res = await SupabaseConfig.client
          .from('profiles')
          .select('phone')
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted || res == null) return;
      setState(() => _userPhone = res['phone'] as String?);
    } catch (_) {
      // Silent — UI will fall back to "no phone" state.
    }
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleTextChange);
    _priceController.removeListener(_handleTextChange);
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final l = AppLocalizations.of(context);
    if (_pickedImages.length >= 15) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.clMaxImages, style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AtrioColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AtrioColors.hostSurface,
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
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              Text(
                l.clAddImages,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.hostTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: AtrioColors.neonLime),
                ),
                title: Text(l.clGallery, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
                subtitle: Text(l.clGallerySubtitle, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextSecondary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: AtrioColors.neonLime),
                ),
                title: Text(l.clCamera, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
                subtitle: Text(l.clCameraSubtitle, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextSecondary)),
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
    if (source == ImageSource.gallery) {
      picked = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } else {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      picked = photo != null ? [photo] : [];
    }

    if (picked.isNotEmpty) {
      for (final img in picked) {
        if (_pickedImages.length >= 15) break;
        final bytes = await img.readAsBytes();
        if (bytes.lengthInBytes > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l.clImageTooLarge,
                  style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: AtrioColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
          continue;
        }
        final ext = img.path.split('.').last.toLowerCase();
        if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) {
          continue;
        }
        setState(() {
          _pickedImages.add(img);
          _imageBytes.add(bytes);
        });
      }
    }
  }

  Future<void> _publish() async {
    final l = AppLocalizations.of(context);
    final userId = AuthService.currentUser?.id;
    if (userId == null) return;
    if (_selectedType == null || _titleController.text.trim().isEmpty) {
      _showErrorSnack(l.clCompleteRequired);
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (price <= 0 || price > 99999999) {
      _showErrorSnack(l.clValidPrice);
      return;
    }

    final capacityText = _capacityController.text.trim();
    if (capacityText.isNotEmpty) {
      final capacity = int.tryParse(capacityText) ?? 0;
      if (capacity <= 0 || capacity > 10000) {
        _showErrorSnack(l.clValidCapacity);
        return;
      }
    }

    if (_titleController.text.trim().length > 200) {
      _showErrorSnack(l.clTitleTooLong);
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final imageUrls = <String>[];
      for (int i = 0; i < _pickedImages.length; i++) {
        final ext = _pickedImages[i].path.split('.').last;
        final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        await SupabaseConfig.client.storage.from('listings').uploadBinary(
          path, _imageBytes[i],
          fileOptions: const FileOptions(upsert: true),
        );
        final url = SupabaseConfig.client.storage.from('listings').getPublicUrl(path);
        imageUrls.add(url);
      }

      await SupabaseConfig.client.from('listings').insert({
        'host_id': userId,
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'images': imageUrls,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'city': _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        'country': _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        'base_price': double.tryParse(_priceController.text.trim()) ?? 0,
        'price_unit': _priceUnit,
        'rental_mode': _rentalMode,
        'cancellation_policy': _cancellationPolicy,
        'instant_booking': _instantBooking,
        'capacity': int.tryParse(_capacityController.text.trim()),
        'rules': _selectedRules,
        'amenities': _selectedAmenities,
        if (_rentalMode == 'hours') ...{
          'available_from': _availableFrom,
          'available_until': _availableUntil,
          'block_hours': _blockHours,
          'slot_duration_minutes': _blockHours * 60,
        },
        // Contact phone — only persisted when toggle is on and phone exists.
        if (_userPhone != null && _userPhone!.trim().isNotEmpty)
          'host_phone': _userPhone!.trim(),
        'show_host_phone':
            _showHostPhone && (_userPhone?.trim().isNotEmpty ?? false),
        'status': 'published',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Text(l.clPublishedSuccess,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black)),
            ],
          ),
          backgroundColor: AtrioColors.neonLime,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
      backgroundColor: AtrioColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  bool get _canAdvance {
    switch (_currentStep) {
      case 0:
        // Category: a type must be selected.
        return _selectedType != null;
      case 1:
        // Details: title is mandatory; description optional.
        return _titleController.text.trim().isNotEmpty;
      case 7:
        // Pricing (final step): price must be a positive number.
        final price = double.tryParse(_priceController.text.trim()) ?? 0;
        return price > 0;
      default:
        // Photos / Location / Amenities / Rules / Rental mode all optional.
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── EDITORIAL HEADER ───
            _EditorialHeader(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              isEditing: widget.editId != null,
              onClose: () => Navigator.of(context).maybePop(),
              stepLabel: l.clNavStep(_currentStep + 1, _totalSteps),
              navTitle: widget.editId != null ? l.clEditTitle : l.clNewTitle,
            ),

            // ─── CONTENT ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),

            // ─── EDITORIAL FOOTER ───
            _EditorialFooter(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              isPublishing: _isPublishing,
              canAdvance: _canAdvance,
              labelBack: l.clBack,
              labelNext: _currentStep < _totalSteps - 1 ? l.clNext : l.clPublish,
              onBack: () {
                HapticFeedback.selectionClick();
                setState(() => _currentStep--);
              },
              onNext: () {
                HapticFeedback.lightImpact();
                if (_currentStep < _totalSteps - 1) {
                  setState(() => _currentStep++);
                } else {
                  _publish();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildPhotosStep();
      case 3:
        return _buildLocationStep();
      case 4:
        return _buildAmenitiesStep();
      case 5:
        return _buildRulesStep();
      case 6:
        return RentalModeStep(
          selectedType: _selectedType,
          rentalMode: _rentalMode,
          availableFrom: _availableFrom,
          availableUntil: _availableUntil,
          blockHours: _blockHours,
          capacityController: _capacityController,
          instantBooking: _instantBooking,
          cancellationPolicy: _cancellationPolicy,
          onRentalModeChanged: (mode) => setState(() {
            _rentalMode = mode;
            _priceUnit = mode == 'hours' ? 'hour' : mode == 'full_day' ? 'session' : 'night';
          }),
          onAvailableFromChanged: (v) => setState(() => _availableFrom = v),
          onAvailableUntilChanged: (v) => setState(() => _availableUntil = v),
          onBlockHoursChanged: (v) => setState(() => _blockHours = v),
          onInstantBookingChanged: (v) => setState(() => _instantBooking = v),
          onCancellationPolicyChanged: (v) => setState(() => _cancellationPolicy = v),
        );
      case 7:
        return _buildPricingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 0 — CATEGORY
  // ─────────────────────────────────────────────────────────────
  Widget _buildCategoryStep() {
    final l = AppLocalizations.of(context);
    final types = [
      {'id': 'space', 'icon': Icons.home_work_rounded, 'label': l.clTypeSpace, 'desc': l.clTypeSpaceDesc},
      {'id': 'experience', 'icon': Icons.auto_awesome_rounded, 'label': l.clTypeExperience, 'desc': l.clTypeExperienceDesc},
      {'id': 'service', 'icon': Icons.build_circle_rounded, 'label': l.clTypeService, 'desc': l.clTypeServiceDesc},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l.clCategoryEyebrow,
          title: l.clCategoryQuestion,
          subtitle: l.clCategorySelect,
        ),
        const SizedBox(height: 20),
        // Commission promo banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AtrioColors.neonLime.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: Colors.black, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.clCommissionTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.neonLime,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.clCommissionDesc,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.hostTextSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ...types.map((type) {
          final selected = _selectedType == type['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedType = type['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selected
                      ? AtrioColors.neonLime.withValues(alpha: 0.08)
                      : AtrioColors.hostSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AtrioColors.neonLime
                        : AtrioColors.hostCardBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? AtrioColors.neonLime
                            : AtrioColors.hostSurfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        type['icon'] as IconData,
                        size: 24,
                        color: selected ? Colors.black : AtrioColors.hostTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.hostTextPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type['desc'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AtrioColors.hostTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      scale: selected ? 1 : 0,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AtrioColors.neonLime,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 1 — DETAILS
  // ─────────────────────────────────────────────────────────────
  Widget _buildDetailsStep() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l.clDetailsEyebrow,
          title: l.clDetailsTitle,
          subtitle: l.clDetailsSubtitle,
        ),
        const SizedBox(height: 28),
        _EditorialField(
          controller: _titleController,
          label: l.clTitleLabel,
          hint: l.clTitleHint,
          maxLength: 80,
          // Force a rebuild on every keystroke so the footer's "Next" button
          // re-evaluates `_canAdvance` even if the controller listener is
          // shadowed by an in-flight animation.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        _EditorialField(
          controller: _descriptionController,
          label: l.clDescriptionLabel,
          hint: l.clDescriptionHint,
          maxLines: 10,
          maxLength: 3000,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 2 — PHOTOS
  // ─────────────────────────────────────────────────────────────
  Widget _buildPhotosStep() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l.clPhotosEyebrow,
          title: l.clPhotosTitle,
          subtitle: l.clPhotosSubtitle,
        ),
        const SizedBox(height: 24),
        if (_imageBytes.isEmpty)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AtrioColors.hostSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AtrioColors.hostCardBorder,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AtrioColors.neonLime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded,
                        size: 26, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.clPhotosTapToAdd,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.hostTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG · PNG · WEBP · max 10 MB',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.hostTextTertiary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _imageBytes.length + (_imageBytes.length < 15 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _imageBytes.length) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AtrioColors.hostSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AtrioColors.hostCardBorder),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_rounded,
                          size: 30, color: AtrioColors.neonLime),
                    ),
                  ),
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_imageBytes[index], fit: BoxFit.cover),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.clPhotosCover,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _pickedImages.removeAt(index);
                          _imageBytes.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            l.clPhotosCount(_imageBytes.length),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AtrioColors.hostTextTertiary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 3 — LOCATION
  // ─────────────────────────────────────────────────────────────
  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        if (result.address != null && result.address!.isNotEmpty) {
          _addressController.text = result.address!;
        }
        if (result.city != null && result.city!.isNotEmpty) {
          _cityController.text = result.city!;
        }
        if (result.country != null && result.country!.isNotEmpty) {
          _countryController.text = result.country!;
        }
      });
    }
  }

  Widget _buildLocationStep() {
    final l = AppLocalizations.of(context);
    final pinned = _latitude != null && _longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l.clLocationEyebrow,
          title: l.clLocationTitle,
          subtitle: l.clLocationSubtitle,
        ),
        const SizedBox(height: 28),
        // Map picker tile
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AtrioColors.hostSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: pinned
                    ? AtrioColors.neonLime.withValues(alpha: 0.6)
                    : AtrioColors.hostCardBorder,
                width: pinned ? 1.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (pinned)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AtrioColors.neonLime.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            size: 30, color: Colors.black),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AtrioColors.neonLime,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_location_alt_rounded,
                              size: 26, color: Colors.black),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.clMapSelect,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.hostTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.clMapTapToOpen,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.hostTextTertiary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (pinned)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l.clChange,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (pinned) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: AtrioColors.neonLime),
              const SizedBox(width: 6),
              Text(
                l.clLocationSelected,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.neonLime,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _EditorialField(
          controller: _addressController,
          label: l.clAddressLabel,
          hint: l.clAddressHint,
          icon: Icons.place_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _EditorialField(
                controller: _cityController,
                label: l.clCityLabel,
                hint: l.clCityHint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EditorialField(
                controller: _countryController,
                label: l.clCountryLabel,
                hint: l.clCountryHint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 4 — AMENITIES (optional, host can skip)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAmenitiesStep() {
    // Custom amenities = those selected but not in the catalog.
    final catalogLabels =
        AmenitiesCatalog.all.map((s) => s.label).toSet();
    final customAmenities = _selectedAmenities
        .where((a) => !catalogLabels.contains(a))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: 'AMENIDADES',
          title: '¿Qué incluye tu lugar?',
          subtitle:
              'Marca todo lo que ofrece tu publicación. Los huéspedes verán esta lista.',
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 13, color: AtrioColors.neonLime),
              const SizedBox(width: 6),
              Text(
                _selectedAmenities.isEmpty
                    ? 'Ninguna seleccionada'
                    : '${_selectedAmenities.length} seleccionadas',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.neonLime,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Catalog chips
            ...AmenitiesCatalog.all.map((spec) {
              final selected = _selectedAmenities.contains(spec.label);
              return _amenityChip(
                icon: spec.icon,
                label: spec.label,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedAmenities.remove(spec.label);
                    } else {
                      _selectedAmenities.add(spec.label);
                    }
                  });
                },
              );
            }),
            // Custom amenity chips (always selected, tap to remove).
            ...customAmenities.map((label) => _amenityChip(
                  icon: Icons.label_outline_rounded,
                  label: label,
                  selected: true,
                  custom: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedAmenities.remove(label));
                  },
                )),
            // "Agregar otra" trigger
            _addAmenityChip(),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AtrioColors.neonLime, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: las publicaciones con más amenidades obtienen un 28% más reservas que las que no listan ninguna.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.hostTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AMENITY CHIPS (helpers for step 4)
  // ─────────────────────────────────────────────────────────────
  Widget _amenityChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool custom = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AtrioColors.neonLime
              : AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AtrioColors.neonLime
                : AtrioColors.hostCardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.black
                  : AtrioColors.hostTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? Colors.black
                    : AtrioColors.hostTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
            if (custom) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close_rounded, size: 14, color: Colors.black),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addAmenityChip() {
    return GestureDetector(
      onTap: _showAddAmenityDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AtrioColors.neonLime.withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded,
                size: 16, color: AtrioColors.neonLime),
            const SizedBox(width: 8),
            Text(
              'Agregar otra',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AtrioColors.neonLime,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAmenityDialog() async {
    HapticFeedback.selectionClick();
    final ctrl = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void submit() {
              final raw = ctrl.text.trim();
              if (raw.length < 2) {
                setLocal(() => errorText = 'Mínimo 2 caracteres');
                return;
              }
              if (raw.length > 30) {
                setLocal(() => errorText = 'Máximo 30 caracteres');
                return;
              }
              if (!ProfanityFilter.isClean(raw)) {
                setLocal(() => errorText =
                    'Contiene palabras no permitidas. Usá un nombre respetuoso.');
                return;
              }
              // Capitalize first letter for nicer display.
              final formatted = raw[0].toUpperCase() + raw.substring(1);
              // Prevent duplicates (case-insensitive).
              final exists = _selectedAmenities
                      .any((a) => a.toLowerCase() == formatted.toLowerCase()) ||
                  AmenitiesCatalog.all.any(
                      (s) => s.label.toLowerCase() == formatted.toLowerCase());
              if (exists) {
                setLocal(() => errorText = 'Ya está en la lista');
                return;
              }
              setState(() => _selectedAmenities.add(formatted));
              Navigator.of(ctx).pop();
            }

            return AlertDialog(
              backgroundColor: AtrioColors.hostSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text(
                'Nueva amenidad',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.hostTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escribe el nombre de la amenidad que querés agregar.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.hostTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: AtrioColors.neonLime,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AtrioColors.hostTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej. Máquina de café',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AtrioColors.hostTextTertiary,
                      ),
                      filled: true,
                      fillColor: AtrioColors.hostBackground,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AtrioColors.hostCardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AtrioColors.hostCardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AtrioColors.neonLime, width: 1.5),
                      ),
                      errorText: errorText,
                      errorStyle: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AtrioColors.error,
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                    onChanged: (_) {
                      if (errorText != null) {
                        setLocal(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                      color: AtrioColors.hostTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.neonLime,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Agregar',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 5 — RULES
  // ─────────────────────────────────────────────────────────────
  Widget _buildRulesStep() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l.clRulesEyebrow,
          title: l.clRulesTitle,
          subtitle: l.clRulesSubtitle,
        ),
        const SizedBox(height: 18),
        // Counter pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _selectedRules.length >= _maxRules
                ? AtrioColors.neonLime
                : AtrioColors.neonLime.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: _selectedRules.length >= _maxRules
                    ? Colors.black
                    : AtrioColors.neonLime,
              ),
              const SizedBox(width: 6),
              Text(
                l.clRulesSelected(_selectedRules.length),
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _selectedRules.length >= _maxRules
                      ? Colors.black
                      : AtrioColors.neonLime,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: RulesCatalog.all.map((spec) {
            final selected = _selectedRules.contains(spec.key);
            final disabled = !selected && _selectedRules.length >= _maxRules;
            return GestureDetector(
              onTap: () {
                if (disabled) {
                  _showErrorSnack(l.clRulesMaxReached);
                  return;
                }
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _selectedRules.remove(spec.key);
                  } else {
                    _selectedRules.add(spec.key);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? AtrioColors.neonLime
                      : AtrioColors.hostSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AtrioColors.neonLime
                        : AtrioColors.hostCardBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      spec.icon,
                      size: 16,
                      color: selected
                          ? Colors.black
                          : (disabled
                              ? AtrioColors.hostTextTertiary
                              : AtrioColors.hostTextSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      RulesCatalog.label(context, spec.key),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? Colors.black
                            : (disabled
                                ? AtrioColors.hostTextTertiary
                                : AtrioColors.hostTextPrimary),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AtrioColors.neonLime, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.clRulesHint,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.hostTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 7 — PRICING
  // ─────────────────────────────────────────────────────────────
  Widget _buildPricingStep() {
    final l = AppLocalizations.of(context);
    final units = [
      if (_selectedType == 'space' && _rentalMode == 'nights')
        {'id': 'night', 'label': l.clUnitNight},
      if (_rentalMode == 'hours') {'id': 'hour', 'label': l.clUnitHour},
      if (_rentalMode == 'full_day') {'id': 'session', 'label': l.clUnitSession},
      if (_selectedType == 'experience') {'id': 'person', 'label': l.clUnitPerson},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l.clPricingEyebrow,
          title: l.clPricingTitle,
          subtitle: l.clPricingSubtitle,
        ),
        const SizedBox(height: 28),
        // Big price field
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.clPriceLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.hostTextTertiary,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '\$',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.neonLime,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.hostTextPrimary,
                        letterSpacing: -1,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: '0',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.hostTextTertiary,
                          letterSpacing: -1,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (units.isNotEmpty) ...[
          Text(
            l.clChargeBy.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AtrioColors.hostTextTertiary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: units.map((u) {
              final selected = _priceUnit == u['id'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _priceUnit = u['id']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AtrioColors.neonLime : AtrioColors.hostSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AtrioColors.neonLime
                          : AtrioColors.hostCardBorder,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    u['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? Colors.black : AtrioColors.hostTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AtrioColors.neonLime.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded,
                  color: AtrioColors.neonLime, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.clCommissionInfo,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.hostTextPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Contact phone (optional) ───
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CONTACTO',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AtrioColors.neonLime,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ContactPhoneSection(
          userPhone: _userPhone,
          showHostPhone: _showHostPhone,
          onShowChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _showHostPhone = v);
          },
          dark: true,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EDITORIAL HEADER
// ─────────────────────────────────────────────────────────────
class _EditorialHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isEditing;
  final VoidCallback onClose;
  final String stepLabel;
  final String navTitle;
  const _EditorialHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.isEditing,
    required this.onClose,
    required this.stepLabel,
    required this.navTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AtrioColors.hostSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AtrioColors.hostCardBorder),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AtrioColors.hostTextPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  navTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Text(
                stepLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.hostTextTertiary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Editorial progress bar — single rail with tinted segments
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: List.generate(totalSteps, (i) {
                final filled = i <= currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 3),
                    decoration: BoxDecoration(
                      color: filled
                          ? AtrioColors.neonLime
                          : AtrioColors.hostSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EDITORIAL FOOTER
// ─────────────────────────────────────────────────────────────
class _EditorialFooter extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isPublishing;
  final bool canAdvance;
  final String labelBack;
  final String labelNext;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _EditorialFooter({
    required this.currentStep,
    required this.totalSteps,
    required this.isPublishing,
    required this.canAdvance,
    required this.labelBack,
    required this.labelNext,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        18 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AtrioColors.hostBackground,
        border: Border(top: BorderSide(color: AtrioColors.hostCardBorder)),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            _GhostButton(label: labelBack, onTap: onBack),
          if (currentStep > 0) const SizedBox(width: 10),
          Expanded(
            child: _LimeButton(
              label: labelNext,
              isLoading: isPublishing,
              enabled: canAdvance && !isPublishing,
              onTap: canAdvance ? onNext : null,
              showArrow: currentStep < totalSteps - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_rounded,
                size: 18, color: AtrioColors.hostTextPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AtrioColors.hostTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimeButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final bool showArrow;
  final VoidCallback? onTap;
  const _LimeButton({
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.showArrow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? AtrioColors.neonLime : AtrioColors.hostSurfaceVariant,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AtrioColors.neonLime.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: enabled ? Colors.black : AtrioColors.hostTextTertiary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: enabled ? Colors.black : AtrioColors.hostTextTertiary,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP HEADER (eyebrow + lime bar + title + subtitle)
// ─────────────────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  const _StepHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              eyebrow,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AtrioColors.neonLime,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AtrioColors.hostTextPrimary,
            letterSpacing: -0.9,
            height: 1.05,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AtrioColors.hostTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EDITORIAL TEXT FIELD
// ─────────────────────────────────────────────────────────────
class _EditorialField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  const _EditorialField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AtrioColors.hostTextTertiary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            cursorColor: AtrioColors.neonLime,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AtrioColors.hostTextPrimary,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AtrioColors.hostTextTertiary,
              ),
              prefixIcon: icon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Icon(icon, size: 18, color: AtrioColors.hostTextSecondary),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: icon == null ? 16 : 4,
                  vertical: 16),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
