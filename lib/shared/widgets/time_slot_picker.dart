import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../core/providers/availability_provider.dart';

/// Time slot picker for hourly bookings with real-time availability
class TimeSlotPicker extends ConsumerWidget {
  final String listingId;
  final DateTime selectedDate;
  final String availableFrom; // e.g. '09:00'
  final String availableUntil; // e.g. '22:00'
  final int slotDurationMinutes;
  final Set<String> selectedSlots; // set of 'HH:mm' start times
  final void Function(String startTime, String endTime, bool selected) onSlotToggle;

  const TimeSlotPicker({
    super.key,
    required this.listingId,
    required this.selectedDate,
    this.availableFrom = '09:00',
    this.availableUntil = '22:00',
    this.slotDurationMinutes = 60,
    required this.selectedSlots,
    required this.onSlotToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookedAsync = ref.watch(bookedTimeSlotsProvider(
      TimeSlotsParams(listingId: listingId, date: selectedDate),
    ));

    final slots = _generateSlots();

    return bookedAsync.when(
      data: (bookedSlots) {
        final bookedTimes = <String>{};
        for (final s in bookedSlots) {
          bookedTimes.add(s['start_time']?.toString().substring(0, 5) ?? '');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horarios disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final startStr = slot['start']!;
                final endStr = slot['end']!;
                final isBooked = bookedTimes.contains(startStr);
                final isSelected = selectedSlots.contains(startStr);

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () => onSlotToggle(startStr, endStr, !isSelected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.grey[200]
                          : isSelected
                              ? AtrioColors.neonLime
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isBooked
                            ? Colors.grey[300]!
                            : isSelected
                                ? AtrioColors.neonLime
                                : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$startStr - $endStr',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isBooked
                                ? Colors.grey[400]
                                : isSelected
                                    ? Colors.black
                                    : Colors.black87,
                            decoration: isBooked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (isBooked)
                          Text(
                            'Ocupado',
                            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedSlots.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: AtrioColors.neonLimeDark),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedSlots.length} hora${selectedSlots.length > 1 ? 's' : ''} seleccionada${selectedSlots.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AtrioColors.neonLimeDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error cargando horarios'),
    );
  }

  List<Map<String, String>> _generateSlots() {
    final slots = <Map<String, String>>[];
    final fromParts = availableFrom.split(':');
    final untilParts = availableUntil.split(':');
    var hour = int.parse(fromParts[0]);
    var minute = int.parse(fromParts[1]);
    final endHour = int.parse(untilParts[0]);
    final endMinute = int.parse(untilParts[1]);

    while (hour < endHour || (hour == endHour && minute < endMinute)) {
      final startStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      final nextMinutes = hour * 60 + minute + slotDurationMinutes;
      final nextHour = nextMinutes ~/ 60;
      final nextMin = nextMinutes % 60;
      if (nextHour > endHour || (nextHour == endHour && nextMin > endMinute)) break;
      final endStr = '${nextHour.toString().padLeft(2, '0')}:${nextMin.toString().padLeft(2, '0')}';
      slots.add({'start': startStr, 'end': endStr});
      hour = nextHour;
      minute = nextMin;
    }

    return slots;
  }
}
