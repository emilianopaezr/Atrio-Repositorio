import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/listings_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _categories = ['Todos', 'Espacios', 'Experiencias', 'Servicios'];
  final _categoryTypes = [null, 'space', 'experience', 'service'];
  int _selectedCategory = 0;
  Timer? _debounce;
  String _searchQuery = '';

  // Price range filter
  RangeValues _priceRange = const RangeValues(0, 500);
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query.trim());
    });
  }

  ListingsFilter get _currentFilter {
    return ListingsFilter(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      type: _categoryTypes[_selectedCategory],
    );
  }

  bool get _hasActiveSearch =>
      _searchQuery.isNotEmpty || _selectedCategory > 0;

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync =
        _hasActiveSearch ? ref.watch(listingsProvider(_currentFilter)) : null;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Buscar',
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AtrioColors.guestSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty
                        ? AtrioColors.neonLimeDark.withValues(alpha: 0.4)
                        : AtrioColors.guestCardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search_rounded,
                        size: 22, color: AtrioColors.neonLimeDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          color: AtrioColors.guestTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Espacios, experiencias, servicios...',
                          hintStyle: GoogleFonts.roboto(
                            fontSize: 15,
                            color: AtrioColors.guestTextTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.close_rounded,
                              size: 20, color: AtrioColors.guestTextTertiary),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showFilters = !_showFilters),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _showFilters
                                ? AtrioColors.neonLimeDark
                                : AtrioColors.guestSurfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: _showFilters
                                ? Colors.white
                                : AtrioColors.guestTextSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category chips (lime green)
            SizedBox(
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
                      onTap: () => setState(() => _selectedCategory = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AtrioColors.neonLime
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AtrioColors.neonLimeDark
                                : AtrioColors.guestCardBorder,
                          ),
                        ),
                        child: Text(
                          _categories[index],
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.black
                                : AtrioColors.guestTextTertiary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Advanced filters panel
            if (_showFilters) ...[
              const SizedBox(height: 12),
              _buildFiltersPanel(),
            ],

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: !_hasActiveSearch
                  ? _buildExploreSection()
                  : searchResultsAsync!.when(
                      data: (data) {
                        final listings = data
                            .map((json) => Listing.fromJson(json))
                            .toList();
                        if (listings.isEmpty) {
                          return _buildEmptyResults();
                        }
                        return _buildSearchResults(listings);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AtrioColors.neonLimeDark,
                          strokeWidth: 2.5,
                        ),
                      ),
                      error: (_, _) => Center(
                        child: Text(
                          'Error al buscar. Intenta de nuevo.',
                          style: AtrioTypography.bodyMedium.copyWith(
                            color: AtrioColors.error,
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

  // ──────────────────────────────────────────────
  // FILTERS PANEL
  // ──────────────────────────────────────────────
  Widget _buildFiltersPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.guestCardBorder.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rango de Precio',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
                Text(
                  '\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.neonLimeDark,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AtrioColors.neonLime,
                inactiveTrackColor: AtrioColors.guestCardBorder,
                thumbColor: AtrioColors.neonLimeDark,
                overlayColor: AtrioColors.neonLime.withValues(alpha: 0.15),
              ),
              child: RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000,
                divisions: 20,
                onChanged: (values) => setState(() => _priceRange = values),
              ),
            ),
            const SizedBox(height: 8),

            // Quick filter tags
            Text(
              'Filtros Rapidos',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickFilterChip(label: 'Superhost', icon: Icons.star_rounded),
                _QuickFilterChip(label: 'WiFi', icon: Icons.wifi_rounded),
                _QuickFilterChip(label: 'Parking', icon: Icons.local_parking_rounded),
                _QuickFilterChip(label: 'Piscina', icon: Icons.pool_rounded),
                _QuickFilterChip(label: 'Cocina', icon: Icons.kitchen_rounded),
                _QuickFilterChip(label: 'A/C', icon: Icons.ac_unit_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // EXPLORE SECTION (before search)
  // ──────────────────────────────────────────────
  Widget _buildExploreSection() {
    final allListingsAsync = ref.watch(listingsProvider(const ListingsFilter()));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular searches
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Busquedas Populares',
              style: GoogleFonts.roboto(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _PopularSearchChip(
                  label: 'Estudios Foto',
                  icon: Icons.camera_alt_outlined,
                  onTap: () {
                    _searchController.text = 'estudio';
                    setState(() => _searchQuery = 'estudio');
                  },
                ),
                const SizedBox(width: 8),
                _PopularSearchChip(
                  label: 'Villas Premium',
                  icon: Icons.villa_outlined,
                  onTap: () {
                    _searchController.text = 'villa';
                    setState(() => _searchQuery = 'villa');
                  },
                ),
                const SizedBox(width: 8),
                _PopularSearchChip(
                  label: 'Loft Creativo',
                  icon: Icons.apartment_outlined,
                  onTap: () {
                    _searchController.text = 'loft';
                    setState(() => _searchQuery = 'loft');
                  },
                ),
                const SizedBox(width: 8),
                _PopularSearchChip(
                  label: 'Experiencias',
                  icon: Icons.explore_outlined,
                  onTap: () {
                    setState(() => _selectedCategory = 2);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Browse by category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Explorar por Categoria',
              style: GoogleFonts.roboto(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _CategoryCard(
                    icon: Icons.business_rounded,
                    label: 'Espacios',
                    subtitle: 'Studios, lofts, villas',
                    color: AtrioColors.neonLime,
                    onTap: () => setState(() => _selectedCategory = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Experiencias',
                    subtitle: 'Tours, talleres',
                    color: AtrioColors.neonLimeDark,
                    onTap: () => setState(() => _selectedCategory = 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _CategoryCard(
                    icon: Icons.handyman_rounded,
                    label: 'Servicios',
                    subtitle: 'Profesionales',
                    color: AtrioColors.vibrantOrange,
                    onTap: () => setState(() => _selectedCategory = 3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Tendencias',
                    subtitle: 'Lo mas popular',
                    color: AtrioColors.neonLimeDark,
                    onTap: () {
                      _searchController.text = 'premium';
                      setState(() => _searchQuery = 'premium');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Nearby / Suggestions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cerca de Ti',
                  style: GoogleFonts.roboto(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
                Icon(Icons.location_on_rounded,
                    size: 18, color: AtrioColors.neonLimeDark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          allListingsAsync.when(
            data: (data) {
              final listings =
                  data.map((json) => Listing.fromJson(json)).take(4).toList();
              if (listings.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _NearbyCard(
                        listing: listing,
                        onTap: () =>
                            context.push('/listing/${listing.id}'),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                    color: AtrioColors.neonLimeDark, strokeWidth: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SEARCH RESULTS
  // ──────────────────────────────────────────────
  Widget _buildSearchResults(List<Listing> listings) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: listings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '${listings.length} resultado${listings.length != 1 ? 's' : ''}',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AtrioColors.guestTextTertiary,
              ),
            ),
          );
        }
        final listing = listings[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SearchResultCard(
            listing: listing,
            onTap: () => context.push('/listing/${listing.id}'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AtrioColors.guestSurfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                size: 48, color: AtrioColors.guestTextTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin resultados',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AtrioColors.guestTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros terminos de busqueda',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AtrioColors.guestTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════

class _PopularSearchChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PopularSearchChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AtrioColors.guestCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AtrioColors.neonLimeDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  const _QuickFilterChip({required this.label, required this.icon});

  @override
  State<_QuickFilterChip> createState() => _QuickFilterChipState();
}

class _QuickFilterChipState extends State<_QuickFilterChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _selected = !_selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _selected
              ? AtrioColors.neonLimeDark.withValues(alpha: 0.1)
              : AtrioColors.guestSurfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selected
                ? AtrioColors.neonLimeDark
                : AtrioColors.guestCardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon,
                size: 16,
                color: _selected
                    ? AtrioColors.neonLimeDark
                    : AtrioColors.guestTextSecondary),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: _selected ? FontWeight.w600 : FontWeight.w500,
                color: _selected
                    ? AtrioColors.neonLimeDark
                    : AtrioColors.guestTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.guestCardBorder.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AtrioColors.guestTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _NearbyCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AtrioColors.guestSurface,
          border: Border.all(color: AtrioColors.guestCardBorder.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: AtrioColors.guestSurfaceVariant),
                          errorWidget: (_, _, _) =>
                              Container(color: AtrioColors.guestSurfaceVariant),
                        )
                      : Container(color: AtrioColors.guestSurfaceVariant),
                  // Price
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLime,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${listing.basePrice?.toStringAsFixed(0) ?? '0'}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (listing.city != null)
                    Text(
                      listing.city!,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AtrioColors.guestTextTertiary,
                      ),
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

class _SearchResultCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _SearchResultCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.guestCardBorder.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15)),
              child: SizedBox(
                width: 110,
                height: 100,
                child: listing.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AtrioColors.guestSurfaceVariant),
                        errorWidget: (_, _, _) =>
                            Container(color: AtrioColors.guestSurfaceVariant),
                      )
                    : Container(color: AtrioColors.guestSurfaceVariant),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: GoogleFonts.roboto(
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
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: AtrioColors.guestTextTertiary),
                          const SizedBox(width: 3),
                          Text(
                            listing.city!,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AtrioColors.guestTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${listing.basePrice?.toStringAsFixed(0) ?? '0'}/${listing.priceUnit == 'hour' ? 'hr' : listing.priceUnit}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (listing.rating > 0)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AtrioColors.ratingGold),
                              const SizedBox(width: 3),
                              Text(
                                listing.rating.toStringAsFixed(1),
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AtrioColors.guestTextPrimary,
                                ),
                              ),
                            ],
                          ),
                      ],
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
