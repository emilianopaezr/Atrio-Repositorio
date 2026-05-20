import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// Configuración — editorial redesign.
///
/// Header sin barrita lime, secciones con SectionEyebrow + íconos,
/// cards con borde hairline, toggles refinados.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifBookings = true;
  bool _notifMessages = true;
  bool _notifReminders = true;
  bool _notifPromos = false;
  bool _notifUpdates = true;
  bool _profileVisible = true;
  bool _showRatings = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifBookings = p.getBool('notif_bookings') ?? true;
      _notifMessages = p.getBool('notif_messages') ?? true;
      _notifReminders = p.getBool('notif_reminders') ?? true;
      _notifPromos = p.getBool('notif_promos') ?? false;
      _notifUpdates = p.getBool('notif_updates') ?? true;
      _profileVisible = p.getBool('privacy_visible') ?? true;
      _showRatings = p.getBool('privacy_ratings') ?? true;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, val);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final currentLanguageLabel =
        locale.languageCode == 'en' ? l.langEnglish : l.langSpanish;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header (no lime bar) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AtrioColors.guestTextPrimary),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(height: 6),
                  PageEyebrow(text: l.settingsEyebrow),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.settingsTitle,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_loaded
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AtrioColors.neonLimeDark, strokeWidth: 2.4),
                    )
                  : _body(l, currentLanguageLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l, String currentLanguageLabel) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // ─── Notifications ───
        SectionEyebrow(text: l.sectionNotifications),
        const SizedBox(height: 12),
        _card([
          _Toggle(
            icon: Icons.calendar_today_rounded,
            label: l.notifBookings,
            value: _notifBookings,
            onChanged: (v) {
              setState(() => _notifBookings = v);
              _save('notif_bookings', v);
            },
          ),
          _divider(),
          _Toggle(
            icon: Icons.chat_bubble_outline_rounded,
            label: l.notifMessages,
            value: _notifMessages,
            onChanged: (v) {
              setState(() => _notifMessages = v);
              _save('notif_messages', v);
            },
          ),
          _divider(),
          _Toggle(
            icon: Icons.alarm_rounded,
            label: l.notifReminders,
            value: _notifReminders,
            onChanged: (v) {
              setState(() => _notifReminders = v);
              _save('notif_reminders', v);
            },
          ),
          _divider(),
          _Toggle(
            icon: Icons.local_offer_outlined,
            label: l.notifPromos,
            value: _notifPromos,
            onChanged: (v) {
              setState(() => _notifPromos = v);
              _save('notif_promos', v);
            },
          ),
          _divider(),
          _Toggle(
            icon: Icons.system_update_alt_rounded,
            label: l.notifUpdates,
            value: _notifUpdates,
            onChanged: (v) {
              setState(() => _notifUpdates = v);
              _save('notif_updates', v);
            },
          ),
        ]),
        const SizedBox(height: 24),

        // ─── Privacy ───
        SectionEyebrow(text: l.sectionPrivacy),
        const SizedBox(height: 12),
        _card([
          _Toggle(
            icon: Icons.visibility_outlined,
            label: l.privacyVisible,
            value: _profileVisible,
            onChanged: (v) {
              setState(() => _profileVisible = v);
              _save('privacy_visible', v);
            },
          ),
          _divider(),
          _Toggle(
            icon: Icons.star_outline_rounded,
            label: l.privacyRatings,
            value: _showRatings,
            onChanged: (v) {
              setState(() => _showRatings = v);
              _save('privacy_ratings', v);
            },
          ),
        ]),
        const SizedBox(height: 24),

        // ─── General ───
        SectionEyebrow(text: l.sectionGeneral),
        const SizedBox(height: 12),
        _card([
          _RowTile(
            icon: Icons.language_rounded,
            label: l.lblLanguage,
            value: currentLanguageLabel,
            tappable: true,
            onTap: () => _showLanguagePicker(l),
          ),
          _divider(),
          _RowTile(
            icon: Icons.payments_outlined,
            label: l.lblCurrency,
            value: 'CLP',
          ),
          _divider(),
          _RowTile(
            icon: Icons.schedule_rounded,
            label: l.lblTimezone,
            value: DateTime.now().timeZoneName,
          ),
        ]),
        const SizedBox(height: 24),

        // ─── Account ───
        SectionEyebrow(text: l.sectionAccount),
        const SizedBox(height: 12),
        _card([
          _RowTile(
            icon: Icons.lock_outline_rounded,
            label: l.lblChangePassword,
            tappable: true,
            onTap: () => _showChangePassword(l),
          ),
          _divider(),
          _RowTile(
            icon: Icons.delete_outline_rounded,
            label: l.lblDeleteAccount,
            tappable: true,
            danger: true,
            onTap: () => _showDeleteConfirmation(l),
          ),
        ]),
        const SizedBox(height: 32),

        Center(
          child: Text(
            'Atrio v0.3.0-beta',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextTertiary,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AtrioColors.guestCardBorder),
        ),
        child: Column(children: children),
      );

  Widget _divider() => Container(
        height: 1,
        color: AtrioColors.guestDivider,
        margin: const EdgeInsets.only(left: 60),
      );

  // ─── Pickers / dialogs ───
  Future<void> _showLanguagePicker(AppLocalizations l) async {
    HapticFeedback.selectionClick();
    final current = ref.read(localeProvider).languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AtrioColors.guestSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6, bottom: 14),
                  decoration: BoxDecoration(
                    color: AtrioColors.guestCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l.langChooseTitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              _LangOption(
                label: l.langSpanish,
                code: 'es',
                current: current,
                onTap: () => Navigator.pop(ctx, 'es'),
              ),
              const SizedBox(height: 8),
              _LangOption(
                label: l.langEnglish,
                code: 'en',
                current: current,
                onTap: () => Navigator.pop(ctx, 'en'),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected != current) {
      await ref.read(localeProvider.notifier).setLanguageCode(selected);
    }
  }

  void _showChangePassword(AppLocalizations l) {
    HapticFeedback.selectionClick();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtrioColors.guestSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l.lblChangePassword,
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: l.dlgCurrentPassword),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: l.dlgNewPassword),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.btnCancel,
                  style: GoogleFonts.inter(
                      color: AtrioColors.guestTextSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.msgPasswordUpdated)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.neonLime,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.btnSave,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(AppLocalizations l) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtrioColors.guestSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          l.lblDeleteAccount,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AtrioColors.error,
          ),
        ),
        content: Text(
          l.dlgDeleteAccountConfirm,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AtrioColors.guestTextSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.btnCancel,
                  style: GoogleFonts.inter(
                      color: AtrioColors.guestTextSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.msgDeleteRequested)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.btnDelete,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle tile ─────────────────────────────────────────────
class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value
                      ? AtrioColors.guestTextPrimary.withValues(alpha: 0.06)
                      : AtrioColors.guestSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: value
                      ? AtrioColors.guestTextPrimary
                      : AtrioColors.guestTextSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _AtrioSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom switch (editorial) ──────────────────────────────
/// Minimal black-on-white toggle. Off: hairline gray track + white knob.
/// On: solid black track + white knob shifted right. No lime — accent stays
/// reserved for the rest of the UI.
class _AtrioSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AtrioSwitch({required this.value, required this.onChanged});

  static const double _w = 46;
  static const double _h = 26;
  static const double _padding = 3;
  static const double _knob = _h - _padding * 2; // 20

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: _w,
        height: _h,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: value
              ? AtrioColors.guestTextPrimary
              : AtrioColors.guestSurfaceVariant,
          borderRadius: BorderRadius.circular(_h),
          border: Border.all(
            color: value
                ? AtrioColors.guestTextPrimary
                : AtrioColors.guestCardBorder,
            width: 1,
          ),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: _knob,
          height: _knob,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_knob),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: value ? 0.18 : 0.10),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Row tile (info / tappable / danger) ─────────────────────
class _RowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool tappable;
  final bool danger;
  final VoidCallback? onTap;
  const _RowTile({
    required this.icon,
    required this.label,
    this.value,
    this.tappable = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = danger
        ? AtrioColors.error.withValues(alpha: 0.10)
        : AtrioColors.guestSurfaceVariant;
    final iconColor =
        danger ? AtrioColors.error : AtrioColors.guestTextSecondary;
    final labelColor =
        danger ? AtrioColors.error : AtrioColors.guestTextPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tappable && onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!.call();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextSecondary,
                    ),
                  ),
                ),
              if (tappable) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: danger
                      ? AtrioColors.error
                      : AtrioColors.guestTextTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language picker option ──────────────────────────────────
class _LangOption extends StatelessWidget {
  final String label;
  final String code;
  final String current;
  final VoidCallback onTap;
  const _LangOption({
    required this.label,
    required this.code,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = code == current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? AtrioColors.neonLime.withValues(alpha: 0.14)
                : AtrioColors.guestSurfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AtrioColors.neonLimeDark.withValues(alpha: 0.5)
                  : AtrioColors.guestCardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AtrioColors.neonLimeDark : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AtrioColors.neonLimeDark
                        : AtrioColors.guestTextTertiary,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.guestTextPrimary,
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
