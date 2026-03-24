import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../core/providers/availability_provider.dart';
import '../../core/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interactive 3-month availability calendar with real-time sync
class AvailabilityCalendar extends ConsumerStatefulWidget {
  final String listingId;
  final String rentalMode; // 'nights', 'full_day', 'hours'
  final DateTime? selectedCheckIn;
  final DateTime? selectedCheckOut;
  final DateTime? selectedDate; // for hours/full_day
  final void Function(DateTime)? onDateTap;
  final void Function(DateTime, DateTime)? onRangeSelected;
  final bool isHostView;

  const AvailabilityCalendar({
    super.key,
    required this.listingId,
    required this.rentalMode,
    this.selectedCheckIn,
    this.selectedCheckOut,
    this.selectedDate,
    this.onDateTap,
    this.onRangeSelected,
    this.isHostView = false,
  });

  @override
  ConsumerState<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends ConsumerState<AvailabilityCalendar> {
  late DateTime _focusedMonth;
  final Set<String> _bookedDates = {};
  final Set<String> _blockedDates = {};
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _rangeStart = widget.selectedCheckIn;
    _rangeEnd = widget.selectedCheckOut;
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeChannel = RealtimeService.subscribeToAvailability(
      widget.listingId,
      onChange: () {
        // Invalidate provider to refetch
        ref.invalidate(bookedDatesProvider);
      },
    );
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      RealtimeService.unsubscribe(_realtimeChannel!);
    }
    super.dispose();
  }

  bool _isBooked(DateTime date) {
    return _bookedDates.contains(_dateKey(date));
  }

  bool _isBlocked(DateTime date) {
    return _blockedDates.contains(_dateKey(date));
  }

  bool _isUnavailable(DateTime date) {
    return _isBooked(date) || _isBlocked(date) || date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return date.isAfter(_rangeStart!.subtract(const Duration(days: 1))) &&
        date.isBefore(_rangeEnd!.add(const Duration(days: 1)));
  }

  bool _isRangeStart(DateTime date) {
    return _rangeStart != null && _dateKey(date) == _dateKey(_rangeStart!);
  }

  bool _isRangeEnd(DateTime date) {
    return _rangeEnd != null && _dateKey(date) == _dateKey(_rangeEnd!);
  }

  bool _isSelected(DateTime date) {
    if (widget.selectedDate != null && _dateKey(date) == _dateKey(widget.selectedDate!)) return true;
    return _isRangeStart(date) || _isRangeEnd(date);
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _onDayTapped(DateTime date) {
    if (_isUnavailable(date)) return;

    if (widget.rentalMode == 'nights') {
      // Range selection logic
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        setState(() {
          _rangeStart = date;
          _rangeEnd = null;
        });
      } else if (_rangeStart != null && _rangeEnd == null) {
        if (date.isBefore(_rangeStart!)) {
          setState(() {
            _rangeStart = date;
          });
        } else {
          // Check no unavailable dates in between
          bool hasUnavailable = false;
          var check = _rangeStart!.add(const Duration(days: 1));
          while (check.isBefore(date)) {
            if (_isUnavailable(check)) {
              hasUnavailable = true;
              break;
            }
            check = check.add(const Duration(days: 1));
          }
          if (!hasUnavailable) {
            setState(() {
              _rangeEnd = date;
            });
            widget.onRangeSelected?.call(_rangeStart!, date);
          } else {
            setState(() {
              _rangeStart = date;
              _rangeEnd = null;
            });
          }
        }
      }
    } else {
      // Single date selection for hours/full_day
      widget.onDateTap?.call(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final endDate = DateTime(_focusedMonth.year, _focusedMonth.month + 3, 0);

    final bookedAsync = ref.watch(bookedDatesProvider(BookedDatesParams(
      listingId: widget.listingId,
      startDate: startDate,
      endDate: endDate,
    )));

    bookedAsync.whenData((data) {
      _bookedDates.clear();
      _blockedDates.clear();
      for (final d in data) {
        final dateStr = d['booked_date']?.toString() ?? '';
        if (d['is_blocked'] == true) {
          _blockedDates.add(dateStr);
        } else {
          _bookedDates.add(dateStr);
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month navigation
        _buildMonthNav(),
        const SizedBox(height: 8),
        // Day headers
        _buildDayHeaders(),
        const SizedBox(height: 4),
        // Calendar months (scrollable 3 months)
        SizedBox(
          height: 280,
          child: PageView.builder(
            itemCount: 3,
            onPageChanged: (i) {
              setState(() {
                _focusedMonth = DateTime(
                  DateTime.now().year,
                  DateTime.now().month + i,
                  1,
                );
              });
            },
            itemBuilder: (_, i) {
              final month = DateTime(DateTime.now().year, DateTime.now().month + i, 1);
              return _buildMonth(month);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildMonthNav() {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 24),
                onPressed: () {
                  final now = DateTime.now();
                  if (_focusedMonth.month > now.month || _focusedMonth.year > now.year) {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 24),
                onPressed: () {
                  final maxMonth = DateTime(DateTime.now().year, DateTime.now().month + 3, 1);
                  if (_focusedMonth.isBefore(maxMonth)) {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    const days = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
    return Row(
      children: days.map((d) => Expanded(
        child: Center(
          child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
        ),
      )).toList(),
    );
  }

  Widget _buildMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7; // Mon=0
    final totalDays = lastDay.day;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42,
      itemBuilder: (_, index) {
        final dayNum = index - startWeekday + 1;
        if (dayNum < 1 || dayNum > totalDays) {
          return const SizedBox();
        }

        final date = DateTime(month.year, month.month, dayNum);
        final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
        final booked = _isBooked(date);
        final blocked = _isBlocked(date);
        final unavailable = isPast || booked || blocked;
        final selected = _isSelected(date);
        final inRange = _isInRange(date);
        final isStart = _isRangeStart(date);
        final isEnd = _isRangeEnd(date);

        Color bgColor = Colors.transparent;
        Color textColor = Colors.black87;
        BoxDecoration? decoration;

        if (selected) {
          bgColor = AtrioColors.neonLime;
          textColor = Colors.black;
          decoration = BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          );
        } else if (inRange) {
          bgColor = AtrioColors.neonLime.withValues(alpha: 0.15);
          decoration = BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.horizontal(
              left: isStart ? const Radius.circular(20) : Radius.zero,
              right: isEnd ? const Radius.circular(20) : Radius.zero,
            ),
          );
        } else if (booked) {
          textColor = Colors.white;
          decoration = BoxDecoration(
            color: Colors.red[400],
            shape: BoxShape.circle,
          );
        } else if (blocked) {
          decoration = BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          );
          textColor = Colors.grey[500]!;
        } else if (isPast) {
          textColor = Colors.grey[300]!;
        }

        return GestureDetector(
          onTap: unavailable ? null : () => _onDayTapped(date),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: decoration,
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  decoration: unavailable && !booked && !blocked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      children: [
        _legendItem(AtrioColors.neonLime, 'Seleccionado'),
        _legendItem(Colors.red[400]!, 'Reservado'),
        _legendItem(Colors.grey[300]!, 'Bloqueado'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
