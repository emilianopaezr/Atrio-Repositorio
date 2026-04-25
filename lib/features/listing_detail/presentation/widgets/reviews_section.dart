import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';

const _bg = AtrioColors.guestSurfaceVariant;
const _white = AtrioColors.guestSurface;
const _border = AtrioColors.guestCardBorder;
const _text = AtrioColors.guestTextPrimary;
const _textSec = AtrioColors.guestTextSecondary;
const _textMuted = AtrioColors.guestTextTertiary;
const _lime = AtrioColors.neonLime;
const _limeDark = AtrioColors.neonLimeDark;
const _gold = AtrioColors.ratingGold;

/// Reviews section for the listing detail page.
class ListingReviewsSection extends StatelessWidget {
  final String listingId;
  final double rating;
  final int reviewCount;
  final bool loadingReviews;
  final List<Map<String, dynamic>> reviews;

  const ListingReviewsSection({
    super.key,
    required this.listingId,
    required this.rating,
    required this.reviewCount,
    required this.loadingReviews,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reseñas', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
            const SizedBox(width: 8),
            if (rating > 0) ...[
              const Icon(Icons.star_rounded, size: 16, color: _gold),
              const SizedBox(width: 3),
              Text(
                '${rating.toStringAsFixed(1)} ($reviewCount)',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _text),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        if (loadingReviews)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: _limeDark, strokeWidth: 2),
          ))
        else if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.rate_review_outlined, size: 32, color: _textMuted),
                  const SizedBox(height: 8),
                  Text('Aún no hay reseñas', style: GoogleFonts.inter(fontSize: 14, color: _textMuted)),
                  Text('Sé el primero en opinar', style: GoogleFonts.inter(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            reviews.length > 3 ? 3 : reviews.length,
            (i) => _reviewCard(reviews[i]),
          ),

        if (reviews.length > 3) ...[
          const SizedBox(height: 4),
          Center(
            child: GestureDetector(
              onTap: () => context.push('/reviews/$listingId'),
              child: Text(
                'Ver las ${reviews.length} reseñas',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _limeDark),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    final reviewer = r['reviewer'] as Map<String, dynamic>?;
    final name = reviewer?['display_name'] as String? ?? 'Usuario';
    final photo = reviewer?['photo_url'] as String?;
    final ratingVal = (r['rating'] as num?)?.toDouble() ?? 0;
    final comment = r['comment'] as String? ?? '';
    final hostReply = r['host_reply'] as String?;
    final created = DateTime.tryParse(r['created_at'] ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _lime.withValues(alpha: 0.2),
                  backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
                  child: photo == null ? Text(name[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _limeDark)) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
                      if (created != null)
                        Text(_timeAgo(created), style: GoogleFonts.inter(fontSize: 11, color: _textMuted)),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (j) => Icon(
                    j < ratingVal ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: j < ratingVal ? _gold : _gold.withValues(alpha: 0.3),
                  )),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(comment, style: GoogleFonts.inter(fontSize: 13, color: _textSec, height: 1.5)),
            ],
            if (hostReply != null && hostReply.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bg, borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.reply_rounded, size: 14, color: _limeDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Respuesta del anfitrión', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _text)),
                          const SizedBox(height: 3),
                          Text(hostReply, style: GoogleFonts.inter(fontSize: 12, color: _textSec, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return 'Hace ${diff.inDays ~/ 365} año${diff.inDays ~/ 365 > 1 ? 's' : ''}';
    if (diff.inDays > 30) return 'Hace ${diff.inDays ~/ 30} mes${diff.inDays ~/ 30 > 1 ? 'es' : ''}';
    if (diff.inDays > 0) return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    return 'Hace un momento';
  }
}
