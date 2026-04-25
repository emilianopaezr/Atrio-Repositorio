import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/database_service.dart';
import '../../../l10n/app_localizations.dart';

class ReviewsListScreen extends StatefulWidget {
  final String listingId;
  const ReviewsListScreen({super.key, required this.listingId});

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await DatabaseService.getListingReviews(widget.listingId);
      if (mounted) setState(() { _reviews = data; _loading = false; });
    } catch (e) {
      debugPrint('ReviewsList error: $e');
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() { _loading = false; _error = l.reviewsError; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const bg = AtrioColors.guestBackground;
    const textP = AtrioColors.guestTextPrimary;
    const textS = AtrioColors.guestTextSecondary;
    const textT = AtrioColors.guestTextTertiary;
    const border = AtrioColors.guestCardBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: textP),
          onPressed: () => context.pop(),
        ),
        title: Text(l.reviewsListCountTitle(_reviews.length),
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textP)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AtrioColors.neonLimeDark))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AtrioColors.guestTextTertiary),
                      const SizedBox(height: 12),
                      Text(_error!, style: GoogleFonts.inter(fontSize: 15, color: textS)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _load,
                        child: Text(l.reviewsRetry, style: GoogleFonts.inter(color: AtrioColors.neonLimeDark, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: textT),
                      const SizedBox(height: 16),
                      Text(l.reviewsEmptyTitle,
                          style: GoogleFonts.inter(fontSize: 16, color: textS)),
                      const SizedBox(height: 8),
                      Text(l.reviewsEmptySubtitle,
                          style: GoogleFonts.inter(fontSize: 13, color: textT)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 32, color: AtrioColors.guestDivider),
                    itemBuilder: (context, i) {
                      final r = _reviews[i];
                      final guest = r['guest'] as Map<String, dynamic>?;
                      final name = guest?['full_name'] ?? l.reviewsDefaultUser;
                      final avatar = guest?['avatar_url'] as String?;
                      final rating = (r['rating'] as num?)?.toInt() ?? 5;
                      final comment = r['comment'] as String? ?? '';
                      final createdAt = DateTime.tryParse(r['created_at'] ?? '');
                      final timeAgo = _formatTimeAgo(l, createdAt);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: border,
                            backgroundImage:
                                avatar != null ? CachedNetworkImageProvider(avatar) : null,
                            child: avatar == null
                                ? Text(name[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600, color: textP))
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(name,
                                          style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textP)),
                                    ),
                                    Text(timeAgo,
                                        style: GoogleFonts.inter(
                                            fontSize: 12, color: textT)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(
                                    5,
                                    (idx) => Icon(
                                      idx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 16,
                                      color: idx < rating
                                          ? AtrioColors.ratingGold
                                          : textT,
                                    ),
                                  ),
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(comment,
                                      style: GoogleFonts.inter(
                                          fontSize: 14, color: textS, height: 1.5)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTimeAgo(AppLocalizations l, DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return l.timeToday;
    if (diff.inDays == 1) return l.timeYesterday;
    if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays);
    if (diff.inDays < 30) return l.timeWeeksAgo(diff.inDays ~/ 7);
    if (diff.inDays < 365) return l.timeMonthsAgo(diff.inDays ~/ 30);
    return l.timeYearsAgo(diff.inDays ~/ 365);
  }
}
