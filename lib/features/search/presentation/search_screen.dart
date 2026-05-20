import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../config/theme/app_colors.dart';
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

  RangeValues _priceRange = const RangeValues(0, 500000);
  bool _showFilters = false;
  bool _showMapView = false;

  bool _nearbyMode = false;
  double _radiusKm = 5;
  double _radiusKmApplied = 5;
  Timer? _radiusDebounce;
  GeoPoint? _nearbyCenter;

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
    setState(() => _nearbyMode = true);
    final pos = await ref.read(devicePositionProvider.future);
    if (!mounted) return;
    setState(() {
      _nearbyCenter = pos ?? GeoService.defaultCenter;
    });
    if (pos == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).searchLocationFailed),
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
    final nearbyAsync = nearbyFilter != null
        ? ref.watch(nearbyListingsProvider(nearbyFilter))
        : null;
    final searchResultsAsync = _hasActiveSearch && nearbyFilter == null
        ? ref.watch(listingsProvider(_currentFilter))
        : null;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER (eyebrow + title + map toggle) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.searchHeroEyebrow,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.guestTextTertiary,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.searchHeroTitle,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -0.6,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasActiveSearch)
                    GestureDetector(
                      onTap: () => setState(() => _showMapView = !_showMapView),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _showMapView
                              ? AtrioColors.guestTextPrimary
                              : AtrioColors.warmGray,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _showMapView
                              ? Icons.list_rounded
                              : Icons.map_rounded,
                          size: 19,
                          color: _showMapView
                              ? Colors.white
                              : AtrioColors.guestTextPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ─── SEARCH BAR (home style) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AtrioColors.warmGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search_rounded,
                        size: 20, color: AtrioColors.guestTextSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: AtrioColors.guestTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: l.searchHint,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
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
                              size: 18,
                              color: AtrioColors.guestTextSecondary),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showFilters = !_showFilters),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _showFilters
                                  ? AtrioColors.neonLime
                                  : AtrioColors.guestTextPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: _showFilters
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ─── CATEGORY TABS (text + animated underline, like home) ───
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Near-me chip first (distinct rounded chip)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: _toggleNearby,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _nearbyMode
                              ? AtrioColors.guestTextPrimary
                              : AtrioColors.warmGray,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _nearbyMode
                                  ? Icons.my_location_rounded
                                  : Icons.location_on_outlined,
                              size: 14,
                              color: _nearbyMode
                                  ? AtrioColors.neonLime
                                  : AtrioColors.guestTextSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _nearbyMode
                                  ? l.searchNearbyOn(_radiusKm.round())
                                  : l.searchNearMe,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _nearbyMode
                                    ? Colors.white
                                    : AtrioColors.guestTextPrimary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (int index = 0;
                      index < AppConstants.categoryLabels.length;
                      index++)
                    _CategoryTab(
                      label: <String>[
                        l.bookingsAll,
                        l.searchCategorySpaces,
                        l.searchCategoryExperiences,
                        l.searchCategoryServices,
                      ][index],
                      selected: _selectedCategory == index,
                      onTap: () => setState(() => _selectedCategory = index),
                    ),
                ],
              ),
            ),

            // ─── RADIUS SLIDER (only when nearby mode) ───
            if (_nearbyMode) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.radar_rounded,
                        size: 16, color: AtrioColors.neonLimeDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AtrioColors.neonLimeDark,
                          inactiveTrackColor: AtrioColors.guestCardBorder,
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
                          fontWeight: FontWeight.w700,
                          color: AtrioColors.guestTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── FILTERS PANEL ───
            if (_showFilters) ...[
              const SizedBox(height: 12),
              _buildFiltersPanel(),
            ],

            const SizedBox(height: 14),

            // ─── CONTENT ───
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
                            if (listings.isEmpty) return _buildEmptyResults();
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
                          error: (_, __) => Center(
                            child: Text(
                              l.searchError,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AtrioColors.warmGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.searchPriceRange,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '${_priceRange.start.toCLP} - ${_priceRange.end.toCLP}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.neonLimeDark,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AtrioColors.neonLime,
                inactiveTrackColor: Colors.white,
                thumbColor: AtrioColors.guestTextPrimary,
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
            Text(
              l.searchQuickFilters,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickFilterChip(
                    label: l.searchFilterSuperhost,
                    icon: Icons.star_rounded),
                _QuickFilterChip(label: 'WiFi', icon: Icons.wifi_rounded),
                _QuickFilterChip(
                    label: 'Parking', icon: Icons.local_parking_rounded),
                _QuickFilterChip(
                    label: l.searchFilterPool, icon: Icons.pool_rounded),
                _QuickFilterChip(
                    label: l.searchFilterKitchen,
                    icon: Icons.kitchen_rounded),
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
    final allListingsAsync =
        ref.watch(listingsProvider(const ListingsFilter()));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // POPULAR SEARCHES
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SectionShell(
              title: l.searchPopular,
              subtitle: l.searchPopularSubtitle,
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
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
            ),
          ),
          const SizedBox(height: 30),

          // BROWSE BY CATEGORY (2x2 grid like home services)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SectionShell(
              title: l.searchBrowseByCategory,
              subtitle: l.searchBrowseSubtitle,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryTile(
                          icon: Icons.business_rounded,
                          label: l.searchCategorySpaces,
                          subtitle: l.searchCategorySpacesDesc,
                          accentBg: const Color(0xFFE9F7C6),
                          accentFg: const Color(0xFF65A30D),
                          onTap: () => setState(() => _selectedCategory = 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CategoryTile(
                          icon: Icons.auto_awesome_rounded,
                          label: l.searchCategoryExperiences,
                          subtitle: l.searchCategoryExperiencesDesc,
                          accentBg: const Color(0xFFFCE7F3),
                          accentFg: const Color(0xFFDB2777),
                          onTap: () => setState(() => _selectedCategory = 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryTile(
                          icon: Icons.handyman_rounded,
                          label: l.searchCategoryServices,
                          subtitle: l.searchCategoryServicesDesc,
                          accentBg: const Color(0xFFFFEDD5),
                          accentFg: const Color(0xFFEA580C),
                          onTap: () => setState(() => _selectedCategory = 3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CategoryTile(
                          icon: Icons.local_fire_department_rounded,
                          label: l.searchCategoryTrending,
                          subtitle: l.searchCategoryTrendingDesc,
                          accentBg: const Color(0xFFDBEAFE),
                          accentFg: const Color(0xFF2563EB),
                          onTap: () {
                            _searchController.text = 'premium';
                            setState(() => _searchQuery = 'premium');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // NEARBY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SectionShell(
              title: l.searchNearYou,
              subtitle: l.searchNearYouSubtitle,
              child: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 4),
          allListingsAsync.when(
            data: (data) {
              final listings = data
                  .map((json) => Listing.fromJson(json))
                  .take(6)
                  .toList();
              if (listings.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _NearbyCard(
                        listing: listing,
                        onTap: () => context.push('/listing/${listing.id}'),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(
                child: CircularProgressIndicator(
                  color: AtrioColors.neonLimeDark,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
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
    final withLocation =
        listings.where((l) => l.latitude != null && l.longitude != null).toList();

    if (withLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                size: 48, color: AtrioColors.guestTextTertiary),
            const SizedBox(height: 12),
            Text(
              l.searchNoLocations,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.searchNoCoords,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AtrioColors.guestTextTertiary),
            ),
          ],
        ),
      );
    }

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
          snippet: (l.basePrice ?? 0).toCLPWithFee,
          onTap: () => context.push('/listing/${l.id}'),
        ),
      );
    }).toSet();

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    final circles = <Circle>{};
    if (_nearbyMode && _nearbyCenter != null) {
      circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center:
              LatLng(_nearbyCenter!.latitude, _nearbyCenter!.longitude),
          radius: _radiusKmApplied * 1000,
          fillColor: AtrioColors.neonLime.withValues(alpha: 0.18),
          strokeColor: AtrioColors.neonLimeDark,
          strokeWidth: 2,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Text(
                l.searchInMap(withLocation.length),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: listings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              l.searchResults(listings.length),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AtrioColors.guestTextTertiary,
                letterSpacing: 0.2,
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
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AtrioColors.warmGray,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                size: 36, color: AtrioColors.guestTextTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            l.searchNoResults,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AtrioColors.guestTextPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.searchTryOther,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
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
  return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
}

// ══════════════════════════════════════════════════
// SECTION SHELL — lime vertical bar + title + subtitle
// ══════════════════════════════════════════════════
class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// CATEGORY TAB — text + animated underline
// ══════════════════════════════════════════════════
class _CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected
                    ? AtrioColors.guestTextPrimary
                    : AtrioColors.guestTextTertiary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 22 : 0,
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
  }
}

// ══════════════════════════════════════════════════
// POPULAR SEARCH CHIP
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
          color: AtrioColors.warmGray,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AtrioColors.neonLime,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 13, color: Colors.black),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// QUICK FILTER CHIP
// ══════════════════════════════════════════════════
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selected
              ? AtrioColors.guestTextPrimary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 15,
              color:
                  _selected ? AtrioColors.neonLime : AtrioColors.guestTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _selected ? Colors.white : AtrioColors.guestTextPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// CATEGORY TILE — 2x2 grid (home services style)
// ══════════════════════════════════════════════════
class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentBg;
  final Color accentFg;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentBg,
    required this.accentFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AtrioColors.warmGray,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: accentFg),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// NEARBY CARD — rounded image + info below (home style)
// ══════════════════════════════════════════════════
class _NearbyCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _NearbyCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.05,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    listing.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AtrioColors.warmGray),
                            errorWidget: (_, __, ___) => Container(
                                color: AtrioColors.warmGray),
                          )
                        : Container(color: AtrioColors.warmGray),
                    if (listing.rating > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 12, color: AtrioColors.ratingGold),
                              const SizedBox(width: 3),
                              Text(
                                listing.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AtrioColors.guestTextPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (listing.basePrice ?? 0).toCLPWithFee,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (listing.city != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      listing.city!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// SEARCH RESULT CARD — horizontal layout
// ══════════════════════════════════════════════════
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
          color: AtrioColors.warmGray,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 92,
                child: listing.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.white),
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.white),
                      )
                    : Container(color: Colors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (listing.city != null) ...[
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: AtrioColors.guestTextTertiary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              listing.city!,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AtrioColors.guestTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (listing.distanceM != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AtrioColors.neonLime.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatDistance(listing.distanceM!),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextPrimary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: (listing.basePrice ?? 0).toCLPWithFee,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' / ${listing.priceUnit == 'hour' ? 'hr' : listing.priceUnit}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AtrioColors.guestTextTertiary,
                              ),
                            ),
                          ]),
                        ),
                        if (listing.rating > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 13,
                                    color: AtrioColors.ratingGold),
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
