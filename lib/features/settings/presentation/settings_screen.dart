import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: textP),
          onPressed: () => context.pop(),
        ),
        title: Text('Configuración',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textP)),
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionTitle('Notificaciones', textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  _toggle('Reservas nuevas', _notifBookings, textP, (v) {
                    setState(() => _notifBookings = v);
                    _save('notif_bookings', v);
                  }),
                  _divider(),
                  _toggle('Mensajes', _notifMessages, textP, (v) {
                    setState(() => _notifMessages = v);
                    _save('notif_messages', v);
                  }),
                  _divider(),
                  _toggle('Recordatorios', _notifReminders, textP, (v) {
                    setState(() => _notifReminders = v);
                    _save('notif_reminders', v);
                  }),
                  _divider(),
                  _toggle('Promociones', _notifPromos, textP, (v) {
                    setState(() => _notifPromos = v);
                    _save('notif_promos', v);
                  }),
                  _divider(),
                  _toggle('Actualizaciones de la app', _notifUpdates, textP, (v) {
                    setState(() => _notifUpdates = v);
                    _save('notif_updates', v);
                  }),
                ]),
                const SizedBox(height: 24),
                _sectionTitle('Privacidad', textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  _toggle('Perfil visible', _profileVisible, textP, (v) {
                    setState(() => _profileVisible = v);
                    _save('privacy_visible', v);
                  }),
                  _divider(),
                  _toggle('Mostrar calificaciones', _showRatings, textP, (v) {
                    setState(() => _showRatings = v);
                    _save('privacy_ratings', v);
                  }),
                ]),
                const SizedBox(height: 24),
                _sectionTitle('General', textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  _infoTile('Idioma', 'Español', textP, textT),
                  _divider(),
                  _infoTile('Moneda', 'CLP', textP, textT),
                  _divider(),
                  _infoTile('Zona horaria', DateTime.now().timeZoneName, textP, textT),
                ]),
                const SizedBox(height: 24),
                _sectionTitle('Cuenta', textS),
                const SizedBox(height: 8),
                _card(border, surface, [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, size: 20, color: textP),
                    title: Text('Cambiar contraseña',
                        style: GoogleFonts.inter(fontSize: 15, color: textP)),
                    trailing: const Icon(Icons.chevron_right, color: textT, size: 20),
                    onTap: () => _showChangePassword(),
                  ),
                  _divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, size: 20, color: AtrioColors.error),
                    title: Text('Eliminar cuenta',
                        style: GoogleFonts.inter(
                            fontSize: 15, color: AtrioColors.error, fontWeight: FontWeight.w500)),
                    trailing:
                        const Icon(Icons.chevron_right, color: AtrioColors.error, size: 20),
                    onTap: () => _showDeleteConfirmation(),
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

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar contraseña', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraseña actualizada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime),
            child: Text('Guardar',
                style: GoogleFonts.inter(color: AtrioColors.guestTextPrimary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar cuenta',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AtrioColors.error)),
        content: Text(
          'Esta acción es permanente. Se eliminarán todos tus datos, reservas y publicaciones. ¿Estás seguro?',
          style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.guestTextSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitud de eliminación enviada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.error),
            child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
