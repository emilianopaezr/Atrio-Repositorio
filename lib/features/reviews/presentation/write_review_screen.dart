import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.writeReviewSelectRating,
              style: GoogleFonts.inter(color: Colors.white)),
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
      if (userId == null) throw Exception(l.writeReviewNotAuthenticated);

      // Validate rating range
      final safeRating = _rating.clamp(1, 5);

      // Sanitize and limit comment length
      final comment = _commentController.text.trim();
      final safeComment = comment.length > 2000 ? comment.substring(0, 2000) : comment;

      await SupabaseConfig.client.from('reviews').insert({
        'booking_id': widget.bookingId,
        'listing_id': widget.listingId,
        'reviewer_id': userId,
        'host_id': widget.hostId,
        'rating': safeRating,
        if (safeComment.isNotEmpty)
          'comment': safeComment,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.writeReviewSentSuccess,
                style: GoogleFonts.inter(color: Colors.black)),
            backgroundColor: AtrioColors.neonLime,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      appBar: AppBar(
        backgroundColor: AtrioColors.guestBackground,
        elevation: 0,
        title: Text(
          l.writeReviewTitle,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AtrioColors.guestTextPrimary,
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
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              l.writeReviewHowWasIt,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AtrioColors.guestTextSecondary,
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
                        color: _rating >= starIndex ? AtrioColors.ratingGold : AtrioColors.ratingGold.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _rating == 0
                  ? l.writeReviewTapToRate
                  : _rating <= 2
                      ? l.writeReviewRatingPoor
                      : _rating <= 3
                          ? l.writeReviewRatingGood
                          : _rating == 4
                              ? l.writeReviewRatingVeryGood
                              : l.writeReviewRatingExcellent,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _rating == 0 ? AtrioColors.guestTextTertiary : AtrioColors.neonLimeDark,
              ),
            ),
            const SizedBox(height: 32),

            // Comment
            Container(
              decoration: BoxDecoration(
                color: AtrioColors.guestSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AtrioColors.guestCardBorder),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 500,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AtrioColors.guestTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: l.writeReviewCommentHint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AtrioColors.guestTextTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: GoogleFonts.inter(
                    fontSize: 11,
                    color: AtrioColors.guestTextTertiary,
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
                  backgroundColor: AtrioColors.neonLime,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AtrioColors.neonLime.withValues(alpha: 0.4),
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
                        l.writeReviewSubmitButton,
                        style: GoogleFonts.inter(
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
