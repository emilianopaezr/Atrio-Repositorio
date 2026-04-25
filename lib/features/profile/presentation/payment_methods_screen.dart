import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _stripeConnected = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          l.paymentMethodsTitle,
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
                              l.pmStripePayments,
                              style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.pmStripeTagline,
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
                              Text(l.pmActive, style: GoogleFonts.inter(
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
                              Text(l.pmStripeConnected, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black)),
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
                        child: Text(l.pmConnectStripe, style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === SAVED CARDS (empty state — no real payment integration yet) ===
            Text(
              l.pmSavedCards,
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF635BFF).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.credit_card_off_outlined, size: 40, color: Color(0xFF635BFF)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.pmNoSavedCards,
                    style: AtrioTypography.labelLarge.copyWith(
                      color: AtrioColors.guestTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.pmNoSavedCardsDesc,
                    style: AtrioTypography.bodySmall.copyWith(
                      color: AtrioColors.guestTextSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCardSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF635BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.pmAddCard, style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // === OTHER METHODS ===
            Text(
              l.pmOtherMethods,
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _PaymentOption(
              icon: Icons.account_balance,
              title: l.pmBankTransfer,
              subtitle: l.pmBankTransferDesc,
              badge: l.pmSoon,
            ),
            _PaymentOption(
              icon: Icons.apple,
              title: l.pmApplePay,
              subtitle: l.pmApplePayDesc,
              badge: l.pmSoon,
            ),
            _PaymentOption(
              icon: Icons.g_mobiledata_rounded,
              title: l.pmGooglePay,
              subtitle: l.pmGooglePayDesc,
              badge: l.pmSoon,
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
                          l.pmSecure100,
                          style: AtrioTypography.labelMedium.copyWith(
                            color: const Color(0xFF635BFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.pmSecureDesc,
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
    final l = AppLocalizations.of(context);
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
                  Text(l.pmAddCardTitle, style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                  )),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l.pmAddCardDesc,
                style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.guestTextSecondary),
              ),
              const SizedBox(height: 20),
              _cardField(numberCtrl, l.pmFieldCardNumber, '4242 4242 4242 4242', Icons.credit_card),
              const SizedBox(height: 12),
              _cardField(nameCtrl, l.pmFieldCardHolder, l.pmFieldCardHolderHint, Icons.person_outline),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _cardField(expiryCtrl, l.pmFieldExpiry, '12/27', Icons.calendar_today_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _cardField(cvcCtrl, l.pmFieldCvc, '123', Icons.lock_outline)),
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
                        Text(l.pmCardAdded, style: GoogleFonts.inter(
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
                  label: Text(l.pmSaveWithStripe, style: GoogleFonts.inter(
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
                    Text(l.pmProcessedByStripe, style: GoogleFonts.inter(
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
