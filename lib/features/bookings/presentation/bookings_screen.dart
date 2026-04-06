import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/bookings_provider.dart';
import '../../../core/utils/extensions.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  int _selectedTab = 0; // 0=Proximas, 1=Pasadas
  int _selectedFilter = 0; // 0=Todas, 1/2 vary by tab

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(guestBookingsProvider);

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
                'Mis Reservas',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tab pills with count badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: bookingsAsync.when(
                data: (bookings) {
                  final upcomingCount = bookings.where((b) {
                    final status = b['status'] as String? ?? '';
                    return status == 'pending' ||
                        status == 'confirmed' ||
                        status == 'active';
                  }).length;
                  final pastCount = bookings.where((b) {
                    final status = b['status'] as String? ?? '';
                    return status == 'completed' ||
                        status == 'cancelled' ||
                        status == 'rejected';
                  }).length;

                  return _buildTabPills(upcomingCount, pastCount);
                },
                loading: () => _buildTabPills(null, null),
                error: (_, _) => _buildTabPills(null, null),
              ),
            ),
            const SizedBox(height: 12),

            // Filter chips row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FilterChipsRow(
                selectedTab: _selectedTab,
                selectedFilter: _selectedFilter,
                onFilterChanged: (index) {
                  setState(() => _selectedFilter = index);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) {
                  final upcoming = bookings.where((b) {
                    final status = b['status'] as String? ?? '';
                    return status == 'pending' ||
                        status == 'confirmed' ||
                        status == 'active';
                  }).toList();

                  final past = bookings.where((b) {
                    final status = b['status'] as String? ?? '';
                    return status == 'completed' ||
                        status == 'cancelled' ||
                        status == 'rejected';
                  }).toList();

                  var list = _selectedTab == 0 ? upcoming : past;

                  // Apply sub-filter
                  list = _applyFilter(list);

                  if (list.isEmpty) {
                    return _EmptyBookings(
                      message: _selectedTab == 0
                          ? 'No tienes reservas proximas'
                          : 'Aun no has completado ninguna reserva',
                    );
                  }

                  return RefreshIndicator(
                    color: AtrioColors.neonLimeDark,
                    onRefresh: () async {
                      ref.invalidate(guestBookingsProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return _BookingCard(booking: list[index]);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AtrioColors.neonLimeDark,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Error al cargar reservas',
                    style: AtrioTypography.bodyLarge.copyWith(
                      color: AtrioColors.guestTextSecondary,
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

  Widget _buildTabPills(int? upcomingCount, int? pastCount) {
    final upcomingLabel =
        upcomingCount != null ? 'Proximas ($upcomingCount)' : 'Proximas';
    final pastLabel =
        pastCount != null ? 'Pasadas ($pastCount)' : 'Pasadas';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              label: upcomingLabel,
              isSelected: _selectedTab == 0,
              onTap: () => setState(() {
                _selectedTab = 0;
                _selectedFilter = 0;
              }),
            ),
          ),
          Expanded(
            child: _TabPill(
              label: pastLabel,
              isSelected: _selectedTab == 1,
              onTap: () => setState(() {
                _selectedTab = 1;
                _selectedFilter = 0;
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    if (_selectedFilter == 0) return list; // "Todas"

    if (_selectedTab == 0) {
      // Upcoming: 1=Pendientes, 2=Confirmadas
      final targetStatus = _selectedFilter == 1 ? 'pending' : 'confirmed';
      return list
          .where((b) => (b['status'] as String? ?? '') == targetStatus)
          .toList();
    } else {
      // Past: 1=Completadas, 2=Canceladas
      final targetStatus = _selectedFilter == 1 ? 'completed' : 'cancelled';
      return list
          .where((b) => (b['status'] as String? ?? '') == targetStatus)
          .toList();
    }
  }
}

class _FilterChipsRow extends StatelessWidget {
  final int selectedTab;
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;

  const _FilterChipsRow({
    required this.selectedTab,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = selectedTab == 0
        ? ['Todas', 'Pendientes', 'Confirmadas']
        : ['Todas', 'Completadas', 'Canceladas'];

    return Row(
      children: List.generate(labels.length, (index) {
        final isSelected = selectedFilter == index;
        return Padding(
          padding: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () => onFilterChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AtrioColors.guestTextPrimary
                    : AtrioColors.guestSurfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AtrioColors.guestTextPrimary
                      : AtrioColors.guestCardBorder,
                  width: 1,
                ),
              ),
              child: Text(
                labels[index],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AtrioColors.guestBackground
                      : AtrioColors.guestTextSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AtrioColors.neonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : AtrioColors.guestTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
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

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendiente';
      case 'active':
        return 'Activa';
      case 'cancelled':
        return 'Cancelada';
      case 'rejected':
        return 'Rechazada';
      case 'completed':
        return 'Completada';
      default:
        return status;
    }
  }

  IconData _listingTypeIcon(String? type) {
    switch (type) {
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final listing =
        booking['listing'] as Map<String, dynamic>? ?? {};
    final status = booking['status'] as String? ?? 'pending';
    final images = List<String>.from(listing['images'] ?? []);
    final checkIn = DateTime.tryParse(booking['check_in'] ?? '');
    final checkOut = DateTime.tryParse(booking['check_out'] ?? '');
    final totalNum = (booking['total'] as num?) ?? 0;
    final total = totalNum.toCLP;
    final listingType = listing['type'] as String?;

    return GestureDetector(
      onTap: () {
        final bookingId = booking['id']?.toString() ?? '';
        context.push('/booking-detail/$bookingId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AtrioColors.guestCardBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            // Image thumbnail with listing type icon overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                                color: AtrioColors.guestSurfaceVariant),
                            errorWidget: (_, _, _) => Container(
                                color: AtrioColors.guestSurfaceVariant,
                                child: const Icon(Icons.image, size: 28,
                                    color: AtrioColors.guestTextTertiary)),
                          )
                        : Container(
                            color: AtrioColors.guestSurfaceVariant,
                            child: const Icon(Icons.image, size: 28,
                                color: AtrioColors.guestTextTertiary),
                          ),
                  ),
                ),
                // Listing type icon badge
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _listingTypeIcon(listingType),
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge with colored dot
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      listing['title'] ?? 'Reserva',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Dates
                    if (checkIn != null)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13,
                              color: AtrioColors.guestTextTertiary),
                          const SizedBox(width: 4),
                          Text(
                            checkOut != null
                                ? '${_formatDate(checkIn)} - ${_formatDate(checkOut)}'
                                : _formatDate(checkIn),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AtrioColors.guestTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    // Price
                    Text(
                      total,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AtrioColors.guestTextTertiary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  final String message;
  const _EmptyBookings({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AtrioColors.neonLime.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_outlined,
                size: 48, color: AtrioColors.neonLimeDark),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go('/guest/home'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Explorar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
