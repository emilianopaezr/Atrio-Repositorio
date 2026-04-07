import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';


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
            // === TOP BAR ===
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo_negro.png',
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AtrioColors.guestSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AtrioColors.guestCardBorder),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 20,
                                color: AtrioColors.guestTextPrimary,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AtrioColors.neonLime,
                                  shape: BoxShape.circle,
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
            ),

            // === SEARCH BAR ===
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GestureDetector(
                  onTap: () => context.go('/guest/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AtrioColors.guestSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AtrioColors.guestCardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AtrioColors.neonLimeDark,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Buscar espacios, experiencias...',
                          style: AtrioTypography.bodyMedium.copyWith(
                            color: AtrioColors.guestTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // === CATEGORY CHIPS ===
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: AppConstants.categoryLabels.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategory == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AtrioColors.neonLime : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AtrioColors.neonLimeDark : AtrioColors.guestCardBorder,
                              ),
                            ),
                            child: Text(
                              AppConstants.categoryLabels[index],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AtrioColors.guestTextPrimary : AtrioColors.guestTextTertiary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // === QUICK SERVICES BANNER ===
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.push('/quick-services'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.handyman_rounded,
                            color: AtrioColors.neonLime, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicios Rapidos',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mudanza, limpieza, armado y mas',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AtrioColors.neonLime,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.black, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // === BECOME A HOST BANNER ===
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.push('/host-benefits'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A3A00), Color(0xFF1A2800)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AtrioColors.neonLime.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AtrioColors.neonLime.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.home_work_rounded,
                                color: AtrioColors.neonLime, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sé anfitrión en Atrio',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Publica tu espacio y genera ingresos',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AtrioColors.neonLime, size: 24),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Haptics.medium();
                            ref.read(appModeProvider.notifier).switchToHost();
                            context.go('/host/dashboard');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AtrioColors.neonLime,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                          label: Text(
                            'Sé anfitrión',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // === LISTINGS GRID ===
            listingsAsync.when(
              data: (listingsData) {
                final listings = listingsData
                    .map((json) => Listing.fromJson(json))
                    .toList();
                if (listings.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      icon: Icons.explore_outlined,
                      title: 'No hay anuncios disponibles',
                      subtitle:
                          'Intenta con otra categoria o vuelve mas tarde',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final listing = listings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _ListingCard(
                            listing: listing,
                            onTap: () =>
                                context.push('/listing/${listing.id}'),
                          ),
                        );
                      },
                      childCount: listings.length,
                    ),
                  ),
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
                          'Error al cargar anuncios',
                          style: AtrioTypography.headingSmall.copyWith(
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => ref
                              .invalidate(listingsProvider(_currentFilter)),
                          child: Text(
                            'Reintentar',
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

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// === LISTING CARD (full-width, clean, minimal) ===
class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AtrioColors.guestSurface,
          border: Border.all(color: AtrioColors.guestCardBorder.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlays
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: const Color(0xFFF0F0F0),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.image,
                                size: 40, color: AtrioColors.guestTextTertiary),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.image,
                              size: 40, color: AtrioColors.guestTextTertiary),
                        ),
                  // Price pill (lime)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${listing.basePrice?.toCLP ?? '\$0'}/${_unitShort(listing.priceUnit)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Favorite
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: AtrioColors.guestTextSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.guestTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.rating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded,
                            size: 14, color: AtrioColors.ratingGold),
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
                  const SizedBox(height: 4),
                  if (listing.city != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AtrioColors.guestTextTertiary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.city!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AtrioColors.guestTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (listing.hostData != null) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.3),
                            backgroundImage: listing.hostData!['photo_url'] != null
                                ? NetworkImage(listing.hostData!['photo_url'] as String)
                                : null,
                            child: listing.hostData!['photo_url'] == null
                                ? const Icon(Icons.person, size: 12, color: AtrioColors.guestTextTertiary)
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (listing.hostData!['display_name'] as String? ?? '').split(' ').first,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AtrioColors.guestTextTertiary,
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
    );
  }

  String _unitShort(String unit) {
    switch (unit) {
      case 'night': return 'noche';
      case 'hour': return 'hr';
      case 'session': return 'sesion';
      case 'person': return 'persona';
      default: return unit;
    }
  }
}

// === EMPTY STATE ===
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
              style: AtrioTypography.headingSmall.copyWith(
                color: AtrioColors.guestTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AtrioTypography.bodyMedium.copyWith(
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
