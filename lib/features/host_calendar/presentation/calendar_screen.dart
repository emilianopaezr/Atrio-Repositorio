import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../l10n/app_localizations.dart';

/// Calendar — minimalist redesign.
///
/// Editorial principles:
///   1. The grid is the hero. Headers, toggles and status bars are
///      reduced to the bare minimum so the dates breathe.
///   2. State is conveyed by tinted cell backgrounds + numeral color.
///      No dots, no badges, no extra chrome inside the cells.
///   3. Lime is reserved for active states (today / selected / range
///      endpoints). Booked and blocked use desaturated tints.
///   4. The action bar mounts only when there is something to do.
///
/// All functionality from the previous version is preserved:
/// listing pill picker, month nav, Today shortcut, Day/Range mode
/// toggle, single-day tap → select, long-press → detail sheet,
/// range selection with Block / Unblock, realtime updates.
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

  // ─── Locale helpers ──────────────────────────────────────────────
  List<String> _months(AppLocalizations l) => [
        l.calendarMonthJan, l.calendarMonthFeb, l.calendarMonthMar,
        l.calendarMonthApr, l.calendarMonthMay, l.calendarMonthJun,
        l.calendarMonthJul, l.calendarMonthAug, l.calendarMonthSep,
        l.calendarMonthOct, l.calendarMonthNov, l.calendarMonthDec,
      ];
  List<String> _dayHeaders(AppLocalizations l) => [
        l.calendarDayShortMon, l.calendarDayShortTue, l.calendarDayShortWed,
        l.calendarDayShortThu, l.calendarDayShortFri, l.calendarDayShortSat,
        l.calendarDayShortSun,
      ];
  List<String> _dayFullNames(AppLocalizations l) => [
        l.calendarDayFullMon, l.calendarDayFullTue, l.calendarDayFullWed,
        l.calendarDayFullThu, l.calendarDayFullFri, l.calendarDayFullSat,
        l.calendarDayFullSun,
      ];
  List<String> _dayAbbrNames(AppLocalizations l) => [
        l.calendarDayAbbrMon, l.calendarDayAbbrTue, l.calendarDayAbbrWed,
        l.calendarDayAbbrThu, l.calendarDayAbbrFri, l.calendarDayAbbrSat,
        l.calendarDayAbbrSun,
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

  // ─── Realtime + data load ────────────────────────────────────────
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
              _dateBookingStatus[dateStr] =
                  d['booking_status']?.toString() ?? '';
              if (d['booking_id'] != null) {
                _dateBookingId[dateStr] = d['booking_id'].toString();
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─── Block / unblock mutations ───────────────────────────────────
  Future<void> _toggleBlock(DateTime date) async {
    if (_selectedListingId == null) return;
    final key = _dateKey(date);

    if (_bookedDates.contains(key)) {
      _showSnack(AppLocalizations.of(context).calendarCannotBlockBooked);
      return;
    }

    final isCurrentlyBlocked = _blockedDates.contains(key);
    final newIsAvailable = isCurrentlyBlocked; // unblock → available

    try {
      await DatabaseService.setDateAvailability(
        _selectedListingId!,
        date,
        newIsAvailable,
      );
      setState(() {
        if (isCurrentlyBlocked) {
          _blockedDates.remove(key);
        } else {
          _blockedDates.add(key);
        }
      });
    } catch (_) {
      if (mounted) _showSnack(AppLocalizations.of(context).calendarUpdateError);
    }
  }

  Future<void> _blockRange() async {
    if (_selectedListingId == null ||
        _rangeStart == null ||
        _rangeEnd == null) {
      return;
    }

    final start =
        _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;

    var d = start;
    while (!d.isAfter(end)) {
      if (_bookedDates.contains(_dateKey(d))) {
        _showSnack(
            AppLocalizations.of(context).calendarCannotBlockRangeBooked);
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
      if (mounted) {
        _showSnack(AppLocalizations.of(context).calendarDatesBlocked);
      }
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack(AppLocalizations.of(context).calendarBlockRangeError);
      }
    }
  }

  Future<void> _unblockRange() async {
    if (_selectedListingId == null ||
        _rangeStart == null ||
        _rangeEnd == null) {
      return;
    }

    final start =
        _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
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
      if (mounted) {
        _showSnack(AppLocalizations.of(context).calendarDatesUnblocked);
      }
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack(AppLocalizations.of(context).calendarUnblockRangeError);
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
              GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white)),
      backgroundColor: const Color(0xFF1A1A1C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── User interactions ───────────────────────────────────────────
  void _onDayTap(DateTime date) {
    HapticFeedback.selectionClick();
    if (_isRangeMode) {
      setState(() {
        if (_rangeStart == null ||
            (_rangeStart != null && _rangeEnd != null)) {
          _rangeStart = date;
          _rangeEnd = null;
        } else {
          _rangeEnd = date;
        }
        _selectedDay = null;
      });
    } else {
      final tappedSame = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;
      setState(() {
        _selectedDay = tappedSame ? null : date;
        _rangeStart = null;
        _rangeEnd = null;
      });
    }
  }

  void _clearSelection() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDay = null;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _goToToday() {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime.now();
      _selectedDay = DateTime.now();
    });
    if (_selectedListingId != null) _loadBookedDates(_selectedListingId!);
  }

  void _showDayDetail(DateTime date) {
    HapticFeedback.selectionClick();
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
      useRootNavigator: true,
      useSafeArea: true,
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
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '$dayName ${date.day} ${_months(l)[date.month - 1]}',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: booked
                        ? const Color(0xFF4ADE80)
                        : blocked
                            ? const Color(0xFFFCA5A5)
                            : AtrioColors.neonLimeDark,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  booked
                      ? (status.isNotEmpty
                          ? l.calendarStatusReservedWith(status)
                          : l.calendarStatusReserved)
                      : blocked
                          ? l.calendarStatusBlockedManually
                          : l.calendarStatusAvailable,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: booked
                        ? const Color(0xFF4ADE80)
                        : blocked
                            ? const Color(0xFFFCA5A5)
                            : AtrioColors.hostTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (booked && bookingId != null)
              _SheetButton(
                icon: Icons.arrow_forward_rounded,
                label: l.calendarViewBooking,
                background: AtrioColors.neonLime,
                foreground: Colors.black,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/booking-detail/$bookingId');
                },
              ),
            if (!booked)
              _SheetButton(
                icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                label: blocked ? l.calendarUnblockDay : l.calendarBlockDay,
                background: blocked
                    ? AtrioColors.neonLime
                    : const Color(0xFFEF4444),
                foreground: blocked ? Colors.black : Colors.white,
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleBlock(date);
                },
              ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    final start =
        _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  // ═════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final userId = AuthService.currentUser?.id;
    if (userId == null) {
      return Scaffold(
        backgroundColor: AtrioColors.hostBackground,
        body: Center(
          child: Text(l.calendarSignIn,
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final listingsAsync = ref.watch(hostListingsProvider(userId));

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) return _emptyState(l);

          // Auto-select the first listing on first render.
          if (_selectedListingId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(
                  () => _selectedListingId = listings.first['id'] as String);
              _setupRealtime(listings.first['id'] as String);
              _loadBookedDates(listings.first['id'] as String);
            });
          }

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(l),
                const SizedBox(height: 14),
                _listingPicker(l, listings),
                const SizedBox(height: 22),
                _monthNav(l),
                const SizedBox(height: 14),
                _modeToggle(l),
                const SizedBox(height: 18),
                _dayHeadersRow(l),
                const SizedBox(height: 4),
                Expanded(
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (ctx, c) {
                          final gridWidth = c.maxWidth - 48;
                          final cellWidth = gridWidth / 7;
                          final cellHeight = c.maxHeight / 6;
                          final aspect = cellHeight <= 0
                              ? 1.0
                              : (cellWidth / cellHeight)
                                  .clamp(0.85, 1.6)
                                  .toDouble();
                          return _buildCalendarGrid(aspect);
                        },
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: AtrioColors.hostBackground
                                .withValues(alpha: 0.5),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AtrioColors.neonLimeDark,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildActionBar(l),
                SizedBox(
                  height: 72 + MediaQuery.of(context).viewPadding.bottom,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AtrioColors.neonLimeDark, strokeWidth: 2),
        ),
        error: (_, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                size: 48, color: AtrioColors.hostTextTertiary),
            const SizedBox(height: 12),
            Text(l.calendarLoadError,
                style:
                    GoogleFonts.inter(color: AtrioColors.hostTextSecondary)),
          ]),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────
  Widget _header(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.calendarTitle,
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
                height: 1.05,
              ),
            ),
          ),
          GestureDetector(
            onTap: _goToToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l.calendarToday,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Listing picker (horizontal pills) ───────────────────────────
  Widget _listingPicker(AppLocalizations l, List<Map<String, dynamic>> listings) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: listings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = listings[i];
          final id = item['id'] as String;
          final selected = _selectedListingId == id;
          return _ListingPill(
            label: item['title'] as String? ?? l.calendarNoTitle,
            selected: selected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedListingId = id;
                _selectedDay = null;
                _rangeStart = null;
                _rangeEnd = null;
              });
              _setupRealtime(id);
              _loadBookedDates(id);
            },
          );
        },
      ),
    );
  }

  // ─── Month nav (subtle arrows + bold month name) ─────────────────
  Widget _monthNav(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _focusedMonth = DateTime(
                  _focusedMonth.year, _focusedMonth.month - 1, 1));
              if (_selectedListingId != null) {
                _loadBookedDates(_selectedListingId!);
              }
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_months(l)[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _focusedMonth = DateTime(
                  _focusedMonth.year, _focusedMonth.month + 1, 1));
              if (_selectedListingId != null) {
                _loadBookedDates(_selectedListingId!);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Day / Range mode toggle ─────────────────────────────────────
  Widget _modeToggle(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _ModeToggle(
        dayLabel: l.calendarModeDay,
        rangeLabel: l.calendarModeRange,
        isRangeMode: _isRangeMode,
        onTapDay: () {
          HapticFeedback.selectionClick();
          setState(() {
            _isRangeMode = false;
            _rangeStart = null;
            _rangeEnd = null;
          });
        },
        onTapRange: () {
          HapticFeedback.selectionClick();
          setState(() {
            _isRangeMode = true;
            _selectedDay = null;
          });
        },
      ),
    );
  }

  // ─── Weekday headers (Mo Tu We Th Fr Sa Su) ──────────────────────
  Widget _dayHeadersRow(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _dayHeaders(l)
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.hostTextTertiary,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── Calendar grid ───────────────────────────────────────────────
  Widget _buildCalendarGrid(double aspectRatio) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;
    final totalDays = lastDay.day;
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: aspectRatio,
        ),
        itemCount: 42,
        itemBuilder: (_, index) {
          final dayNum = index - startWeekday + 1;
          if (dayNum < 1 || dayNum > totalDays) return const SizedBox();

          final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
          final key = _dateKey(date);
          final isPast =
              date.isBefore(DateTime(today.year, today.month, today.day));
          final isToday = key == todayKey;
          final booked = _bookedDates.contains(key);
          final blocked = _blockedDates.contains(key);
          final selected = !_isRangeMode &&
              _selectedDay != null &&
              _dateKey(_selectedDay!) == key;
          final inRange = _isRangeMode && _isInRange(date);
          final isRangeEndpoint = _isRangeMode &&
              ((_rangeStart != null && _dateKey(_rangeStart!) == key) ||
                  (_rangeEnd != null && _dateKey(_rangeEnd!) == key));

          // ─── Resolve visual state (single source of truth) ───
          Color bg = Colors.transparent;
          Color textColor = Colors.white;
          BoxBorder? border;
          FontWeight weight = FontWeight.w500;

          if (selected || isRangeEndpoint) {
            bg = AtrioColors.neonLime;
            textColor = Colors.black;
            weight = FontWeight.w800;
          } else if (inRange) {
            bg = AtrioColors.neonLime.withValues(alpha: 0.16);
            textColor = AtrioColors.neonLimeDark;
            weight = FontWeight.w700;
          } else if (booked) {
            bg = const Color(0xFF22C55E).withValues(alpha: 0.16);
            textColor = const Color(0xFF4ADE80);
            weight = FontWeight.w700;
          } else if (blocked) {
            bg = const Color(0xFFEF4444).withValues(alpha: 0.14);
            textColor = const Color(0xFFFCA5A5);
            weight = FontWeight.w700;
          } else if (isPast) {
            textColor = Colors.white.withValues(alpha: 0.22);
          }

          if (isToday && !selected && !isRangeEndpoint) {
            border = Border.all(color: AtrioColors.neonLime, width: 1.5);
            weight = FontWeight.w800;
          }

          return GestureDetector(
            onTap: isPast ? null : () => _onDayTap(date),
            onLongPress: isPast ? null : () => _showDayDetail(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: border,
              ),
              child: Center(
                child: Text(
                  '$dayNum',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: weight,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Contextual action card (AnimatedSize) ───────────────────────
  Widget _buildActionBar(AppLocalizations l) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _actionBarContent(l),
    );
  }

  Widget _actionBarContent(AppLocalizations l) {
    // Range complete → Block / Unblock buttons + summary.
    if (_isRangeMode && _rangeStart != null && _rangeEnd != null) {
      final start =
          _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
      final end = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;
      final days = end.difference(start).inDays + 1;
      return _ActionCard(
        key: const ValueKey('range-ready'),
        title: _formatRangeTitle(l, start, end),
        statusLabel:
            '$days ${days == 1 ? l.calendarDay : l.calendarDays}',
        statusColor: AtrioColors.neonLimeDark,
        primary: Row(children: [
          Expanded(
            child: _ActionButton(
              label: l.calendarBlock,
              icon: Icons.block_rounded,
              background: const Color(0xFFEF4444),
              foreground: Colors.white,
              onTap: _blockRange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: l.calendarUnblock,
              icon: Icons.lock_open_rounded,
              background: AtrioColors.neonLime,
              foreground: Colors.black,
              onTap: _unblockRange,
            ),
          ),
        ]),
        onClose: _clearSelection,
      );
    }

    // Single day selected → status + Block / View detail.
    if (!_isRangeMode && _selectedDay != null) {
      final key = _dateKey(_selectedDay!);
      final booked = _bookedDates.contains(key);
      final blocked = _blockedDates.contains(key);
      final dayName = _dayAbbrNames(l)[_selectedDay!.weekday - 1];
      final title =
          '$dayName ${_selectedDay!.day} ${_months(l)[_selectedDay!.month - 1]}';

      final Widget primary;
      if (booked) {
        primary = _ActionButton(
          label: l.calendarViewDetails,
          icon: Icons.arrow_forward_rounded,
          background: AtrioColors.neonLime,
          foreground: Colors.black,
          onTap: () => _showDayDetail(_selectedDay!),
        );
      } else {
        primary = _ActionButton(
          label: blocked ? l.calendarUnblock : l.calendarBlock,
          icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
          background:
              blocked ? AtrioColors.neonLime : const Color(0xFFEF4444),
          foreground: blocked ? Colors.black : Colors.white,
          onTap: () => _toggleBlock(_selectedDay!),
        );
      }

      return _ActionCard(
        key: const ValueKey('single-day'),
        title: title,
        statusLabel: booked
            ? l.calendarStatusReserved
            : blocked
                ? l.calendarStatusBlocked
                : l.calendarStatusAvailable,
        statusColor: booked
            ? const Color(0xFF4ADE80)
            : blocked
                ? const Color(0xFFFCA5A5)
                : AtrioColors.neonLimeDark,
        primary: primary,
        onClose: _clearSelection,
      );
    }

    // Range mode but incomplete → soft hint card.
    if (_isRangeMode && (_rangeStart == null || _rangeEnd == null)) {
      return _HintCard(
        key: const ValueKey('range-hint'),
        text: _rangeStart == null
            ? l.calendarSelectStartDate
            : l.calendarSelectEndDate,
        onClose: _clearSelection,
      );
    }

    return const SizedBox(key: ValueKey('empty'), height: 0);
  }

  String _formatRangeTitle(
      AppLocalizations l, DateTime start, DateTime end) {
    final months = _months(l);
    final sameMonth =
        start.month == end.month && start.year == end.year;
    if (sameMonth) {
      return '${start.day} – ${end.day} ${months[start.month - 1]}';
    }
    return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]}';
  }

  // ─── Empty state (no listings) ───────────────────────────────────
  Widget _emptyState(AppLocalizations l) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 40,
                  color: AtrioColors.neonLime,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                l.calendarEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.calendarEmptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AtrioColors.hostTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => context.push('/host/create-listing'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.calendarEmptyCta,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═════════════════════════════════════════════════════════════════

class _ListingPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ListingPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.72),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.85),
          size: 24,
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String dayLabel;
  final String rangeLabel;
  final bool isRangeMode;
  final VoidCallback onTapDay;
  final VoidCallback onTapRange;
  const _ModeToggle({
    required this.dayLabel,
    required this.rangeLabel,
    required this.isRangeMode,
    required this.onTapDay,
    required this.onTapRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(child: _modeBtn(dayLabel, !isRangeMode, onTapDay)),
          Expanded(child: _modeBtn(rangeLabel, isRangeMode, onTapRange)),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.65),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating contextual card at the bottom of the screen.
class _ActionCard extends StatelessWidget {
  final String title;
  final String? statusLabel;
  final Color? statusColor;
  final Widget primary;
  final VoidCallback onClose;
  const _ActionCard({
    super.key,
    required this.title,
    this.statusLabel,
    this.statusColor,
    required this.primary,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor ?? Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel!,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor ?? Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  const _HintCard({
    super.key,
    required this.text,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ),
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded,
                    size: 16, color: Colors.white.withValues(alpha: 0.55)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: foreground,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  const _SheetButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
