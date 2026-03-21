import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/listings_provider.dart';

// === Minimal Light Theme Constants ===
const _bg = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E5E5);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF666666);
const _textMuted = Color(0xFF999999);
const _lime = Color(0xFFD4FF00);
const _limeDark = Color(0xFF9BBF00);
const _gold = Color(0xFFFFB800);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;
  final _categories = ['Todos', 'Espacios', 'Experiencias', 'Servicios'];
  final _categoryFilters = [null, 'space', 'experience', 'service'];

  ListingsFilter get _currentFilter => ListingsFilter(
        type: _categoryFilters[_selectedCategory],
      );

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider(_currentFilter));

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _limeDark,
        backgroundColor: _white,
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
                                color: _white,
                                shape: BoxShape.circle,
                                border: Border.all(color: _border),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 20,
                                color: _textPrimary,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _lime,
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
                      color: _white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _limeDark,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Buscar espacios, experiencias...',
                          style: AtrioTypography.bodyMedium.copyWith(
                            color: _textMuted,
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
                    itemCount: _categories.length,
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
                              color: isSelected ? _lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? _limeDark : _border,
                              ),
                            ),
                            child: Text(
                              _categories[index],
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? _textPrimary : _textMuted,
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
                          color: _lime.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.handyman_rounded,
                            color: _lime, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicios Rapidos',
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mudanza, limpieza, armado y mas',
                              style: GoogleFonts.roboto(
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
                          color: _lime,
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
                      color: _lime.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _lime.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_work_rounded,
                            color: _lime, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Se anfitrion en Atrio',
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Publica tu espacio y genera ingresos',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: _lime, size: 24),
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
                      color: _limeDark,
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
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => ref
                              .invalidate(listingsProvider(_currentFilter)),
                          child: Text(
                            'Reintentar',
                            style: GoogleFonts.roboto(
                              color: _limeDark,
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
          color: _white,
          border: Border.all(color: _border.withValues(alpha: 0.6)),
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
                                size: 40, color: _textMuted),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.image,
                              size: 40, color: _textMuted),
                        ),
                  // Price pill (lime)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _lime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${listing.basePrice?.toStringAsFixed(0) ?? '0'}/${_unitShort(listing.priceUnit)}',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
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
                        color: _textSecondary,
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
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.rating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded,
                            size: 14, color: _gold),
                        const SizedBox(width: 3),
                        Text(
                          listing.rating.toStringAsFixed(1),
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
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
                          color: _textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.city!,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (listing.hostData != null) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: _lime.withValues(alpha: 0.3),
                            backgroundImage: listing.hostData!['photo_url'] != null
                                ? NetworkImage(listing.hostData!['photo_url'] as String)
                                : null,
                            child: listing.hostData!['photo_url'] == null
                                ? const Icon(Icons.person, size: 12, color: _textMuted)
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (listing.hostData!['display_name'] as String? ?? '').split(' ').first,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textMuted,
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
            Icon(icon, size: 64, color: _textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: AtrioTypography.headingSmall.copyWith(
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AtrioTypography.bodyMedium.copyWith(
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
