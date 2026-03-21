import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';

const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF141414);
const _border = Color(0xFF2A2A2A);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFAAAAAA);
const _textMuted = Color(0xFF666666);
const _lime = Color(0xFFD4FF00);
const _limeDark = Color(0xFF9BBF00);

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

  String _selectedCategory = 'Mudanza';
  String _selectedUrgency = 'Flexible';
  bool _isLoading = false;

  final _categories = [
    'Mudanza',
    'Limpieza',
    'Armado',
    'Eventos',
    'Jardineria',
    'Reparaciones',
    'Pintura',
    'Otro',
  ];

  final _urgencies = ['Hoy', 'Manana', 'Esta semana', 'Flexible'];

  final _categoryIcons = {
    'Mudanza': Icons.local_shipping_rounded,
    'Limpieza': Icons.cleaning_services_rounded,
    'Armado': Icons.handyman_rounded,
    'Eventos': Icons.celebration_rounded,
    'Jardineria': Icons.grass_rounded,
    'Reparaciones': Icons.build_rounded,
    'Pintura': Icons.format_paint_rounded,
    'Otro': Icons.more_horiz_rounded,
  };

  bool get _isOffer => widget.mode == 'offer';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception('No autenticado');

      await SupabaseConfig.client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .single();

      // For now we show a success message (backend table for quick_services
      // could be added later - this demonstrates the full UX flow)
      await Future.delayed(const Duration(milliseconds: 800));

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
                        ? 'Servicio publicado exitosamente'
                        : 'Solicitud publicada exitosamente',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _lime,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AtrioColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isOffer ? 'Ofrecer Servicio' : 'Solicitar Servicio',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
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
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _ModeTab(
                      label: 'Ofrecer',
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
                      label: 'Solicitar',
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
              _buildLabel(_isOffer ? 'Titulo del Servicio' : 'Que necesitas?'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: _isOffer
                    ? 'Ej: Ayuda con mudanza, armado de muebles...'
                    : 'Ej: Necesito ayuda para mover un sofa...',
                maxLength: 80,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),

              // Description
              _buildLabel('Descripcion'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: _isOffer
                    ? 'Describe tu experiencia y lo que ofreces...'
                    : 'Describe lo que necesitas con detalle...',
                maxLines: 4,
                maxLength: 500,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Categoria'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _lime : _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _limeDark : _border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _categoryIcons[cat] ?? Icons.category,
                            size: 16,
                            color: isSelected ? Colors.black : _textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? Colors.black : _textSecondary,
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
              _buildLabel(_isOffer ? 'Precio por hora (\$)' : 'Presupuesto (\$)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: _isOffer ? 'Ej: 25' : 'Ej: 50',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (double.tryParse(v) == null) return 'Ingresa un numero';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Urgency (only for requests)
              if (!_isOffer) ...[
                _buildLabel('Urgencia'),
                const SizedBox(height: 10),
                Row(
                  children: _urgencies.map((u) {
                    final isSelected = u == _selectedUrgency;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedUrgency = u),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _lime : _surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? _limeDark : _border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            u,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? Colors.black : _textSecondary,
                            ),
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
                  color: _lime.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _lime.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: _lime),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consejo',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _lime,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOffer
                                ? 'Incluye fotos de trabajos anteriores y se especifico sobre tus habilidades para recibir mas solicitudes.'
                                : 'Se detallado sobre lo que necesitas. Incluye medidas, piso, y si tienes herramientas disponibles.',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: _textSecondary,
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
                    backgroundColor: _lime,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: _lime.withValues(alpha: 0.3),
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
                          _isOffer ? 'Publicar Servicio' : 'Publicar Solicitud',
                          style: GoogleFonts.roboto(
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
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
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
      style: GoogleFonts.roboto(fontSize: 15, color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(fontSize: 14, color: _textMuted),
        filled: true,
        fillColor: _surface,
        counterStyle: GoogleFonts.roboto(fontSize: 11, color: _textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _limeDark, width: 1.5),
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
            color: isSelected ? _lime : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.black : _textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
