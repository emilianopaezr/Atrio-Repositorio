import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _periodIdx = 1; // 0=week, 1=month, 2=year

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const bg = AtrioColors.hostBackground;
    const surface = AtrioColors.hostSurface;
    const surfaceV = AtrioColors.hostSurfaceVariant;
    const border = AtrioColors.hostCardBorder;
    const textP = AtrioColors.hostTextPrimary;
    const textS = AtrioColors.hostTextSecondary;
    const textT = AtrioColors.hostTextTertiary;

    final analyticsAsync = ref.watch(analyticsProvider(_periodIdx));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: textP),
          onPressed: () => context.pop(),
        ),
        title: Text(l.hostAnalyticsTitle,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textP)),
        centerTitle: true,
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AtrioColors.neonLime)),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AtrioColors.hostTextTertiary),
              const SizedBox(height: 12),
              Text(l.hostAnalyticsLoadError,
                  style: GoogleFonts.inter(fontSize: 15, color: textS)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.invalidate(analyticsProvider(_periodIdx)),
                child: Text(l.btnRetry,
                    style: GoogleFonts.inter(color: AtrioColors.neonLime, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(analyticsProvider(_periodIdx)),
          color: AtrioColors.neonLime,
          backgroundColor: surface,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Period selector
              Row(
                children: [
                  _periodChip(l.hostAnalyticsPeriodWeek, 0, textP, textT, border),
                  const SizedBox(width: 8),
                  _periodChip(l.hostAnalyticsPeriodMonth, 1, textP, textT, border),
                  const SizedBox(width: 8),
                  _periodChip(l.hostAnalyticsPeriodYear, 2, textP, textT, border),
                ],
              ),
              const SizedBox(height: 24),

              // Revenue card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AtrioColors.neonLimeDark, AtrioColors.neonLime],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.hostAnalyticsRevenueOfPeriod,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('${data.totalRevenue.toCLP} CLP',
                        style: GoogleFonts.inter(
                            fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black)),
                    if (data.dailyRevenue.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: data.dailyRevenue.map((v) {
                            final maxVal = data.dailyRevenue.reduce((a, b) => a > b ? a : b);
                            final h = maxVal > 0 ? (v / maxVal * 40) + 4 : 4.0;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                height: h,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _statCard(l.hostAnalyticsBookings, '${data.totalBookings}', Icons.calendar_today_rounded,
                      surface, border, textP, textS),
                  const SizedBox(width: 12),
                  _statCard(
                      l.hostAnalyticsRating,
                      data.avgRating > 0 ? data.avgRating.toStringAsFixed(1) : '-',
                      Icons.star_rounded,
                      surface, border, textP, textS),
                  const SizedBox(width: 12),
                  _statCard(l.hostAnalyticsReviews, '${data.totalReviews}', Icons.rate_review_rounded,
                      surface, border, textP, textS),
                ],
              ),
              const SizedBox(height: 28),

              // Top listings
              Text(l.hostAnalyticsTopListings,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
              const SizedBox(height: 12),
              if (data.topListings.isEmpty)
                _emptyState(l.hostAnalyticsNoListings, textT)
              else
                ...data.topListings.map((item) {
                  final imgs = item['images'] as List? ?? [];
                  final img = imgs.isNotEmpty ? imgs[0] as String : null;
                  final title = item['title'] as String? ?? l.hostAnalyticsNoTitle;
                  final reviews = item['review_count'] as int? ?? 0;
                  final rating = (item['average_rating'] as num?)?.toDouble() ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: img != null
                              ? CachedNetworkImage(
                                  imageUrl: img,
                                  width: 50, height: 50, fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    width: 50, height: 50,
                                    color: surfaceV,
                                    child: const Icon(Icons.broken_image, color: textT, size: 20),
                                  ),
                                )
                              : Container(
                                  width: 50, height: 50,
                                  color: surfaceV,
                                  child: const Icon(Icons.image, color: textT)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: textP),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 14, color: AtrioColors.ratingGold),
                                  const SizedBox(width: 3),
                                  Text(rating > 0 ? rating.toStringAsFixed(1) : '-',
                                      style: GoogleFonts.inter(fontSize: 12, color: textS)),
                                  const SizedBox(width: 10),
                                  Text(l.hostAnalyticsReviewsCount(reviews),
                                      style: GoogleFonts.inter(fontSize: 12, color: textT)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 28),

              // Recent bookings
              Text(l.hostAnalyticsRecentActivity,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
              const SizedBox(height: 12),
              if (data.recentBookings.isEmpty)
                _emptyState(l.hostAnalyticsNoRecentBookings, textT)
              else
                ...data.recentBookings.map((b) {
                  final status = b['status'] as String? ?? 'pending';
                  final price = (b['total_price'] as num?)?.toDouble() ?? 0;
                  final listing = b['listing'] as Map<String, dynamic>?;
                  final title = listing?['title'] as String? ?? l.hostAnalyticsBookingFallback;
                  final date = (b['created_at'] as String?)?.substring(0, 10) ?? '';
                  final statusColor = _statusColor(status);
                  final statusLabel = _statusLabel(status, l);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w500, color: textP),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('$date · $statusLabel',
                                  style: GoogleFonts.inter(fontSize: 12, color: textT)),
                            ],
                          ),
                        ),
                        Text(price.toCLP,
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w700, color: AtrioColors.neonLime)),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodChip(String label, int idx, Color textP, Color textT, Color border) {
    final sel = _periodIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _periodIdx = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AtrioColors.neonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AtrioColors.neonLime : border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.black : textT)),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color surface, Color border,
      Color textP, Color textS) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AtrioColors.neonLime),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: textP)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: textS)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: color))),
      );

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AtrioColors.statusConfirmed;
      case 'pending': return AtrioColors.statusPending;
      case 'completed': return AtrioColors.statusCompleted;
      case 'cancelled': return AtrioColors.statusCancelled;
      default: return AtrioColors.hostTextTertiary;
    }
  }

  String _statusLabel(String s, AppLocalizations l) {
    switch (s) {
      case 'confirmed': return l.bookingStatusConfirmed;
      case 'pending': return l.bookingStatusPending;
      case 'completed': return l.bookingStatusCompleted;
      case 'cancelled': return l.bookingStatusCancelled;
      default: return s;
    }
  }
}
