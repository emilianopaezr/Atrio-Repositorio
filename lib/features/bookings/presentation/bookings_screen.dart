import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/providers/bookings_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

/// Mis Reservas — editorial, robust, simple.
///
/// Two tabs (Próximas / Pasadas), filter chips (Todas / Pendientes /
/// Confirmadas — or Completadas / Canceladas in Pasadas), then a list
/// of [_BookingCard]s. The previous version used `_isUpcoming` /
/// `_isPast` partition functions whose implementation diverged between
/// the count pill and the list render after the migration that auto-
/// completes overdue bookings — meaning the pill said "20" while the
/// body still derived an empty list. This rewrite uses a single source
/// of truth (`_partition`) so the count and the list ALWAYS agree.
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  int _selectedTab = 0; // 0 = Próximas, 1 = Pasadas
  int _selectedFilter = 0; // 0 = Todas, 1+2 = sub-filters

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bookingsAsync = ref.watch(guestBookingsProvider);

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              eyebrow: l.bookingsEyebrow,
              title: l.bookingsTitle,
              subtitle: l.bookingsHeroSubtitle,
            ),
            const SizedBox(height: 22),
            bookingsAsync.when(
              data: (bookings) {
                final partition = _partition(bookings);
                return _TabPillsRow(
                  upcomingCount: partition.upcoming.length,
                  pastCount: partition.past.length,
                  selectedTab: _selectedTab,
                  onChanged: (i) => setState(() {
                    _selectedTab = i;
                    _selectedFilter = 0;
                  }),
                );
              },
              loading: () => _TabPillsRow(
                upcomingCount: null,
                pastCount: null,
                selectedTab: _selectedTab,
                onChanged: (i) => setState(() {
                  _selectedTab = i;
                  _selectedFilter = 0;
                }),
              ),
              error: (_, _) => _TabPillsRow(
                upcomingCount: null,
                pastCount: null,
                selectedTab: _selectedTab,
                onChanged: (i) => setState(() {
                  _selectedTab = i;
                  _selectedFilter = 0;
                }),
              ),
            ),
            const SizedBox(height: 12),
            _FilterChipsRow(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
              onChanged: (i) => setState(() => _selectedFilter = i),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) {
                  final partition = _partition(bookings);
                  final base = _selectedTab == 0
                      ? partition.upcoming
                      : partition.past;
                  final list = _applyChip(base);
                  if (list.isEmpty) {
                    return _EmptyBookings(
                      message: _selectedTab == 0
                          ? l.bookingsNoUpcoming
                          : l.bookingsNoPast,
                    );
                  }
                  return RefreshIndicator(
                    color: AtrioColors.neonLimeDark,
                    onRefresh: () async {
                      ref.invalidate(guestBookingsProvider);
                      await Future<void>.delayed(
                          const Duration(milliseconds: 600));
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _BookingCard(booking: list[index]),
                    ),
                  );
                },
                loading: () => const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AtrioColors.neonLimeDark,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 48,
                          color: AtrioColors.error.withValues(alpha: 0.6)),
                      const SizedBox(height: 16),
                      Text(
                        l.bookingsLoadError,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AtrioColors.guestTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(guestBookingsProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l.btnRetry),
                        style: TextButton.styleFrom(
                            foregroundColor: AtrioColors.neonLimeDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single source of truth: split bookings into upcoming/past. A booking
  /// is **past** if any of these is true:
  ///   - status ∈ {completed, cancelled, rejected}
  ///   - payment_status ∈ {failed, refunded}
  ///   - end date < today (everything else with overdue date is past)
  ///
  /// Otherwise it's **upcoming**.
  _Partition _partition(List<Map<String, dynamic>> bookings) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final upcoming = <Map<String, dynamic>>[];
    final past = <Map<String, dynamic>>[];
    for (final b in bookings) {
      final status = (b['status'] as String? ?? '').toLowerCase();
      final payment = (b['payment_status'] as String? ?? '').toLowerCase();
      final isFinishedStatus =
          status == 'completed' || status == 'cancelled' || status == 'rejected';
      final isFinishedPayment =
          payment == 'failed' || payment == 'refunded';
      final end = _bookingEndDate(b);
      final isOverdue = end != null && end.isBefore(todayDate);
      if (isFinishedStatus || isFinishedPayment || isOverdue) {
        past.add(b);
      } else {
        upcoming.add(b);
      }
    }
    return _Partition(upcoming, past);
  }

  static DateTime? _bookingEndDate(Map<String, dynamic> b) {
    final raw =
        (b['check_out'] ?? b['booking_date'] ?? b['check_in']) as String?;
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  List<Map<String, dynamic>> _applyChip(List<Map<String, dynamic>> base) {
    if (_selectedFilter == 0) return base; // Todas
    final isUpcomingTab = _selectedTab == 0;
    final target = isUpcomingTab
        ? (_selectedFilter == 1 ? 'pending' : 'confirmed')
        : (_selectedFilter == 1 ? 'completed' : 'cancelled');
    return base
        .where((b) => (b['status'] as String? ?? '').toLowerCase() == target)
        .toList();
  }
}

class _Partition {
  final List<Map<String, dynamic>> upcoming;
  final List<Map<String, dynamic>> past;
  _Partition(this.upcoming, this.past);
}

// ═══════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _Header(
      {required this.eyebrow, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AtrioColors.guestTextTertiary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AtrioColors.guestTextPrimary,
              letterSpacing: -1.0,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tab pills
// ═══════════════════════════════════════════════════════════════
class _TabPillsRow extends StatelessWidget {
  final int? upcomingCount;
  final int? pastCount;
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _TabPillsRow({
    required this.upcomingCount,
    required this.pastCount,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabPill(
                label: l.bookingsUpcoming,
                count: upcomingCount,
                selected: selectedTab == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(0);
                },
              ),
            ),
            Expanded(
              child: _TabPill(
                label: l.bookingsPast,
                count: pastCount,
                selected: selectedTab == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AtrioColors.guestTextPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AtrioColors.guestTextSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AtrioColors.neonLime
                      : AtrioColors.guestCardBorder,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.black
                        : AtrioColors.guestTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Filter chips
// ═══════════════════════════════════════════════════════════════
class _FilterChipsRow extends StatelessWidget {
  final int selectedTab;
  final int selectedFilter;
  final ValueChanged<int> onChanged;

  const _FilterChipsRow({
    required this.selectedTab,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = selectedTab == 0
        ? [l.bookingsAll, l.bookingsPending, l.bookingsConfirmed]
        : [l.bookingsAll, l.bookingsCompleted, l.bookingsCancelled];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = selectedFilter == i;
          return Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AtrioColors.guestTextPrimary
                      : AtrioColors.guestSurfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AtrioColors.guestTextPrimary
                        : AtrioColors.guestCardBorder,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AtrioColors.guestBackground
                        : AtrioColors.guestTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Booking card — defensive layout, no fixed-height children
// ═══════════════════════════════════════════════════════════════
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
      case 'active':
        return AtrioColors.neonLimeDark;
      case 'pending':
        return AtrioColors.vibrantOrange;
      case 'cancelled':
      case 'rejected':
        return AtrioColors.error;
      case 'completed':
        return AtrioColors.success;
      default:
        return AtrioColors.guestTextSecondary;
    }
  }

  String _statusLabel(BuildContext context, String s) {
    final l = AppLocalizations.of(context);
    switch (s) {
      case 'confirmed':
        return l.bookingStatusConfirmed;
      case 'pending':
        return l.bookingStatusPending;
      case 'active':
        return l.bookingStatusActive;
      case 'cancelled':
        return l.bookingStatusCancelled;
      case 'rejected':
        return l.bookingStatusRejected;
      case 'completed':
        return l.bookingStatusCompleted;
      default:
        return s;
    }
  }

  IconData _typeIcon(String? t) {
    switch (t) {
      case 'space':
        return Icons.apartment_rounded;
      case 'experience':
        return Icons.explore_rounded;
      case 'service':
        return Icons.room_service_rounded;
      default:
        return Icons.calendar_today_outlined;
    }
  }

  String _date(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final l = AppLocalizations.of(context);
    final months = [
      '',
      l.monthAbbrJan,
      l.monthAbbrFeb,
      l.monthAbbrMar,
      l.monthAbbrApr,
      l.monthAbbrMay,
      l.monthAbbrJun,
      l.monthAbbrJul,
      l.monthAbbrAug,
      l.monthAbbrSep,
      l.monthAbbrOct,
      l.monthAbbrNov,
      l.monthAbbrDec,
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final listing = (booking['listing'] as Map<String, dynamic>?) ?? const {};
    final status = (booking['status'] as String?) ?? 'pending';
    final imagesRaw = listing['images'];
    final images = imagesRaw is List ? imagesRaw : const [];
    final firstImage = images.isNotEmpty ? images.first?.toString() : null;
    final checkIn = DateTime.tryParse(booking['check_in']?.toString() ?? '');
    final checkOut =
        DateTime.tryParse(booking['check_out']?.toString() ?? '');
    final total = ((booking['total'] as num?) ?? 0).toCLP;
    final type = listing['type'] as String?;
    final title =
        (listing['title']?.toString() ?? '').isEmpty
            ? l.bookingDefault
            : listing['title'].toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          final id = booking['id']?.toString() ?? '';
          if (id.isNotEmpty) context.push('/booking-detail/$id');
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(19)),
                  child: SizedBox(
                    width: 108,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (firstImage != null)
                          CachedNetworkImage(
                            imageUrl: firstImage,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                                color: AtrioColors.guestSurfaceVariant),
                            errorWidget: (_, _, _) => Container(
                              color: AtrioColors.guestSurfaceVariant,
                              child: const Icon(Icons.image_outlined,
                                  color: AtrioColors.guestTextTertiary),
                            ),
                          )
                        else
                          Container(
                            color: AtrioColors.guestSurfaceVariant,
                            child: const Icon(Icons.image_outlined,
                                color: AtrioColors.guestTextTertiary),
                          ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AtrioColors.neonLime,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_typeIcon(type),
                                size: 12, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // top
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(status)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _statusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _statusLabel(context, status),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _statusColor(status),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextPrimary,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            if (checkIn != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 12,
                                      color: AtrioColors.guestTextTertiary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      checkOut != null
                                          ? '${_date(context, checkIn)} → ${_date(context, checkOut)}'
                                          : _date(context, checkIn),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AtrioColors.guestTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        // bottom
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  total,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AtrioColors.guestTextPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22,
                                  color: AtrioColors.guestTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════
class _EmptyBookings extends StatelessWidget {
  final String message;
  const _EmptyBookings({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_available_rounded,
            color: AtrioColors.neonLimeDark,
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AtrioColors.guestTextSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
