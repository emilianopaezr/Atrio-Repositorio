import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/atrio_text_field.dart';

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
      if (!restrictedType) {'id': 'nights', 'icon': Icons.nightlight_round, 'label': l.rmModeNights, 'desc': l.rmModeNightsDesc},
      {'id': 'full_day', 'icon': Icons.today, 'label': l.rmModeFullDay, 'desc': isService ? l.rmModeFullDayDescService : isExperience ? l.rmModeFullDayDescExperience : l.rmModeFullDayDescSpace},
      {'id': 'hours', 'icon': Icons.access_time, 'label': l.rmModeHours, 'desc': isService ? l.rmModeHoursDescService : isExperience ? l.rmModeHoursDescExperience : l.rmModeHoursDescSpace},
    ];

    final typeLabel = isService ? l.rmTypeService : isExperience ? l.rmTypeExperience : l.rmTypeSpace;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.rmModeTitle, style: AtrioTypography.headingLarge.copyWith(color: AtrioColors.hostTextPrimary)),
        const SizedBox(height: 8),
        Text(l.rmModeQuestion(typeLabel), style: AtrioTypography.bodyMedium.copyWith(color: AtrioColors.hostTextSecondary)),
        const SizedBox(height: 24),

        // Mode selector cards
        ...allModes.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onRentalModeChanged(m['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AtrioColors.hostSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: rentalMode == m['id'] ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder,
                  width: rentalMode == m['id'] ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: rentalMode == m['id'] ? AtrioColors.neonLimeDark.withValues(alpha: 0.2) : AtrioColors.hostSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m['icon'] as IconData, color: rentalMode == m['id'] ? AtrioColors.neonLimeDark : AtrioColors.hostTextSecondary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['label'] as String, style: AtrioTypography.labelLarge.copyWith(color: AtrioColors.hostTextPrimary)),
                  Text(m['desc'] as String, style: AtrioTypography.bodySmall.copyWith(color: AtrioColors.hostTextSecondary)),
                ])),
                if (rentalMode == m['id']) const Icon(Icons.check_circle, color: AtrioColors.neonLimeDark),
              ]),
            ),
          ),
        )),

        // Hours-specific options
        if (rentalMode == 'hours') ...[
          const SizedBox(height: 16),
          Text(l.rmAvailableSchedule, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _timePickerButton(context, l.rmFrom(availableFrom), onAvailableFromChanged, const TimeOfDay(hour: 9, minute: 0))),
            const SizedBox(width: 12),
            Expanded(child: _timePickerButton(context, l.rmUntil(availableUntil), onAvailableUntilChanged, const TimeOfDay(hour: 22, minute: 0))),
          ]),
          const SizedBox(height: 16),
          Text(l.rmBlockDuration, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextPrimary)),
          const SizedBox(height: 6),
          Text(l.rmBlockDurationHelp, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextSecondary)),
          const SizedBox(height: 8),
          _buildBlockHoursSelector(l),
        ],

        const SizedBox(height: 20),

        // Capacity
        AtrioTextField(
          controller: capacityController,
          label: l.rmCapacity,
          hint: l.rmCapacityHint,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.people_outline, size: 20),
        ),
        const SizedBox(height: 20),

        // Instant booking
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AtrioColors.hostCardBorder)),
          child: Row(children: [
            Icon(Icons.flash_on, size: 20, color: instantBooking ? AtrioColors.neonLimeDark : AtrioColors.hostTextTertiary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.rmInstantBooking, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextPrimary)),
              Text(l.rmInstantBookingDesc, style: AtrioTypography.caption.copyWith(color: AtrioColors.hostTextSecondary)),
            ])),
            Switch(
              value: instantBooking,
              onChanged: onInstantBookingChanged,
              activeTrackColor: AtrioColors.neonLimeDark,
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Cancellation policy
        Text(l.rmCancellationPolicy, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextPrimary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final p in [
            {'id': 'flexible', 'label': l.rmFlexible},
            {'id': 'moderate', 'label': l.rmModerate},
            {'id': 'strict', 'label': l.rmStrict},
          ])
            GestureDetector(
              onTap: () => onCancellationPolicyChanged(p['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cancellationPolicy == p['id'] ? AtrioColors.neonLime : AtrioColors.hostSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cancellationPolicy == p['id'] ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder),
                ),
                child: Text(p['label']!, style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: cancellationPolicy == p['id'] ? FontWeight.w700 : FontWeight.w500,
                  color: cancellationPolicy == p['id'] ? Colors.black : AtrioColors.hostTextSecondary,
                )),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _timePickerButton(BuildContext context, String label, ValueChanged<String> onChange, TimeOfDay initial) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: initial);
        if (t != null) onChange('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AtrioColors.hostCardBorder)),
        child: Row(children: [
          const Icon(Icons.schedule, size: 18, color: AtrioColors.neonLimeDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
          ),
        ]),
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

    final validBlocks = <int>{};
    for (int b = 1; b <= totalHours; b++) {
      validBlocks.add(b);
    }
    final sorted = validBlocks.toList()..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sorted.map((b) {
        final sel = b == blockHours;
        return GestureDetector(
          onTap: () => onBlockHoursChanged(b),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AtrioColors.neonLime : AtrioColors.hostSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AtrioColors.neonLime : AtrioColors.hostCardBorder),
            ),
            child: Text(
              l.rmHours(b),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: sel ? Colors.black : AtrioColors.hostTextPrimary),
            ),
          ),
        );
      }).toList(),
    );
  }
}
