import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/bookings_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../config/supabase/supabase_config.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AtrioColors.neonLime;
      case 'pending':
        return AtrioColors.vibrantOrange;
      case 'active':
        return AtrioColors.neonLimeDark;
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'rejected':
        return AtrioColors.error;
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
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'active':
        return Icons.play_circle;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return bookingAsync.when(
      loading: () => Scaffold(
        backgroundColor: AtrioColors.guestBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AtrioColors.guestTextPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AtrioColors.neonLimeDark),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AtrioColors.guestBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AtrioColors.guestTextPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AtrioColors.error),
              const SizedBox(height: 16),
              Text('Error al cargar la reserva',
                  style: AtrioTypography.headingSmall),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(bookingDetailProvider(bookingId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (bookingData) {
        if (bookingData == null) {
          return Scaffold(
            backgroundColor: AtrioColors.guestBackground,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AtrioColors.guestTextPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('Reserva no encontrada')),
          );
        }

        final listing = bookingData['listing'] as Map<String, dynamic>?;
        final host = bookingData['host'] as Map<String, dynamic>?;
        final status = bookingData['status'] as String? ?? 'pending';
        final checkIn = DateTime.tryParse(bookingData['check_in'] ?? '');
        final checkOut = DateTime.tryParse(bookingData['check_out'] ?? '');
        final guestsCount = bookingData['guests_count'] as int? ?? 1;
        final baseTotal = (bookingData['base_total'] as num?)?.toDouble() ?? 0;
        final cleaningFee = (bookingData['cleaning_fee'] as num?)?.toDouble() ?? 0;
        final serviceFee = (bookingData['service_fee'] as num?)?.toDouble() ?? 0;
        final total = (bookingData['total'] as num?)?.toDouble() ?? 0;
        final listingTitle = listing?['title'] as String? ?? 'Reserva';
        final listingCity = listing?['city'] as String? ?? '';
        final listingRating = (listing?['rating'] as num?)?.toDouble() ?? 0;
        final listingImages = List<String>.from(listing?['images'] ?? []);
        final listingBasePrice = (listing?['base_price'] as num?)?.toDouble() ?? 0;
        final listingPriceUnit = listing?['price_unit'] as String? ?? 'night';
        final hostName = host?['display_name'] as String? ?? 'Anfitrión';
        final hostPhoto = host?['photo_url'] as String?;
        final hostVerified = host?['is_verified'] as bool? ?? false;
        final conversationId = bookingData['conversation_id'] as String?;
        final hostId = bookingData['host_id'] as String?;
        final listingId = bookingData['listing_id'] as String?;

        int nights = 0;
        if (checkIn != null && checkOut != null) {
          nights = checkOut.difference(checkIn).inDays;
          if (nights <= 0) nights = 1;
        }

        final dateFormat = DateFormat('dd MMM', 'es');
        final timeFormat = DateFormat('h:mm a');

        final statusColor = _statusColor(status);
        final statusTextColor = status == 'confirmed' ? Colors.black : Colors.white;

        return Scaffold(
          backgroundColor: AtrioColors.guestBackground,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AtrioColors.guestBackground,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (listingImages.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: listingImages.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: AtrioColors.neonLimeDark.withValues(alpha: 0.3),
                          ),
                          errorWidget: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AtrioColors.neonLimeDark,
                                  AtrioColors.neonLimeDark.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                            child: const Icon(Icons.image, size: 64, color: Colors.white24),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AtrioColors.neonLimeDark,
                                AtrioColors.neonLimeDark.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: const Icon(Icons.image, size: 64, color: Colors.white24),
                        ),
                      // Dark gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Status overlay
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_statusIcon(status), size: 14, color: statusTextColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    _statusLabel(status),
                                    style: AtrioTypography.caption.copyWith(
                                      color: statusTextColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '#${bookingId.length >= 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}',
                              style: AtrioTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Listing Info
                      Text(
                        listingTitle,
                        style: AtrioTypography.headingMedium.copyWith(
                          color: AtrioColors.guestTextPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (listingCity.isNotEmpty) ...[
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: AtrioColors.guestTextSecondary),
                            const SizedBox(width: 4),
                            Text(
                              listingCity,
                              style: AtrioTypography.bodySmall.copyWith(
                                color: AtrioColors.guestTextSecondary,
                              ),
                            ),
                          ],
                          if (listingRating > 0) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFFFB800)),
                            const SizedBox(width: 4),
                            Text(
                              listingRating.toStringAsFixed(1),
                              style: AtrioTypography.bodySmall.copyWith(
                                color: AtrioColors.guestTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Date Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _DateBlock(
                                    label: 'ENTRADA',
                                    date: checkIn != null ? dateFormat.format(checkIn) : '--',
                                    time: checkIn != null ? timeFormat.format(checkIn) : '--',
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AtrioColors.neonLimeDark.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: AtrioColors.neonLimeDark,
                                  ),
                                ),
                                Expanded(
                                  child: _DateBlock(
                                    label: 'SALIDA',
                                    date: checkOut != null ? dateFormat.format(checkOut) : '--',
                                    time: checkOut != null ? timeFormat.format(checkOut) : '--',
                                    isEnd: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AtrioColors.guestBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _InfoChip(
                                    icon: Icons.nights_stay_outlined,
                                    label: '$nights ${nights == 1 ? 'noche' : 'noches'}',
                                  ),
                                  _InfoChip(
                                    icon: Icons.people_outline,
                                    label: '$guestsCount ${guestsCount == 1 ? 'huésped' : 'huéspedes'}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Host Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AtrioColors.neonLimeDark.withValues(alpha: 0.15),
                              backgroundImage: hostPhoto != null
                                  ? CachedNetworkImageProvider(hostPhoto)
                                  : null,
                              child: hostPhoto == null
                                  ? const Icon(Icons.person, color: AtrioColors.neonLimeDark)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        hostName,
                                        style: AtrioTypography.labelLarge.copyWith(
                                          color: AtrioColors.guestTextPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (hostVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified,
                                            size: 16, color: AtrioColors.neonLimeDark),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    'Anfitrión',
                                    style: AtrioTypography.bodySmall.copyWith(
                                      color: AtrioColors.guestTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final currentUserId = SupabaseConfig.auth.currentUser?.id;
                                if (currentUserId == null || hostId == null) return;

                                if (conversationId != null) {
                                  context.push('/chat/$conversationId');
                                } else {
                                  final convo = await DatabaseService.getOrCreateConversation(
                                    userId1: currentUserId,
                                    userId2: hostId,
                                    listingId: listingId,
                                    bookingId: bookingId,
                                  );
                                  if (context.mounted) {
                                    context.push('/chat/${convo['id']}');
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AtrioColors.neonLimeDark.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.chat_outlined,
                                  color: AtrioColors.neonLimeDark,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Price Breakdown
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Desglose de Precio',
                              style: AtrioTypography.labelLarge.copyWith(
                                color: AtrioColors.guestTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PriceRow(
                              label: '\$${listingBasePrice.toStringAsFixed(2)} x $nights $listingPriceUnit${nights != 1 ? 's' : ''}',
                              value: '\$${baseTotal.toStringAsFixed(2)}',
                            ),
                            if (cleaningFee > 0)
                              _PriceRow(
                                label: 'Tarifa de limpieza',
                                value: '\$${cleaningFee.toStringAsFixed(2)}',
                              ),
                            if (serviceFee > 0)
                              _PriceRow(
                                label: 'Tarifa de servicio Atrio',
                                value: '\$${serviceFee.toStringAsFixed(2)}',
                              ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: AtrioTypography.headingSmall.copyWith(
                                    color: AtrioColors.guestTextPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)} USD',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AtrioColors.neonLimeDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Policies
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Políticas',
                              style: AtrioTypography.labelLarge.copyWith(
                                color: AtrioColors.guestTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const _PolicyItem(
                              icon: Icons.cancel_outlined,
                              title: 'Cancelación flexible',
                              subtitle: 'Cancelación gratuita hasta 24h antes de la entrada',
                            ),
                            const SizedBox(height: 12),
                            const _PolicyItem(
                              icon: Icons.smoke_free,
                              title: 'No fumar',
                              subtitle: 'Prohibido fumar dentro del espacio',
                            ),
                            const SizedBox(height: 12),
                            _PolicyItem(
                              icon: Icons.access_time,
                              title: 'Horarios',
                              subtitle: checkIn != null && checkOut != null
                                  ? 'Entrada: ${timeFormat.format(checkIn)} • Salida: ${timeFormat.format(checkOut)}'
                                  : 'Consultar con el anfitrión',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      if (status == 'pending' || status == 'confirmed' || status == 'active')
                        Column(
                          children: [
                            // Contact host button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final currentUserId = SupabaseConfig.auth.currentUser?.id;
                                  if (currentUserId == null || hostId == null) return;

                                  if (conversationId != null) {
                                    context.push('/chat/$conversationId');
                                  } else {
                                    final convo = await DatabaseService.getOrCreateConversation(
                                      userId1: currentUserId,
                                      userId2: hostId,
                                      listingId: listingId,
                                      bookingId: bookingId,
                                    );
                                    if (context.mounted) {
                                      context.push('/chat/${convo['id']}');
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AtrioColors.neonLime,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.chat_outlined, size: 18),
                                label: const Text('Contactar Anfitrion'),
                              ),
                            ),
                            if (status != 'active') ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final confirm = await showModalBottomSheet<bool>(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: AtrioColors.error.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.warning_amber_rounded, size: 40, color: AtrioColors.error),
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              'Cancelar Reserva',
                                              style: GoogleFonts.roboto(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: AtrioColors.guestTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Esta accion no se puede deshacer. Si cancelas, perderas tu reserva en "$listingTitle".',
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                color: AtrioColors.guestTextSecondary,
                                                height: 1.4,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.info_outline, size: 16, color: AtrioColors.guestTextSecondary),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Cancelacion gratuita hasta 24h antes de la entrada',
                                                      style: GoogleFonts.roboto(fontSize: 12, color: AtrioColors.guestTextSecondary),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AtrioColors.error,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  elevation: 0,
                                                ),
                                                child: Text('Si, cancelar reserva', style: GoogleFonts.roboto(fontWeight: FontWeight.w700, fontSize: 15)),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                ),
                                                child: Text('No, mantener reserva', style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 15, color: AtrioColors.guestTextPrimary)),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                    );
                                    if (confirm == true) {
                                      await DatabaseService.updateBookingStatus(bookingId, 'cancelled');
                                      ref.invalidate(bookingDetailProvider(bookingId));
                                      ref.invalidate(guestBookingsProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                                const SizedBox(width: 8),
                                                const Text('Reserva cancelada correctamente'),
                                              ],
                                            ),
                                            backgroundColor: AtrioColors.guestTextPrimary,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AtrioColors.error,
                                    side: BorderSide(color: AtrioColors.error.withValues(alpha: 0.3)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text('Cancelar reserva', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ],
                        ),

                      // Write review button for completed bookings
                      if (status == 'completed')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.push('/write-review', extra: {
                                  'bookingId': bookingId,
                                  'listingId': listingId ?? '',
                                  'hostId': hostId ?? '',
                                  'listingTitle': listingTitle,
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AtrioColors.neonLimeDark,
                                side: BorderSide(color: AtrioColors.neonLime.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.star_rounded, size: 18),
                              label: const Text('Escribir Resena'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String label;
  final String date;
  final String time;
  final bool isEnd;

  const _DateBlock({
    required this.label,
    required this.date,
    required this.time,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AtrioColors.neonLimeDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          date,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextPrimary,
          ),
        ),
        Text(
          time,
          style: AtrioTypography.bodySmall.copyWith(
            color: AtrioColors.guestTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AtrioColors.guestTextSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AtrioTypography.caption.copyWith(
            color: AtrioColors.guestTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AtrioTypography.bodyMedium.copyWith(
              color: AtrioColors.guestTextSecondary,
            ),
          ),
          Text(
            value,
            style: AtrioTypography.bodyMedium.copyWith(
              color: AtrioColors.guestTextPrimary,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PolicyItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AtrioColors.guestBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AtrioColors.guestTextSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AtrioTypography.labelMedium.copyWith(
                  color: AtrioColors.guestTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AtrioTypography.caption.copyWith(
                  color: AtrioColors.guestTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
