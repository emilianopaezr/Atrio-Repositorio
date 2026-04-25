import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/services/geo_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  int _selectedCategory = 0;
  Timer? _debounce;
  String _searchQuery = '';

  // Price range filter
  RangeValues _priceRange = const RangeValues(0, 500000);
  bool _showFilters = false;
  bool _showMapView = false;

  // Near-me (PostGIS) filter state
  bool _nearbyMode = false;
  double _radiusKm = 5; // 1..50 km — shown on UI
  double _radiusKmApplied = 5; // debounced value actually sent to RPC
  Timer? _radiusDebounce;
  GeoPoint? _nearbyCenter; // resolved device pos (or fallback) when nearbyMode

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _radiusDebounce?.cancel();
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
      type: AppConstants.categoryTypes[_selectedCategory],
    );
  }

  NearbyFilter? get _currentNearbyFilter {
    if (!_nearbyMode || _nearbyCenter == null) return null;
    return NearbyFilter(
      center: _nearbyCenter!,
      radiusMeters: _radiusKmApplied * 1000,
      type: AppConstants.categoryTypes[_selectedCategory],
    );
  }

  void _onRadiusChanged(double v) {
    setState(() => _radiusKm = v);
    _radiusDebounce?.cancel();
    _radiusDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _radiusKmApplied = v);
    });
  }

  bool get _hasActiveSearch =>
      _searchQuery.isNotEmpty || _selectedCategory > 0 || _nearbyMode;

  Future<void> _toggleNearby() async {
    if (_nearbyMode) {
      setState(() {
        _nearbyMode = false;
        _nearbyCenter = null;
      });
      return;
    }
    // Resolve device position on the fly
    setState(() => _nearbyMode = true);
    final pos = await ref.read(devicePositionProvider.future);
    if (!mounted) return;
    setState(() {
      _nearbyCenter = pos ?? GeoService.defaultCenter;
    });
    if (pos == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).searchLocationFailed),
          backgroundColor: AtrioColors.guestTextSecondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nearbyFilter = _currentNearbyFilter;
    final nearbyAsync =
        nearbyFilter != null ? ref.watch(nearbyListingsProvider(nearbyFilter)) : null;
    final searchResultsAsync =
        _hasActiveSearch && nearbyFilter == null
            ? ref.watch(listingsProvider(_currentFilter))
            : null;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.searchTitle,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                    ),
                  ),
                  if (_hasActiveSearch)
                    GestureDetector(
                      onTap: () => setState(() => _showMapView = !_showMapView),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showMapView
                              ? AtrioColors.neonLimeDark
                              : AtrioColors.guestSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _showMapView
                                ? AtrioColors.neonLimeDark
                                : AtrioColors.guestCardBorder,
                          ),
                        ),
                        child: Icon(
                          _showMapView ? Icons.list_rounded : Icons.map_rounded,
                          size: 22,
                          color: _showMapView
                              ? Colors.white
                              : AtrioColors.guestTextSecondary,
                        ),
                      ),
                    ),
                ],
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
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AtrioColors.guestTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: l.searchHint,
                          hintStyle: GoogleFonts.inter(
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

            // Category chips (lime green) + Near-me toggle
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Near-me chip (always first, distinct style)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _toggleNearby,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _nearbyMode
                              ? AtrioColors.neonLimeDark
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _nearbyMode
                                ? AtrioColors.neonLimeDark
                                : AtrioColors.guestCardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _nearbyMode
                                  ? Icons.my_location_rounded
                                  : Icons.location_on_outlined,
                              size: 15,
                              color: _nearbyMode
                                  ? Colors.white
                                  : AtrioColors.guestTextSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _nearbyMode
                                  ? l.searchNearbyOn(_radiusKm.round())
                                  : l.searchNearMe,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: _nearbyMode
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _nearbyMode
                                    ? Colors.white
                                    : AtrioColors.guestTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Category chips
                  for (int index = 0;
                      index < AppConstants.categoryLabels.length;
                      index++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == index
                                ? AtrioColors.neonLime
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedCategory == index
                                  ? AtrioColors.neonLimeDark
                                  : AtrioColors.guestCardBorder,
                            ),
                          ),
                          child: Text(
                            <String>[
                              l.bookingsAll,
                              l.searchCategorySpaces,
                              l.searchCategoryExperiences,
                              l.searchCategoryServices,
                            ][index],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: _selectedCategory == index
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedCategory == index
                                  ? Colors.black
                                  : AtrioColors.guestTextTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Radius slider (only when nearby mode)
            if (_nearbyMode) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.radar_rounded,
                        size: 16, color: AtrioColors.neonLimeDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AtrioColors.neonLimeDark,
                          inactiveTrackColor:
                              AtrioColors.guestCardBorder,
                          thumbColor: AtrioColors.neonLimeDark,
                          trackHeight: 2,
                          overlayColor:
                              AtrioColors.neonLime.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          value: _radiusKm,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          onChanged: _onRadiusChanged,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${_radiusKm.round()} km',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AtrioColors.guestTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                  : (_nearbyMode && _nearbyCenter == null)
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AtrioColors.neonLimeDark,
                            strokeWidth: 2.5,
                          ),
                        )
                      : (nearbyAsync ?? searchResultsAsync!).when(
                          data: (data) {
                            final listings = data
                                .map((json) => Listing.fromJson(json))
                                .toList();
                            if (listings.isEmpty) {
                              return _buildEmptyResults();
                            }
                            return _showMapView
                                ? _buildMapView(listings)
                                : _buildSearchResults(listings);
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AtrioColors.neonLimeDark,
                              strokeWidth: 2.5,
                            ),
                          ),
                          error: (_, _) => Center(
                            child: Text(
                              l.searchError,
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
    final l = AppLocalizations.of(context);
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
                  l.searchPriceRange,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
                Text(
                  '${_priceRange.start.toCLP} - ${_priceRange.end.toCLP}',
                  style: GoogleFonts.inter(
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
                max: 500000,
                divisions: 50,
                onChanged: (values) => setState(() => _priceRange = values),
              ),
            ),
            const SizedBox(height: 8),

            // Quick filter tags
            Text(
              l.searchQuickFilters,
              style: GoogleFonts.inter(
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
                _QuickFilterChip(label: l.searchFilterSuperhost, icon: Icons.star_rounded),
                _QuickFilterChip(label: 'WiFi', icon: Icons.wifi_rounded),
                _QuickFilterChip(label: 'Parking', icon: Icons.local_parking_rounded),
                _QuickFilterChip(label: l.searchFilterPool, icon: Icons.pool_rounded),
                _QuickFilterChip(label: l.searchFilterKitchen, icon: Icons.kitchen_rounded),
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
    final l = AppLocalizations.of(context);
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
              l.searchPopular,
              style: GoogleFonts.inter(
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
                  label: l.searchPopularStudios,
                  icon: Icons.camera_alt_outlined,
                  onTap: () {
                    _searchController.text = 'estudio';
                    setState(() => _searchQuery = 'estudio');
                  },
                ),
                const SizedBox(width: 8),
                _PopularSearchChip(
                  label: l.searchPopularVillas,
                  icon: Icons.villa_outlined,
                  onTap: () {
                    _searchController.text = 'villa';
                    setState(() => _searchQuery = 'villa');
                  },
                ),
                const SizedBox(width: 8),
                _PopularSearchChip(
                  label: l.searchPopularLoft,
                  icon: Icons.apartment_outlined,
                  onTap: () {
                    _searchController.text = 'loft';
                    setState(() => _searchQuery = 'loft');
                  },
                ),
                const SizedBox(width: 8),
                _PopularSearchChip(
                  label: l.searchPopularExperiences,
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
              l.searchBrowseByCategory,
              style: GoogleFonts.inter(
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
                    label: l.searchCategorySpaces,
                    subtitle: l.searchCategorySpacesDesc,
                    color: AtrioColors.neonLime,
                    onTap: () => setState(() => _selectedCategory = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryCard(
                    icon: Icons.auto_awesome_rounded,
                    label: l.searchCategoryExperiences,
                    subtitle: l.searchCategoryExperiencesDesc,
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
                    label: l.searchCategoryServices,
                    subtitle: l.searchCategoryServicesDesc,
                    color: AtrioColors.vibrantOrange,
                    onTap: () => setState(() => _selectedCategory = 3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryCard(
                    icon: Icons.local_fire_department_rounded,
                    label: l.searchCategoryTrending,
                    subtitle: l.searchCategoryTrendingDesc,
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
                  l.searchNearYou,
                  style: GoogleFonts.inter(
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
  // MAP VIEW
  // ──────────────────────────────────────────────
  Widget _buildMapView(List<Listing> listings) {
    final l = AppLocalizations.of(context);
    final withLocation = listings
        .where((l) => l.latitude != null && l.longitude != null)
        .toList();

    if (withLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: AtrioColors.guestTextTertiary),
            const SizedBox(height: 12),
            Text(
              l.searchNoLocations,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.searchNoCoords,
              style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.guestTextTertiary),
            ),
          ],
        ),
      );
    }

    // Calculate bounds to fit all markers
    double minLat = withLocation.first.latitude!;
    double maxLat = withLocation.first.latitude!;
    double minLng = withLocation.first.longitude!;
    double maxLng = withLocation.first.longitude!;
    for (final l in withLocation) {
      if (l.latitude! < minLat) minLat = l.latitude!;
      if (l.latitude! > maxLat) maxLat = l.latitude!;
      if (l.longitude! < minLng) minLng = l.longitude!;
      if (l.longitude! > maxLng) maxLng = l.longitude!;
    }

    final markers = withLocation.map((l) {
      return Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.latitude!, l.longitude!),
        infoWindow: InfoWindow(
          title: l.title,
          snippet: l.basePrice?.toCLP ?? '',
          onTap: () => context.push('/listing/${l.id}'),
        ),
      );
    }).toSet();

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Draw search radius circle when in nearby mode with a resolved center.
    final circles = <Circle>{};
    if (_nearbyMode && _nearbyCenter != null) {
      circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: LatLng(
            _nearbyCenter!.latitude,
            _nearbyCenter!.longitude,
          ),
          radius: _radiusKmApplied * 1000,
          fillColor: AtrioColors.neonLime.withValues(alpha: 0.18),
          strokeColor: AtrioColors.neonLimeDark,
          strokeWidth: 2,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 12),
            markers: markers,
            circles: circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              if (withLocation.length > 1) {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(minLat, minLng),
                      northeast: LatLng(maxLat, maxLng),
                    ),
                    60,
                  ),
                );
              }
            },
          ),
          // Result count badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Text(
                l.searchInMap(withLocation.length),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SEARCH RESULTS
  // ──────────────────────────────────────────────
  Widget _buildSearchResults(List<Listing> listings) {
    final l = AppLocalizations.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: listings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              l.searchResults(listings.length),
              style: GoogleFonts.inter(
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
    final l = AppLocalizations.of(context);
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
            l.searchNoResults,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AtrioColors.guestTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.searchTryOther,
            style: GoogleFonts.inter(
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
// HELPERS
// ══════════════════════════════════════════════════

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  return km < 10
      ? '${km.toStringAsFixed(1)} km'
      : '${km.round()} km';
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
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
                        listing.basePrice?.toCLP ?? '\$0',
                        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (listing.city != null) ...[
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: AtrioColors.guestTextTertiary),
                          const SizedBox(width: 3),
                          Text(
                            listing.city!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AtrioColors.guestTextSecondary,
                            ),
                          ),
                        ],
                        if (listing.distanceM != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AtrioColors.neonLime
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatDistance(listing.distanceM!),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AtrioColors.guestTextPrimary,
                              ),
                            ),
                          ),
                        ],
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
                            '${listing.basePrice?.toCLP ?? '\$0'}/${listing.priceUnit == 'hour' ? 'hr' : listing.priceUnit}',
                            style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
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
