import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/mercadopago_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

/// Minimalist editorial card payment form. Submits card data to the Edge
/// Function for server-side tokenization + payment, returns a
/// [PaymentResult] via Navigator.pop.
class CardPaymentScreen extends StatefulWidget {
  final String bookingId;
  final double total;
  final String? listingTitle;

  const CardPaymentScreen({
    super.key,
    required this.bookingId,
    required this.total,
    this.listingTitle,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _holderController = TextEditingController();
  final _expController = TextEditingController();
  final _cvvController = TextEditingController();
  final _rutController = TextEditingController();

  bool _submitting = false;
  String _brand = 'unknown';

  bool get _isSandbox =>
      (dotenv.env['MP_SANDBOX'] ?? 'true').toLowerCase() == 'true';

  @override
  void initState() {
    super.initState();
    _cardController.addListener(_onCardChange);
    if (_isSandbox) {
      _holderController.text = 'APRO';
      _rutController.text = '12345678-5';
    }
  }

  void _onCardChange() {
    final raw = _cardController.text.replaceAll(' ', '');
    String brand;
    if (raw.startsWith('4')) {
      brand = 'visa';
    } else if (RegExp(r'^5[1-5]').hasMatch(raw)) {
      brand = 'master';
    } else if (RegExp(r'^3[47]').hasMatch(raw)) {
      brand = 'amex';
    } else {
      brand = 'unknown';
    }
    if (brand != _brand && mounted) setState(() => _brand = brand);
  }

  @override
  void dispose() {
    _cardController.dispose();
    _holderController.dispose();
    _expController.dispose();
    _cvvController.dispose();
    _rutController.dispose();
    super.dispose();
  }

  // ─── Validators ───
  String? _vCard(String? v) {
    final raw = (v ?? '').replaceAll(' ', '');
    final l = AppLocalizations.of(context);
    if (raw.length < 13 || raw.length > 19) return l.cardInvalidNumber;
    if (!RegExp(r'^\d+$').hasMatch(raw)) return l.cardOnlyDigits;
    if (!_luhn(raw)) return l.cardNotValid;
    return null;
  }

  bool _luhn(String n) {
    var sum = 0, alt = false;
    for (var i = n.length - 1; i >= 0; i--) {
      var d = int.parse(n[i]);
      if (alt) { d *= 2; if (d > 9) d -= 9; }
      sum += d; alt = !alt;
    }
    return sum % 10 == 0;
  }

  String? _vHolder(String? v) =>
      (v == null || v.trim().length < 2) ? AppLocalizations.of(context).cardEnterName : null;

  String? _vExp(String? v) {
    final t = (v ?? '').trim();
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(t)) return 'MM/AA';
    final p = t.split('/');
    final mm = int.parse(p[0]), yy = int.parse(p[1]);
    if (mm < 1 || mm > 12) return AppLocalizations.of(context).cardInvalidMonth;
    final now = DateTime.now();
    final fy = 2000 + yy;
    if (fy < now.year || (fy == now.year && mm < now.month)) return AppLocalizations.of(context).cardExpired;
    return null;
  }

  String? _vCvv(String? v) {
    final t = (v ?? '').trim();
    final n = _brand == 'amex' ? 4 : 3;
    if (t.length != n || !RegExp(r'^\d+$').hasMatch(t)) return AppLocalizations.of(context).cardInvalid;
    return null;
  }

  String? _vRut(String? v) =>
      (v == null || v.trim().length < 7) ? 'RUT inválido' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();
    try {
      final p = _expController.text.trim().split('/');
      final result = await MercadoPagoService.payWithCard(
        bookingId: widget.bookingId,
        cardNumber: _cardController.text,
        cardHolderName: _holderController.text,
        expirationMonth: int.parse(p[0]),
        expirationYear: 2000 + int.parse(p[1]),
        cvv: _cvvController.text,
        identificationType: 'RUT',
        identificationNumber:
            _rutController.text.trim().replaceAll('.', '').replaceAll('-', ''),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on MpException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).cardPaymentError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: AtrioColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ─── Header ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AtrioColors.guestTextPrimary, size: 22),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const Spacer(),
                    const Icon(Icons.lock_rounded,
                        size: 13, color: AtrioColors.guestTextTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'PAGO SEGURO',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextSecondary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 32), // counter-balance close button
                  ],
                ),
              ),

              // ─── Body ───
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Eyebrow + title
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
                              'CHECKOUT',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextSecondary,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.cardYourCard,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -1.0,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Total card (clean, minimal)
                        _TotalCard(
                          total: widget.total,
                          listing: widget.listingTitle,
                        ),
                        const SizedBox(height: 20),

                        if (_isSandbox) const _SandboxNotice(),
                        if (_isSandbox) const SizedBox(height: 18),

                        // ─── Form ───
                        _Field(
                          label: l.cardNumber,
                          controller: _cardController,
                          hint: '0000 0000 0000 0000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(19),
                            _CardNumFormatter(),
                          ],
                          validator: _vCard,
                          trailing: _BrandTag(brand: _brand),
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label: l.cardHolder,
                          controller: _holderController,
                          hint: l.cardHolderHint,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-zÀ-ÿ\s]')),
                          ],
                          validator: _vHolder,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _Field(
                                label: l.cardExpiry,
                                controller: _expController,
                                hint: 'MM/AA',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpFormatter(),
                                ],
                                validator: _vExp,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _Field(
                                label: l.cardCvv,
                                controller: _cvvController,
                                hint: _brand == 'amex' ? '1234' : '123',
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: _vCvv,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label: l.cardRut,
                          controller: _rutController,
                          hint: '12.345.678-5',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(15),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9kK\.\-]')),
                          ],
                          validator: _vRut,
                        ),
                        const SizedBox(height: 22),

                        // Trust strip
                        Row(
                          children: [
                            const Icon(Icons.lock_rounded,
                                size: 13,
                                color: AtrioColors.guestTextTertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l.cardTrustStrip,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AtrioColors.guestTextTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Footer ───
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, 14, 20, 16 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: AtrioColors.guestBackground,
                  border: Border(
                    top: BorderSide(
                        color: AtrioColors.guestCardBorder, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AtrioColors.neonLime,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      disabledBackgroundColor:
                          AtrioColors.neonLime.withValues(alpha: 0.4),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  l.cardPayTotal(widget.total.toCLP),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: Colors.black),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Total card ───
class _TotalCard extends StatelessWidget {
  final double total;
  final String? listing;
  const _TotalCard({required this.total, this.listing});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.cardToPayLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextTertiary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                if (listing != null && listing!.isNotEmpty)
                  Text(
                    listing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AtrioColors.guestTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            total.toCLP,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AtrioColors.guestTextPrimary,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sandbox notice ───
class _SandboxNotice extends StatelessWidget {
  const _SandboxNotice();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined,
              size: 14, color: Color(0xFF8C6D00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).cardSandboxNotice,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C6D00),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field ───
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final Widget? trailing;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextTertiary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          obscureText: obscureText,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          cursorColor: AtrioColors.neonLimeDark,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AtrioColors.guestTextPrimary,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextTertiary,
            ),
            suffixIcon: trailing,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AtrioColors.guestSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: AtrioColors.guestCardBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: AtrioColors.guestTextPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AtrioColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AtrioColors.error, width: 1.5),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AtrioColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Brand tag ───
class _BrandTag extends StatelessWidget {
  final String brand;
  const _BrandTag({required this.brand});

  @override
  Widget build(BuildContext context) {
    if (brand == 'unknown') {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.credit_card_rounded,
            size: 18, color: AtrioColors.guestTextTertiary),
      );
    }
    String label;
    switch (brand) {
      case 'visa':
        label = 'VISA';
        break;
      case 'master':
        label = 'MC';
        break;
      case 'amex':
        label = 'AMEX';
        break;
      default:
        label = brand.toUpperCase();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AtrioColors.guestTextPrimary,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─── Formatters ───
class _CardNumFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final f = buf.toString();
    return TextEditingValue(
        text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class _ExpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll('/', '');
    String f;
    if (d.length <= 2) {
      f = d;
    } else {
      f = '${d.substring(0, 2)}/${d.substring(2)}';
    }
    return TextEditingValue(
        text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
