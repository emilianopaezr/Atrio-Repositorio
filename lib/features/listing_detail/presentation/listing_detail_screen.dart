import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';
import '../../../shared/widgets/location_map_widget.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/providers/availability_provider.dart';
import '../../../core/providers/host_detail_provider.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/models/enums.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/rules_catalog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/verified_badge.dart';
import 'widgets/reviews_section.dart';

const _bg = AtrioColors.guestSurfaceVariant;
const _white = AtrioColors.guestSurface;
const _border = AtrioColors.guestCardBorder;
const _text = AtrioColors.guestTextPrimary;
const _textSec = AtrioColors.guestTextSecondary;
const _textMuted = AtrioColors.guestTextTertiary;
const _lime = AtrioColors.neonLime;
const _limeDark = AtrioColors.neonLimeDark;
const _gold = AtrioColors.ratingGold;

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _imgIdx = 0;
  bool _descExpanded = false;
  bool _isFav = false;
  final _pageCtrl = PageController();
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _checkFav();
    _loadReviews();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkFav() async {
    final uid = SupabaseConfig.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final p = await SupabaseConfig.client
          .from('profiles').select('favorite_listing_ids').eq('id', uid).maybeSingle();
      if (p != null && mounted) {
        final favs = List<String>.from(p['favorite_listing_ids'] ?? []);
        setState(() => _isFav = favs.contains(widget.listingId));
      }
    } catch (e) {
      AppLogger.w('_checkFav: $e', tag: 'listing_detail');
    }
  }

  Future<void> _toggleFav() async {
    final uid = SupabaseConfig.auth.currentUser?.id;
    if (uid == null) return;
    final newState = !_isFav;
    setState(() => _isFav = newState);
    try {
      final p = await SupabaseConfig.client
          .from('profiles').select('favorite_listing_ids').eq('id', uid).single();
      final favs = List<String>.from(p['favorite_listing_ids'] ?? []);
      if (newState) {
        if (!favs.contains(widget.listingId)) favs.add(widget.listingId);
      } else {
        favs.remove(widget.listingId);
      }
      await SupabaseConfig.client.from('profiles').update({'favorite_listing_ids': favs}).eq('id', uid);
    } catch (e) {
      AppLogger.w('_toggleFav: $e', tag: 'listing_detail');
      if (mounted) setState(() => _isFav = !newState);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final data = await DatabaseService.getListingReviews(widget.listingId);
      if (mounted) setState(() { _reviews = data; _loadingReviews = false; });
    } catch (e) {
      AppLogger.w('_loadReviews: $e', tag: 'listing_detail');
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  void _shareListing() {
    final l = AppLocalizations.of(context);
    final listingsAsync = ref.read(listingsProvider(const ListingsFilter()));
    final all = listingsAsync.value ?? [];
    final listing = all.cast<Map<String, dynamic>>().where((l) => l['id'] == widget.listingId).firstOrNull;
    if (listing == null) return;
    final type = listing['type'] as String? ?? 'space';
    final typeLabel = type == 'space'
        ? l.listingTypeSpaceLower
        : type == 'experience'
            ? l.listingTypeExperienceLower
            : l.listingTypeServiceLower;
    // Share with all-in price (base + 7% fee).
    final price = (listing['base_price'] as num?)?.toCLPWithFee ?? '\$0';
    final title = listing['title'] as String? ?? '';
    final unit = listing['price_unit'] as String? ?? 'session';
    SharePlus.instance.share(
      ShareParams(text: l.listingShareText(typeLabel, title, price, _priceUnit(context, unit))),
    );
  }

  void _showReportSheet() {
    final l = AppLocalizations.of(context);
    String? selectedReason;
    final reasons = [
      l.listingReportInappropriate,
      l.listingReportFalseInfo,
      l.listingReportPhotosMismatch,
      l.listingReportWrongPrice,
      l.listingReportSpam,
      l.listingReportOther,
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(l.listingReportTitle, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (v) => setSheetState(() => selectedReason = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons.map((r) => RadioListTile<String>(
                    title: Text(r, style: GoogleFonts.inter(fontSize: 14, color: _text)),
                    value: r,
                    activeColor: _limeDark,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.listingReportSent)),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lime,
                    disabledBackgroundColor: _border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(l.listingReportSubmit, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _text)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priceUnit(BuildContext context, String u) {
    final l = AppLocalizations.of(context);
    switch (u) {
      case 'night': return l.listingUnitNight;
      case 'hour': return l.listingUnitHour;
      case 'session': return l.listingUnitSession;
      case 'person': return l.listingUnitPerson;
      default: return u;
    }
  }

  IconData _amenityIcon(String a) {
    final l = a.toLowerCase();
    if (l.contains('wifi')) return Icons.wifi_rounded;
    if (l.contains('parking') || l.contains('estacionamiento')) return Icons.local_parking_rounded;
    if (l.contains('piscina') || l.contains('pool')) return Icons.pool_rounded;
    if (l.contains('aire') || l.contains('a/c')) return Icons.ac_unit_rounded;
    if (l.contains('cocina') || l.contains('kitchen')) return Icons.kitchen_rounded;
    if (l.contains('jacuzzi')) return Icons.hot_tub_rounded;
    if (l.contains('vista') || l.contains('view')) return Icons.landscape_rounded;
    if (l.contains('quincho') || l.contains('bbq')) return Icons.outdoor_grill_rounded;
    if (l.contains('sonido') || l.contains('sound')) return Icons.speaker_rounded;
    if (l.contains('bar')) return Icons.local_bar_rounded;
    if (l.contains('gym') || l.contains('gimnasio')) return Icons.fitness_center_rounded;
    if (l.contains('tv')) return Icons.tv_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingDetailProvider(widget.listingId));

    return async.when(
      data: (data) {
        if (data == null) return _empty();
        return _page(Listing.fromJson(data));
      },
      loading: () => const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _limeDark, strokeWidth: 2.5)),
      ),
      error: (_, _) => _empty(error: true),
    );
  }

  Widget _empty({bool error = false}) {
    final l = AppLocalizations.of(context);
    return Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _bg, elevation: 0, surfaceTintColor: Colors.transparent,
      leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: _text))),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(error ? Icons.error_outline : Icons.search_off, size: 48, color: _textMuted),
          const SizedBox(height: 12),
          Text(error ? l.listingLoadError : l.listingNotFound, style: GoogleFonts.inter(fontSize: 16, color: _textSec)),
          if (error) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ref.invalidate(listingDetailProvider(widget.listingId)),
              child: Text(l.btnRetry, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _limeDark)),
            ),
          ],
        ],
      ),
    ),
  );
  }

  Widget _page(Listing listing) {
    final l = AppLocalizations.of(context);
    // Host vars are deliberately not destructured here — the new
    // `_knowTheHostSection` fetches the host via `hostDetailProvider`
    // (which has both profile + stats). The fallback `_hostCard` reads
    // `listing.hostData` directly when the provider can't resolve.
    final _ = l; // keep AppLocalizations bound for future strings
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Image gallery ───
              SliverToBoxAdapter(child: _gallery(listing)),

              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 38, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Title (no eyebrow) ───
                          Text(
                            listing.title,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _text,
                              height: 1.15,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ─── Location + rating in one quiet row ───
                          Row(
                            children: [
                              if (listing.city != null) ...[
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: _textMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${listing.city}${listing.country != null ? ', ${listing.country}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _textSec,
                                    ),
                                  ),
                                ),
                              ],
                              if (listing.rating > 0) ...[
                                if (listing.city != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: _textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                const Icon(Icons.star_rounded,
                                    size: 14, color: _gold),
                                const SizedBox(width: 3),
                                Text(
                                  '${listing.rating.toStringAsFixed(1)}${listing.reviewCount > 0 ? ' · ${listing.reviewCount}' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _text,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // ─── Quick facts (plain icon+text list, 2x2 grid) ───
                          const SizedBox(height: 22),
                          _quickFactsList(listing),

                          // ─── Lo que destaca (highlights) ───
                          const SizedBox(height: 22),
                          _hairline(),
                          const SizedBox(height: 22),
                          _highlightsSection(listing),

                          // ─── Conoce al anfitrión ───
                          const SizedBox(height: 22),
                          _hairline(),
                          const SizedBox(height: 22),
                          _knowTheHostSection(listing),

                          // ─── Description ───
                          const SizedBox(height: 22),
                          _hairline(),
                          const SizedBox(height: 22),
                          _descSection(listing),

                          // ─── Amenities (only if any) ───
                          if (listing.amenities.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            _hairline(),
                            const SizedBox(height: 22),
                            _amenitiesSection(listing),
                          ],

                          // ─── Availability ───
                          const SizedBox(height: 22),
                          _hairline(),
                          const SizedBox(height: 22),
                          _availabilitySection(listing),

                          // ─── House rules ───
                          const SizedBox(height: 22),
                          _hairline(),
                          const SizedBox(height: 22),
                          _rulesSection(listing),

                          // ─── Cancellation ───
                          const SizedBox(height: 22),
                          _hairline(),
                          const SizedBox(height: 22),
                          _cancellationSection(listing),

                          // ─── Map ───
                          if (listing.latitude != null && listing.longitude != null) ...[
                            const SizedBox(height: 22),
                            _hairline(),
                            const SizedBox(height: 22),
                            _locationSection(listing),
                          ],

                          // ─── Reviews ───
                          const SizedBox(height: 22),
                          _hairline(),
                          const SizedBox(height: 22),
                          ListingReviewsSection(
                            listingId: widget.listingId,
                            rating: listing.rating,
                            reviewCount: listing.reviewCount,
                            loadingReviews: _loadingReviews,
                            reviews: _reviews,
                          ),

                          SizedBox(height: 100 + bottom),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ─── Bottom bar ───
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _bottomBar(listing, bottom),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // IMAGE GALLERY
  // ══════════════════════════════════════════
  Widget _gallery(Listing listing) {
    final top = MediaQuery.of(context).padding.top;
    final h = MediaQuery.of(context).size.height * 0.40;

    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Images
          if (listing.images.isNotEmpty)
            PageView.builder(
              controller: _pageCtrl,
              itemCount: listing.images.length,
              onPageChanged: (i) => setState(() => _imgIdx = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: listing.images[i],
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AtrioColors.guestSurfaceVariant),
                errorWidget: (_, _, _) => Container(
                  color: AtrioColors.guestSurfaceVariant,
                  child: const Icon(Icons.image, size: 48, color: _textMuted),
                ),
              ),
            )
          else
            Container(color: AtrioColors.guestSurfaceVariant, child: const Icon(Icons.image, size: 56, color: _textMuted)),

          // Top gradient
          Positioned(
            top: 0, left: 0, right: 0, height: top + 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                ),
              ),
            ),
          ),

          // Top buttons
          Positioned(
            top: top + 8, left: 14, right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleBtn(Icons.arrow_back_ios_new, () => Navigator.of(context).pop()),
                Row(
                  children: [
                    _circleBtn(
                      _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      _toggleFav,
                      color: _isFav ? Colors.red : null,
                    ),
                    const SizedBox(width: 10),
                    _circleBtn(Icons.ios_share_rounded, () => _shareListing()),
                    const SizedBox(width: 10),
                    _circleBtn(Icons.flag_outlined, () => _showReportSheet()),
                  ],
                ),
              ],
            ),
          ),

          // Price badge — bigger glass pill over image.
          Positioned(
            bottom: 18, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    (listing.basePrice ?? 0).toCLPWithFee,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${_priceUnit(context, listing.priceUnit)}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image counter
          if (listing.images.length > 1)
            Positioned(
              bottom: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_imgIdx + 1} / ${listing.images.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // "LO QUE DESTACA" — derived from listing + rating
  // ══════════════════════════════════════════
  Widget _highlightsSection(Listing listing) {
    final l = AppLocalizations.of(context);
    final highlights = <(IconData, String, String)>[];

    // Top performer (review-based)
    if (listing.rating >= 4.9 && listing.reviewCount >= 30) {
      highlights.add((
        Icons.emoji_events_rounded,
        l.listingHighlightTopRated,
        l.listingHighlightTopRatedDesc,
      ));
    } else if (listing.rating >= 4.8 && listing.reviewCount >= 20) {
      highlights.add((
        Icons.workspace_premium_rounded,
        l.listingHighlightFavorite,
        l.listingHighlightFavoriteDesc,
      ));
    }

    // Booking style
    if (listing.instantBooking == true) {
      highlights.add((
        Icons.flash_on_rounded,
        l.listingHighlightInstant,
        l.listingHighlightInstantDesc,
      ));
    }

    // Amenity-based highlights (only show the most distinctive)
    final amenities = listing.amenities
        .map((a) => a.toLowerCase())
        .toList();
    if (amenities.any((a) => a.contains('piscina') || a.contains('pool'))) {
      highlights.add((
        Icons.pool_rounded,
        l.listingHighlightPool,
        l.listingHighlightPoolDesc,
      ));
    }
    if (amenities.any((a) => a.contains('gimnasio') || a.contains('gym'))) {
      highlights.add((
        Icons.fitness_center_rounded,
        l.listingHighlightGym,
        l.listingHighlightGymDesc,
      ));
    }
    if (amenities.any((a) => a.contains('vista') || a.contains('view'))) {
      highlights.add((
        Icons.landscape_rounded,
        l.listingHighlightView,
        l.listingHighlightViewDesc,
      ));
    }
    if (amenities.any((a) => a.contains('jacuzzi'))) {
      highlights.add((
        Icons.hot_tub_rounded,
        l.listingHighlightJacuzzi,
        l.listingHighlightJacuzziDesc,
      ));
    }

    // Anti-noise: if there are no relevant highlights, skip the section.
    if (highlights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.listingHighlightsTitle),
        const SizedBox(height: 14),
        ...highlights.take(4).map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _lime.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(h.$1, size: 18, color: _limeDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.$2,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _text,
                            letterSpacing: -0.2,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h.$3,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _textSec,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ══════════════════════════════════════════
  // "CONOCE AL ANFITRIÓN" — full host card (Airbnb-style)
  // ══════════════════════════════════════════
  Widget _knowTheHostSection(Listing listing) {
    final l = AppLocalizations.of(context);
    final hostAsync = ref.watch(hostDetailProvider(listing.hostId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.listingMeetHostTitle),
        const SizedBox(height: 14),
        hostAsync.when(
          data: (data) {
            if (data == null) {
              return _hostCard(
                listing.hostData?['display_name'] as String? ?? l.listingHostFallback,
                listing.hostData?['photo_url'] as String?,
                false,
                listing.hostData?['is_verified'] == true,
                listing,
              );
            }
            return _HostDetailCard(
              data: data,
              listing: listing,
              onChat: () async {
                final currentUserId =
                    SupabaseConfig.auth.currentUser?.id;
                if (currentUserId == null) return;
                if (currentUserId == listing.hostId) return;
                final convo = await DatabaseService.getOrCreateConversation(
                  userId1: currentUserId,
                  userId2: listing.hostId,
                  listingId: listing.id,
                );
                if (mounted) context.push('/chat/${convo['id']}');
              },
            );
          },
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
                color: _limeDark, strokeWidth: 2.4),
          ),
          error: (_, _) => _hostCard(
            listing.hostData?['display_name'] as String? ?? l.listingHostFallback,
            listing.hostData?['photo_url'] as String?,
            false,
            listing.hostData?['is_verified'] == true,
            listing,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // HOST CARD
  // ══════════════════════════════════════════
  Widget _hostCard(String name, String? photo, bool superhost, bool verified, Listing listing) {
    final l = AppLocalizations.of(context);
    final showPhone = listing.showHostPhone &&
        listing.hostPhone != null &&
        listing.hostPhone!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _lime.withValues(alpha: 0.2),
                backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
                child: photo == null ? const Icon(Icons.person, size: 24, color: _limeDark) : null,
              ),
              if (superhost)
                Positioned(
                  bottom: -2, right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: _white, shape: BoxShape.circle),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AtrioColors.vibrantOrange, shape: BoxShape.circle),
                      child: const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 4),
                      const VerifiedCheck(size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${superhost ? l.listingSuperhostLabel : ''}${l.listingHostResponseTime}',
                  style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
                ),
                if (verified) ...[
                  const SizedBox(height: 6),
                  const VerifiedProfilePill(compact: true),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final currentUserId = SupabaseConfig.auth.currentUser?.id;
              if (currentUserId == null) return;
              final hostId = listing.hostId;
              if (currentUserId == hostId) return; // Can't chat with yourself
              final convo = await DatabaseService.getOrCreateConversation(
                userId1: currentUserId,
                userId2: hostId,
                listingId: listing.id,
              );
              if (mounted) {
                context.push('/chat/${convo['id']}');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 14, color: _limeDark),
                  const SizedBox(width: 5),
                  Text(l.listingChatButton, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _limeDark)),
                ],
              ),
            ),
          ),
        ],
      ),
          if (showPhone) ...[
            const SizedBox(height: 12),
            _hostPhoneRow(listing.hostPhone!.trim()),
          ],
        ],
      ),
    );
  }

  Widget _hostPhoneRow(String rawPhone) {
    final l = AppLocalizations.of(context);
    final cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final waNumber = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;

    Future<void> launch(Uri uri) async {
      HapticFeedback.selectionClick();
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _lime.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone_iphone_rounded,
                size: 17, color: _limeDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.listingDirectContactLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rawPhone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PhoneActionButton(
            icon: Icons.phone_rounded,
            onTap: () => launch(Uri(scheme: 'tel', path: rawPhone)),
          ),
          const SizedBox(width: 6),
          _PhoneActionButton(
            icon: Icons.chat_rounded,
            onTap: () =>
                launch(Uri.parse('https://wa.me/$waNumber')),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // DESCRIPTION
  // ══════════════════════════════════════════
  Widget _descSection(Listing listing) {
    final l = AppLocalizations.of(context);
    final desc = listing.description ?? l.listingDescEmpty;
    final words = desc.split(RegExp(r'\s+'));
    final isLong = words.length > 60;
    final display = (!_descExpanded && isLong) ? '${words.take(60).join(' ')}...' : desc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          listing.type == 'space'
              ? l.listingAboutSpace
              : listing.type == 'experience'
                  ? l.listingAboutExperience
                  : l.listingAboutService,
        ),
        const SizedBox(height: 12),
        Text(
          display,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textSec,
            height: 1.6,
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _descExpanded ? l.listingShowLess : l.listingShowMore,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.4,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _descExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _text,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════
  // AMENITIES
  // ══════════════════════════════════════════
  Widget _amenitiesSection(Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppLocalizations.of(context).listingAmenities),
        const SizedBox(height: 14),
        // Two-column grid of plain icon + text rows.
        LayoutBuilder(
          builder: (ctx, c) {
            final colW = (c.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: listing.amenities.map((a) {
                return SizedBox(
                  width: colW,
                  child: Row(
                    children: [
                      Icon(_amenityIcon(a), size: 18, color: _text),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          a,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _text,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // AVAILABILITY SECTION
  // ══════════════════════════════════════════
  Widget _availabilitySection(Listing listing) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 3, 0);

    final bookedAsync = ref.watch(bookedDatesProvider(BookedDatesParams(
      listingId: listing.id,
      startDate: startDate,
      endDate: endDate,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.listingAvailability),
        const SizedBox(height: 14),
        bookedAsync.when(
          data: (data) {
            final bookedDates = <String>{};
            final blockedDates = <String>{};
            for (final d in data) {
              final dateStr = d['booked_date']?.toString() ?? '';
              if (d['is_blocked'] == true) {
                blockedDates.add(dateStr);
              } else {
                bookedDates.add(dateStr);
              }
            }
            return _buildMiniCalendar(now, bookedDates, blockedDates);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _limeDark, strokeWidth: 2),
            ),
          ),
          error: (_, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Text(l.listingAvailabilityLoadError, style: GoogleFonts.inter(fontSize: 13, color: _textMuted)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Row(
          children: [
            _availLegend(AtrioColors.success, l.listingAvailabilityAvailable),
            const SizedBox(width: 14),
            _availLegend(Colors.red[400]!, l.listingAvailabilityBooked),
            const SizedBox(width: 14),
            _availLegend(Colors.grey[400]!, l.listingAvailabilityBlocked),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCalendar(DateTime now, Set<String> bookedDates, Set<String> blockedDates) {
    final l = AppLocalizations.of(context);
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;
    final totalDays = lastDay.day;
    final dayHeaders = [l.listingDayMon, l.listingDayTue, l.listingDayWed, l.listingDayThu, l.listingDayFri, l.listingDaySat, l.listingDaySun];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Month header
          Text(
            '${_monthName(context, now.month)} ${now.year}',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _text),
          ),
          const SizedBox(height: 10),
          // Day headers
          Row(
            children: dayHeaders.map((d) => Expanded(
              child: Center(child: Text(d, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted))),
            )).toList(),
          ),
          const SizedBox(height: 6),
          // Grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.2),
            itemCount: 42,
            itemBuilder: (_, index) {
              final dayNum = index - startWeekday + 1;
              if (dayNum < 1 || dayNum > totalDays) return const SizedBox();

              final date = DateTime(now.year, now.month, dayNum);
              final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              final booked = bookedDates.contains(key);
              final blocked = blockedDates.contains(key);
              final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;

              Color dotColor = AtrioColors.success; // available green
              if (booked) dotColor = Colors.red[400]!;
              if (blocked) dotColor = Colors.grey[400]!;
              if (isPast) dotColor = Colors.grey[300]!;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNum',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isPast ? _textMuted : _text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(BuildContext context, int m) {
    final l = AppLocalizations.of(context);
    final months = [l.listingMonthJan, l.listingMonthFeb, l.listingMonthMar, l.listingMonthApr, l.listingMonthMay, l.listingMonthJun,
      l.listingMonthJul, l.listingMonthAug, l.listingMonthSep, l.listingMonthOct, l.listingMonthNov, l.listingMonthDec];
    return months[m - 1];
  }

  Widget _availLegend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: _textSec)),
    ],
  );

  // ══════════════════════════════════════════
  // HOUSE RULES
  // ══════════════════════════════════════════
  Widget _rulesSection(Listing listing) {
    final l = AppLocalizations.of(context);
    final mode = RentalMode.fromDb(listing.rentalMode);
    final checkIn = listing.checkInTime ?? '15:00';
    final checkOut = listing.checkOutTime ?? '11:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.listingRules),
        const SizedBox(height: 12),
        if (mode == RentalMode.nights)
          _ruleRow(Icons.schedule_rounded, l.listingRuleCheckInOut(checkIn, checkOut))
        else if (mode == RentalMode.hours)
          _ruleRow(Icons.schedule_rounded, l.listingRuleHours(listing.availableFrom ?? '09:00', listing.availableUntil ?? '22:00'))
        else
          _ruleRow(Icons.schedule_rounded, l.listingRuleFullDay),
        if (listing.rules.isEmpty) ...[
          _ruleRow(Icons.smoke_free_rounded, l.listingRuleNoSmoke),
          _ruleRow(Icons.pets_rounded, l.listingRulePets),
          _ruleRow(Icons.volume_down_rounded, l.listingRuleQuiet),
        ] else
          ...listing.rules.map(
            (key) => _ruleRow(
              RulesCatalog.icon(key),
              RulesCatalog.label(context, key),
            ),
          ),
      ],
    );
  }

  Widget _ruleRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 18, color: _textMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: _textSec))),
      ],
    ),
  );

  // ══════════════════════════════════════════
  // CANCELLATION
  // ══════════════════════════════════════════
  Widget _cancellationSection(Listing listing) {
    final l = AppLocalizations.of(context);
    final policy = CancellationPolicy.fromDb(listing.cancellationPolicy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _sectionTitle(l.listingCancellation),
            const SizedBox(width: 10),
            Text(
              '· ${policy.label}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textSec,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          policy.description,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textSec,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 14),
        if (policy == CancellationPolicy.flexible) ...[
          _cancelRow(Icons.check_circle_outline, _limeDark, l.listingCancelFlexFree, l.listingCancelFlexFreeDesc),
          const SizedBox(height: 12),
          _cancelRow(Icons.warning_amber_rounded, _gold, l.listingCancelFlexPartial, l.listingCancelFlexPartialDesc),
          const SizedBox(height: 12),
          _cancelRow(Icons.cancel_outlined, AtrioColors.error, l.listingCancelFlexNone, l.listingCancelFlexNoneDesc),
        ] else if (policy == CancellationPolicy.moderate) ...[
          _cancelRow(Icons.check_circle_outline, _limeDark, l.listingCancelModFree, l.listingCancelModFreeDesc),
          const SizedBox(height: 12),
          _cancelRow(Icons.warning_amber_rounded, _gold, l.listingCancelModPartial, l.listingCancelModPartialDesc),
          const SizedBox(height: 12),
          _cancelRow(Icons.cancel_outlined, AtrioColors.error, l.listingCancelModNone, l.listingCancelModNoneDesc),
        ] else ...[
          _cancelRow(Icons.check_circle_outline, _limeDark, l.listingCancelStrictFree, l.listingCancelStrictFreeDesc),
          const SizedBox(height: 12),
          _cancelRow(Icons.warning_amber_rounded, _gold, l.listingCancelStrictPartial, l.listingCancelStrictPartialDesc),
          const SizedBox(height: 12),
          _cancelRow(Icons.cancel_outlined, AtrioColors.error, l.listingCancelStrictNone, l.listingCancelStrictNoneDesc),
        ],
      ],
    );
  }

  Widget _cancelRow(IconData icon, Color c, String title, String sub) => Row(
    children: [
      Icon(icon, size: 18, color: c),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
            Text(sub, style: GoogleFonts.inter(fontSize: 12, color: _textMuted)),
          ],
        ),
      ),
    ],
  );

  // ══════════════════════════════════════════
  // LOCATION MAP
  // ══════════════════════════════════════════
  Widget _locationSection(Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppLocalizations.of(context).listingLocation),
        const SizedBox(height: 8),
        if (listing.city != null)
          Text(
            '${listing.address != null ? '${listing.address}, ' : ''}${listing.city}${listing.country != null ? ', ${listing.country}' : ''}',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: _textSec,
              height: 1.4,
            ),
          ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LocationMapWidget(
            latitude: listing.latitude!,
            longitude: listing.longitude!,
            title: listing.title,
            height: 200,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // BOTTOM BAR
  // ══════════════════════════════════════════
  Widget _bottomBar(Listing listing, double bottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      decoration: const BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  (listing.basePrice ?? 0).toCLPWithFee,
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '/ ${_priceUnit(context, listing.priceUnit)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _textSec,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/checkout/${listing.id}');
              },
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: _text,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).listingBookNow,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════
  Widget _hairline() => Container(height: 1, color: _border);

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _text,
          letterSpacing: -0.4,
        ),
      );

  Widget _quickFactsList(Listing listing) {
    final l = AppLocalizations.of(context);
    final mode = RentalMode.fromDb(listing.rentalMode);
    final items = <(IconData, String)>[
      (
        Icons.people_outline_rounded,
        l.listingHighlightPersons(listing.capacity ?? 4),
      ),
      (_rentalModeIcon(listing.rentalMode), mode.label),
      (
        listing.instantBooking == true
            ? Icons.flash_on_rounded
            : Icons.schedule_rounded,
        listing.instantBooking == true
            ? l.listingHighlightInstant
            : l.listingHighlightConfirm,
      ),
      (Icons.verified_user_outlined, l.listingHighlightInsured),
    ];

    // 2-column grid: better use of horizontal space.
    return LayoutBuilder(
      builder: (ctx, c) {
        final colW = (c.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items.map((it) {
            return SizedBox(
              width: colW,
              child: Row(
                children: [
                  Icon(it.$1, size: 18, color: _text),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _text,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color? color}) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color ?? _text),
      ),
    ),
  );

  IconData _rentalModeIcon(String mode) {
    switch (mode) {
      case 'hours': return Icons.schedule_rounded;
      case 'full_day': return Icons.calendar_today_rounded;
      case 'nights': return Icons.nights_stay_rounded;
      default: return Icons.nights_stay_rounded;
    }
  }

}

// Compact action button used in the host phone row (call / WhatsApp).
class _PhoneActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PhoneActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AtrioColors.guestTextPrimary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: AtrioColors.neonLime),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// HOST DETAIL CARD — "Conoce al anfitrión" (Airbnb-style)
// ───────────────────────────────────────────────────────────────
class _HostDetailCard extends StatelessWidget {
  final HostDetail data;
  final Listing listing;
  final VoidCallback onChat;

  const _HostDetailCard({
    required this.data,
    required this.listing,
    required this.onChat,
  });

  static const _white = AtrioColors.guestSurface;
  static const _border = AtrioColors.guestCardBorder;
  static const _text = AtrioColors.guestTextPrimary;
  static const _textSec = AtrioColors.guestTextSecondary;
  static const _textT = AtrioColors.guestTextTertiary;
  static const _lime = AtrioColors.neonLime;
  static const _limeDark = AtrioColors.neonLimeDark;

  bool get _isSuperhost {
    final lvl = data.stats.currentLevel;
    return lvl == 'ELITE' || lvl == 'SUPERHOST' || data.stats.eliteEligible;
  }

  int get _yearsHosting {
    final since = data.profile.createdAt;
    if (since == null) return 0;
    final diff = DateTime.now().difference(since);
    return (diff.inDays / 365).floor();
  }

  String _yearsHostingLabel(AppLocalizations l) {
    final y = _yearsHosting;
    if (y < 1) return l.listingHostYearsNew;
    if (y == 1) return '1';
    return '$y';
  }

  String _yearsHostingUnit(AppLocalizations l) {
    final y = _yearsHosting;
    if (y < 1) return l.listingHostYearsUnitNew;
    if (y == 1) return l.listingHostYearsUnitOne;
    return l.listingHostYearsUnitMany;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = data.profile;
    final s = data.stats;
    final name = p.displayName ?? l.listingHostFallback;
    final photo = p.photoUrl;
    final reviewCount = listing.reviewCount;
    final rating = s.averageRating > 0 ? s.averageRating : listing.rating;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top: Avatar + Name + Superhost badge ───
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: _lime.withValues(alpha: 0.2),
                      backgroundImage: photo != null
                          ? CachedNetworkImageProvider(photo)
                          : null,
                      child: photo == null
                          ? const Icon(Icons.person_rounded,
                              size: 32, color: _limeDark)
                          : null,
                    ),
                    if (_isSuperhost)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: _white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AtrioColors.vibrantOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (_isSuperhost) ...[
                            const Icon(Icons.workspace_premium_rounded,
                                size: 13, color: AtrioColors.vibrantOrange),
                            const SizedBox(width: 4),
                            Text(
                              l.listingHostBadgeSuperhost,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.vibrantOrange,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ] else if (p.isVerified) ...[
                            const Icon(Icons.verified_rounded,
                                size: 13, color: _limeDark),
                            const SizedBox(width: 4),
                            Text(
                              l.listingHostBadgeVerified,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _limeDark,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ] else
                            Text(
                              l.listingHostBadgeHost,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _textSec,
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

          // ─── Stats row ───
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            decoration: BoxDecoration(
              color: AtrioColors.guestSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _stat(
                  icon: Icons.rate_review_rounded,
                  iconColor: _limeDark,
                  value: '$reviewCount',
                  label: l.listingHostStatReviewLabel(reviewCount),
                ),
                _divider(),
                _stat(
                  icon: Icons.star_rounded,
                  iconColor: AtrioColors.ratingGold,
                  value: rating > 0 ? rating.toStringAsFixed(2) : '—',
                  label: l.listingHostStatRating,
                ),
                _divider(),
                _stat(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AtrioColors.vibrantOrange,
                  value: _yearsHostingLabel(l),
                  label: _yearsHostingUnit(l),
                ),
              ],
            ),
          ),

          // ─── About fields ───
          if (p.decadeBorn != null ||
              (p.profession != null && p.profession!.isNotEmpty) ||
              (p.languages.isNotEmpty)) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.decadeBorn != null && p.decadeBorn!.isNotEmpty)
                    _aboutRow(Icons.cake_outlined,
                        l.listingHostAboutDecade(p.decadeBorn!)),
                  if (p.profession != null && p.profession!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _aboutRow(
                          Icons.work_outline_rounded,
                          l.listingHostAboutProfession(p.profession!)),
                    ),
                  if (p.languages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _aboutRow(Icons.language_rounded,
                          l.listingHostAboutLanguages(_languagesLabel(l, p.languages))),
                    ),
                ],
              ),
            ),
          ],

          // ─── Interests / Hobbies ───
          if (p.interests.isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.listingHostInterests,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _textSec,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.interests
                        .map((i) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: AtrioColors.guestSurfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _border),
                              ),
                              child: Text(
                                i,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _text,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],

          // ─── Bio ───
          if (p.bio != null && p.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSuperhost
                        ? l.listingHostIsSuperhost(name)
                        : l.listingHostAboutTitle(name),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.bio!,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _textSec,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isSuperhost) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.listingHostIsSuperhost(name),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.listingSuperhostDescription,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _textSec,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── Response info ───
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.listingHostInfoTitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.responseRate > 0
                      ? l.listingHostResponseRate(s.responseRate.round())
                      : l.listingHostResponseRateEmpty,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textSec,
                  ),
                ),
                if (p.responseTimeHours != null && p.responseTimeHours! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _responseTimeLabel(l, p.responseTimeHours!),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textSec,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ─── Chat CTA ───
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onChat,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _border, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  foregroundColor: _text,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16, color: _text),
                    const SizedBox(width: 8),
                    Text(
                      l.listingChatWithHost,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textT,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: _border);

  Widget _aboutRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _textSec),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
        ),
      ],
    );
  }

  String _languagesLabel(AppLocalizations l, List<String> codes) {
    final map = {
      'es': l.langSpanish,
      'en': l.langEnglish,
      'pt': l.langPortuguese,
      'fr': l.langFrench,
      'it': l.langItalian,
      'de': l.langGerman,
    };
    return codes.map((c) => map[c.toLowerCase()] ?? c).join(', ');
  }

  String _responseTimeLabel(AppLocalizations l, int hours) {
    if (hours <= 1) return l.listingHostResponseTime1h;
    if (hours <= 6) return l.listingHostResponseTimeFew;
    if (hours <= 24) return l.listingHostResponseTimeDay;
    return l.listingHostResponseTimeDays;
  }
}
