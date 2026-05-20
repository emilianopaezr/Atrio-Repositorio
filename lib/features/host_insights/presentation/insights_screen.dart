import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/providers/host_stats_provider.dart';
import '../../../core/providers/insights_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// "Estadísticas" — replaces the wallet screen in host mode. Focused on
/// growth metrics + reviews (the two levers a host can actually pull,
/// since payments hit their MP account directly).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final insightsAsync = ref.watch(hostInsightsProvider);
    final topListingsAsync = ref.watch(topListingsProvider);
    final reviewsAsync = ref.watch(hostReviewSummaryProvider);
    final hostStatsAsync = ref.watch(hostStatsProvider);

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AtrioColors.neonLime,
          backgroundColor: AtrioColors.hostSurface,
          onRefresh: () async {
            ref.invalidate(hostInsightsProvider);
            ref.invalidate(topListingsProvider);
            ref.invalidate(hostReviewSummaryProvider);
            ref.invalidate(hostStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header (editorial, no lime bar) ───
                PageEyebrow(text: l.insightsEyebrow, dark: true),
                const SizedBox(height: 10),
                Text(
                  l.insightsTitle,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.insightsSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.hostTextSecondary,
                  ),
                ),

                // ─── KPIs ───
                const SizedBox(height: 26),
                SectionEyebrow(text: l.insightsThisMonth, dark: true),
                const SizedBox(height: 14),
                insightsAsync.when(
                  data: (data) => _KpiGrid(data: data),
                  loading: () => const _KpiLoading(),
                  error: (_, _) => const _KpiGrid(data: HostInsights()),
                ),

                // ─── Top listings ───
                const SizedBox(height: 26),
                SectionEyebrow(text: l.insightsTopListings, dark: true),
                const SizedBox(height: 14),
                topListingsAsync.when(
                  data: (rows) => rows.isEmpty
                      ? _EmptyCard(
                          icon: Icons.bar_chart_rounded,
                          text: l.insightsNoBookingsThisMonth,
                        )
                      : Column(
                          children: List.generate(
                            rows.length,
                            (i) => Padding(
                              padding: EdgeInsets.only(
                                  bottom: i < rows.length - 1 ? 10 : 0),
                              child: _TopListingRow(
                                rank: i + 1,
                                listing: rows[i],
                                onTap: () =>
                                    context.push('/listing/${rows[i].id}'),
                              ),
                            ),
                          ),
                        ),
                  loading: () => const _SectionLoading(),
                  error: (_, _) => _EmptyCard(
                    icon: Icons.bar_chart_rounded,
                    text: l.insightsLoadError,
                  ),
                ),

                // ─── Lifetime totals ───
                const SizedBox(height: 26),
                SectionEyebrow(text: l.insightsAllTime, dark: true),
                const SizedBox(height: 14),
                hostStatsAsync.when(
                  data: (s) => _LifetimeCard(
                    bookings: s?.completedBookingsCount ?? 0,
                    rating: s?.averageRating ?? 0,
                    response: s?.responseRate ?? 0,
                    totalEarnings: s?.totalEarnings ?? 0,
                  ),
                  loading: () => const _SectionLoading(),
                  error: (_, _) => const _LifetimeCard(
                      bookings: 0, rating: 0, response: 0, totalEarnings: 0),
                ),

                // ─── Reviews ───
                const SizedBox(height: 26),
                SectionEyebrow(text: l.insightsReviews, dark: true),
                const SizedBox(height: 14),
                reviewsAsync.when(
                  data: (r) => _ReviewsBlock(summary: r),
                  loading: () => const _SectionLoading(),
                  error: (_, _) => _EmptyCard(
                    icon: Icons.reviews_outlined,
                    text: l.insightsReviewsLoadError,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── KPI grid (2x2) ────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final HostInsights data;
  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pct = data.revenueChangePct;
    final pctStr = pct == 0
        ? null
        : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%';
    final pctUp = pct >= 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                value: data.revenueThisMonth.toCLP,
                label: l.insightsKpiRevenue,
                trailing: pctStr == null
                    ? null
                    : _ChangePill(label: pctStr, up: pctUp),
                primary: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                value: data.bookingsThisMonth.toString(),
                label: l.insightsKpiBookings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                value: data.totalViews.toString(),
                label: l.insightsKpiViews,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                value: data.listingsCount.toString(),
                label: l.insightsKpiActive,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String value;
  final String label;
  final Widget? trailing;
  final bool primary;

  const _KpiTile({
    required this.value,
    required this.label,
    this.trailing,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary
              ? AtrioColors.neonLime.withValues(alpha: 0.35)
              : AtrioColors.hostCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.hostTextTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: primary
                    ? AtrioColors.neonLime
                    : AtrioColors.hostTextPrimary,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  final String label;
  final bool up;
  const _ChangePill({required this.label, required this.up});

  @override
  Widget build(BuildContext context) {
    final color = up ? AtrioColors.neonLime : AtrioColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top listing row ───────────────────────────────────────────
class _TopListingRow extends StatelessWidget {
  final int rank;
  final TopListing listing;
  final VoidCallback onTap;
  const _TopListingRow({
    required this.rank,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: listing.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                              color: AtrioColors.hostSurfaceVariant),
                          errorWidget: (_, _, _) => Container(
                              color: AtrioColors.hostSurfaceVariant,
                              child: const Icon(Icons.image_outlined,
                                  color: AtrioColors.hostTextTertiary)),
                        )
                      : Container(
                          color: AtrioColors.hostSurfaceVariant,
                          child: const Icon(Icons.image_outlined,
                              color: AtrioColors.hostTextTertiary),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rank',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            listing.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.hostTextPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.bookingsCount} ${listing.bookingsCount == 1 ? AppLocalizations.of(context).insightsBookingsCountOne : AppLocalizations.of(context).insightsBookingsCountMany} · ${listing.revenue.toCLP}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AtrioColors.hostTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AtrioColors.hostTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Lifetime stats card ───────────────────────────────────────
class _LifetimeCard extends StatelessWidget {
  final int bookings;
  final double rating;
  final double response;
  final double totalEarnings;
  const _LifetimeCard({
    required this.bookings,
    required this.rating,
    required this.response,
    required this.totalEarnings,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      child: Column(
        children: [
          _statRow(l.insightsBookingsCompleted, '$bookings'),
          _divider(),
          _statRow(
              l.insightsAvgRating, rating > 0 ? '⭐ ${rating.toStringAsFixed(1)}' : '—'),
          _divider(),
          _statRow(
              l.insightsResponseRateStat, response > 0 ? '${response.round()}%' : '—'),
          _divider(),
          _statRow(l.insightsTotalRevenue, totalEarnings.toCLP),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AtrioColors.hostTextSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AtrioColors.hostTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );

  Widget _divider() =>
      Container(height: 1, color: AtrioColors.hostDivider);
}

// ─── Reviews block ─────────────────────────────────────────────
class _ReviewsBlock extends StatelessWidget {
  final HostReviewSummary summary;
  const _ReviewsBlock({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (summary.total == 0) {
      return _EmptyCard(
        icon: Icons.reviews_outlined,
        text: l.insightsNoReviewsYet,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RatingCard(summary: summary),
        if (summary.pendingReplies > 0 || summary.negativeCount > 0) ...[
          const SizedBox(height: 10),
          if (summary.pendingReplies > 0)
            _AlertCard(
              icon: Icons.chat_outlined,
              color: AtrioColors.vibrantOrange,
              title: l.insightsPendingReviews(summary.pendingReplies),
              subtitle: l.insightsRespondImprovesTrust,
            ),
          if (summary.negativeCount > 0) ...[
            if (summary.pendingReplies > 0) const SizedBox(height: 8),
            _AlertCard(
              icon: Icons.warning_amber_rounded,
              color: AtrioColors.error,
              title: l.insightsNegativeReviews(summary.negativeCount),
              subtitle: l.insightsReviewCheck,
            ),
          ],
        ],
        const SizedBox(height: 14),
        ...summary.recent.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecentReviewCard(review: r),
          ),
        ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  final HostReviewSummary summary;
  const _RatingCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.hostTextPrimary,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < summary.averageRating.round();
                  return Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: filled
                        ? AtrioColors.ratingGold
                        : AtrioColors.hostCardBorder,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.total} reseñas',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.hostTextTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Container(width: 1, height: 80, color: AtrioColors.hostDivider),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final stars = 5 - i;
                final count = summary.distribution[stars] ?? 0;
                final pct = summary.total > 0 ? count / summary.total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    children: [
                      Text(
                        '$stars',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AtrioColors.hostTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor:
                                AtrioColors.hostSurfaceVariant,
                            valueColor: const AlwaysStoppedAnimation(
                                AtrioColors.neonLime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.hostTextTertiary,
                          ),
                        ),
                      ),
                    ],
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

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
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
    );
  }
}

class _RecentReviewCard extends StatelessWidget {
  final RecentReview review;
  const _RecentReviewCard({required this.review});

  String _timeAgo(AppLocalizations l, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return l.insightsAgoMin(diff.inMinutes);
    if (diff.inHours < 24) return l.insightsAgoHour(diff.inHours);
    if (diff.inDays < 7) return l.insightsAgoDay(diff.inDays);
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < review.rating;
                  return Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: filled
                        ? AtrioColors.ratingGold
                        : AtrioColors.hostCardBorder,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewerName ?? l.insightsReviewerAnonymous,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.hostTextPrimary,
                  ),
                ),
              ),
              Text(
                _timeAgo(l, review.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AtrioColors.hostTextTertiary,
                ),
              ),
            ],
          ),
          if (review.listingTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              review.listingTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AtrioColors.hostTextTertiary,
                letterSpacing: 0.1,
              ),
            ),
          ],
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AtrioColors.hostTextSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (!review.hasReply) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AtrioColors.vibrantOrange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l.insightsPendingResponse,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.vibrantOrange,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AtrioColors.hostSurfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AtrioColors.hostTextSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
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
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: AtrioColors.neonLime,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}

class _KpiLoading extends StatelessWidget {
  const _KpiLoading();
  @override
  Widget build(BuildContext context) {
    Widget shimmer() => Container(
          height: 96,
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
        );
    return Column(
      children: [
        Row(children: [
          Expanded(child: shimmer()),
          const SizedBox(width: 10),
          Expanded(child: shimmer()),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: shimmer()),
          const SizedBox(width: 10),
          Expanded(child: shimmer()),
        ]),
      ],
    );
  }
}
