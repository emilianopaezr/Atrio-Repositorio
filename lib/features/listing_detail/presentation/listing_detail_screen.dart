import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme/app_colors.dart';
import '../../../shared/widgets/location_map_widget.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/providers/availability_provider.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/models/enums.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
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
      debugPrint('_checkFav error: $e');
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
      debugPrint('_toggleFav error: $e');
      if (mounted) setState(() => _isFav = !newState);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final data = await DatabaseService.getListingReviews(widget.listingId);
      if (mounted) setState(() { _reviews = data; _loadingReviews = false; });
    } catch (e) {
      debugPrint('_loadReviews error: $e');
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
    final price = (listing['base_price'] as num?)?.toCLP ?? '\$0';
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
    final host = listing.hostData;
    final hostName = host?['display_name'] as String? ?? l.listingDefaultHost;
    final hostPhoto = host?['photo_url'] as String?;
    final isSuperhost = host?['is_superhost'] == true;
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),

                          // ─── Category + Rating ───
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _lime.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    listing.type == 'space' ? l.listingTypeSpace : listing.type == 'experience' ? l.listingTypeExperience : l.listingTypeService,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _limeDark, letterSpacing: 0.3),
                                  ),
                                ),
                                const Spacer(),
                                if (listing.rating > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _gold.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, size: 16, color: _gold),
                                        const SizedBox(width: 4),
                                        Text(
                                          listing.rating.toStringAsFixed(1),
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _text),
                                        ),
                                        if (listing.reviewCount > 0) ...[
                                          const SizedBox(width: 3),
                                          Text(
                                            '(${listing.reviewCount})',
                                            style: GoogleFonts.inter(fontSize: 12, color: _textSec),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ─── Title ───
                          Text(
                            listing.title,
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: _text, height: 1.15),
                          ),

                          const SizedBox(height: 6),

                          // ─── Location ───
                          if (listing.city != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: _textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  '${listing.city}${listing.country != null ? ', ${listing.country}' : ''}',
                                  style: GoogleFonts.inter(fontSize: 13, color: _textSec),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Rental mode badge ───
                          _rentalModeBadge(listing),
                          const SizedBox(height: 14),

                          // ─── Quick highlights ───
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _highlight(Icons.people_outline_rounded, l.listingHighlightPersons(listing.capacity ?? 4)),
                              _highlight(
                                _rentalModeIcon(listing.rentalMode),
                                RentalMode.fromDb(listing.rentalMode).label,
                              ),
                              _highlight(Icons.verified_user_outlined, l.listingHighlightInsured),
                              if (listing.instantBooking == true)
                                _highlight(Icons.flash_on_rounded, l.listingHighlightInstant)
                              else
                                _highlight(Icons.schedule_rounded, l.listingHighlightConfirm),
                            ],
                          ),

                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Host card ───
                          _hostCard(hostName, hostPhoto, isSuperhost, listing),

                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Description ───
                          _descSection(listing),

                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Amenities ───
                          if (listing.amenities.isNotEmpty) ...[
                            _amenitiesSection(listing),
                            const SizedBox(height: 18),
                            _divider(),
                            const SizedBox(height: 18),
                          ],

                          // ─── Availability preview ───
                          _availabilitySection(listing),
                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── House rules ───
                          _rulesSection(listing),

                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Cancellation ───
                          _cancellationSection(listing),

                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Map / Location ───
                          if (listing.latitude != null && listing.longitude != null) ...[
                            _locationSection(listing),
                            const SizedBox(height: 18),
                            _divider(),
                            const SizedBox(height: 18),
                          ],

                          // ─── Reviews ───
                          ListingReviewsSection(
                            listingId: widget.listingId,
                            rating: listing.rating,
                            reviewCount: listing.reviewCount,
                            loadingReviews: _loadingReviews,
                            reviews: _reviews,
                          ),

                          const SizedBox(height: 24),
                          SizedBox(height: 90 + bottom),
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

          // Price badge
          Positioned(
            bottom: 32, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _lime, borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.basePrice?.toCLP ?? '\$0',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  Text(
                    '/${_priceUnit(context, listing.priceUnit)}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),

          // Image dots
          if (listing.images.length > 1)
            Positioned(
              bottom: 36, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_imgIdx + 1} / ${listing.images.length}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // HOST CARD
  // ══════════════════════════════════════════
  Widget _hostCard(String name, String? photo, bool superhost, Listing listing) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
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
                Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
                const SizedBox(height: 2),
                Text(
                  '${superhost ? l.listingSuperhostLabel : ''}${l.listingHostResponseTime}',
                  style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
                ),
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
        Text(
          listing.type == 'space' ? l.listingAboutSpace : listing.type == 'experience' ? l.listingAboutExperience : l.listingAboutService,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _text),
        ),
        const SizedBox(height: 10),
        Text(
          display,
          style: GoogleFonts.inter(fontSize: 14, color: _textSec, height: 1.6),
        ),
        if (isLong) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? l.listingShowLess : l.listingShowMore,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _limeDark),
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
        Text(AppLocalizations.of(context).listingAmenities, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: listing.amenities.map((a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_amenityIcon(a), size: 18, color: _limeDark),
                const SizedBox(width: 8),
                Text(a, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // RENTAL MODE BADGE
  // ══════════════════════════════════════════
  Widget _rentalModeBadge(Listing listing) {
    final l = AppLocalizations.of(context);
    final mode = RentalMode.fromDb(listing.rentalMode);
    String subtitle;
    switch (mode) {
      case RentalMode.hours:
        final from = listing.availableFrom ?? '09:00';
        final until = listing.availableUntil ?? '22:00';
        final minH = listing.minHours;
        subtitle = l.listingRentalHoursSubtitle(from, until, minH);
        break;
      case RentalMode.fullDay:
        subtitle = l.listingRentalFullDaySubtitle;
        break;
      case RentalMode.nights:
        final checkIn = listing.checkInTime ?? '15:00';
        final checkOut = listing.checkOutTime ?? '11:00';
        final minN = listing.minNights;
        subtitle = l.listingRentalNightsSubtitle(checkIn, checkOut, minN);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lime.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lime.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_rentalModeIcon(listing.rentalMode), size: 18, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.listingRentalMode(mode.label),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _text),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: _textSec),
                ),
              ],
            ),
          ),
        ],
      ),
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
        Text(l.listingAvailability, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
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
        Text(l.listingRules, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
        const SizedBox(height: 12),
        if (mode == RentalMode.nights)
          _ruleRow(Icons.schedule_rounded, l.listingRuleCheckInOut(checkIn, checkOut))
        else if (mode == RentalMode.hours)
          _ruleRow(Icons.schedule_rounded, l.listingRuleHours(listing.availableFrom ?? '09:00', listing.availableUntil ?? '22:00'))
        else
          _ruleRow(Icons.schedule_rounded, l.listingRuleFullDay),
        _ruleRow(Icons.smoke_free_rounded, l.listingRuleNoSmoke),
        _ruleRow(Icons.pets_rounded, l.listingRulePets),
        _ruleRow(Icons.volume_down_rounded, l.listingRuleQuiet),
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
          children: [
            Text(l.listingCancellation, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                policy.label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _limeDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                policy.description,
                style: GoogleFonts.inter(fontSize: 13, color: _textSec, height: 1.5),
              ),
              const SizedBox(height: 12),
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
          ),
        ),
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
        Row(
          children: [
            const Icon(Icons.map_outlined, size: 20, color: _limeDark),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).listingLocation, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
          ],
        ),
        const SizedBox(height: 6),
        if (listing.city != null)
          Text(
            '${listing.address != null ? '${listing.address}, ' : ''}${listing.city}${listing.country != null ? ', ${listing.country}' : ''}',
            style: GoogleFonts.inter(fontSize: 13, color: _textSec),
          ),
        const SizedBox(height: 12),
        LocationMapWidget(
          latitude: listing.latitude!,
          longitude: listing.longitude!,
          title: listing.title,
          height: 200,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // BOTTOM BAR
  // ══════════════════════════════════════════
  Widget _bottomBar(Listing listing, double bottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottom),
      decoration: BoxDecoration(
        color: _white,
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.basePrice?.toCLP ?? '\$0',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: _text),
                ),
                Text(
                  '/ ${_priceUnit(context, listing.priceUnit)}',
                  style: GoogleFonts.inter(fontSize: 12, color: _textSec),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/checkout/${listing.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _lime, borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                AppLocalizations.of(context).listingBookNow,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
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
  Widget _divider() => Container(height: 1, color: _border);

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color? color}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color ?? _text),
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

  Widget _highlight(IconData icon, String label) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 20, color: _limeDark),
      ),
      const SizedBox(height: 5),
      Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _textSec)),
    ],
  );
}
