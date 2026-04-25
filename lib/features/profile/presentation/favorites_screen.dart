import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

/// Provider for user's favorite listings using favorite_listing_ids from profiles
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
      .select('*, host:profiles!host_id(id, display_name, photo_url, is_verified)')
      .inFilter('id', favIds);

  return List<Map<String, dynamic>>.from(data)
      .map((json) => Listing.fromJson(json))
      .toList();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      appBar: AppBar(
        backgroundColor: AtrioColors.guestBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AtrioColors.guestTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l.favoritesTitle,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLime.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_outline_rounded,
                      size: 56,
                      color: AtrioColors.guestTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.favoritesEmptyTitle,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      l.favoritesEmptyDesc,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AtrioColors.guestTextTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go('/guest/home'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLime,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.explore_rounded, size: 18, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            l.favoritesExplore,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AtrioColors.neonLimeDark,
            onRefresh: () async => ref.invalidate(favoritesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final listing = favorites[index];
                return _FavoriteCard(
                  listing: listing,
                  onTap: () => context.push('/listing/${listing.id}'),
                  onRemove: () async {
                    final userId = SupabaseConfig.auth.currentUser?.id;
                    if (userId == null) return;
                    try {
                      final profile = await SupabaseConfig.client
                          .from('profiles')
                          .select('favorite_listing_ids')
                          .eq('id', userId)
                          .single();
                      final favs = List<String>.from(profile['favorite_listing_ids'] ?? []);
                      favs.remove(listing.id);
                      await SupabaseConfig.client
                          .from('profiles')
                          .update({'favorite_listing_ids': favs})
                          .eq('id', userId);
                      ref.invalidate(favoritesProvider);
                    } catch (e) { debugPrint('favorites error: $e'); }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AtrioColors.neonLimeDark),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AtrioColors.error),
              const SizedBox(height: 12),
              Text(
                l.favoritesLoadError,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AtrioColors.guestTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(favoritesProvider),
                child: Text(
                  l.favoritesRetry,
                  style: GoogleFonts.inter(
                    color: AtrioColors.neonLimeDark,
                    fontWeight: FontWeight.w600,
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

class _FavoriteCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.listing,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AtrioColors.guestCardBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
              child: SizedBox(
                width: 120,
                height: 110,
                child: listing.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AtrioColors.guestSurfaceVariant),
                        errorWidget: (_, _, _) =>
                            Container(color: AtrioColors.guestSurfaceVariant),
                      )
                    : Container(
                        color: AtrioColors.guestSurfaceVariant,
                        child: const Icon(Icons.image, color: AtrioColors.guestTextTertiary),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (listing.city != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AtrioColors.guestTextTertiary),
                          const SizedBox(width: 3),
                          Text(
                            listing.city!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AtrioColors.guestTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${listing.basePrice?.toCLP ?? '\$0'}/${listing.priceUnit == 'hour' ? 'hr' : listing.priceUnit}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (listing.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: AtrioColors.ratingGold),
                          const SizedBox(width: 3),
                          Text(
                            listing.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AtrioColors.guestTextPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AtrioColors.error.withValues(alpha: 0.8),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
