import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/services/database_service.dart';

const _bg = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _border = Color(0xFFEEEEEE);
const _text = Color(0xFF1A1A1A);
const _textSec = Color(0xFF777777);
const _textMuted = Color(0xFFAAAAAA);
const _lime = Color(0xFFD4FF00);
const _limeDark = Color(0xFF9BBF00);
const _gold = Color(0xFFFFB800);

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
    } catch (_) {}
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
    } catch (_) {
      if (mounted) setState(() => _isFav = !newState);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final data = await DatabaseService.getListingReviews(widget.listingId);
      if (mounted) setState(() { _reviews = data; _loadingReviews = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  String _priceUnit(String u) {
    switch (u) {
      case 'night': return 'noche';
      case 'hour': return 'hora';
      case 'session': return 'sesión';
      case 'person': return 'persona';
      default: return u;
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return 'Hace ${diff.inDays ~/ 365} año${diff.inDays ~/ 365 > 1 ? 's' : ''}';
    if (diff.inDays > 30) return 'Hace ${diff.inDays ~/ 30} mes${diff.inDays ~/ 30 > 1 ? 'es' : ''}';
    if (diff.inDays > 0) return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    return 'Hace un momento';
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

  Widget _empty({bool error = false}) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _bg, elevation: 0, surfaceTintColor: Colors.transparent,
      leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: _text))),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(error ? Icons.error_outline : Icons.search_off, size: 48, color: _textMuted),
          const SizedBox(height: 12),
          Text(error ? 'Error al cargar' : 'No encontrado', style: GoogleFonts.roboto(fontSize: 16, color: _textSec)),
          if (error) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ref.invalidate(listingDetailProvider(widget.listingId)),
              child: Text('Reintentar', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: _limeDark)),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _page(Listing listing) {
    final host = listing.hostData;
    final hostName = host?['display_name'] as String? ?? 'Anfitrión';
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
                          const SizedBox(height: 20),

                          // ─── Category + Rating ───
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _lime.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  listing.type == 'space' ? 'Espacio' : listing.type == 'experience' ? 'Experiencia' : 'Servicio',
                                  style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: _limeDark, letterSpacing: 0.5),
                                ),
                              ),
                              const Spacer(),
                              if (listing.rating > 0) ...[
                                const Icon(Icons.star_rounded, size: 16, color: _gold),
                                const SizedBox(width: 4),
                                Text(
                                  listing.rating.toStringAsFixed(1),
                                  style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: _text),
                                ),
                                if (listing.reviewCount > 0) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    ' (${listing.reviewCount})',
                                    style: GoogleFonts.roboto(fontSize: 13, color: _textSec),
                                  ),
                                ],
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ─── Title ───
                          Text(
                            listing.title,
                            style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w800, color: _text, height: 1.15),
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
                                  style: GoogleFonts.roboto(fontSize: 13, color: _textSec),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Quick highlights ───
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _highlight(Icons.people_outline_rounded, '${listing.capacity ?? 4} pers.'),
                              _highlight(Icons.access_time_rounded, 'Flexible'),
                              _highlight(Icons.verified_user_outlined, 'Asegurado'),
                              _highlight(Icons.flash_on_rounded, 'Inst.'),
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

                          // ─── House rules ───
                          _rulesSection(),

                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Cancellation ───
                          _cancellationSection(),

                          const SizedBox(height: 18),
                          _divider(),
                          const SizedBox(height: 18),

                          // ─── Reviews ───
                          _reviewsSection(listing),

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
                placeholder: (_, _) => Container(color: const Color(0xFFF0F0F0)),
                errorWidget: (_, _, _) => Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.image, size: 48, color: _textMuted),
                ),
              ),
            )
          else
            Container(color: const Color(0xFFF0F0F0), child: const Icon(Icons.image, size: 56, color: _textMuted)),

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
                    _circleBtn(Icons.ios_share_rounded, () {}),
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
                    '\$${listing.basePrice?.toStringAsFixed(0) ?? '0'}',
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  Text(
                    '/${_priceUnit(listing.priceUnit)}',
                    style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.6)),
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
                  style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
                backgroundImage: photo != null ? NetworkImage(photo) : null,
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
                      decoration: const BoxDecoration(color: Color(0xFFFF8C00), shape: BoxShape.circle),
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
                Text(name, style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
                const SizedBox(height: 2),
                Text(
                  '${superhost ? 'Superhost · ' : ''}Responde en 1hr',
                  style: GoogleFonts.roboto(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                backgroundColor: Color(0xFFD4FF00),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: Duration(seconds: 1),
              ));
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
                  Text('Chat', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: _limeDark)),
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
    final desc = listing.description ?? 'Sin descripción disponible.';
    final words = desc.split(RegExp(r'\s+'));
    final isLong = words.length > 60;
    final display = (!_descExpanded && isLong) ? '${words.take(60).join(' ')}...' : desc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.type == 'space' ? 'Acerca del espacio' : listing.type == 'experience' ? 'Acerca de la experiencia' : 'Acerca del servicio',
          style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: _text),
        ),
        const SizedBox(height: 10),
        Text(
          display,
          style: GoogleFonts.roboto(fontSize: 14, color: _textSec, height: 1.6),
        ),
        if (isLong) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? 'Mostrar menos' : 'Ver más',
              style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: _limeDark),
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
        Text('Amenidades', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
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
                Text(a, style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // HOUSE RULES
  // ══════════════════════════════════════════
  Widget _rulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reglas', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
        const SizedBox(height: 12),
        _ruleRow(Icons.schedule_rounded, 'Check-in: 10:00 AM — Check-out: 8:00 PM'),
        _ruleRow(Icons.smoke_free_rounded, 'No fumar dentro del espacio'),
        _ruleRow(Icons.pets_rounded, 'Mascotas con previo aviso'),
        _ruleRow(Icons.volume_down_rounded, 'Respetar horario de silencio'),
      ],
    );
  }

  Widget _ruleRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 18, color: _textMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.roboto(fontSize: 13, color: _textSec))),
      ],
    ),
  );

  // ══════════════════════════════════════════
  // CANCELLATION
  // ══════════════════════════════════════════
  Widget _cancellationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cancelación', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              _cancelRow(Icons.check_circle_outline, _limeDark, 'Gratis hasta 48h antes', 'Reembolso completo'),
              const SizedBox(height: 12),
              _cancelRow(Icons.warning_amber_rounded, _gold, '24-48h: 50% reembolso', 'Se retiene la mitad'),
              const SizedBox(height: 12),
              _cancelRow(Icons.cancel_outlined, const Color(0xFFE53935), 'Menos de 24h', 'Sin reembolso'),
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
            Text(title, style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
            Text(sub, style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
          ],
        ),
      ),
    ],
  );

  // ══════════════════════════════════════════
  // REVIEWS
  // ══════════════════════════════════════════
  Widget _reviewsSection(Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reseñas', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
            const SizedBox(width: 8),
            if (listing.rating > 0) ...[
              const Icon(Icons.star_rounded, size: 16, color: _gold),
              const SizedBox(width: 3),
              Text(
                '${listing.rating.toStringAsFixed(1)} (${listing.reviewCount})',
                style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: _text),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        if (_loadingReviews)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: _limeDark, strokeWidth: 2),
          ))
        else if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.rate_review_outlined, size: 32, color: _textMuted),
                  const SizedBox(height: 8),
                  Text('Aún no hay reseñas', style: GoogleFonts.roboto(fontSize: 14, color: _textMuted)),
                  Text('Sé el primero en opinar', style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            _reviews.length > 3 ? 3 : _reviews.length,
            (i) {
              final r = _reviews[i];
              final reviewer = r['reviewer'] as Map<String, dynamic>?;
              final name = reviewer?['display_name'] as String? ?? 'Usuario';
              final photo = reviewer?['photo_url'] as String?;
              final rating = (r['rating'] as num?)?.toDouble() ?? 0;
              final comment = r['comment'] as String? ?? '';
              final hostReply = r['host_reply'] as String?;
              final created = DateTime.tryParse(r['created_at'] ?? '');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _lime.withValues(alpha: 0.2),
                            backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
                            child: photo == null ? Text(name[0].toUpperCase(), style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: _limeDark)) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
                                if (created != null)
                                  Text(_timeAgo(created), style: GoogleFonts.roboto(fontSize: 11, color: _textMuted)),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (j) => Icon(
                              j < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 14,
                              color: j < rating ? _gold : _gold.withValues(alpha: 0.3),
                            )),
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(comment, style: GoogleFonts.roboto(fontSize: 13, color: _textSec, height: 1.5)),
                      ],
                      if (hostReply != null && hostReply.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _bg, borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.reply_rounded, size: 14, color: _limeDark),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Respuesta del anfitrión', style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: _text)),
                                    const SizedBox(height: 3),
                                    Text(hostReply, style: GoogleFonts.roboto(fontSize: 12, color: _textSec, height: 1.4)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

        if (_reviews.length > 3) ...[
          const SizedBox(height: 4),
          Center(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                  backgroundColor: Color(0xFFD4FF00),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: Duration(seconds: 1),
                ));
              },
              child: Text(
                'Ver las ${_reviews.length} reseñas',
                style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: _limeDark),
              ),
            ),
          ),
        ],
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
                  '\$${listing.basePrice?.toStringAsFixed(0) ?? '0'}',
                  style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w800, color: _text),
                ),
                Text(
                  '/ ${_priceUnit(listing.priceUnit)}',
                  style: GoogleFonts.roboto(fontSize: 12, color: _textSec),
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
                'Reservar',
                style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
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
      Text(label, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, color: _textSec)),
    ],
  );
}
