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

class CreateListingScreen extends StatefulWidget {
  final String? editId;
  const CreateListingScreen({super.key, this.editId});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  int _currentStep = 0;
  final _totalSteps = 5;
  String? _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final List<XFile> _pickedImages = [];
  final List<Uint8List> _imageBytes = [];
  bool _isPublishing = false;
  String _priceUnit = 'night';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked.isNotEmpty) {
      for (final img in picked) {
        if (_pickedImages.length >= 8) break;
        final bytes = await img.readAsBytes();
        setState(() {
          _pickedImages.add(img);
          _imageBytes.add(bytes);
        });
      }
    }
  }

  Future<void> _publish() async {
    final userId = AuthService.currentUser?.id;
    if (userId == null) return;
    if (_selectedType == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Completa todos los campos requeridos',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w600, color: Colors.white)),
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
        'base_price': double.tryParse(_priceController.text.trim()) ?? 0,
        'price_unit': _priceUnit,
        'status': 'published',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Text('Anuncio publicado exitosamente',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w600, color: Colors.black)),
            ],
          ),
          backgroundColor: AtrioColors.neonLime,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo publicar. Intenta de nuevo.',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
          backgroundColor: AtrioColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editId != null ? 'Editar Anuncio' : 'Nuevo Anuncio',
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
                'Paso ${_currentStep + 1} de $_totalSteps',
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
                      label: 'Anterior',
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
                        ? 'Siguiente'
                        : 'Publicar',
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
        return _buildPricingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCategoryStep() {
    final types = [
      {'id': 'space', 'icon': Icons.home_work, 'label': 'Espacio', 'desc': 'Loft, estudio, villa, sala...'},
      {'id': 'experience', 'icon': Icons.auto_awesome, 'label': 'Experiencia', 'desc': 'Tour, clase, taller, evento...'},
      {'id': 'service', 'icon': Icons.build_circle, 'label': 'Servicio', 'desc': 'Fotografía, catering, limpieza...'},
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
                      'Solo 1% de comisión',
                      style: AtrioTypography.labelLarge.copyWith(
                        color: AtrioColors.neonLimeDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Como adoptador temprano, tú recibes el 99% de cada reserva',
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
          '¿Qué vas a ofrecer?',
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona la categoría que mejor describe tu oferta',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles del anuncio',
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 24),
        AtrioTextField(
          controller: _titleController,
          label: 'Título',
          hint: 'Ej: Loft Industrial con Vista a la Ciudad',
        ),
        const SizedBox(height: 20),
        AtrioTextField(
          controller: _descriptionController,
          label: 'Descripción',
          hint: 'Describe tu espacio, experiencia o servicio...',
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agrega fotos',
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Las buenas fotos atraen más reservas (max 8)',
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
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 32, color: AtrioColors.neonLimeDark),
                          SizedBox(height: 4),
                          Text('Agregar', style: TextStyle(fontSize: 12, color: AtrioColors.hostTextSecondary)),
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
                          child: Text('Portada', style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_imageBytes.length} foto${_imageBytes.length != 1 ? 's' : ''} seleccionada${_imageBytes.length != 1 ? 's' : ''}',
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
                    'Toca para agregar fotos',
                    style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación',
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 24),
        AtrioTextField(
          controller: _addressController,
          label: 'Dirección',
          hint: 'Calle, número, colonia',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AtrioTextField(controller: _cityController, label: 'Ciudad', hint: 'Ciudad'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtrioTextField(controller: _countryController, label: 'País', hint: 'País'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Map placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: const Center(
            child: Icon(Icons.map, size: 48, color: AtrioColors.hostTextTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precio',
          style: AtrioTypography.headingLarge.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Establece un precio competitivo',
          style: AtrioTypography.bodyMedium.copyWith(
            color: AtrioColors.hostTextSecondary,
          ),
        ),
        const SizedBox(height: 24),
        AtrioTextField(
          controller: _priceController,
          label: 'Precio base (USD)',
          hint: '0.00',
          keyboardType: TextInputType.number,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text('\$', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Cobrar por:', style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final u in [
              {'id': 'night', 'label': 'Noche'},
              {'id': 'hour', 'label': 'Hora'},
              {'id': 'session', 'label': 'Sesion'},
              {'id': 'person', 'label': 'Persona'},
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
                    style: GoogleFonts.roboto(
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
                  'Atrio solo cobra 1% en tus primeras reservas. Máximo \$99 USD por reserva.',
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
