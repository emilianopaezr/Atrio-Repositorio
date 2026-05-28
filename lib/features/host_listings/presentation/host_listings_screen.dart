import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/atrio_snackbar.dart';
import '../../../shared/widgets/edit_listing_sheet.dart';

class HostListingsScreen extends ConsumerWidget {
  const HostListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final userId = SupabaseConfig.auth.currentUser?.id ?? '';
    final listingsAsync = ref.watch(hostListingsProvider(userId));

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: RefreshIndicator(
        color: AtrioColors.neonLimeDark,
        backgroundColor: AtrioColors.hostSurface,
        onRefresh: () async {
          ref.invalidate(hostListingsProvider(userId));
        },
        child: CustomScrollView(
          slivers: [
            // ─── HERO HEADER ───
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.hostListingsEyebrow,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AtrioColors.hostTextTertiary,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.hostListingsHeader,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.hostTextPrimary,
                                letterSpacing: -1.0,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.hostListingsHeroSubtitle,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AtrioColors.hostTextSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/host/create-listing'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AtrioColors.neonLime,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded,
                              size: 24, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── STATS ROW ───
            listingsAsync.when(
              data: (listings) {
                final published = listings
                    .where((j) => j['status'] == 'published')
                    .length;
                final drafts =
                    listings.where((j) => j['status'] == 'draft').length;
                final paused =
                    listings.where((j) => j['status'] == 'paused').length;
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: '$published',
                            label: l.hostListingsStatPublished,
                            accent: AtrioColors.neonLime,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            value: '$drafts',
                            label: l.hostListingsStatDraft,
                            accent: AtrioColors.hostTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            value: '$paused',
                            label: l.hostListingsStatPaused,
                            accent: AtrioColors.vibrantOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, _) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ─── LIST ───
            listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      onCreate: () => context.push('/host/create-listing'),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Section header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AtrioColors.neonLime,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.hostListingsAllSection,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AtrioColors.hostTextPrimary,
                                    letterSpacing: -0.6,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.hostListingsAllSectionSubtitle(
                                      listings.length),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AtrioColors.hostTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        l.hostListingsTapToManage,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AtrioColors.hostTextTertiary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: listings
                            .map((listing) => Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _HostListingCard(
                                    listing: listing,
                                    onTap: () => context
                                        .push('/listing/${listing['id']}'),
                                    onMenuTap: () => _showListingOptions(
                                        context, ref, listing, userId),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AtrioColors.neonLimeDark,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l.hostListingsLoadError,
                    style: GoogleFonts.inter(
                      color: AtrioColors.hostTextSecondary,
                      fontSize: 14,
                    ),
                  ),
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
      // The host shell sets extendBody: true with a floating
      // bottomNavigationBar. Mounting on the local navigator means the
      // sheet is drawn UNDER that nav — clipping the "Eliminar anuncio"
      // tile. useRootNavigator lifts the sheet above the host shell's
      // nav. useSafeArea additionally honors the system gesture inset.
      useRootNavigator: true,
      useSafeArea: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AtrioColors.hostBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AtrioColors.hostCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AtrioColors.hostTextPrimary,
                letterSpacing: -0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 22),
            _OptionTile(
              icon: Icons.visibility_outlined,
              label: l.hostListingsViewListing,
              color: AtrioColors.hostTextPrimary,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/listing/$listingId');
              },
            ),
            _OptionTile(
              icon: Icons.edit_outlined,
              label: l.hostListingsEditListing,
              color: AtrioColors.hostTextPrimary,
              onTap: () async {
                Navigator.pop(ctx);
                // Spaces/experiences usually have a cleaning fee; services
                // don't, so we hide the field for service listings.
                final type = listing['type'] as String? ?? '';
                final saved = await showEditListingSheet(
                  context,
                  listing: listing,
                  showCleaningFee: type != 'service',
                );
                if (saved == true) {
                  ref.invalidate(hostListingsProvider(userId));
                  if (context.mounted) {
                    AtrioSnackbar.success(
                        context, l.hostListingsEditSavedSnack);
                  }
                }
              },
            ),
            if (status == 'published')
              _OptionTile(
                icon: Icons.pause_circle_outline,
                label: l.hostListingsPauseListing,
                color: AtrioColors.vibrantOrange,
                onTap: () async {
                  Navigator.pop(ctx);
                  await DatabaseService.updateListing(
                      listingId, {'status': 'paused'});
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
                  await DatabaseService.updateListing(
                      listingId, {'status': 'published'});
                  ref.invalidate(hostListingsProvider(userId));
                },
              ),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text(
                      l.hostListingsDeleteListing,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.hostTextPrimary,
                      ),
                    ),
                    content: Text(
                      l.hostListingsDeleteConfirm(title),
                      style: GoogleFonts.inter(
                          color: AtrioColors.hostTextSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: Text(l.btnCancel,
                            style: GoogleFonts.inter(
                                color: AtrioColors.hostTextSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: Text(l.btnDelete,
                            style: GoogleFonts.inter(
                                color: AtrioColors.error,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseService.deleteListing(listingId);
                  ref.invalidate(hostListingsProvider(userId));
                  if (context.mounted) {
                    AtrioSnackbar.info(context, l.hostListingsDeletedSnack);
                  }
                }
              },
            ),
            const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  const _StatCard({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AtrioColors.hostTextPrimary,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AtrioColors.hostTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HOST LISTING CARD (full-width)
// ═══════════════════════════════════════════════════════════════════
class _HostListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;
  const _HostListingCard({
    required this.listing,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final images = List<String>.from(listing['images'] ?? []);
    final status = listing['status'] as String? ?? 'draft';
    final title = listing['title'] as String? ?? l.hostListingsNoTitle;
    final rating = (listing['rating'] as num?)?.toDouble() ?? 0;
    final viewCount = (listing['view_count'] as num?)?.toInt() ?? 0;
    final basePrice = (listing['base_price'] as num?)?.toDouble();
    final city = listing['city'] as String?;

    return GestureDetector(
      onTap: onTap,
      // Long-press still works as a shortcut, but the visible menu
      // button is the primary affordance now.
      onLongPress: onMenuTap,
      child: Container(
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                                color: AtrioColors.hostSurfaceVariant),
                            errorWidget: (_, _, _) => Container(
                              color: AtrioColors.hostSurfaceVariant,
                              child: const Icon(Icons.image,
                                  size: 36,
                                  color: AtrioColors.hostTextTertiary),
                            ),
                          )
                        : Container(
                            color: AtrioColors.hostSurfaceVariant,
                            child: const Icon(Icons.image,
                                size: 36,
                                color: AtrioColors.hostTextTertiary),
                          ),
                    // Status pill top-left
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusPill(status: status),
                    ),
                    // Floating menu button top-right — primary entry
                    // point for edit/pause/delete (long-press still
                    // works as a shortcut).
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CardMenuButton(onTap: onMenuTap),
                    ),
                    // Price pill bottom-right
                    if (basePrice != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            basePrice.toCLP,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.hostTextPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (city != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13,
                            color: AtrioColors.hostTextTertiary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            city,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AtrioColors.hostTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (rating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: AtrioColors.ratingGold),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.hostTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      const Icon(Icons.visibility_outlined,
                          size: 13, color: AtrioColors.hostTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        l.hostListingsViewsCount(viewCount),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AtrioColors.hostTextSecondary,
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
  }
}

// ═══════════════════════════════════════════════════════════════════
// CARD MENU BUTTON — floating "···" affordance on each listing card
// ═══════════════════════════════════════════════════════════════════
class _CardMenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CardMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STATUS PILL
// ═══════════════════════════════════════════════════════════════════
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Color bg;
    Color fg;
    String label;
    IconData icon;
    switch (status) {
      case 'published':
        bg = AtrioColors.neonLime;
        fg = Colors.black;
        label = l.hostListingsStatusPublished;
        icon = Icons.check_circle_rounded;
      case 'draft':
        bg = Colors.white.withValues(alpha: 0.92);
        fg = AtrioColors.hostBackground;
        label = l.hostListingsStatusDraft;
        icon = Icons.edit_note_rounded;
      case 'paused':
        bg = AtrioColors.vibrantOrange;
        fg = Colors.white;
        label = l.hostListingsStatusPaused;
        icon = Icons.pause_rounded;
      default:
        bg = Colors.white.withValues(alpha: 0.92);
        fg = AtrioColors.hostBackground;
        label = status;
        icon = Icons.circle_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// OPTION TILE
// ═══════════════════════════════════════════════════════════════════
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AtrioColors.hostTextTertiary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AtrioColors.hostSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AtrioColors.hostCardBorder),
              ),
              child: const Icon(Icons.home_work_outlined,
                  size: 36, color: AtrioColors.neonLime),
            ),
            const SizedBox(height: 22),
            Text(
              l.hostListingsNoListingsTitle,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AtrioColors.hostTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.hostListingsNoListingsSubtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AtrioColors.hostTextTertiary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 20, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      l.hostListingsCreateListingBtn,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
