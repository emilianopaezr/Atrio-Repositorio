import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Step widget for selecting rental mode, schedule, capacity, and policies.
class RentalModeStep extends StatelessWidget {
  final String? selectedType;
  final String rentalMode;
  final String availableFrom;
  final String availableUntil;
  final int blockHours;
  final TextEditingController capacityController;
  final bool instantBooking;
  final String cancellationPolicy;
  final ValueChanged<String> onRentalModeChanged;
  final ValueChanged<String> onAvailableFromChanged;
  final ValueChanged<String> onAvailableUntilChanged;
  final ValueChanged<int> onBlockHoursChanged;
  final ValueChanged<bool> onInstantBookingChanged;
  final ValueChanged<String> onCancellationPolicyChanged;

  const RentalModeStep({
    super.key,
    required this.selectedType,
    required this.rentalMode,
    required this.availableFrom,
    required this.availableUntil,
    required this.blockHours,
    required this.capacityController,
    required this.instantBooking,
    required this.cancellationPolicy,
    required this.onRentalModeChanged,
    required this.onAvailableFromChanged,
    required this.onAvailableUntilChanged,
    required this.onBlockHoursChanged,
    required this.onInstantBookingChanged,
    required this.onCancellationPolicyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isService = selectedType == 'service';
    final isExperience = selectedType == 'experience';
    final restrictedType = isService || isExperience;

    final allModes = [
      if (!restrictedType)
        {
          'id': 'nights',
          'icon': Icons.nightlight_round,
          'label': l.rmModeNights,
          'desc': l.rmModeNightsDesc,
        },
      {
        'id': 'full_day',
        'icon': Icons.today_rounded,
        'label': l.rmModeFullDay,
        'desc': isService
            ? l.rmModeFullDayDescService
            : isExperience
                ? l.rmModeFullDayDescExperience
                : l.rmModeFullDayDescSpace,
      },
      {
        'id': 'hours',
        'icon': Icons.access_time_rounded,
        'label': l.rmModeHours,
        'desc': isService
            ? l.rmModeHoursDescService
            : isExperience
                ? l.rmModeHoursDescExperience
                : l.rmModeHoursDescSpace,
      },
    ];

    final typeLabel = isService
        ? l.rmTypeService
        : isExperience
            ? l.rmTypeExperience
            : l.rmTypeSpace;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l.clModeEyebrow,
          title: l.rmModeTitle,
          subtitle: l.rmModeQuestion(typeLabel),
        ),
        const SizedBox(height: 28),

        // Mode selector cards
        ...allModes.map((m) {
          final selected = rentalMode == m['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onRentalModeChanged(m['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: selected
                      ? AtrioColors.neonLime.withValues(alpha: 0.08)
                      : AtrioColors.hostSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AtrioColors.neonLime : AtrioColors.hostCardBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? AtrioColors.neonLime
                            : AtrioColors.hostSurfaceVariant,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        m['icon'] as IconData,
                        size: 22,
                        color: selected ? Colors.black : AtrioColors.hostTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.hostTextPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['desc'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AtrioColors.hostTextSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      scale: selected ? 1 : 0,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AtrioColors.neonLime,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Hours-specific options
        if (rentalMode == 'hours') ...[
          const SizedBox(height: 20),
          _SectionLabel(text: l.rmAvailableSchedule),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _timePickerButton(
                  context,
                  l.rmFrom(availableFrom),
                  onAvailableFromChanged,
                  const TimeOfDay(hour: 9, minute: 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timePickerButton(
                  context,
                  l.rmUntil(availableUntil),
                  onAvailableUntilChanged,
                  const TimeOfDay(hour: 22, minute: 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionLabel(text: l.rmBlockDuration),
          const SizedBox(height: 4),
          Text(
            l.rmBlockDurationHelp,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AtrioColors.hostTextTertiary,
            ),
          ),
          const SizedBox(height: 10),
          _buildBlockHoursSelector(l),
        ],

        const SizedBox(height: 22),

        // Capacity field — editorial style
        _SectionLabel(text: l.rmCapacity.toUpperCase()),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Icon(Icons.people_outline_rounded,
                    size: 18, color: AtrioColors.hostTextSecondary),
              ),
              Expanded(
                child: TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  cursorColor: AtrioColors.neonLime,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: l.rmCapacityHint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.hostTextTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Instant booking toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: instantBooking
                  ? AtrioColors.neonLime.withValues(alpha: 0.4)
                  : AtrioColors.hostCardBorder,
              width: instantBooking ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: instantBooking
                      ? AtrioColors.neonLime
                      : AtrioColors.hostSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 20,
                  color: instantBooking ? Colors.black : AtrioColors.hostTextTertiary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.rmInstantBooking,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.hostTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.rmInstantBookingDesc,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.hostTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: instantBooking,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onInstantBookingChanged(v);
                },
                activeThumbColor: Colors.black,
                activeTrackColor: AtrioColors.neonLime,
                inactiveTrackColor: AtrioColors.hostSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Cancellation policy
        _SectionLabel(text: l.rmCancellationPolicy.toUpperCase()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in [
              {'id': 'flexible', 'label': l.rmFlexible},
              {'id': 'moderate', 'label': l.rmModerate},
              {'id': 'strict', 'label': l.rmStrict},
            ])
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCancellationPolicyChanged(p['id']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cancellationPolicy == p['id']
                        ? AtrioColors.neonLime
                        : AtrioColors.hostSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cancellationPolicy == p['id']
                          ? AtrioColors.neonLime
                          : AtrioColors.hostCardBorder,
                      width: cancellationPolicy == p['id'] ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    p['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: cancellationPolicy == p['id']
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: cancellationPolicy == p['id']
                          ? Colors.black
                          : AtrioColors.hostTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _timePickerButton(
    BuildContext context,
    String label,
    ValueChanged<String> onChange,
    TimeOfDay initial,
  ) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: initial);
        if (t != null) {
          onChange(
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 17, color: AtrioColors.neonLime),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.hostTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockHoursSelector(AppLocalizations l) {
    final fromParts = availableFrom.split(':');
    final untilParts = availableUntil.split(':');
    final fromH = int.tryParse(fromParts[0]) ?? 9;
    final untilH = int.tryParse(untilParts[0]) ?? 22;
    final totalHours = untilH - fromH;
    if (totalHours <= 0) return const SizedBox.shrink();

    final blocks = <int>[for (int b = 1; b <= totalHours; b++) b];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: blocks.map((b) {
        final sel = b == blockHours;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onBlockHoursChanged(b);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? AtrioColors.neonLime : AtrioColors.hostSurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: sel ? AtrioColors.neonLime : AtrioColors.hostCardBorder,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Text(
              l.rmHours(b),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel ? Colors.black : AtrioColors.hostTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AtrioColors.hostTextTertiary,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  const _StepHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              eyebrow,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AtrioColors.neonLime,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AtrioColors.hostTextPrimary,
            letterSpacing: -0.9,
            height: 1.05,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AtrioColors.hostTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
