import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/atrio_button.dart';
import '../../../shared/widgets/atrio_text_field.dart';
import '../../../shared/widgets/location_picker_widget.dart';
import '../../../core/utils/error_handler.dart';
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
  final _totalSteps = 6;
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

  @override
  void dispose() {
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
    if (_pickedImages.length >= 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.clMaxImages, style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AtrioColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    // Show source picker (gallery or camera)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AtrioColors.hostSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(l.clAddImages, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AtrioColors.neonLimeDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: AtrioColors.neonLimeDark),
                ),
                title: Text(l.clGallery, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
                subtitle: Text(l.clGallerySubtitle, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextSecondary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AtrioColors.neonLimeDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: AtrioColors.neonLimeDark),
                ),
                title: Text(l.clCamera, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
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
        if (_pickedImages.length >= 8) break;
        final bytes = await img.readAsBytes();
        // Validate file size (max 10 MB)
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
        // Validate file extension
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.clCompleteRequired,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // Validate price
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (price <= 0 || price > 99999999) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.clValidPrice,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // Validate capacity if provided
    final capacityText = _capacityController.text.trim();
    if (capacityText.isNotEmpty) {
      final capacity = int.tryParse(capacityText) ?? 0;
      if (capacity <= 0 || capacity > 10000) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.clValidCapacity,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: AtrioColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
    }

    // Validate title length
    if (_titleController.text.trim().length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.clTitleTooLong,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isPublishing = true);
    try {
      // Upload images
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

      // Create listing
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
        if (_rentalMode == 'hours') ...{
          'available_from': _availableFrom,
          'available_until': _availableUntil,
          'block_hours': _blockHours,
          'slot_duration_minutes': _blockHours * 60,
        },
        'status': 'published',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Text(l.clPublishedSuccess,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black)),
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editId != null ? l.clEditTitle : l.clNewTitle,
          style: AtrioTypography.headingSmall.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        backgroundColor: AtrioColors.hostBackground,
        iconTheme: const IconThemeData(color: AtrioColors.hostTextPrimary),
      ),
      backgroundColor: AtrioColors.hostBackground,
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(_totalSteps, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AtrioColors.neonLimeDark
                          : AtrioColors.hostCardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                l.clStepOf(_currentStep + 1, _totalSteps),
                style: AtrioTypography.caption.copyWith(
                  color: AtrioColors.hostTextTertiary,
                ),
              ),
            ),
          ),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStep(),
            ),
          ),

          // Bottom navigation
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AtrioColors.hostCardBorder),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: AtrioButton(
                      label: l.clBack,
                      variant: AtrioButtonVariant.secondary,
                      onTap: () {
                        setState(() => _currentStep--);
                      },
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: AtrioButton(
                    label: _currentStep < _totalSteps - 1
                        ? l.clNext
                        : l.clPublish,
                    isLoading: _isPublishing,
                    onTap: () {
                      if (_currentStep < _totalSteps - 1) {
                        setState(() => _currentStep++);
                      } else {
                        _publish();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
      case 5:
        return _buildPricingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCategoryStep() {
    final l = AppLocalizations.of(context);
    final types = [
      {'id': 'space', 'icon': Icons.home_work, 'label': l.clTypeSpace, 'desc': l.clTypeSpaceDesc},
      {'id': 'experience', 'icon': Icons.auto_awesome, 'label': l.clTypeExperience, 'desc': l.clTypeExperienceDesc},
      {'id': 'service', 'icon': Icons.build_circle, 'label': l.clTypeService, 'desc': l.clTypeServiceDesc},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1% Hook Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AtrioColors.neonLime.withValues(alpha: 0.15),
                AtrioColors.neonLime.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AtrioColors.neonLime.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department,
                    color: AtrioColors.neonLimeDark, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.clCommissionTitle,
                      style: AtrioTypography.labelLarge.copyWith(
                        color: AtrioColors.neonLimeDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.clCommissionDesc,
                      style: AtrioTypography.bodySmall.copyWith(
                        color: AtrioColors.hostTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.clCategoryQuestion,
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.clCategorySelect,
          style: AtrioTypography.bodyMedium.copyWith(
            color: AtrioColors.hostTextSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...types.map((type) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AtrioColors.hostSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedType == type['id']
                      ? AtrioColors.neonLimeDark
                      : AtrioColors.hostCardBorder,
                  width: _selectedType == type['id'] ? 2 : 1,
                ),
                boxShadow: _selectedType == type['id']
                    ? [
                        BoxShadow(
                          color: AtrioColors.neonLimeDark.withValues(alpha: 0.2),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedType == type['id']
                          ? AtrioColors.neonLimeDark.withValues(alpha: 0.2)
                          : AtrioColors.hostSurfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      type['icon'] as IconData,
                      color: _selectedType == type['id']
                          ? AtrioColors.neonLimeDark
                          : AtrioColors.hostTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type['label'] as String,
                          style: AtrioTypography.labelLarge.copyWith(
                            color: AtrioColors.hostTextPrimary,
                          ),
                        ),
                        Text(
                          type['desc'] as String,
                          style: AtrioTypography.bodySmall.copyWith(
                            color: AtrioColors.hostTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedType == type['id'])
                    const Icon(
                      Icons.check_circle,
                      color: AtrioColors.neonLimeDark,
                    ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.clDetailsTitle,
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 24),
        AtrioTextField(
          controller: _titleController,
          label: l.clTitleLabel,
          hint: l.clTitleHint,
        ),
        const SizedBox(height: 20),
        AtrioTextField(
          controller: _descriptionController,
          label: l.clDescriptionLabel,
          hint: l.clDescriptionHint,
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.clPhotosTitle,
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.clPhotosSubtitle,
          style: AtrioTypography.bodyMedium.copyWith(
            color: AtrioColors.hostTextSecondary,
          ),
        ),
        const SizedBox(height: 24),
        if (_imageBytes.isNotEmpty) ...[
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageBytes.length + (_imageBytes.length < 8 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _imageBytes.length) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AtrioColors.hostSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AtrioColors.hostCardBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, size: 32, color: AtrioColors.neonLimeDark),
                          const SizedBox(height: 4),
                          Text(l.clPhotosAdd, style: const TextStyle(fontSize: 12, color: AtrioColors.hostTextSecondary)),
                        ],
                      ),
                    ),
                  );
                }
                return Stack(
                  children: [
                    Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: MemoryImage(_imageBytes[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6, right: 16,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _pickedImages.removeAt(index);
                          _imageBytes.removeAt(index);
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(l.clPhotosCover, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.clPhotosCount(_imageBytes.length),
            style: AtrioTypography.caption.copyWith(color: AtrioColors.hostTextTertiary),
          ),
        ] else
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AtrioColors.hostSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AtrioColors.hostCardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AtrioColors.neonLimeDark),
                  const SizedBox(height: 12),
                  Text(
                    l.clPhotosTapToAdd,
                    style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.clLocationTitle,
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 24),
        AtrioTextField(
          controller: _addressController,
          label: l.clAddressLabel,
          hint: l.clAddressHint,
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AtrioTextField(controller: _cityController, label: l.clCityLabel, hint: l.clCityHint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtrioTextField(controller: _countryController, label: l.clCountryLabel, hint: l.clCountryHint),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Map picker
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AtrioColors.hostSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AtrioColors.hostCardBorder),
            ),
            child: _latitude != null && _longitude != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      children: [
                        IgnorePointer(
                          child: Image.network(
                            'https://maps.googleapis.com/maps/api/staticmap?center=$_latitude,$_longitude&zoom=15&size=600x300&markers=color:red%7C$_latitude,$_longitude&key=',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.map, size: 48, color: AtrioColors.neonLimeDark),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0, left: 0, right: 0, bottom: 0,
                          child: Center(
                            child: Icon(Icons.location_on, size: 40, color: AtrioColors.neonLimeDark),
                          ),
                        ),
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AtrioColors.neonLimeDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(l.clChange, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_location_alt_rounded, size: 40, color: AtrioColors.neonLimeDark),
                      const SizedBox(height: 8),
                      Text(
                        l.clMapSelect,
                        style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.clMapTapToOpen,
                        style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary),
                      ),
                    ],
                  ),
          ),
        ),
        if (_latitude != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: AtrioColors.success),
              const SizedBox(width: 6),
              Text(
                l.clLocationSelected,
                style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.success, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPricingStep() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.clPricingTitle,
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.clPricingSubtitle,
          style: AtrioTypography.bodyMedium.copyWith(
            color: AtrioColors.hostTextSecondary,
          ),
        ),
        const SizedBox(height: 24),
        AtrioTextField(
          controller: _priceController,
          label: l.clPriceLabel,
          hint: '0.00',
          keyboardType: TextInputType.number,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text('\$', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 16),
        Text(l.clChargeBy, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final u in [
              if (_selectedType == 'space' && _rentalMode == 'nights') {'id': 'night', 'label': l.clUnitNight},
              if (_rentalMode == 'hours') {'id': 'hour', 'label': l.clUnitHour},
              if (_rentalMode == 'full_day') {'id': 'session', 'label': l.clUnitSession},
              if (_selectedType == 'experience') {'id': 'person', 'label': l.clUnitPerson},
            ])
              GestureDetector(
                onTap: () => setState(() => _priceUnit = u['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _priceUnit == u['id'] ? AtrioColors.neonLime : AtrioColors.hostSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _priceUnit == u['id'] ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder,
                    ),
                  ),
                  child: Text(
                    u['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: _priceUnit == u['id'] ? FontWeight.w700 : FontWeight.w500,
                      color: _priceUnit == u['id'] ? Colors.black : AtrioColors.hostTextSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Commission info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AtrioColors.neonLime.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AtrioColors.neonLimeDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.clCommissionInfo,
                  style: AtrioTypography.bodySmall.copyWith(
                    color: AtrioColors.hostTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
