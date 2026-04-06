import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
// Database queries are done inline via SupabaseConfig.client

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _periodIdx = 1; // 0=week, 1=month, 2=year
  bool _loading = true;
  String? _error;
  double _totalRevenue = 0;
  int _totalBookings = 0;
  double _avgRating = 0;
  int _totalReviews = 0;
  List<Map<String, dynamic>> _topListings = [];
  List<Map<String, dynamic>> _recentBookings = [];
  List<double> _dailyRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final uid = SupabaseConfig.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      late DateTime start;
      if (_periodIdx == 0) {
        start = now.subtract(const Duration(days: 7));
      } else if (_periodIdx == 1) {
        start = DateTime(now.year, now.month, 1);
      } else {
        start = DateTime(now.year, 1, 1);
      }

      // Fetch bookings for this host in period
      final bookings = await SupabaseConfig.client
          .from('bookings')
          .select('id, total_price, status, check_in, created_at, listing:listings(id, title, images)')
          .eq('host_id', uid)
          .gte('created_at', start.toIso8601String())
          .order('created_at', ascending: false);

      final bookingList = List<Map<String, dynamic>>.from(bookings);

      // Revenue from confirmed/completed only
      double rev = 0;
      for (final b in bookingList) {
        final s = b['status'] as String? ?? '';
        if (s == 'confirmed' || s == 'completed') {
          rev += (b['total_price'] as num?)?.toDouble() ?? 0;
        }
      }

      // Reviews
      final reviews = await SupabaseConfig.client
          .from('reviews')
          .select('rating')
          .eq('host_id', uid);
      final reviewList = List<Map<String, dynamic>>.from(reviews);
      double ratingSum = 0;
      for (final r in reviewList) {
        ratingSum += (r['rating'] as num?)?.toDouble() ?? 0;
      }

      // Top listings
      final listings = await SupabaseConfig.client
          .from('listings')
          .select('id, title, images, review_count, average_rating')
          .eq('host_id', uid)
          .order('review_count', ascending: false)
          .limit(5);

      // Daily revenue bars (last 7 entries)
      final Map<String, double> dailyMap = {};
      for (final b in bookingList) {
        final s = b['status'] as String? ?? '';
        if (s == 'confirmed' || s == 'completed') {
          final d = (b['created_at'] as String?)?.substring(0, 10) ?? '';
          dailyMap[d] = (dailyMap[d] ?? 0) + ((b['total_price'] as num?)?.toDouble() ?? 0);
        }
      }
      final dailyKeys = dailyMap.keys.toList()..sort();
      final daily = dailyKeys.take(7).map((k) => dailyMap[k]!).toList();

      if (mounted) {
        setState(() {
          _totalRevenue = rev;
          _totalBookings = bookingList.length;
          _avgRating = reviewList.isEmpty ? 0 : ratingSum / reviewList.length;
          _totalReviews = reviewList.length;
          _topListings = List<Map<String, dynamic>>.from(listings);
          _recentBookings = bookingList.take(5).toList();
          _dailyRevenue = daily;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Analytics error: $e');
      if (mounted) setState(() { _loading = false; _error = 'Error al cargar analíticas'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = AtrioColors.hostBackground;
    const surface = AtrioColors.hostSurface;
    const surfaceV = AtrioColors.hostSurfaceVariant;
    const border = AtrioColors.hostCardBorder;
    const textP = AtrioColors.hostTextPrimary;
    const textS = AtrioColors.hostTextSecondary;
    const textT = AtrioColors.hostTextTertiary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: textP),
          onPressed: () => context.pop(),
        ),
        title: Text('Analíticas',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textP)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AtrioColors.neonLime))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AtrioColors.hostTextTertiary),
                      const SizedBox(height: 12),
                      Text(_error!, style: GoogleFonts.inter(fontSize: 15, color: textS)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _loadData,
                        child: Text('Reintentar', style: GoogleFonts.inter(color: AtrioColors.neonLime, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AtrioColors.neonLime,
              backgroundColor: surface,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Period selector
                  Row(
                    children: [
                      _periodChip('Semana', 0, textP, textT, border),
                      const SizedBox(width: 8),
                      _periodChip('Mes', 1, textP, textT, border),
                      const SizedBox(width: 8),
                      _periodChip('Año', 2, textP, textT, border),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Revenue card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AtrioColors.neonLimeDark, AtrioColors.neonLime],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ingresos del período',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text('${_totalRevenue.toCLP} CLP',
                            style: GoogleFonts.inter(
                                fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black)),
                        if (_dailyRevenue.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 50,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _dailyRevenue.map((v) {
                                final maxVal = _dailyRevenue.reduce((a, b) => a > b ? a : b);
                                final h = maxVal > 0 ? (v / maxVal * 40) + 4 : 4.0;
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      _statCard('Reservas', '$_totalBookings', Icons.calendar_today_rounded,
                          surface, border, textP, textS),
                      const SizedBox(width: 12),
                      _statCard(
                          'Rating',
                          _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '-',
                          Icons.star_rounded,
                          surface,
                          border,
                          textP,
                          textS),
                      const SizedBox(width: 12),
                      _statCard('Reseñas', '$_totalReviews', Icons.rate_review_rounded, surface,
                          border, textP, textS),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Top listings
                  Text('Top Publicaciones',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
                  const SizedBox(height: 12),
                  if (_topListings.isEmpty)
                    _emptyState('Sin publicaciones aún', textT)
                  else
                    ..._topListings.map((l) {
                      final imgs = l['images'] as List? ?? [];
                      final img = imgs.isNotEmpty ? imgs[0] as String : null;
                      final title = l['title'] as String? ?? 'Sin título';
                      final reviews = l['review_count'] as int? ?? 0;
                      final rating = (l['average_rating'] as num?)?.toDouble() ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: img != null
                                  ? Image.network(img,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: surfaceV,
                                      child: const Icon(Icons.image, color: textT)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textP),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 14, color: AtrioColors.ratingGold),
                                      const SizedBox(width: 3),
                                      Text(rating > 0 ? rating.toStringAsFixed(1) : '-',
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: textS)),
                                      const SizedBox(width: 10),
                                      Text('$reviews reseñas',
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: textT)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 28),

                  // Recent bookings
                  Text('Actividad Reciente',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
                  const SizedBox(height: 12),
                  if (_recentBookings.isEmpty)
                    _emptyState('Sin reservas recientes', textT)
                  else
                    ..._recentBookings.map((b) {
                      final status = b['status'] as String? ?? 'pending';
                      final price = (b['total_price'] as num?)?.toDouble() ?? 0;
                      final listing = b['listing'] as Map<String, dynamic>?;
                      final title = listing?['title'] as String? ?? 'Reserva';
                      final date = (b['created_at'] as String?)?.substring(0, 10) ?? '';
                      final statusColor = _statusColor(status);
                      final statusLabel = _statusLabel(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: textP),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('$date · $statusLabel',
                                      style:
                                          GoogleFonts.inter(fontSize: 12, color: textT)),
                                ],
                              ),
                            ),
                            Text(price.toCLP,
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AtrioColors.neonLime)),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _periodChip(String label, int idx, Color textP, Color textT, Color border) {
    final sel = _periodIdx == idx;
    return GestureDetector(
      onTap: () {
        setState(() => _periodIdx = idx);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AtrioColors.neonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AtrioColors.neonLime : border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.black : textT)),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color surface, Color border,
      Color textP, Color textS) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AtrioColors.neonLime),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w800, color: textP)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: textS)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: color))),
      );

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return AtrioColors.statusConfirmed;
      case 'pending':
        return AtrioColors.statusPending;
      case 'completed':
        return AtrioColors.statusCompleted;
      case 'cancelled':
        return AtrioColors.statusCancelled;
      default:
        return AtrioColors.hostTextTertiary;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendiente';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return s;
    }
  }
}
