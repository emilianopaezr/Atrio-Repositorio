import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// Loads listings whose ids are in profile.favorite_listing_ids.
final favoritesProvider = FutureProvider<List<Listing>>((ref) async {
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await SupabaseConfig.client
      .from('profiles')
      .select('favorite_listing_ids')
      .eq('id', userId)
      .maybeSingle();

  if (profile == null) return [];

  final favIds = List<String>.from(profile['favorite_listing_ids'] ?? []);
  if (favIds.isEmpty) return [];

  final data = await SupabaseConfig.client
      .from('listings')
      .select(
          '*, host:profiles!host_id(id, display_name, photo_url, is_verified)')
      .inFilter('id', favIds);

  return List<Map<String, dynamic>>.from(data)
      .map((json) => Listing.fromJson(json))
      .toList();
});

/// Favoritos — editorial redesign.
///
///  • Header: PageEyebrow + título + contador lime
///  • Cards verticales con hero image, overlay de precio y heart-to-remove
///  • Empty state amplio con CTA negro
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final l = AppLocalizations.of(context);

    final count = favoritesAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AtrioColors.guestTextPrimary),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(height: 6),
                  PageEyebrow(text: l.favoritesEyebrow),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l.favoritesTitle,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.guestTextPrimary,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, ref, favoritesAsync, l)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Listing>> async,
    AppLocalizations l,
  ) {
    return async.when(
      data: (favs) {
        if (favs.isEmpty) return _EmptyState(l: l);
        return RefreshIndicator(
          color: AtrioColors.neonLimeDark,
          backgroundColor: AtrioColors.guestSurface,
          onRefresh: () async => ref.invalidate(favoritesProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            itemCount: favs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) {
              final listing = favs[i];
              return _FavoriteCard(
                listing: listing,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/listing/${listing.id}');
                },
                onRemove: () async {
                  HapticFeedback.mediumImpact();
                  final userId = SupabaseConfig.auth.currentUser?.id;
                  if (userId == null) return;
                  try {
                    final profile = await SupabaseConfig.client
                        .from('profiles')
                        .select('favorite_listing_ids')
                        .eq('id', userId)
                        .single();
                    final list = List<String>.from(
                        profile['favorite_listing_ids'] ?? []);
                    list.remove(listing.id);
                    await SupabaseConfig.client
                        .from('profiles')
                        .update({'favorite_listing_ids': list}).eq(
                            'id', userId);
                    ref.invalidate(favoritesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 2),
                            backgroundColor: AtrioColors.guestTextPrimary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            content: Text(
                              'Quitado de guardados',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                    }
                  } catch (e) {
                    AppLogger.w('favorites: $e', tag: 'favorites');
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AtrioColors.neonLimeDark, strokeWidth: 2.4),
      ),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AtrioColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 28, color: AtrioColors.error),
              ),
              const SizedBox(height: 16),
              Text(
                l.favoritesLoadError,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => ref.invalidate(favoritesProvider),
                style: TextButton.styleFrom(
                  backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.18),
                  foregroundColor: AtrioColors.neonLimeDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
                child: Text(
                  l.favoritesRetry,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.neonLimeDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Favorite card (vertical, premium) ────────────────────────
class _FavoriteCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _FavoriteCard({
    required this.listing,
    required this.onTap,
    required this.onRemove,
  });

  String get _unitLabel {
    switch (listing.priceUnit) {
      case 'hour':
        return 'hr';
      case 'night':
        return 'noche';
      case 'day':
        return 'día';
      case 'session':
        return 'sesión';
      default:
        return listing.priceUnit;
    }
  }

  String? get _hostName {
    final raw = listing.hostData?['display_name'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = listing.images.isNotEmpty ? listing.images.first : null;
    final price = (listing.basePrice ?? 0).toCLPWithFee;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (image != null)
                        CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                              color: AtrioColors.guestSurfaceVariant),
                          errorWidget: (_, _, _) => Container(
                            color: AtrioColors.guestSurfaceVariant,
                            child: const Icon(Icons.image_outlined,
                                color: AtrioColors.guestTextTertiary),
                          ),
                        )
                      else
                        Container(
                          color: AtrioColors.guestSurfaceVariant,
                          child: const Icon(Icons.image_outlined,
                              size: 32, color: AtrioColors.guestTextTertiary),
                        ),

                      // Bottom-to-top dark gradient for legibility
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Heart (remove) top-right
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _GlassButton(
                          icon: Icons.favorite_rounded,
                          iconColor: AtrioColors.error,
                          onTap: onRemove,
                        ),
                      ),

                      // Price pill bottom-left
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                price,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (_unitLabel.isNotEmpty)
                                Text(
                                  ' / $_unitLabel',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Rating chip bottom-right (only if any)
                      if (listing.rating > 0)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 13, color: AtrioColors.ratingGold),
                                const SizedBox(width: 3),
                                Text(
                                  listing.rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13.5, color: AtrioColors.guestTextSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.city ?? 'Sin ubicación',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AtrioColors.guestTextSecondary,
                              ),
                            ),
                          ),
                          if (_hostName != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AtrioColors.guestTextTertiary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _hostName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AtrioColors.guestTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

// ─── Frosted glass icon button ───────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _GlassButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final AppLocalizations l;
  const _EmptyState({required this.l});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AtrioColors.neonLime.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 36,
                color: AtrioColors.neonLimeDark,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l.favoritesEmptyTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.favoritesEmptyDesc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.go('/guest/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtrioColors.guestTextPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_rounded,
                        size: 17, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l.favoritesExplore,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
