import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/atrio_snackbar.dart';

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
      AppLogger.w('reviews list: $e', tag: 'reviews');
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
                      // Joined as `reviewer` in DatabaseService —
                      // previously read `guest.full_name` which never
                      // existed (so name + avatar fell through to
                      // the placeholder forever).
                      final reviewer = r['reviewer'] as Map<String, dynamic>?;
                      final name = (reviewer?['display_name'] as String?) ??
                          l.reviewsDefaultUser;
                      final avatar = reviewer?['photo_url'] as String?;
                      final rating = (r['rating'] as num?)?.toInt() ?? 5;
                      final comment = r['comment'] as String? ?? '';
                      final hostReply = (r['host_reply'] as String?)?.trim();
                      final hasReply = hostReply != null && hostReply.isNotEmpty;
                      final createdAt = DateTime.tryParse(r['created_at'] ?? '');
                      final timeAgo = _formatTimeAgo(l, createdAt);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: border,
                            backgroundImage: avatar != null
                                ? CachedNetworkImageProvider(avatar)
                                : null,
                            child: avatar == null
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: textP),
                                  )
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
                                              fontWeight: FontWeight.w700,
                                              color: textP,
                                              letterSpacing: -0.2)),
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
                                      idx < rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
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
                                          fontSize: 14,
                                          color: textS,
                                          height: 1.5)),
                                ],
                                if (hasReply) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 12),
                                    decoration: BoxDecoration(
                                      color: AtrioColors.guestSurfaceVariant,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.reviewsHostReplyLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: textT,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hostReply,
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: textP,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                // Host-only "Responder" affordance —
                                // shown when the signed-in user is
                                // the host of this review.
                                if (_canReply(r)) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () => _openReplySheet(r),
                                    icon: Icon(
                                      hasReply
                                          ? Icons.edit_outlined
                                          : Icons.reply_rounded,
                                      size: 16,
                                      color: textP,
                                    ),
                                    label: Text(
                                      hasReply
                                          ? l.reviewsEditReply
                                          : l.reviewsAddReply,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textP,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap,
                                    ),
                                  ),
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

  /// True when the signed-in user is the host of this review (only
  /// the host can write the public reply).
  bool _canReply(Map<String, dynamic> review) {
    final me = SupabaseConfig.auth.currentUser?.id;
    if (me == null) return false;
    return review['host_id'] == me;
  }

  /// Modal sheet to write / edit the host's public reply.
  Future<void> _openReplySheet(Map<String, dynamic> review) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: (review['host_reply'] as String?) ?? '',
    );
    final reviewId = review['id'] as String;
    final saved = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          decoration: const BoxDecoration(
            color: AtrioColors.guestBackground,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AtrioColors.guestCardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l.reviewsReplySheetTitle,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l.reviewsReplyHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: AtrioColors.guestCardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: AtrioColors.guestCardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: AtrioColors.guestTextPrimary,
                          width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(ctx, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AtrioColors.guestTextPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l.reviewsReplySave,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == null) return;
    try {
      await DatabaseService.setHostReply(
        reviewId: reviewId,
        reply: saved,
      );
      if (mounted) AtrioSnackbar.success(context, l.reviewsReplySaved);
      await _load();
    } catch (e) {
      if (mounted) {
        AtrioSnackbar.danger(context, l.reviewsError);
      }
    }
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
