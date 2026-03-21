import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  final Set<String> _blockedDays = {};

  // Mock bookings: day key -> list of time slot data
  final Map<String, List<_TimeSlot>> _mockBookings = {};

  static const List<String> _mesesNombres = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const List<String> _diasSemana = [
    'DOM',
    'LUN',
    'MAR',
    'MIÉ',
    'JUE',
    'VIE',
    'SÁB',
  ];

  static const List<String> _diasNombresLargos = [
    'Dom',
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    // Add some mock bookings for demo
    final bookingDay1 = DateTime(now.year, now.month, 5);
    final bookingDay2 = DateTime(now.year, now.month, 12);
    final bookingDay3 = DateTime(now.year, now.month, 20);

    _mockBookings[_dayKey(bookingDay1)] = [
      _TimeSlot(hora: '09:00', estado: _SlotEstado.disponible),
      _TimeSlot(
          hora: '10:00',
          estado: _SlotEstado.reservado,
          nombreCliente: 'Alex'),
      _TimeSlot(hora: '11:00', estado: _SlotEstado.disponible),
    ];
    _mockBookings[_dayKey(bookingDay2)] = [
      _TimeSlot(hora: '09:00', estado: _SlotEstado.disponible),
      _TimeSlot(
          hora: '10:00',
          estado: _SlotEstado.reservado,
          nombreCliente: 'María'),
      _TimeSlot(
          hora: '11:00',
          estado: _SlotEstado.reservado,
          nombreCliente: 'Carlos'),
      _TimeSlot(hora: '12:00', estado: _SlotEstado.disponible),
    ];
    _mockBookings[_dayKey(bookingDay3)] = [
      _TimeSlot(hora: '14:00', estado: _SlotEstado.disponible),
      _TimeSlot(
          hora: '15:00',
          estado: _SlotEstado.reservado,
          nombreCliente: 'Laura'),
      _TimeSlot(hora: '16:00', estado: _SlotEstado.disponible),
    ];

    // Block a couple of days
    _blockedDays.add(_dayKey(DateTime(now.year, now.month, 8)));
    _blockedDays.add(_dayKey(DateTime(now.year, now.month, 9)));
  }

  String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  void _previousMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDay = null;
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  void _toggleBlockDay(DateTime day) {
    final key = _dayKey(day);
    setState(() {
      if (_blockedDays.contains(key)) {
        _blockedDays.remove(key);
      } else {
        _blockedDays.add(key);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cambios guardados',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w100,
            color: Colors.black,
          ),
        ),
        backgroundColor: AtrioColors.neonLime,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPremiumPricingSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AtrioColors.hostSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AtrioColors.hostTextTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Precio Premium',
              style: AtrioTypography.headingMedium.copyWith(
                color: AtrioColors.hostTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Establece un precio especial para este día',
              style: AtrioTypography.bodyMedium.copyWith(
                color: AtrioColors.hostTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AtrioTypography.bodyLarge.copyWith(
                color: AtrioColors.hostTextPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: AtrioTypography.priceMedium.copyWith(
                  color: AtrioColors.neonLime,
                ),
                hintText: 'Ingresa el precio',
                hintStyle: AtrioTypography.bodyLarge.copyWith(
                  color: AtrioColors.hostTextTertiary,
                ),
                filled: true,
                fillColor: AtrioColors.hostSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AtrioColors.neonLime, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Precio premium aplicado',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w100,
                          color: AtrioColors.hostBackground,
                        ),
                      ),
                      backgroundColor: AtrioColors.neonLime,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtrioColors.neonLime,
                  foregroundColor: AtrioColors.hostBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Aplicar Precio',
                  style: AtrioTypography.buttonLarge.copyWith(
                    color: AtrioColors.hostBackground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasBookings(DateTime day) {
    return _mockBookings.containsKey(_dayKey(day));
  }

  bool _isBlocked(DateTime day) {
    return _blockedDays.contains(_dayKey(day));
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  bool _isPast(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isBefore(today);
  }

  bool _isSelected(DateTime day) {
    if (_selectedDay == null) return false;
    return day.year == _selectedDay!.year &&
        day.month == _selectedDay!.month &&
        day.day == _selectedDay!.day;
  }

  List<DateTime> _daysInMonth() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    // Pad start: weekday 1=Mon ... 7=Sun. We want Sunday=0.
    int startWeekday = firstDay.weekday % 7; // Sun=0, Mon=1, ..., Sat=6

    final days = <DateTime>[];

    // Padding before
    for (int i = 0; i < startWeekday; i++) {
      days.add(
          DateTime(year, month, 1 - startWeekday + i)); // days from prev month
    }

    // Actual days
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(year, month, d));
    }

    // Padding after to complete the grid (multiple of 7)
    while (days.length % 7 != 0) {
      days.add(DateTime(year, month + 1, days.length - startWeekday - lastDay.day + 1));
    }

    return days;
  }

  String _formatSelectedDay() {
    if (_selectedDay == null) return '';
    final dayName =
        _diasNombresLargos[_selectedDay!.weekday % 7];
    final mesNombre =
        _mesesNombres[_selectedDay!.month - 1].substring(0, 3);
    return '$dayName, $mesNombre ${_selectedDay!.day}';
  }

  List<_TimeSlot> _slotsForSelectedDay() {
    if (_selectedDay == null) return [];
    final key = _dayKey(_selectedDay!);
    return _mockBookings[key] ??
        [
          _TimeSlot(hora: '09:00', estado: _SlotEstado.disponible),
          _TimeSlot(hora: '10:00', estado: _SlotEstado.disponible),
          _TimeSlot(hora: '11:00', estado: _SlotEstado.disponible),
        ];
  }

  int _availableCount() {
    final slots = _slotsForSelectedDay();
    return slots.where((s) => s.estado == _SlotEstado.disponible).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),
            // Month navigation
            _buildMonthNav(),
            const SizedBox(height: 16),
            // Calendar grid
            Expanded(
              child: _selectedDay != null
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCalendarGrid(),
                          const SizedBox(height: 8),
                          _buildDayDetailPanel(),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: _buildCalendarGrid(),
                    ),
            ),
            // Bottom padding for floating nav
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AtrioColors.hostTextPrimary, size: 22),
          ),
          Expanded(
            child: Text(
              'Gestionar Disponibilidad',
              style: AtrioTypography.headingSmall.copyWith(
                color: AtrioColors.hostTextPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                backgroundColor: Color(0xFFD4FF00),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: Duration(seconds: 1),
              ));
            },
            icon: const Icon(Icons.tune_rounded,
                color: AtrioColors.hostTextSecondary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    final mesNombre = _mesesNombres[_focusedMonth.month - 1];
    final anio = _focusedMonth.year;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AtrioColors.hostSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AtrioColors.hostTextPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$mesNombre $anio',
            style: AtrioTypography.headingMedium.copyWith(
              color: AtrioColors.hostTextPrimary,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _nextMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AtrioColors.hostSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AtrioColors.hostTextPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _daysInMonth();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day headers
          Row(
            children: _diasSemana
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AtrioTypography.labelSmall.copyWith(
                            color: AtrioColors.hostTextTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Day cells
          ...List.generate((days.length / 7).ceil(), (weekIndex) {
            final weekDays = days.skip(weekIndex * 7).take(7).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: weekDays.map((day) {
                  final isCurrentMonth = day.month == _focusedMonth.month;
                  return Expanded(child: _buildDayCell(day, isCurrentMonth));
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isCurrentMonth) {
    if (!isCurrentMonth) {
      return const SizedBox(height: 48);
    }

    final selected = _isSelected(day);
    final today = _isToday(day);
    final past = _isPast(day);
    final blocked = _isBlocked(day);
    final hasBooking = _hasBookings(day);

    Color bgColor;
    Color textColor;
    BoxBorder? border;
    Widget? overlay;

    if (selected || today) {
      bgColor = AtrioColors.neonLime;
      textColor = AtrioColors.hostBackground;
    } else if (blocked) {
      bgColor = AtrioColors.hostSurfaceVariant;
      textColor = AtrioColors.hostTextTertiary;
    } else if (past) {
      bgColor = Colors.transparent;
      textColor = AtrioColors.hostTextTertiary.withValues(alpha: 0.5);
    } else {
      bgColor = Colors.transparent;
      textColor = AtrioColors.hostTextPrimary;
    }

    if (hasBooking && !selected && !today) {
      border = Border.all(
        color: AtrioColors.neonLime.withValues(alpha: 0.5),
        width: 1.5,
      );
    }

    if (blocked && !selected) {
      overlay = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _DiagonalStripePainter(),
          size: const Size(44, 44),
        ),
      );
    }

    return GestureDetector(
      onTap: past ? null : () => _selectDay(day),
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: border,
              ),
            ),
            if (overlay != null)
              SizedBox(width: 44, height: 44, child: overlay),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight:
                        (selected || today) ? FontWeight.w700 : FontWeight.w100,
                    color: textColor,
                  ),
                ),
                if (hasBooking || blocked)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (selected || today)
                          ? AtrioColors.hostBackground.withValues(alpha: 0.6)
                          : blocked
                              ? AtrioColors.hostTextTertiary
                              : AtrioColors.neonLime,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetailPanel() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final slots = _slotsForSelectedDay();
    final available = _availableCount();
    final isBlockedDay = _isBlocked(_selectedDay!);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AtrioColors.hostCardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day title row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatSelectedDay(),
                      style: AtrioTypography.headingMedium.copyWith(
                        color: AtrioColors.hostTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$available espacios disponibles',
                      style: AtrioTypography.bodyMedium.copyWith(
                        color: AtrioColors.hostTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                    backgroundColor: Color(0xFFD4FF00),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: Duration(seconds: 1),
                  ));
                },
                icon: const Icon(Icons.edit_rounded,
                    color: AtrioColors.hostTextSecondary, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AtrioColors.hostSurfaceVariant,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _selectedDay = null),
                icon: const Icon(Icons.close_rounded,
                    color: AtrioColors.hostTextSecondary, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AtrioColors.hostSurfaceVariant,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action pills
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleBlockDay(_selectedDay!),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isBlockedDay
                          ? AtrioColors.neonLime.withValues(alpha: 0.3)
                          : AtrioColors.neonLime,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isBlockedDay ? 'Desbloquear dia' : 'Bloquear dia',
                      style: AtrioTypography.buttonMedium.copyWith(
                        color: AtrioColors.hostBackground,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _showPremiumPricingSheet,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AtrioColors.hostSurfaceVariant,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AtrioColors.hostTextTertiary.withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Precio Premium',
                      style: AtrioTypography.buttonMedium.copyWith(
                        color: AtrioColors.hostTextPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Time slots
          ...slots.map((slot) => _buildTimeSlotRow(slot)),
        ],
      ),
    );
  }

  Widget _buildTimeSlotRow(_TimeSlot slot) {
    final isReservado = slot.estado == _SlotEstado.reservado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReservado
                  ? AtrioColors.neonLime
                  : Colors.transparent,
              border: Border.all(
                color: isReservado
                    ? AtrioColors.neonLime
                    : AtrioColors.hostTextTertiary,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Time and status text
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: slot.hora,
                    style: AtrioTypography.labelMedium.copyWith(
                      color: AtrioColors.hostTextPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' — ',
                    style: AtrioTypography.bodyMedium.copyWith(
                      color: AtrioColors.hostTextTertiary,
                    ),
                  ),
                  TextSpan(
                    text: isReservado
                        ? 'Reservado por ${slot.nombreCliente}'
                        : 'Disponible',
                    style: AtrioTypography.bodyMedium.copyWith(
                      color: isReservado
                          ? AtrioColors.hostTextPrimary
                          : AtrioColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isReservado) ...[
            // Avatar placeholder
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AtrioColors.neonLimeDark.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Text(
                  slot.nombreCliente?.substring(0, 1) ?? 'U',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.neonLime,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.info_outline_rounded,
                color: AtrioColors.hostTextTertiary, size: 18),
          ],
        ],
      ),
    );
  }
}

// === Helper models ===

enum _SlotEstado { disponible, reservado }

class _TimeSlot {
  final String hora;
  final _SlotEstado estado;
  final String? nombreCliente;

  _TimeSlot({
    required this.hora,
    required this.estado,
    this.nombreCliente,
  });
}

// === Diagonal stripe painter for blocked days ===

class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtrioColors.hostTextTertiary.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const spacing = 7.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
