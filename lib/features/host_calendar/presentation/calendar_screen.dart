import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  String? _selectedListingId;
  final Set<String> _bookedDates = {};
  final Set<String> _blockedDates = {};
  final Map<String, String> _dateBookingStatus = {};
  final Map<String, String> _dateBookingId = {};
  RealtimeChannel? _channel;
  bool _isLoading = false;
  bool _isRangeMode = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Stats
  int _totalBookings = 0;
  int _blockedCount = 0;

  List<String> _months(AppLocalizations l) => [
    l.calendarMonthJan, l.calendarMonthFeb, l.calendarMonthMar, l.calendarMonthApr,
    l.calendarMonthMay, l.calendarMonthJun, l.calendarMonthJul, l.calendarMonthAug,
    l.calendarMonthSep, l.calendarMonthOct, l.calendarMonthNov, l.calendarMonthDec,
  ];
  List<String> _dayHeaders(AppLocalizations l) => [
    l.calendarDayShortMon, l.calendarDayShortTue, l.calendarDayShortWed,
    l.calendarDayShortThu, l.calendarDayShortFri, l.calendarDayShortSat, l.calendarDayShortSun,
  ];
  List<String> _dayFullNames(AppLocalizations l) => [
    l.calendarDayFullMon, l.calendarDayFullTue, l.calendarDayFullWed,
    l.calendarDayFullThu, l.calendarDayFullFri, l.calendarDayFullSat, l.calendarDayFullSun,
  ];
  List<String> _dayAbbrNames(AppLocalizations l) => [
    l.calendarDayAbbrMon, l.calendarDayAbbrTue, l.calendarDayAbbrWed,
    l.calendarDayAbbrThu, l.calendarDayAbbrFri, l.calendarDayAbbrSat, l.calendarDayAbbrSun,
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  @override
  void dispose() {
    if (_channel != null) RealtimeService.unsubscribe(_channel!);
    super.dispose();
  }

  void _setupRealtime(String listingId) {
    if (_channel != null) RealtimeService.unsubscribe(_channel!);
    _channel = RealtimeService.subscribeToAvailability(
      listingId,
      onChange: () => _loadBookedDates(listingId),
    );
  }

  Future<void> _loadBookedDates(String listingId) async {
    setState(() => _isLoading = true);
    final start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final end = DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0);

    try {
      final data = await DatabaseService.getBookedDates(listingId, start, end);
      if (mounted) {
        setState(() {
          _bookedDates.clear();
          _blockedDates.clear();
          _dateBookingStatus.clear();
          _dateBookingId.clear();
          for (final d in data) {
            final dateStr = d['booked_date']?.toString() ?? '';
            if (d['is_blocked'] == true) {
              _blockedDates.add(dateStr);
            } else {
              _bookedDates.add(dateStr);
              _dateBookingStatus[dateStr] = d['booking_status']?.toString() ?? '';
              if (d['booking_id'] != null) {
                _dateBookingId[dateStr] = d['booking_id'].toString();
              }
            }
          }
          _totalBookings = _bookedDates.length;
          _blockedCount = _blockedDates.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _toggleBlock(DateTime date) async {
    if (_selectedListingId == null) return;
    final key = _dateKey(date);

    if (_bookedDates.contains(key)) {
      _showSnack(AppLocalizations.of(context).calendarCannotBlockBooked);
      return;
    }

    final isCurrentlyBlocked = _blockedDates.contains(key);
    final newIsAvailable = isCurrentlyBlocked; // unblock -> available

    try {
      await DatabaseService.setDateAvailability(
        _selectedListingId!,
        date,
        newIsAvailable,
      );
      setState(() {
        if (isCurrentlyBlocked) {
          _blockedDates.remove(key);
          _blockedCount--;
        } else {
          _blockedDates.add(key);
          _blockedCount++;
        }
      });
    } catch (_) {
      if (mounted) _showSnack(AppLocalizations.of(context).calendarUpdateError);
    }
  }

  Future<void> _blockRange() async {
    if (_selectedListingId == null || _rangeStart == null || _rangeEnd == null) return;

    final start = _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;

    // Check if any date in range has a booking
    var d = start;
    while (!d.isAfter(end)) {
      if (_bookedDates.contains(_dateKey(d))) {
        _showSnack(AppLocalizations.of(context).calendarCannotBlockRangeBooked);
        return;
      }
      d = d.add(const Duration(days: 1));
    }

    setState(() => _isLoading = true);

    try {
      await DatabaseService.setDateRangeAvailability(
        _selectedListingId!,
        start,
        end.add(const Duration(days: 1)),
        false,
      );
      await _loadBookedDates(_selectedListingId!);
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
        _isRangeMode = false;
      });
      if (mounted) _showSnack(AppLocalizations.of(context).calendarDatesBlocked);
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) _showSnack(AppLocalizations.of(context).calendarBlockRangeError);
    }
  }

  Future<void> _unblockRange() async {
    if (_selectedListingId == null || _rangeStart == null || _rangeEnd == null) return;

    final start = _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;

    setState(() => _isLoading = true);

    try {
      await DatabaseService.setDateRangeAvailability(
        _selectedListingId!,
        start,
        end.add(const Duration(days: 1)),
        true,
      );
      await _loadBookedDates(_selectedListingId!);
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
        _isRangeMode = false;
      });
      if (mounted) _showSnack(AppLocalizations.of(context).calendarDatesUnblocked);
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) _showSnack(AppLocalizations.of(context).calendarUnblockRangeError);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.black)),
      backgroundColor: AtrioColors.neonLime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onDayTap(DateTime date) {
    if (_isRangeMode) {
      setState(() {
        if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
          _rangeStart = date;
          _rangeEnd = null;
        } else {
          _rangeEnd = date;
        }
        _selectedDay = null;
      });
    } else {
      setState(() {
        _selectedDay = date;
        _rangeStart = null;
        _rangeEnd = null;
      });
    }
  }

  void _goToToday() {
    setState(() {
      _focusedMonth = DateTime.now();
      _selectedDay = DateTime.now();
    });
    if (_selectedListingId != null) _loadBookedDates(_selectedListingId!);
  }

  void _showDayDetail(DateTime date) {
    final l = AppLocalizations.of(context);
    final key = _dateKey(date);
    final booked = _bookedDates.contains(key);
    final blocked = _blockedDates.contains(key);
    final status = _dateBookingStatus[key] ?? '';
    final bookingId = _dateBookingId[key];
    final dayName = _dayFullNames(l)[date.weekday - 1];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AtrioColors.hostCardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(
              '$dayName ${date.day} de ${_months(l)[date.month - 1]}',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 8),
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: booked
                    ? Colors.green.withValues(alpha: 0.15)
                    : blocked
                        ? Colors.red.withValues(alpha: 0.15)
                        : AtrioColors.neonLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    booked ? Icons.event_available : blocked ? Icons.block : Icons.check_circle_outline,
                    size: 16,
                    color: booked ? Colors.green : blocked ? Colors.red[400] : AtrioColors.neonLimeDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booked
                        ? (status.isNotEmpty ? l.calendarStatusReservedWith(status) : l.calendarStatusReserved)
                        : blocked
                            ? l.calendarStatusBlockedManually
                            : l.calendarStatusAvailable,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: booked ? Colors.green : blocked ? Colors.red[400] : AtrioColors.neonLimeDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            if (booked && bookingId != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/booking-detail/$bookingId');
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(l.calendarViewBooking, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AtrioColors.neonLime,
                    side: BorderSide(color: AtrioColors.neonLime.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (!booked)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleBlock(date);
                  },
                  icon: Icon(blocked ? Icons.lock_open : Icons.block, size: 18),
                  label: Text(
                    blocked ? l.calendarUnblockDay : l.calendarBlockDay,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blocked ? AtrioColors.neonLime : Colors.red[400],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    final start = _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final userId = AuthService.currentUser?.id;
    if (userId == null) {
      return Scaffold(
        backgroundColor: AtrioColors.hostBackground,
        body: Center(child: Text(l.calendarSignIn, style: const TextStyle(color: Colors.white))),
      );
    }

    final listingsAsync = ref.watch(hostListingsProvider(userId));

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return SafeArea(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today, size: 48, color: AtrioColors.hostTextTertiary),
                  const SizedBox(height: 16),
                  Text(l.calendarEmptyMessage, textAlign: TextAlign.center, style: AtrioTypography.bodyMedium.copyWith(color: AtrioColors.hostTextSecondary)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.push('/host/create-listing'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: AtrioColors.neonLime, borderRadius: BorderRadius.circular(12)),
                      child: Text(l.calendarCreateListing, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
                    ),
                  ),
                ]),
              ),
            );
          }

          if (_selectedListingId == null && listings.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedListingId = listings.first['id'] as String);
              _setupRealtime(listings.first['id'] as String);
              _loadBookedDates(listings.first['id'] as String);
            });
          }

          return SafeArea(
            child: Column(
              children: [
                // ─── Header ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Text(l.calendarTitle, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _goToToday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AtrioColors.hostCardBorder),
                          ),
                          child: Text(l.calendarToday, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AtrioColors.neonLime)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Listing selector chips ───
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: listings.length,
                    itemBuilder: (_, i) {
                      final item = listings[i];
                      final id = item['id'] as String;
                      final selected = _selectedListingId == id;
                      final type = item['type'] as String? ?? '';
                      final icon = type == 'space' ? Icons.home_rounded : type == 'experience' ? Icons.explore_rounded : Icons.build_rounded;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedListingId = id;
                              _selectedDay = null;
                              _rangeStart = null;
                              _rangeEnd = null;
                            });
                            _setupRealtime(id);
                            _loadBookedDates(id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AtrioColors.neonLime : AtrioColors.hostSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 14, color: selected ? Colors.black : AtrioColors.hostTextTertiary),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    item['title'] as String? ?? l.calendarNoTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      color: selected ? Colors.black : AtrioColors.hostTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Stats row ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _statChip(Icons.event_available, '$_totalBookings', l.calendarStatReservations, Colors.green),
                      const SizedBox(width: 8),
                      _statChip(Icons.block, '$_blockedCount', l.calendarStatBlocked, Colors.red[400]!),
                      const SizedBox(width: 8),
                      _statChip(
                        Icons.calendar_today,
                        '${_daysInMonth() - _totalBookings - _blockedCount}',
                        l.calendarStatAvailable,
                        AtrioColors.neonLimeDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Mode toggle: single day / range ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AtrioColors.hostSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _modeButton(l.calendarModeDay, !_isRangeMode, () {
                          setState(() {
                            _isRangeMode = false;
                            _rangeStart = null;
                            _rangeEnd = null;
                          });
                        }),
                        _modeButton(l.calendarModeRange, _isRangeMode, () {
                          setState(() {
                            _isRangeMode = true;
                            _selectedDay = null;
                          });
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Month navigation ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1));
                          if (_selectedListingId != null) _loadBookedDates(_selectedListingId!);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                        ),
                      ),
                      Text(
                        '${_months(l)[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1));
                          if (_selectedListingId != null) _loadBookedDates(_selectedListingId!);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ─── Day headers ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _dayHeaders(l).map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AtrioColors.hostTextTertiary)),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 4),

                // ─── Calendar grid ───
                Expanded(
                  child: Stack(
                    children: [
                      _buildCalendarGrid(),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: AtrioColors.hostBackground.withValues(alpha: 0.5),
                            child: const Center(child: CircularProgressIndicator(color: AtrioColors.neonLimeDark, strokeWidth: 2)),
                          ),
                        ),
                    ],
                  ),
                ),

                // ─── Legend ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Row(children: [
                    _legend(Colors.green[400]!, l.calendarLegendReserved),
                    const SizedBox(width: 12),
                    _legend(Colors.red[400]!, l.calendarLegendBlocked),
                    const SizedBox(width: 12),
                    _legend(AtrioColors.hostSurface, l.calendarLegendAvailable),
                    const SizedBox(width: 12),
                    if (_isRangeMode) _legend(AtrioColors.neonLime.withValues(alpha: 0.3), l.calendarLegendSelection),
                  ]),
                ),

                // ─── Action bar ───
                _buildActionBar(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AtrioColors.neonLimeDark, strokeWidth: 2)),
        error: (_, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AtrioColors.hostTextTertiary),
            const SizedBox(height: 12),
            Text(l.calendarLoadError, style: GoogleFonts.inter(color: AtrioColors.hostTextSecondary)),
          ]),
        ),
      ),
    );
  }

  int _daysInMonth() => DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(label, style: GoogleFonts.inter(fontSize: 10, color: AtrioColors.hostTextTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AtrioColors.neonLime : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : AtrioColors.hostTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;
    final totalDays = lastDay.day;
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: 42,
        itemBuilder: (_, index) {
          final dayNum = index - startWeekday + 1;
          if (dayNum < 1 || dayNum > totalDays) return const SizedBox();

          final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
          final key = _dateKey(date);
          final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
          final isToday = key == todayKey;
          final booked = _bookedDates.contains(key);
          final blocked = _blockedDates.contains(key);
          final selected = !_isRangeMode && _selectedDay != null && _dateKey(_selectedDay!) == key;
          final inRange = _isRangeMode && _isInRange(date);
          final isRangeEndpoint = _isRangeMode && ((_rangeStart != null && _dateKey(_rangeStart!) == key) || (_rangeEnd != null && _dateKey(_rangeEnd!) == key));

          Color bgColor = Colors.transparent;
          Color textColor = Colors.white;
          BoxBorder? border;

          if (selected || isRangeEndpoint) {
            bgColor = AtrioColors.neonLime;
            textColor = Colors.black;
          } else if (inRange) {
            bgColor = AtrioColors.neonLime.withValues(alpha: 0.2);
            textColor = AtrioColors.neonLime;
          } else if (booked) {
            bgColor = Colors.green.withValues(alpha: 0.2);
            textColor = Colors.green[300]!;
          } else if (blocked) {
            bgColor = Colors.red.withValues(alpha: 0.15);
            textColor = Colors.red[300]!;
          } else if (isPast) {
            textColor = AtrioColors.hostTextTertiary;
          }

          if (isToday && !selected && !isRangeEndpoint) {
            border = Border.all(color: AtrioColors.neonLimeDark, width: 1.5);
          }

          return GestureDetector(
            onTap: isPast ? null : () => _onDayTap(date),
            onLongPress: isPast ? null : () => _showDayDetail(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: border,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$dayNum',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: (selected || isRangeEndpoint || isToday) ? FontWeight.w700 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (booked && !selected && !isRangeEndpoint)
                      Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(color: Colors.green[400], shape: BoxShape.circle),
                      ),
                    if (blocked && !selected && !isRangeEndpoint)
                      Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar() {
    final l = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (_isRangeMode && _rangeStart != null && _rangeEnd != null) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          border: Border(top: BorderSide(color: AtrioColors.hostCardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _blockRange,
                icon: const Icon(Icons.block, size: 16),
                label: Text(l.calendarBlock, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _unblockRange,
                icon: const Icon(Icons.lock_open, size: 16),
                label: Text(l.calendarUnblock, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtrioColors.neonLime,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isRangeMode && _selectedDay != null) {
      final key = _dateKey(_selectedDay!);
      final booked = _bookedDates.contains(key);
      final blocked = _blockedDates.contains(key);
      final dayName = _dayAbbrNames(l)[_selectedDay!.weekday - 1];

      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          border: Border(top: BorderSide(color: AtrioColors.hostCardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$dayName ${_selectedDay!.day} ${_months(l)[_selectedDay!.month - 1]}',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    booked ? l.calendarStatusReserved : blocked ? l.calendarStatusBlocked : l.calendarStatusAvailable,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: booked ? Colors.green : blocked ? Colors.red[400] : AtrioColors.neonLimeDark,
                    ),
                  ),
                ],
              ),
            ),
            if (!booked)
              ElevatedButton.icon(
                onPressed: () => _toggleBlock(_selectedDay!),
                icon: Icon(blocked ? Icons.lock_open : Icons.block, size: 16),
                label: Text(
                  blocked ? l.calendarUnblock : l.calendarBlock,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blocked ? AtrioColors.neonLime : Colors.red[400],
                  foregroundColor: blocked ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
            if (booked)
              OutlinedButton(
                onPressed: () => _showDayDetail(_selectedDay!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AtrioColors.neonLime,
                  side: BorderSide(color: AtrioColors.neonLime.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(l.calendarViewDetails, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
          ],
        ),
      );
    }

    if (_isRangeMode && (_rangeStart == null || _rangeEnd == null)) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          border: Border(top: BorderSide(color: AtrioColors.hostCardBorder)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AtrioColors.hostTextTertiary),
            const SizedBox(width: 8),
            Text(
              _rangeStart == null ? l.calendarSelectStartDate : l.calendarSelectEndDate,
              style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary),
            ),
          ],
        ),
      );
    }

    return SizedBox(height: bottomPad + 8);
  }

  Widget _legend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: AtrioColors.hostTextSecondary)),
    ]);
  }
}
