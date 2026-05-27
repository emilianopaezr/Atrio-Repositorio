import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/services/host_payment_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/atrio_snackbar.dart';

/// Lets a host connect (or re-check) their Mercado Pago account so
/// the marketplace split payment can route money to them directly.
///
/// Flow:
///   1. Host taps "Conectar Mercado Pago".
///   2. App POSTs to mp-oauth-init → receives MP authorize URL.
///   3. App opens that URL in the system browser via url_launcher.
///   4. User signs in / authorizes on mercadopago.com.
///   5. MP redirects to mp-oauth-callback Edge Function, which
///      persists tokens and renders a success page.
///   6. User returns to Atrio. The screen polls my_payment_status()
///      (or refreshes on resume) and shows "Conectado ✓".
class HostPaymentConnectScreen extends StatefulWidget {
  const HostPaymentConnectScreen({super.key});

  @override
  State<HostPaymentConnectScreen> createState() =>
      _HostPaymentConnectScreenState();
}

class _HostPaymentConnectScreenState extends State<HostPaymentConnectScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _connecting = false;
  HostPaymentStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user comes back from the MP browser tab, re-fetch.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final s = await HostPaymentService.fetchMyStatus();
      if (!mounted) return;
      setState(() {
        _status = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppLogger.e('host_payment_connect refresh failed: $e', tag: 'mp');
    }
  }

  Future<void> _connect() async {
    HapticFeedback.lightImpact();
    if (!HostPaymentService.marketplaceConfigured) {
      AtrioSnackbar.info(
        context,
        'MP Marketplace aún no está habilitado en este build.',
      );
      return;
    }
    setState(() => _connecting = true);
    try {
      final url = await HostPaymentService.requestAuthorizeUrl();
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        AtrioSnackbar.danger(
          context,
          'No se pudo abrir el navegador.',
        );
      }
    } on HostPaymentException catch (e) {
      if (mounted) AtrioSnackbar.danger(context, e.message);
    } catch (e) {
      if (mounted) {
        AtrioSnackbar.danger(
          context,
          'Error inesperado al iniciar la conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AtrioColors.hostBackground
        : AtrioColors.guestBackground;
    final surface =
        isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface;
    final border = isDark
        ? AtrioColors.hostCardBorder
        : AtrioColors.guestCardBorder;
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textS = isDark
        ? AtrioColors.hostTextSecondary
        : AtrioColors.guestTextSecondary;
    final textT = isDark
        ? AtrioColors.hostTextTertiary
        : AtrioColors.guestTextTertiary;

    final connected = _status?.isUsable ?? false;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: textP),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cuenta de pago',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textP,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AtrioColors.neonLimeDark,
        backgroundColor: surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'MERCADO PAGO',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: textT,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              connected
                  ? 'Tu cuenta está conectada'
                  : 'Conecta tu cuenta para recibir pagos',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: textP,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              connected
                  ? 'Cada vez que un huésped pague una reserva, Mercado Pago depositará el precio base directamente a tu cuenta. Atrio retiene únicamente el Servicio Atrio.'
                  : 'Cuando conectas Mercado Pago, los pagos de tus reservas van directamente a tu cuenta. Sin esperas ni transferencias manuales.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: textS,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            _StatusCard(
              loading: _loading,
              status: _status,
              surface: surface,
              border: border,
              textP: textP,
              textS: textS,
              textT: textT,
            ),
            const SizedBox(height: 16),
            if (!HostPaymentService.marketplaceConfigured)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AtrioColors.vibrantOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AtrioColors.vibrantOrange
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AtrioColors.vibrantOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'MP Marketplace aún no está habilitado en este build. Atrio cobra todo a su cuenta y te transfiere manualmente.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textP,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _connecting || !HostPaymentService.marketplaceConfigured
                    ? null
                    : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: connected
                      ? const Color(0xFF009EE3).withValues(alpha: 0.12)
                      : const Color(0xFF009EE3),
                  foregroundColor:
                      connected ? const Color(0xFF009EE3) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _connecting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        connected
                            ? 'Volver a conectar Mercado Pago'
                            : 'Conectar Mercado Pago',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'Actualizar estado',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textS,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool loading;
  final HostPaymentStatus? status;
  final Color surface;
  final Color border;
  final Color textP;
  final Color textS;
  final Color textT;

  const _StatusCard({
    required this.loading,
    required this.status,
    required this.surface,
    required this.border,
    required this.textP,
    required this.textS,
    required this.textT,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AtrioColors.neonLimeDark,
          ),
        ),
      );
    }

    final connected = status?.isUsable ?? false;
    final accent = connected
        ? AtrioColors.neonLime
        : AtrioColors.vibrantOrange;
    final label = connected
        ? 'CONECTADO'
        : (status == null ? 'NO CONECTADO' : 'EXPIRADO O INACTIVO');
    final sub = connected
        ? 'Tus reservas se depositan en MP user ${status?.mpUserId ?? "—"}'
        : 'Necesitas conectar tu cuenta MP para recibir pagos.';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.55),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textS,
                    height: 1.4,
                  ),
                ),
                if (status?.connectedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Conectado: ${_fmtDate(status!.connectedAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textT,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
