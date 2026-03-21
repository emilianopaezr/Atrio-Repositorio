import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';

const _bg = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E5E5);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF666666);
const _textMuted = Color(0xFF999999);
const _lime = Color(0xFFD4FF00);
const _limeDark = Color(0xFF9BBF00);
const _gold = Color(0xFFFFB800);

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String listingId;
  final String hostId;
  final String? listingTitle;

  const WriteReviewScreen({
    super.key,
    required this.bookingId,
    required this.listingId,
    required this.hostId,
    this.listingTitle,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona una calificacion',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception('No autenticado');

      await SupabaseConfig.client.from('reviews').insert({
        'booking_id': widget.bookingId,
        'listing_id': widget.listingId,
        'reviewer_id': userId,
        'host_id': widget.hostId,
        'rating': _rating,
        if (_commentController.text.trim().isNotEmpty)
          'comment': _commentController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resena enviada!',
                style: GoogleFonts.roboto(color: Colors.black)),
            backgroundColor: _lime,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AtrioColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'Escribir Resena',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Listing name
            if (widget.listingTitle != null)
              Text(
                widget.listingTitle!,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              'Como fue tu experiencia?',
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedScale(
                      scale: _rating >= starIndex ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        _rating >= starIndex
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 48,
                        color: _rating >= starIndex ? _gold : const Color(0xFFFFB800).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _rating == 0
                  ? 'Toca para calificar'
                  : _rating <= 2
                      ? 'Podria mejorar'
                      : _rating <= 3
                          ? 'Buena'
                          : _rating == 4
                              ? 'Muy buena!'
                              : 'Excelente!',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _rating == 0 ? _textMuted : _limeDark,
              ),
            ),
            const SizedBox(height: 32),

            // Comment
            Container(
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 500,
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Cuentanos mas sobre tu experiencia (opcional)',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 14,
                    color: _textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: GoogleFonts.roboto(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: _lime.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Enviar Resena',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
