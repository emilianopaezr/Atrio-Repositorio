import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/providers/locale_provider.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    const bg = AtrioColors.guestBackground;
    const surface = AtrioColors.guestSurface;
    const border = AtrioColors.guestCardBorder;
    const textP = AtrioColors.guestTextPrimary;
    const textS = AtrioColors.guestTextSecondary;
    const textT = AtrioColors.guestTextTertiary;

    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final currentLanguageLabel =
        locale.languageCode == 'en' ? l.langEnglish : l.langSpanish;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: textP),
          onPressed: () => context.pop(),
        ),
        title: Text(l.settingsTitle,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textP)),
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionTitle(l.sectionNotifications, textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  _toggle(l.notifBookings, _notifBookings, textP, (v) {
                    setState(() => _notifBookings = v);
                    _save('notif_bookings', v);
                  }),
                  _divider(),
                  _toggle(l.notifMessages, _notifMessages, textP, (v) {
                    setState(() => _notifMessages = v);
                    _save('notif_messages', v);
                  }),
                  _divider(),
                  _toggle(l.notifReminders, _notifReminders, textP, (v) {
                    setState(() => _notifReminders = v);
                    _save('notif_reminders', v);
                  }),
                  _divider(),
                  _toggle(l.notifPromos, _notifPromos, textP, (v) {
                    setState(() => _notifPromos = v);
                    _save('notif_promos', v);
                  }),
                  _divider(),
                  _toggle(l.notifUpdates, _notifUpdates, textP, (v) {
                    setState(() => _notifUpdates = v);
                    _save('notif_updates', v);
                  }),
                ]),
                const SizedBox(height: 24),
                _sectionTitle(l.sectionPrivacy, textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  _toggle(l.privacyVisible, _profileVisible, textP, (v) {
                    setState(() => _profileVisible = v);
                    _save('privacy_visible', v);
                  }),
                  _divider(),
                  _toggle(l.privacyRatings, _showRatings, textP, (v) {
                    setState(() => _showRatings = v);
                    _save('privacy_ratings', v);
                  }),
                ]),
                const SizedBox(height: 24),
                _sectionTitle(l.sectionGeneral, textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  _tappableTile(
                    l.lblLanguage,
                    currentLanguageLabel,
                    textP,
                    textT,
                    onTap: () => _showLanguagePicker(l),
                  ),
                  _divider(),
                  _infoTile(l.lblCurrency, 'CLP', textP, textT),
                  _divider(),
                  _infoTile(l.lblTimezone, DateTime.now().timeZoneName, textP, textT),
                ]),
                const SizedBox(height: 24),
                _sectionTitle(l.sectionAccount, textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, size: 20, color: textP),
                    title: Text(l.lblChangePassword,
                        style: GoogleFonts.inter(fontSize: 15, color: textP)),
                    trailing: const Icon(Icons.chevron_right, color: textT, size: 20),
                    onTap: () => _showChangePassword(l),
                  ),
                  _divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, size: 20, color: AtrioColors.error),
                    title: Text(l.lblDeleteAccount,
                        style: GoogleFonts.inter(
                            fontSize: 15, color: AtrioColors.error, fontWeight: FontWeight.w500)),
                    trailing:
                        const Icon(Icons.chevron_right, color: AtrioColors.error, size: 20),
                    onTap: () => _showDeleteConfirmation(l),
                  ),
                ]),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Atrio v0.3.0-beta',
                    style: GoogleFonts.inter(fontSize: 12, color: textT),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title, Color color) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(title,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5)),
      );

  Widget _card(Color border, Color surface, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(children: children),
      );

  Widget _divider() => Divider(height: 1, color: AtrioColors.guestDivider, indent: 56);

  Widget _toggle(String title, bool value, Color textColor, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(fontSize: 15, color: textColor)),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AtrioColors.neonLime,
        activeThumbColor: AtrioColors.neonLimeDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );

  Widget _infoTile(String title, String value, Color textColor, Color valueColor) => ListTile(
        title: Text(title, style: GoogleFonts.inter(fontSize: 15, color: textColor)),
        trailing: Text(value, style: GoogleFonts.inter(fontSize: 14, color: valueColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );

  Widget _tappableTile(
    String title,
    String value,
    Color textColor,
    Color valueColor, {
    required VoidCallback onTap,
  }) =>
      ListTile(
        title: Text(title, style: GoogleFonts.inter(fontSize: 15, color: textColor)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 14, color: valueColor)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: valueColor, size: 20),
          ],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );

  Future<void> _showLanguagePicker(AppLocalizations l) async {
    final current = ref.read(localeProvider).languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AtrioColors.guestSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  l.langChooseTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
              ),
              RadioListTile<String>(
                value: 'es',
                groupValue: current,
                title: Text(l.langSpanish,
                    style: GoogleFonts.inter(color: AtrioColors.guestTextPrimary)),
                activeColor: AtrioColors.neonLimeDark,
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: current,
                title: Text(l.langEnglish,
                    style: GoogleFonts.inter(color: AtrioColors.guestTextPrimary)),
                activeColor: AtrioColors.neonLimeDark,
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
              const SizedBox(height: 8),
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
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.lblChangePassword,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.btnCancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.msgPasswordUpdated)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime),
            child: Text(l.btnSave,
                style: GoogleFonts.inter(color: AtrioColors.guestTextPrimary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.lblDeleteAccount,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AtrioColors.error)),
        content: Text(
          l.dlgDeleteAccountConfirm,
          style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.guestTextSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.btnCancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.msgDeleteRequested)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.error),
            child: Text(l.btnDelete, style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
