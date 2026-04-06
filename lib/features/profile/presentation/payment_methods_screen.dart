import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _stripeConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AtrioColors.guestTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Métodos de Pago',
          style: AtrioTypography.headingSmall.copyWith(
            color: AtrioColors.guestTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === STRIPE INTEGRATION BANNER ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF635BFF), Color(0xFF8B5CF6)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pagos con Stripe',
                              style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pagos seguros y rapidos',
                              style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_stripeConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: AtrioColors.neonLime),
                              const SizedBox(width: 4),
                              Text('Activo', style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w700, color: AtrioColors.neonLime,
                              )),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (!_stripeConnected) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _stripeConnected = true);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle, color: Colors.black, size: 20),
                              const SizedBox(width: 10),
                              Text('Stripe conectado exitosamente', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black)),
                            ]),
                            backgroundColor: AtrioColors.neonLime,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF635BFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text('Conectar con Stripe', style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === SAVED CARDS ===
            Text(
              'Tarjetas Guardadas',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _CreditCard(
              brand: 'VISA',
              lastFour: '4521',
              expiry: '12/27',
              color: const Color(0xFF1A1F71),
              isDefault: true,
            ),
            const SizedBox(height: 12),
            _CreditCard(
              brand: 'MASTERCARD',
              lastFour: '8890',
              expiry: '08/26',
              color: const Color(0xFF2D2D2D),
              isDefault: false,
            ),
            const SizedBox(height: 20),

            // === ADD NEW CARD ===
            GestureDetector(
              onTap: () => _showAddCardSheet(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AtrioColors.neonLimeDark.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLimeDark.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AtrioColors.neonLimeDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Agregar Tarjeta',
                      style: AtrioTypography.labelLarge.copyWith(
                        color: AtrioColors.neonLimeDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // === OTHER METHODS ===
            Text(
              'Otros Métodos',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _PaymentOption(
              icon: Icons.account_balance,
              title: 'Transferencia Bancaria',
              subtitle: 'Paga directamente desde tu banco',
              badge: 'Pronto',
            ),
            _PaymentOption(
              icon: Icons.apple,
              title: 'Apple Pay',
              subtitle: 'Pago rapido con tu dispositivo',
              badge: 'Pronto',
            ),
            _PaymentOption(
              icon: Icons.g_mobiledata_rounded,
              title: 'Google Pay',
              subtitle: 'Paga con tu cuenta de Google',
              badge: 'Pronto',
            ),
            const SizedBox(height: 28),

            // === SECURITY INFO ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF635BFF).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF635BFF).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF635BFF), size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pagos 100% seguros',
                          style: AtrioTypography.labelMedium.copyWith(
                            color: const Color(0xFF635BFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tus pagos son procesados por Stripe con cifrado de grado bancario. Atrio nunca almacena tus datos de tarjeta.',
                          style: AtrioTypography.caption.copyWith(
                            color: AtrioColors.guestTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) {
    final numberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvcCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.credit_card, color: Color(0xFF635BFF), size: 24),
                  const SizedBox(width: 10),
                  Text('Agregar Tarjeta', style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                  )),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tu tarjeta sera procesada de forma segura por Stripe',
                style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.guestTextSecondary),
              ),
              const SizedBox(height: 20),
              _cardField(numberCtrl, 'Numero de tarjeta', '4242 4242 4242 4242', Icons.credit_card),
              const SizedBox(height: 12),
              _cardField(nameCtrl, 'Nombre del titular', 'NOMBRE APELLIDO', Icons.person_outline),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _cardField(expiryCtrl, 'MM/AA', '12/27', Icons.calendar_today_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _cardField(cvcCtrl, 'CVC', '123', Icons.lock_outline)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.black, size: 20),
                        const SizedBox(width: 10),
                        Text('Tarjeta agregada correctamente', style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, color: Colors.black,
                        )),
                      ]),
                      backgroundColor: AtrioColors.neonLime,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF635BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.bolt, size: 20),
                  label: Text('Guardar con Stripe', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700,
                  )),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 12, color: AtrioColors.guestTextTertiary),
                    const SizedBox(width: 4),
                    Text('Procesado de forma segura por Stripe', style: GoogleFonts.inter(
                      fontSize: 11, color: AtrioColors.guestTextTertiary,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardField(TextEditingController ctrl, String label, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F7FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF635BFF), width: 2),
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  final String brand;
  final String lastFour;
  final String expiry;
  final Color color;
  final bool isDefault;

  const _CreditCard({
    required this.brand,
    required this.lastFour,
    required this.expiry,
    required this.color,
    required this.isDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                brand,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  letterSpacing: 2, color: Colors.white,
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Por defecto',
                    style: AtrioTypography.caption.copyWith(
                      color: AtrioColors.neonLime, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            '•••• •••• •••• $lastFour',
            style: const TextStyle(
              fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w600,
              letterSpacing: 2, color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VÁLIDA HASTA',
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      letterSpacing: 1, color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    expiry,
                    style: const TextStyle(
                      fontFamily: 'Roboto', fontSize: 14,
                      fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text('Stripe', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AtrioColors.guestTextSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AtrioTypography.labelLarge.copyWith(
                  color: AtrioColors.guestTextPrimary, fontWeight: FontWeight.w600,
                )),
                Text(subtitle, style: AtrioTypography.caption.copyWith(
                  color: AtrioColors.guestTextSecondary,
                )),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AtrioColors.neonLimeDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!, style: AtrioTypography.caption.copyWith(
                color: AtrioColors.neonLimeDark, fontWeight: FontWeight.w600,
              )),
            )
          else
            const Icon(Icons.arrow_forward_ios, size: 14, color: AtrioColors.guestTextTertiary),
        ],
      ),
    );
  }
}
