import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

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

            // === ADD NEW METHOD ===
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Agregar método de pago próximamente'),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AtrioColors.neonLimeDark.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
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
                        color:
                            AtrioColors.neonLimeDark.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: AtrioColors.neonLimeDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Agregar Método de Pago',
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                  backgroundColor: Color(0xFFD4FF00),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: Duration(seconds: 1),
                ));
              },
            ),
            _PaymentOption(
              icon: Icons.paypal_outlined,
              title: 'PayPal',
              subtitle: 'Vincula tu cuenta de PayPal',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                  backgroundColor: Color(0xFFD4FF00),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: Duration(seconds: 1),
                ));
              },
            ),
            _PaymentOption(
              icon: Icons.apple,
              title: 'Apple Pay',
              subtitle: 'Pago rápido con tu dispositivo',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                  backgroundColor: Color(0xFFD4FF00),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: Duration(seconds: 1),
                ));
              },
            ),
            const SizedBox(height: 28),

            // === PAYMENT HISTORY ===
            Text(
              'Historial de Pagos',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _TransactionItem(
              title: 'Loft Premium Centro',
              date: '15 Mar 2026',
              amount: '-\$451.00',
              status: 'Completado',
            ),
            _TransactionItem(
              title: 'Estudio Creativo',
              date: '28 Feb 2026',
              amount: '-\$180.00',
              status: 'Completado',
            ),
            _TransactionItem(
              title: 'Villa con Piscina',
              date: '10 Feb 2026',
              amount: '-\$920.00',
              status: 'Reembolsado',
              isRefund: true,
            ),
            const SizedBox(height: 40),
          ],
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Por defecto',
                    style: AtrioTypography.caption.copyWith(
                      color: AtrioColors.neonLime,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            '•••• •••• •••• $lastFour',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: Colors.white,
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
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    expiry,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
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
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Text(title,
                      style: AtrioTypography.labelLarge.copyWith(
                        color: AtrioColors.guestTextPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(subtitle,
                      style: AtrioTypography.caption.copyWith(
                        color: AtrioColors.guestTextSecondary,
                      )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AtrioColors.guestTextTertiary),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final String status;
  final bool isRefund;

  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    this.isRefund = false,
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
              color: isRefund
                  ? AtrioColors.neonLime.withValues(alpha: 0.1)
                  : AtrioColors.neonLimeDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isRefund ? Icons.replay : Icons.receipt_long_outlined,
              size: 20,
              color: isRefund
                  ? AtrioColors.neonLimeDark
                  : AtrioColors.neonLimeDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AtrioTypography.labelMedium.copyWith(
                      color: AtrioColors.guestTextPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                Text(date,
                    style: AtrioTypography.caption.copyWith(
                      color: AtrioColors.guestTextSecondary,
                    )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isRefund
                      ? AtrioColors.neonLimeDark
                      : AtrioColors.guestTextPrimary,
                ),
              ),
              Text(
                status,
                style: AtrioTypography.caption.copyWith(
                  color: AtrioColors.guestTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
