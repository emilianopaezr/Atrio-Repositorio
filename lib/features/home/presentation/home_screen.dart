import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;

  ListingsFilter get _currentFilter => ListingsFilter(
        type: AppConstants.categoryTypes[_selectedCategory],
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final listingsAsync = ref.watch(listingsProvider(_currentFilter));

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: RefreshIndicator(
        color: AtrioColors.neonLimeDark,
        backgroundColor: AtrioColors.guestSurface,
        onRefresh: () async {
          ref.invalidate(listingsProvider(_currentFilter));
          ref.invalidate(featuredListingsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ─── HERO HEADER (eyebrow + big title + bell) ───
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.homeHeroTitle,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextPrimary,
                                letterSpacing: -1.0,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _IconCircle(
                        icon: Icons.notifications_none_rounded,
                        hasDot: true,
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── SEARCH BAR ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: GestureDetector(
                  onTap: () => context.go('/guest/search'),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
                    height: 52,
                    decoration: BoxDecoration(
                      color: AtrioColors.warmGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: AtrioColors.guestTextSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.homeSearchHint,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AtrioColors.guestTextTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AtrioColors.guestTextPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── CATEGORY TABS ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: AppConstants.categoryLabels.length,
                    itemBuilder: (context, index) {
                      final labels = <String>[
                        l.bookingsAll,
                        l.searchCategorySpaces,
                        l.searchCategoryExperiences,
                        l.searchCategoryServices,
                      ];
                      final isSelected = _selectedCategory == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 22),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = index),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                labels[index],
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AtrioColors.guestTextPrimary
                                      : AtrioColors.guestTextTertiary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 22 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AtrioColors.guestTextPrimary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Divider(color: AtrioColors.guestDivider, height: 1),
            ),

            // ─── QUICK SERVICES (2x2 grid) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: _QuickServicesSection(
                  onSeeAll: () => context.push('/quick-services'),
                ),
              ),
            ),

            // ─── CAROUSEL: For You (featured) ───
            listingsAsync.when(
              data: (listingsData) {
                final all = listingsData
                    .map((j) => Listing.fromJson(j))
                    .toList();
                if (all.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      icon: Icons.explore_outlined,
                      title: l.homeNoListings,
                      subtitle: l.homeNoListingsSubtitle,
                    ),
                  );
                }
                // Build curated lists from the same source
                final featured = [...all]
                  ..sort((a, b) => b.rating.compareTo(a.rating));
                final nearby = [...all]
                  ..sort((a, b) => (a.distanceM ?? double.infinity)
                      .compareTo(b.distanceM ?? double.infinity));
                final trending = [...all]
                  ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
                final recent = [...all]
                  ..sort((a, b) => (b.createdAt ?? DateTime(1970))
                      .compareTo(a.createdAt ?? DateTime(1970)));

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── For You (big horizontal cards) ───
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: l.homeFeaturedListings,
                      subtitle: l.homeFeaturedSubtitle,
                      onSeeAll: () => context.go('/guest/search'),
                    ),
                    const SizedBox(height: 12),
                    _BigCarousel(
                      listings: featured.take(8).toList(),
                      onTap: (id) => context.push('/listing/$id'),
                    ),

                    // ─── Trending (compact pills) ───
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: l.homeTrendingTitle,
                      subtitle: l.homeTrendingSubtitle,
                      onSeeAll: () => context.go('/guest/search'),
                    ),
                    const SizedBox(height: 12),
                    _CompactCarousel(
                      listings: trending.take(8).toList(),
                      onTap: (id) => context.push('/listing/$id'),
                    ),

                    // ─── Become a host banner (mid-page) ───
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _BecomeHostBanner(
                        onTap: () {
                          Haptics.medium();
                          ref.read(appModeProvider.notifier).switchToHost();
                          context.go('/host/dashboard');
                        },
                      ),
                    ),

                    // ─── Near you (medium cards) ───
                    const SizedBox(height: 36),
                    _SectionHeader(
                      title: l.homeNearbyTitle,
                      subtitle: l.homeNearbySubtitle,
                      onSeeAll: () => context.go('/guest/search'),
                    ),
                    const SizedBox(height: 12),
                    _MediumCarousel(
                      listings: nearby.take(8).toList(),
                      onTap: (id) => context.push('/listing/$id'),
                    ),

                    // ─── Recently added (full cards) ───
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: l.homeRecentTitle,
                      subtitle: l.homeRecentSubtitle,
                      onSeeAll: () => context.go('/guest/search'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: recent.take(4).map((listing) => Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: _ListingCard(
                            listing: listing,
                            onTap: () =>
                                context.push('/listing/${listing.id}'),
                          ),
                        )).toList(),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ]),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AtrioColors.neonLimeDark,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AtrioColors.error),
                        const SizedBox(height: 16),
                        Text(
                          l.homeLoadError,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => ref
                              .invalidate(listingsProvider(_currentFilter)),
                          child: Text(
                            l.btnRetry,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SECTION HEADER — lime bar + title + subtitle + see-all CTA
// ═══════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.guestTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Text(
                l.searchSeeAll,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.guestTextPrimary,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BIG CAROUSEL — featured listings (large hero cards)
// ═══════════════════════════════════════════════════════════════════
class _BigCarousel extends StatelessWidget {
  final List<Listing> listings;
  final ValueChanged<String> onTap;
  const _BigCarousel({required this.listings, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final l = listings[index];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _BigCarouselCard(listing: l, onTap: () => onTap(l.id)),
          );
        },
      ),
    );
  }
}

class _BigCarouselCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _BigCarouselCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 5 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    listing.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                Container(color: AtrioColors.warmGray),
                            errorWidget: (_, _, _) => Container(
                              color: AtrioColors.warmGray,
                              child: const Icon(Icons.image,
                                  size: 36,
                                  color: AtrioColors.guestTextTertiary),
                            ),
                          )
                        : Container(
                            color: AtrioColors.warmGray,
                            child: const Icon(Icons.image,
                                size: 36,
                                color: AtrioColors.guestTextTertiary),
                          ),
                    if (listing.rating > 0)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AtrioColors.guestTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: AtrioColors.guestTextPrimary,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            if (listing.city != null)
              Text(
                listing.city!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AtrioColors.guestTextTertiary,
                ),
              ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: (listing.basePrice ?? 0).toCLPWithFee,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: ' / ${_unitShort(context, listing.priceUnit)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.guestTextTertiary,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// COMPACT CAROUSEL — trending pills (image + small text)
// ═══════════════════════════════════════════════════════════════════
class _CompactCarousel extends StatelessWidget {
  final List<Listing> listings;
  final ValueChanged<String> onTap;
  const _CompactCarousel({required this.listings, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final l = listings[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onTap(l.id),
              child: SizedBox(
                width: 156,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1 / 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            l.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: l.images.first,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) =>
                                        Container(color: AtrioColors.warmGray),
                                    errorWidget: (_, _, _) => Container(
                                      color: AtrioColors.warmGray,
                                      child: const Icon(Icons.image,
                                          size: 28,
                                          color: AtrioColors.guestTextTertiary),
                                    ),
                                  )
                                : Container(
                                    color: AtrioColors.warmGray,
                                    child: const Icon(Icons.image,
                                        size: 28,
                                        color: AtrioColors.guestTextTertiary),
                                  ),
                            // Trending badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AtrioColors.neonLime,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 11,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${l.viewCount}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      (l.basePrice ?? 0).toCLPWithFee,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MEDIUM CAROUSEL — nearby (mid-size cards with rating + price overlay)
// ═══════════════════════════════════════════════════════════════════
class _MediumCarousel extends StatelessWidget {
  final List<Listing> listings;
  final ValueChanged<String> onTap;
  const _MediumCarousel({required this.listings, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final l = listings[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onTap(l.id),
              child: SizedBox(
                width: 190,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 230,
                        width: 190,
                        child: l.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: l.images.first,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    Container(color: AtrioColors.warmGray),
                                errorWidget: (_, _, _) => Container(
                                  color: AtrioColors.warmGray,
                                  child: const Icon(Icons.image,
                                      size: 32,
                                      color: AtrioColors.guestTextTertiary),
                                ),
                              )
                            : Container(
                                color: AtrioColors.warmGray,
                                child: const Icon(Icons.image,
                                    size: 32,
                                    color: AtrioColors.guestTextTertiary),
                              ),
                      ),
                    ),
                    // bottom gradient
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Rating top-left
                    if (l.rating > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 11, color: AtrioColors.ratingGold),
                              const SizedBox(width: 2),
                              Text(
                                l.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AtrioColors.guestTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Title + city + price
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (l.city != null)
                            Text(
                              l.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (l.basePrice ?? 0).toCLPWithFee,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ICON CIRCLE (header bell)
// ═══════════════════════════════════════════════════════════════════
class _IconCircle extends StatelessWidget {
  final IconData icon;
  final bool hasDot;
  final VoidCallback onTap;
  const _IconCircle({
    required this.icon,
    required this.hasDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AtrioColors.warmGray,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: AtrioColors.guestTextPrimary),
          ),
          if (hasDot)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// QUICK SERVICES
// ═══════════════════════════════════════════════════════════════════
class _QuickServicesSection extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _QuickServicesSection({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    l.homeQuickServicesTitle,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.homeQuickServicesSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AtrioColors.guestTextPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.homeQuickServicesCta,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 13),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ServiceTile(
                icon: Icons.local_shipping_rounded,
                label: l.homeQuickCatMoving,
                accent: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ServiceTile(
                icon: Icons.cleaning_services_rounded,
                label: l.homeQuickCatCleaning,
                accent: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ServiceTile(
                icon: Icons.handyman_rounded,
                label: l.homeQuickCatAssembly,
                accent: const Color(0xFFE9F7C6),
                iconColor: const Color(0xFF65A30D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ServiceTile(
                icon: Icons.build_rounded,
                label: l.homeQuickCatRepair,
                accent: const Color(0xFFFCE7F3),
                iconColor: const Color(0xFFDB2777),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color iconColor;
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtrioColors.warmGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BECOME A HOST BANNER
// ═══════════════════════════════════════════════════════════════════
class _BecomeHostBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _BecomeHostBanner({required this.onTap});

  Widget _bannerStat({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check_rounded,
              size: 13, color: AtrioColors.neonLimeDark),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AtrioColors.guestTextSecondary,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          // Lime stripe removed by request — the lime "1% COMISIÓN"
          // chip + the lime arrow on the CTA already provide enough
          // brand presence on this card.
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l.homeBecomeHostEyebrow,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AtrioColors.guestTextTertiary,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AtrioColors.neonLime,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.homeBecomeHostBadge,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AtrioColors.guestTextPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.homeBecomeHostHero,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -0.7,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.homeBecomeHostDescription,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Bullet stats row
                        Row(
                          children: [
                            _bannerStat(
                              icon: Icons.flash_on_rounded,
                              label: l.homeBecomeHostStatDirect,
                            ),
                            const SizedBox(width: 16),
                            _bannerStat(
                              icon: Icons.support_agent_rounded,
                              label: l.homeBecomeHostStatSupport,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            color: AtrioColors.guestTextPrimary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l.homeBecomeHostStart,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: AtrioColors.neonLime),
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

// ═══════════════════════════════════════════════════════════════════
// LISTING CARD (full-width)
// ═══════════════════════════════════════════════════════════════════
class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: AtrioColors.warmGray,
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: AtrioColors.warmGray,
                            child: const Icon(Icons.image,
                                size: 40,
                                color: AtrioColors.guestTextTertiary),
                          ),
                        )
                      : Container(
                          color: AtrioColors.warmGray,
                          child: const Icon(Icons.image,
                              size: 40,
                              color: AtrioColors.guestTextTertiary),
                        ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: AtrioColors.guestTextPrimary,
                        size: 19,
                      ),
                    ),
                  ),
                  if (listing.rating > 0)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AtrioColors.guestTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 12, 2, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (listing.basePrice ?? 0).toCLPWithFee,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (listing.city != null) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 13,
                          color: AtrioColors.guestTextTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          listing.city!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '/ ${_unitShort(context, listing.priceUnit)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _unitShort(BuildContext context, String unit) {
  final l = AppLocalizations.of(context);
  switch (unit) {
    case 'night':
      return l.homeUnitNight;
    case 'hour':
      return l.homeUnitHour;
    case 'session':
      return l.homeUnitSession;
    case 'person':
      return l.homeUnitPerson;
    default:
      return unit;
  }
}

// ═══════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(icon, size: 64, color: AtrioColors.guestTextTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
