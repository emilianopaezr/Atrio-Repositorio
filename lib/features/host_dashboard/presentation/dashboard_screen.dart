import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/bookings_provider.dart';
import '../../../core/providers/host_wallet_provider.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/host_stats_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../config/theme/app_colors.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedPeriodIndex = 1; // default "1M"

  final List<String> _periodLabels = ['1S', '1M', '3M', '6M', '1A', 'Todo'];

  // Mock revenue data (12 months)
  List<FlSpot> get _revenueData => const [
        FlSpot(0, 1200),
        FlSpot(1, 1850),
        FlSpot(2, 1400),
        FlSpot(3, 2100),
        FlSpot(4, 1950),
        FlSpot(5, 2800),
        FlSpot(6, 3200),
        FlSpot(7, 2900),
        FlSpot(8, 3600),
        FlSpot(9, 3100),
        FlSpot(10, 4200),
        FlSpot(11, 4850),
      ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final hostProfileAsync = ref.watch(hostProfileProvider);
    final allBookingsAsync = ref.watch(hostBookingsProvider);
    ref.watch(listingsProvider(const ListingsFilter()));
    final userAsync = ref.watch(userProfileStreamProvider);
    final hostStatsAsync = ref.watch(hostStatsProvider);

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AtrioColors.neonLime,
          backgroundColor: AtrioColors.hostSurface,
          onRefresh: () async {
            ref.invalidate(hostProfileProvider);
            ref.invalidate(hostBookingsProvider);
            ref.invalidate(listingsProvider(const ListingsFilter()));
            ref.invalidate(hostStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ===== HEADER =====
                _buildHeader(userAsync),
                const SizedBox(height: 28),

                // ===== REVENUE DISPLAY =====
                _buildRevenueDisplay(hostProfileAsync),
                const SizedBox(height: 24),

                // ===== LINE CHART =====
                _buildChart(),
                const SizedBox(height: 8),

                // ===== PERIOD TABS =====
                _buildPeriodTabs(),
                const SizedBox(height: 28),

                // ===== STATS ROW =====
                _buildStatsRow(allBookingsAsync, hostStatsAsync),
                const SizedBox(height: 28),

                // ===== PROXIMAS RESERVAS =====
                _buildUpcomingBookings(allBookingsAsync),
                const SizedBox(height: 28),

                // ===== ACTIVIDAD RECIENTE =====
                _buildRecentActivity(ref),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // HEADER
  // ────────────────────────────────────────────
  Widget _buildHeader(AsyncValue<dynamic> userAsync) {
    return Row(
      children: [
        Expanded(
          child: userAsync.when(
            data: (profile) {
              final name = profile?.displayName?.split(' ').first ?? 'Anfitrión';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()},',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AtrioColors.hostTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hola, $name',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.hostTextPrimary,
                    ),
                  ),
                ],
              );
            },
            loading: () => Text(
              'Hola, Anfitrión',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AtrioColors.hostTextPrimary,
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        userAsync.when(
          data: (profile) {
            final avatarUrl = profile?.photoUrl;
            return Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: AtrioColors.hostSurface,
                          child: const Icon(Icons.person, color: AtrioColors.hostTextTertiary, size: 20),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: AtrioColors.hostSurface,
                          child: const Icon(Icons.person, color: AtrioColors.hostTextTertiary, size: 20),
                        ),
                      )
                    : Container(
                        color: AtrioColors.hostSurface,
                        child: const Icon(Icons.person, color: AtrioColors.hostTextTertiary, size: 20),
                      ),
              ),
            );
          },
          loading: () => Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AtrioColors.hostSurface,
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────
  // REVENUE DISPLAY
  // ────────────────────────────────────────────
  Widget _buildRevenueDisplay(AsyncValue<Map<String, dynamic>?> hostProfileAsync) {
    return hostProfileAsync.when(
      data: (profile) {
        final totalEarnings = double.tryParse(profile?['total_earnings']?.toString() ?? '0') ?? 0;
        final currentBalance = double.tryParse(profile?['current_balance']?.toString() ?? '0') ?? 0;
        final pendingBalance = double.tryParse(profile?['pending_balance']?.toString() ?? '0') ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${totalEarnings.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AtrioColors.hostTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ganancias totales',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AtrioColors.hostTextTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniBalance(
                  label: 'Disponible',
                  amount: '\$${currentBalance.toStringAsFixed(2)}',
                  color: AtrioColors.success,
                ),
                const SizedBox(width: 16),
                _MiniBalance(
                  label: 'Pendiente',
                  amount: '\$${pendingBalance.toStringAsFixed(2)}',
                  color: AtrioColors.ratingGold,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 36,
            decoration: BoxDecoration(
              color: AtrioColors.hostSurface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: AtrioColors.hostSurface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // ────────────────────────────────────────────
  // LINE CHART
  // ────────────────────────────────────────────
  Widget _buildChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                  final index = value.toInt();
                  if (index < 0 || index >= months.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[index],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AtrioColors.hostTextTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: 5500,
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AtrioColors.hostSurfaceVariant,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(0)}',
                    GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.neonLime,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  const FlLine(
                    color: AtrioColors.hostTextTertiary,
                    strokeWidth: 0.5,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: AtrioColors.neonLime,
                        strokeWidth: 2,
                        strokeColor: AtrioColors.hostBackground,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _revenueData,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AtrioColors.neonLime,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AtrioColors.neonLime.withValues(alpha: 0.25),
                    AtrioColors.neonLime.withValues(alpha: 0.05),
                    AtrioColors.neonLime.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ────────────────────────────────────────────
  // PERIOD TABS
  // ────────────────────────────────────────────
  Widget _buildPeriodTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_periodLabels.length, (index) {
        final isSelected = index == _selectedPeriodIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedPeriodIndex = index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AtrioColors.neonLime : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _periodLabels[index],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : AtrioColors.hostTextTertiary,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ────────────────────────────────────────────
  // STATS ROW
  // ────────────────────────────────────────────
  Widget _buildStatsRow(
    AsyncValue<List<Map<String, dynamic>>> allBookingsAsync,
    AsyncValue<dynamic> hostStatsAsync,
  ) {
    return Row(
      children: [
        // Reservas Activas
        Expanded(
          child: allBookingsAsync.when(
            data: (bookings) {
              final active = bookings.where((b) =>
                  b['status'] == 'confirmed' || b['status'] == 'active').length;
              return _StatCard(
                value: '$active',
                label: 'Reservas\nActivas',
              );
            },
            loading: () => _StatCard(value: '--', label: 'Reservas\nActivas'),
            error: (_, _) => _StatCard(value: '--', label: 'Reservas\nActivas'),
          ),
        ),
        const SizedBox(width: 10),
        // Ocupacion
        Expanded(
          child: allBookingsAsync.when(
            data: (bookings) {
              final total = bookings.length;
              final active = bookings.where((b) =>
                  b['status'] == 'confirmed' || b['status'] == 'active').length;
              final occupancy = total > 0 ? ((active / total) * 100).toInt() : 0;
              return _StatCard(
                value: '$occupancy%',
                label: 'Ocupación',
              );
            },
            loading: () => _StatCard(value: '--%', label: 'Ocupación'),
            error: (_, _) => _StatCard(value: '--%', label: 'Ocupación'),
          ),
        ),
        const SizedBox(width: 10),
        // Calificacion
        Expanded(
          child: hostStatsAsync.when(
            data: (stats) {
              final rating = stats?.averageRating ?? 0;
              return _StatCard(
                value: rating > 0 ? rating.toStringAsFixed(1) : '--',
                label: 'Calificación',
                icon: Icons.star_rounded,
                iconColor: AtrioColors.ratingGold,
              );
            },
            loading: () => _StatCard(value: '--', label: 'Calificación'),
            error: (_, _) => _StatCard(value: '--', label: 'Calificación'),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────
  // PROXIMAS RESERVAS
  // ────────────────────────────────────────────
  Widget _buildUpcomingBookings(AsyncValue<List<Map<String, dynamic>>> bookingsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximas Reservas',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        bookingsAsync.when(
          data: (bookings) {
            final upcoming = bookings.where((b) =>
                b['status'] == 'confirmed' || b['status'] == 'pending').take(3).toList();

            if (upcoming.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay reservas próximas',
                  style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary),
                ),
              );
            }

            return Column(
              children: [
                ...upcoming.map((booking) {
                  final guest = booking['guest'] as Map<String, dynamic>?;
                  final listing = booking['listing'] as Map<String, dynamic>?;
                  final guestName = guest?['display_name'] ?? 'Huésped';
                  final listingTitle = listing?['title'] ?? 'Espacio';
                  final checkIn = booking['check_in']?.toString().split('T').first ?? '';
                  final avatarUrl = guest?['photo_url'] as String?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => context.push('/booking-detail/${booking['id']}'),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AtrioColors.hostSurface,
                              border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => const Icon(Icons.person, size: 18, color: AtrioColors.hostTextTertiary),
                                    )
                                  : const Icon(Icons.person, size: 18, color: AtrioColors.hostTextTertiary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guestName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AtrioColors.hostTextPrimary,
                                  ),
                                ),
                                Text(
                                  '$listingTitle  ·  $checkIn',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AtrioColors.hostTextTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/host/calendar'),
                    child: Text(
                      'Ver todo',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.neonLime,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(height: 60),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────
  // ACTIVIDAD RECIENTE
  // ────────────────────────────────────────────
  IconData _notifIcon(String type) {
    switch (type) {
      case 'booking': return Icons.calendar_today_rounded;
      case 'review': return Icons.star_rounded;
      case 'payment': return Icons.payments_rounded;
      case 'message': return Icons.message_rounded;
      case 'system': return Icons.info_outline_rounded;
      default: return Icons.notifications_outlined;
    }
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'booking': return AtrioColors.electricViolet;
      case 'review': return AtrioColors.ratingGold;
      case 'payment': return AtrioColors.success;
      case 'message': return const Color(0xFF3B82F6);
      case 'system': return AtrioColors.neonLime;
      default: return AtrioColors.hostTextSecondary;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
    return 'Ahora';
  }

  Widget _buildRecentActivity(WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        notifsAsync.when(
          data: (notifs) {
            if (notifs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay actividad reciente',
                  style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary),
                ),
              );
            }
            final recent = notifs.take(5).toList();
            return Column(
              children: recent.map((notif) {
                final type = notif['type'] as String? ?? 'system';
                final title = notif['title'] as String? ?? '';
                final body = notif['body'] as String? ?? '';
                final createdAt = DateTime.tryParse(notif['created_at'] ?? '');
                final iconColor = _notifColor(type);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_notifIcon(type), size: 16, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AtrioColors.hostTextPrimary,
                              ),
                            ),
                            if (body.isNotEmpty)
                              Text(
                                body,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AtrioColors.hostTextTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _timeAgo(createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AtrioColors.hostTextTertiary,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(height: 60),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Error al cargar actividad',
              style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary),
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Text(
            'Ver todo',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AtrioColors.neonLime,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════
// STAT CARD WIDGET
// ════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _StatCard({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor ?? AtrioColors.ratingGold),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.hostTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AtrioColors.hostTextSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// MINI BALANCE WIDGET
// ════════════════════════════════════════════
class _MiniBalance extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _MiniBalance({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AtrioColors.hostTextTertiary,
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AtrioColors.hostTextPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
