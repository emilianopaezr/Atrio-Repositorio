import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/realtime_service.dart';
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
  RealtimeChannel? _channel;

  static const List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const List<String> _dayHeaders = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

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
    final start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final end = DateTime(_focusedMonth.year, _focusedMonth.month + 3, 0);

    try {
      final data = await DatabaseService.getBookedDates(listingId, start, end);
      if (mounted) {
        setState(() {
          _bookedDates.clear();
          _blockedDates.clear();
          _dateBookingStatus.clear();
          for (final d in data) {
            final dateStr = d['booked_date']?.toString() ?? '';
            if (d['is_blocked'] == true) {
              _blockedDates.add(dateStr);
            } else {
              _bookedDates.add(dateStr);
              _dateBookingStatus[dateStr] = d['booking_status']?.toString() ?? '';
            }
          }
        });
      }
    } catch (_) {}
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _toggleBlock(DateTime date) async {
    if (_selectedListingId == null) return;
    final key = _dateKey(date);
    final isCurrentlyBlocked = _blockedDates.contains(key);

    try {
      await DatabaseService.setDateAvailability(
        _selectedListingId!,
        date,
        isCurrentlyBlocked, // if blocked, make available; if available, block
      );
      setState(() {
        if (isCurrentlyBlocked) {
          _blockedDates.remove(key);
        } else {
          _blockedDates.add(key);
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        backgroundColor: AtrioColors.hostBackground,
        body: Center(child: Text('Inicia sesión', style: TextStyle(color: Colors.white))),
      );
    }

    final listingsAsync = ref.watch(hostListingsProvider(userId));

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      appBar: AppBar(
        backgroundColor: AtrioColors.hostBackground,
        elevation: 0,
        title: Text('Calendario', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.hostTextPrimary)),
        centerTitle: true,
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today, size: 48, color: AtrioColors.hostTextTertiary),
                const SizedBox(height: 16),
                Text('Publica un anuncio para ver el calendario', style: AtrioTypography.bodyMedium.copyWith(color: AtrioColors.hostTextSecondary)),
              ]),
            );
          }

          // Auto-select first listing
          if (_selectedListingId == null && listings.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedListingId = listings.first['id'] as String);
              _setupRealtime(listings.first['id'] as String);
              _loadBookedDates(listings.first['id'] as String);
            });
          }

          return Column(
            children: [
              // Listing selector
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: listings.length,
                  itemBuilder: (_, i) {
                    final l = listings[i];
                    final id = l['id'] as String;
                    final selected = _selectedListingId == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedListingId = id);
                          _setupRealtime(id);
                          _loadBookedDates(id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AtrioColors.neonLime : AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder),
                          ),
                          child: Center(
                            child: Text(
                              l['title'] as String? ?? 'Sin título',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? Colors.black : AtrioColors.hostTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Month navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                      style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary),
                    ),
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AtrioColors.hostTextPrimary),
                        onPressed: () {
                          setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1));
                          if (_selectedListingId != null) _loadBookedDates(_selectedListingId!);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AtrioColors.hostTextPrimary),
                        onPressed: () {
                          setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1));
                          if (_selectedListingId != null) _loadBookedDates(_selectedListingId!);
                        },
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Day headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _dayHeaders.map((d) => Expanded(
                    child: Center(child: Text(d, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: AtrioColors.hostTextTertiary))),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 4),

              // Calendar grid
              Expanded(child: _buildCalendarGrid()),

              // Legend + actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(children: [
                  Row(children: [
                    _legend(Colors.green[400]!, 'Reservado'),
                    const SizedBox(width: 16),
                    _legend(Colors.red[400]!, 'Bloqueado'),
                    const SizedBox(width: 16),
                    _legend(AtrioColors.hostSurface, 'Disponible'),
                  ]),
                  const SizedBox(height: 12),
                  if (_selectedDay != null && !_bookedDates.contains(_dateKey(_selectedDay!)))
                    SizedBox(
                      width: double.infinity,
                      child: MaterialButton(
                        onPressed: () => _toggleBlock(_selectedDay!),
                        color: _blockedDates.contains(_dateKey(_selectedDay!)) ? AtrioColors.neonLime : Colors.red[400],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          _blockedDates.contains(_dateKey(_selectedDay!)) ? 'Desbloquear día' : 'Bloquear día',
                          style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                      ),
                    ),
                ]),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AtrioColors.neonLimeDark, strokeWidth: 2)),
        error: (_, _) => const Center(child: Text('Error', style: TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;
    final totalDays = lastDay.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
        itemCount: 42,
        itemBuilder: (_, index) {
          final dayNum = index - startWeekday + 1;
          if (dayNum < 1 || dayNum > totalDays) return const SizedBox();

          final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
          final key = _dateKey(date);
          final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
          final booked = _bookedDates.contains(key);
          final blocked = _blockedDates.contains(key);
          final selected = _selectedDay != null && _dateKey(_selectedDay!) == key;

          Color bgColor = Colors.transparent;
          Color textColor = AtrioColors.hostTextPrimary;

          if (selected) {
            bgColor = AtrioColors.neonLime;
            textColor = Colors.black;
          } else if (booked) {
            bgColor = Colors.green[400]!;
            textColor = Colors.white;
          } else if (blocked) {
            bgColor = Colors.red[400]!;
            textColor = Colors.white;
          } else if (isPast) {
            textColor = AtrioColors.hostTextTertiary;
          }

          return GestureDetector(
            onTap: isPast ? null : () => setState(() => _selectedDay = date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$dayNum',
                  style: GoogleFonts.roboto(fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: textColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.roboto(fontSize: 11, color: AtrioColors.hostTextSecondary)),
    ]);
  }
}
