import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/providers/host_stats_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/widgets/atrio_button.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

class HostListingsScreen extends ConsumerWidget {
  const HostListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final userId = SupabaseConfig.auth.currentUser?.id ?? '';
    final listingsAsync = ref.watch(hostListingsProvider(userId));
    final hostStatsAsync = ref.watch(hostStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.hostListingsHeader,
                    style: AtrioTypography.displayMedium.copyWith(
                      color: AtrioColors.hostTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLimeDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                    onPressed: () => context.push('/host/create-listing'),
                  ),
                ],
              ),
            ),
            // Commission badge under header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: hostStatsAsync.when(
                data: (stats) {
                  if (stats == null) return const SizedBox.shrink();
                  final keepRate = (100 - stats.currentCommissionRate * 100).toStringAsFixed(0);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AtrioColors.neonLime.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 16, color: AtrioColors.neonLimeDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.hostListingsKeepRate(keepRate),
                            style: AtrioTypography.bodySmall.copyWith(
                              color: AtrioColors.neonLimeDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        HostLevelBadge(
                          level: stats.level,
                          compact: true,
                          showLabel: false,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: listingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_work_outlined,
                              size: 64, color: AtrioColors.hostTextTertiary),
                          const SizedBox(height: 16),
                          Text(
                            l.hostListingsNoListingsTitle,
                            style: AtrioTypography.headingSmall.copyWith(
                              color: AtrioColors.hostTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.hostListingsNoListingsSubtitle,
                            style: AtrioTypography.bodyMedium.copyWith(
                              color: AtrioColors.hostTextTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 200,
                            child: AtrioButton(
                              label: l.hostListingsCreateListingBtn,
                              icon: Icons.add,
                              onTap: () =>
                                  context.push('/host/create-listing'),
                              isExpanded: false,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AtrioColors.neonLimeDark,
                    onRefresh: () async {
                      ref.invalidate(hostListingsProvider(userId));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        final images = List<String>.from(listing['images'] ?? []);
                        final status = listing['status'] as String? ?? 'draft';
                        final rating =
                            (listing['rating'] as num?)?.toDouble() ?? 0;
                        final viewCount = listing['view_count'] ?? 0;
                        final basePrice =
                            (listing['base_price'] as num?)?.toDouble();

                        return GestureDetector(
                          onTap: () => context.push('/listing/${listing['id']}'),
                          onLongPress: () => _showListingOptions(
                            context, ref, listing, userId,
                          ),
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: AtrioColors.hostCardBorder),
                          ),
                          child: Column(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                child: AspectRatio(
                                  aspectRatio: 16 / 8,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: images.first,
                                              fit: BoxFit.cover,
                                              placeholder: (_, _) => Container(
                                                  color: AtrioColors
                                                      .hostSurfaceVariant),
                                              errorWidget: (_, _, _) =>
                                                  Container(
                                                color:
                                                    AtrioColors.hostSurfaceVariant,
                                                child: const Icon(Icons.image,
                                                    size: 32),
                                              ),
                                            )
                                          : Container(
                                              color: AtrioColors.hostSurfaceVariant,
                                              child: const Icon(Icons.image,
                                                  size: 32,
                                                  color: AtrioColors
                                                      .hostTextTertiary),
                                            ),
                                      // Price overlay
                                      if (basePrice != null)
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              basePrice.toCLP,
                                              style: AtrioTypography.priceSmall.copyWith(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            listing['title'] ?? l.hostListingsNoTitle,
                                            style: AtrioTypography.labelLarge
                                                .copyWith(
                                              color:
                                                  AtrioColors.hostTextPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        _StatusBadge(status: status),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (rating > 0) ...[
                                          const Icon(Icons.star_rounded,
                                              size: 14,
                                              color:
                                                  AtrioColors.ratingGold),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: AtrioTypography.caption
                                                .copyWith(
                                              color:
                                                  AtrioColors.hostTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Icon(Icons.visibility_outlined,
                                            size: 14,
                                            color:
                                                AtrioColors.hostTextSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          l.hostListingsViewsCount(viewCount is int ? viewCount : (viewCount as num).toInt()),
                                          style:
                                              AtrioTypography.caption.copyWith(
                                            color:
                                                AtrioColors.hostTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AtrioColors.neonLimeDark),
                ),
                error: (_, _) => Center(
                  child: Text(l.hostListingsLoadError),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showListingOptions(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> listing,
    String userId,
  ) {
    final l = AppLocalizations.of(context);
    final listingId = listing['id'] as String;
    final status = listing['status'] as String? ?? 'draft';
    final title = listing['title'] as String? ?? l.hostListingsNoTitle;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AtrioColors.hostBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AtrioColors.hostCardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AtrioColors.hostTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            // View listing
            _OptionTile(
              icon: Icons.visibility_outlined,
              label: l.hostListingsViewListing,
              color: AtrioColors.hostTextPrimary,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/listing/$listingId');
              },
            ),
            // Toggle publish/pause
            if (status == 'published')
              _OptionTile(
                icon: Icons.pause_circle_outline,
                label: l.hostListingsPauseListing,
                color: AtrioColors.vibrantOrange,
                onTap: () async {
                  Navigator.pop(ctx);
                  await DatabaseService.updateListing(listingId, {'status': 'paused'});
                  ref.invalidate(hostListingsProvider(userId));
                },
              )
            else
              _OptionTile(
                icon: Icons.play_circle_outline,
                label: l.hostListingsPublishListing,
                color: AtrioColors.neonLimeDark,
                onTap: () async {
                  Navigator.pop(ctx);
                  await DatabaseService.updateListing(listingId, {'status': 'published'});
                  ref.invalidate(hostListingsProvider(userId));
                },
              ),
            // Delete
            _OptionTile(
              icon: Icons.delete_outline,
              label: l.hostListingsDeleteListing,
              color: AtrioColors.error,
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: AtrioColors.hostBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text(
                      l.hostListingsDeleteListing,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.hostTextPrimary,
                      ),
                    ),
                    content: Text(
                      l.hostListingsDeleteConfirm(title),
                      style: GoogleFonts.inter(color: AtrioColors.hostTextSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: Text(l.btnCancel, style: GoogleFonts.inter(color: AtrioColors.hostTextSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: Text(l.btnDelete, style: GoogleFonts.inter(color: AtrioColors.error, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseService.deleteListing(listingId);
                  ref.invalidate(hostListingsProvider(userId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.hostListingsDeletedSnack),
                        backgroundColor: AtrioColors.hostTextPrimary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: AtrioColors.hostTextTertiary),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Color color;
    String label;
    switch (status) {
      case 'published':
        color = AtrioColors.neonLimeDark;
        label = l.hostListingsStatusPublished;
      case 'draft':
        color = AtrioColors.hostTextSecondary;
        label = l.hostListingsStatusDraft;
      case 'paused':
        color = AtrioColors.vibrantOrange;
        label = l.hostListingsStatusPaused;
      default:
        color = AtrioColors.hostTextSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AtrioTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
